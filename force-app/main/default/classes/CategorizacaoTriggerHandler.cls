public inherited sharing class CategorizacaoTriggerHandler {
    public static void beforeInsert(List<Categorizacao__c> newList) {
        CategorizacaoService.beforeSave(newList);
    }

    public static void beforeUpdate(List<Categorizacao__c> newList) {
        CategorizacaoService.beforeSave(newList);
    }
}