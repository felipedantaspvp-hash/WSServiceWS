public inherited sharing class CaseRecategorizationSelector {
    @TestVisible private static List<Categorizacao__c> testCategorizacoes;
    @TestVisible private static Group testOwnerQueue;
    @TestVisible private static Map<String, CaseCreationSelector.UnidadeConfig> testConfigsByRtDevName;

    public static Case getCaseById(Id caseId) {
        List<Case> rows = [
            SELECT Id, CaseNumber, Subject, Status, IsClosed,
                RecordTypeId, RecordType.DeveloperName, RecordType.Name,
                UnidadeNegocio__c, TipoCaso__c, Categoria__c, Assunto__c, Subassunto__c,
                Priority,
                OwnerId, DistribuicaoSolicitada__c, OrigemDistribuicao__c, FilaDestinoDeveloperName__c, FilaDestinoId__c,
                EtapaAtendimento__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    public static List<Categorizacao__c> getActiveCategorizacoes(String caseRtDeveloperName, String unidadeNegocio) {
        if (testCategorizacoes != null) return testCategorizacoes;
        return CaseCreationSelector.getActiveCategorizacoes(caseRtDeveloperName, unidadeNegocio);
    }

    public static CaseCreationSelector.UnidadeConfig findConfigForCaseRecordType(String caseRtDeveloperName, String caseRtLabel) {
        return CaseCreationSelector.findConfigForCaseRecordType(caseRtDeveloperName, caseRtLabel);
    }

    public static Group getQueueById(Id queueId) {
        if (testOwnerQueue != null) return testOwnerQueue;
        if (queueId == null) return null;
        List<Group> rows = [SELECT Id, Name, DeveloperName, Type FROM Group WHERE Id = :queueId LIMIT 1];
        return rows.isEmpty() ? null : rows[0];
    }

    public static Map<String, CaseCreationSelector.UnidadeConfig> getUnidadeConfigs() {
        if (testConfigsByRtDevName != null) return testConfigsByRtDevName;
        return CaseCreationSelector.getUnidadeConfigByRtDevName();
    }
}