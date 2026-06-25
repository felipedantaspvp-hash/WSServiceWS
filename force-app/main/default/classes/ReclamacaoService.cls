/**
 * @description       : Geração automática do espelho em Reclamacao__c ao encerrar um Case de
 *                       Tipo de Caso = Reclamação, para as unidades habilitadas via
 *                       ParametrosAtendimento__mdt.GerarReclamacaoNoEncerramento__c (sem hardcode
 *                       de unidade no Apex).
 * @author            : Triscal
 * @group             : Reclamações
 **/
public inherited sharing class ReclamacaoService {
    private static final String TIPO_CASO_RECLAMACAO = 'Reclamação';

    @TestVisible private static Map<String, Id> testRecordTypeIdByDeveloperName;
    private static Map<String, Id> recordTypeIdByDeveloperName;

    /**
     * @description Para os Cases encerrados nesta transação elegíveis (Tipo de Caso =
     * Reclamação, unidade habilitada via Custom Metadata, ainda não gerados), cria o espelho em
     * Reclamacao__c e marca os campos de controle no Case. Deve ser chamado em afterUpdate:
     * Case.IsClosed só reflete o valor final do Status já recalculado nesse momento (em
     * beforeUpdate ainda carrega o valor anterior à mudança de Status sendo salva).
     */
    public static void handleClosure(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        if (newMap == null || oldMap == null) return;

        List<Case> eligible = new List<Case>();
        for (Id caseId : newMap.keySet()) {
            Case newC = newMap.get(caseId);
            Case oldC = oldMap.get(caseId);
            if (newC == null || oldC == null) continue;
            if (oldC.IsClosed == true) continue; // não é uma transição de encerramento nesta gravação
            if (isEligibleForAutomaticGeneration(newC)) eligible.add(newC);
        }
        processEligibleCases(eligible);
    }

    /**
     * @description Cobre cargas (Data Loader/API) que inserem o Case já encerrado, sem passar
     * pela transição aberto→fechado de um update (nesse caso afterUpdate nunca dispara). Deve ser
     * chamado em afterInsert - ver CaseAfterInsertTriggerHandler.afterInsert.
     */
    public static void handleClosureOnInsert(List<Case> newList) {
        if (newList == null || newList.isEmpty()) return;

        List<Case> eligible = new List<Case>();
        for (Case newC : newList) {
            if (isEligibleForAutomaticGeneration(newC)) eligible.add(newC);
        }
        processEligibleCases(eligible);
    }

    private static void processEligibleCases(List<Case> eligible) {
        if (eligible.isEmpty()) return;

        List<Reclamacao__c> toInsert = new List<Reclamacao__c>();
        List<Case> toUpdate = new List<Case>();
        for (Case c : eligible) {
            AtendimentoConfigDTO cfg = AtendimentoConfigService.getSurveyConfigByBusinessUnit(c.UnidadeNegocio__c);
            toInsert.add(buildReclamacao(c, cfg));
            toUpdate.add(new Case(Id = c.Id, ReclamacaoGerada__c = true, DtGeracaoReclamacao__c = System.now()));
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    /**
     * @description Indica se o Case é elegível para que a tela de encerramento ofereça a opção
     * "Gerar Reclamação?" ao usuário: unidade habilitada via Custom Metadata, Tipo de Caso =
     * Reclamação e ainda não gerada.
     */
    public static Boolean isEligibleForManualDecision(Case c, AtendimentoConfigDTO cfg) {
        return c != null
            && cfg != null
            && cfg.gerarReclamacaoNoEncerramento == true
            && c.TipoCaso__c == TIPO_CASO_RECLAMACAO
            && c.ReclamacaoGerada__c != true;
    }

    /**
     * @description Elegibilidade para o motor AUTOMÁTICO (trigger) decidir por conta própria -
     * usada tanto na transição aberto→fechado (update) quanto na carga já fechada (insert).
     * Não se aplica quando a tela assistida de encerramento já capturou a decisão nesta
     * transação (ReclamacaoDecisaoManual__c) - nesse caso a escolha do usuário é soberana,
     * inclusive quando ele escolhe não gerar.
     */
    private static Boolean isEligibleForAutomaticGeneration(Case c) {
        if (c == null) return false;
        if (c.ReclamacaoDecisaoManual__c == true) return false;
        if (c.IsClosed != true) return false;
        if (c.TipoCaso__c != TIPO_CASO_RECLAMACAO) return false;
        if (c.ReclamacaoGerada__c == true) return false;

        AtendimentoConfigDTO cfg = AtendimentoConfigService.getSurveyConfigByBusinessUnit(c.UnidadeNegocio__c);
        return cfg != null && cfg.gerarReclamacaoNoEncerramento == true;
    }

    public static Reclamacao__c buildReclamacao(Case c, AtendimentoConfigDTO cfg) {
        Reclamacao__c r = new Reclamacao__c();
        r.Caso__c = c.Id;
        r.Categoria__c = c.Categoria__c;
        r.Assunto__c = c.Assunto__c;
        r.Subassunto__c = c.Subassunto__c;
        // Area__c e Unidade__c hoje são picklists distintos com o mesmo conjunto de valores
        // (achado de auditoria: redundância pré-existente no objeto, fora de escopo corrigir
        // agora) - preenchidos com o mesmo valor para não deixar nenhum dos dois em branco.
        r.Area__c = cfg == null ? null : cfg.reclamacaoAreaValue;
        r.Unidade__c = cfg == null ? null : cfg.reclamacaoAreaValue;

        Id rtId = resolveRecordTypeId(cfg == null ? null : cfg.reclamacaoRecordTypeDeveloperName);
        if (rtId != null) r.RecordTypeId = rtId;
        return r;
    }

    private static Id resolveRecordTypeId(String developerName) {
        if (String.isBlank(developerName)) return null;
        return getRecordTypeIdByDeveloperName().get(developerName);
    }

    private static Map<String, Id> getRecordTypeIdByDeveloperName() {
        if (Test.isRunningTest() && testRecordTypeIdByDeveloperName != null) {
            return testRecordTypeIdByDeveloperName;
        }
        if (recordTypeIdByDeveloperName != null) return recordTypeIdByDeveloperName;

        recordTypeIdByDeveloperName = new Map<String, Id>();
        for (Schema.RecordTypeInfo info : Reclamacao__c.SObjectType.getDescribe().getRecordTypeInfos()) {
            recordTypeIdByDeveloperName.put(info.getDeveloperName(), info.getRecordTypeId());
        }
        return recordTypeIdByDeveloperName;
    }
}