/**
 * @description       : Selector de consultas SOQL para o módulo AreaParticipante. Centraliza queries com security enforced, sem lógica de negócio.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-15-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteSelector {
    @TestVisible private static List<AreaParticipante__c> testAreas;
    @TestVisible private static Case testCase;
    private static final String AREA_FIELD = 'AreaAtendimento__c';

    public static Case getCaseById(Id caseId) {
        if (testCase != null) {
            return testCase;
        }
        List<Case> rows = [
            SELECT Id, CaseNumber, OwnerId, Status, IsClosed, Categorizacao__c, Categorizacao__r.GestaoSLA__c, Priority, Origin,
                AreasParticipantes__c, AreasParticipantesSLA__c, EtapaAtendimento__c, IsStopped
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    public static List<AreaParticipante__c> getAreasByCase(Id caseId) {
        if (testAreas != null) {
            return testAreas;
        }
        String soql =
            'SELECT Id, Caso__c, ' + AREA_FIELD + ', StatusAtuacao__c,' +
            ' DataHoraInicio__c, DataHoraInicioPausa__c, DataHoraPrazo__c, DataHoraFim__c, StatusAtuacaoAnteriorPausa__c,' +
            ' ComentarioSolicitacao__c, ComentarioRetorno__c, SolucaoTomada__c,' +
            ' FinalizadoPor__c, FinalizadoPor__r.Name,' +
            ' ViolouSLA__c, NomeMarco__c, CaseMilestoneId__c,' +
            ' Responsavel__c, RequerRetornoCliente__c, BloqueiaFechamentoCaso__c,' +
            ' PercentualDecorrido__c, StatusSLA__c, TempoSLAMinutos__c, TempoPausadoMinutos__c, TempoConsumidoMinutos__c, TempoRestanteMinutos__c, SequenciaAcionamento__c, TipoAreaParticipante__c, OrigemSLA__c, RegraSLACategorizacao__c, RegraSLACategorizacao__r.BusinessHoursName__c' +
            ' FROM AreaParticipante__c' +
            ' WHERE Caso__c = :caseId' +
            ' ORDER BY DataHoraPrazo__c ASC NULLS LAST, CreatedDate DESC';
        return (List<AreaParticipante__c>) Database.query(soql);
    }

    public static AreaParticipante__c getAreaById(Id areaId) {
        String soql =
            'SELECT Id, Caso__c, ' + AREA_FIELD + ', StatusAtuacao__c,' +
            ' DataHoraInicio__c, DataHoraInicioPausa__c, DataHoraPrazo__c, DataHoraFim__c, StatusAtuacaoAnteriorPausa__c,' +
            ' ComentarioSolicitacao__c, ComentarioRetorno__c, SolucaoTomada__c,' +
            ' FinalizadoPor__c, FinalizadoPor__r.Name,' +
            ' ViolouSLA__c, NomeMarco__c, CaseMilestoneId__c,' +
            ' Responsavel__c, RequerRetornoCliente__c, BloqueiaFechamentoCaso__c,' +
            ' PercentualDecorrido__c, StatusSLA__c, TempoSLAMinutos__c, TempoPausadoMinutos__c, TempoConsumidoMinutos__c, TempoRestanteMinutos__c, SequenciaAcionamento__c, TipoAreaParticipante__c, OrigemSLA__c, RegraSLACategorizacao__c, RegraSLACategorizacao__r.BusinessHoursName__c' +
            ' FROM AreaParticipante__c' +
            ' WHERE Id = :areaId LIMIT 1';
        List<AreaParticipante__c> rows = (List<AreaParticipante__c>) Database.query(soql);
        return rows.isEmpty() ? null : rows[0];
    }

    public static List<AreaParticipante__c> getAreasByIds(Set<Id> areaIds) {
        if (areaIds == null || areaIds.isEmpty()) {
            return new List<AreaParticipante__c>();
        }
        String soql =
            'SELECT Id, Caso__c, ' + AREA_FIELD + ', StatusAtuacao__c,' +
            ' DataHoraInicio__c, DataHoraInicioPausa__c, DataHoraPrazo__c, DataHoraFim__c, StatusAtuacaoAnteriorPausa__c,' +
            ' ViolouSLA__c, PercentualDecorrido__c, StatusSLA__c, TempoSLAMinutos__c,' +
            ' TempoPausadoMinutos__c, TempoConsumidoMinutos__c, TempoRestanteMinutos__c,' +
            ' TipoAreaParticipante__c, OrigemSLA__c, RegraSLACategorizacao__c, RegraSLACategorizacao__r.BusinessHoursName__c' +
            ' FROM AreaParticipante__c' +
            ' WHERE Id IN :areaIds';
        return (List<AreaParticipante__c>) Database.query(soql);
    }

    public static Set<String> getEligibleAreaValuesForCase(Case caseRow) {
        Set<String> out = new Set<String>();
        if (caseRow == null || caseRow.Categorizacao__c == null) {
            return out;
        }
        Id gestaoId;
        try {
            SObject categRel = caseRow.getSObject('Categorizacao__r');
            gestaoId = categRel != null ? (Id) categRel.get('GestaoSLA__c') : null;
        } catch (SObjectException ex) {
            gestaoId = null;
        }
        if (gestaoId == null) {
            return out;
        }
        for (RegrasSLACategorizacao__c rule : [
            SELECT AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
                AND Categorizacao__c = :caseRow.Categorizacao__c
                AND GestaoSLA__c = :gestaoId
                AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
                AND AreaAtendimento__c != null
            WITH USER_MODE
        ]) {
            out.add(rule.AreaAtendimento__c);
        }
        return out;
    }

    public static Boolean hasEligibleAreaRule(Case caseRow, String areaValue) {
        if (String.isBlank(areaValue)) {
            return false;
        }
        return getEligibleAreaValuesForCase(caseRow).contains(areaValue);
    }
}