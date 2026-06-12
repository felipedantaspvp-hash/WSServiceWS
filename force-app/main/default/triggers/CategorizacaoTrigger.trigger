trigger CategorizacaoTrigger on Categorizacao__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CategorizacaoTriggerHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        CategorizacaoTriggerHandler.beforeUpdate(Trigger.new);
    }
}