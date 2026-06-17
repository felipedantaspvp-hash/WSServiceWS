/**
 * @description       : Factory de dados de teste para o módulo AreaParticipante. Cria registros e objetos relacionados para uso em testes.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
public inherited sharing class AreaParticipanteTestDataFactory {
    private static final String AREA_FIELD = 'AreaAtendimento__c';

    public static String pickValue(String objectApiName, String fieldApiName, Integer index) {
        Map<String, Schema.SObjectType> types = Schema.getGlobalDescribe();
        Schema.DescribeFieldResult dfr = types.get(objectApiName).getDescribe().fields.getMap().get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> values = dfr.getPicklistValues();
        Integer safe = values.size() > index ? index : 0;
        return values[safe].getValue();
    }

    public static RecordType anyCaseRt() {
        return [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' AND IsActive = true LIMIT 1];
    }

    public static List<String> commonAreaValues() {
        Set<String> caseValues = new Set<String>();
        for (Schema.PicklistEntry pe : Case.AreasParticipantesSLA__c.getDescribe().getPicklistValues()) {
            caseValues.add(pe.getValue());
        }
        List<String> out = new List<String>();
        for (Schema.PicklistEntry pe : Schema.sObjectType.AreaParticipante__c.fields.getMap().get(AREA_FIELD).getDescribe().getPicklistValues()) {
            if (caseValues.contains(pe.getValue())) out.add(pe.getValue());
        }
        if (out.isEmpty()) {
            for (Schema.PicklistEntry pe : Schema.sObjectType.AreaParticipante__c.fields.getMap().get(AREA_FIELD).getDescribe().getPicklistValues()) out.add(pe.getValue());
        }
        return out;
    }

    public static Case createCase(String area1, String area2) {
        return createCaseInternal(area1, area2, true);
    }

    public static Case createCaseWithoutSla(String area1, String area2) {
        return createCaseInternal(area1, area2, false);
    }

    private static Case createCaseInternal(String area1, String area2, Boolean createSlaRules) {
        RecordType rt = anyCaseRt();
        List<String> allowed = new List<String>();
        for (Schema.PicklistEntry pe : Case.AreasParticipantesSLA__c.getDescribe().getPicklistValues()) allowed.add(pe.getValue());
        if (allowed.isEmpty()) allowed.add('A definir');
        String a1 = String.isBlank(area1) || !allowed.contains(area1) ? allowed[0] : area1;
        String a2 = String.isBlank(area2) || !allowed.contains(area2) ? null : area2;
        String mp = String.isBlank(a2) ? a1 : a1 + ';' + a2;
        Case c = new Case(
            Subject = 'Case AreaParticipante Test',
            RecordTypeId = rt.Id,
            Status = pickValue('Case', 'Status', 0),
            Origin = pickValue('Case', 'Origin', 0),
            Priority = pickValue('Case', 'Priority', 0),
            AreasParticipantesSLA__c = mp,
            EtapaAtendimento__c = 'Aguardando Área Interna'
        );
        insert c;
        if (createSlaRules) {
            GestaoSLA__c sharedGestao = createSharedGestao();
            Categorizacao__c categorizacao = createCategorizacaoForCase();
            categorizacao.GestaoSLA__c = sharedGestao.Id;
            update categorizacao;
            c.Categorizacao__c = categorizacao.Id;
            update c;
            createSlaRule(categorizacao.Id, sharedGestao.Id, a1);
            if (!String.isBlank(a2) && AreaParticipanteHelper.normalizeText(a1) != AreaParticipanteHelper.normalizeText(a2)) {
                createSlaRule(categorizacao.Id, sharedGestao.Id, a2);
            }
        }
        return c;
    }

    private static Categorizacao__c createCategorizacaoForCase() {
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        insert row;
        return row;
    }

    private static GestaoSLA__c createSharedGestao() {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> unidadeEntries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!unidadeEntries.isEmpty()) unidade = unidadeEntries[0].getValue();
        GestaoSLA__c gestao = new GestaoSLA__c(
            Name = 'Gestao SLA Test ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 100000)),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Tecon Salvador',
            Ativo__c = true
        );
        insert gestao;
        return gestao;
    }

    private static RegrasSLACategorizacao__c createSlaRule(Id categorizacaoId, Id gestaoId, String area) {
        RegrasSLACategorizacao__c rule = new RegrasSLACategorizacao__c(
            Categorizacao__c = categorizacaoId,
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'Tecon Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestaoId,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 60,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );
        insert rule;
        return rule;
    }

    public static AreaParticipante__c createArea(Id caseId, String area, String status, Integer prazoOffsetHours) {
        Datetime inicio = System.now().addHours(-2);
        Datetime prazo = System.now().addHours(prazoOffsetHours);
        List<String> allowed = new List<String>();
        for (Schema.PicklistEntry pe : Schema.sObjectType.AreaParticipante__c.fields.getMap().get(AREA_FIELD).getDescribe().getPicklistValues()) allowed.add(pe.getValue());
        String chosenArea = (String.isBlank(area) || !allowed.contains(area)) ? (allowed.isEmpty() ? null : allowed[0]) : area;
        AreaParticipante__c row = new AreaParticipante__c(
            Caso__c = caseId,
            StatusAtuacao__c = status,
            DataHoraInicio__c = inicio,
            DataHoraPrazo__c = prazo,
            ComentarioSolicitacao__c = 'Solicitacao de teste'
        );
        row.put(AREA_FIELD, chosenArea);
        insert row;
        if (prazoOffsetHours != null) {
            row.DataHoraPrazo__c = prazo;
            update row;
        }
        return row;
    }

    public static String openStatus() {
        for (Schema.PicklistEntry pe : AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues()) {
            String n = AreaParticipanteHelper.normalizeText(pe.getValue() + ' ' + pe.getLabel());
            if (n.contains('abert') || n.contains('andamento') || n.contains('open') || n.contains('progress')) return pe.getValue();
        }
        List<Schema.PicklistEntry> values = AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues();
        return values.isEmpty() ? 'Aberta' : values[0].getValue();
    }

    public static String closedStatus() {
        for (Schema.PicklistEntry pe : AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues()) {
            String n = AreaParticipanteHelper.normalizeText(pe.getValue() + ' ' + pe.getLabel());
            if (n.contains('conclu') || n.contains('completed') || n.contains('finaliz')) return pe.getValue();
        }
        return AreaParticipanteHelper.resolveConcluidaStatusValue();
    }
}