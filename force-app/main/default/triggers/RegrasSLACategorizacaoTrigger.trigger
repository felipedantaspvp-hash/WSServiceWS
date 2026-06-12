trigger RegrasSLACategorizacaoTrigger on RegrasSLACategorizacao__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) RegrasSLACategorizacaoTriggerHandler.beforeInsert(Trigger.new);
    if (Trigger.isBefore && Trigger.isUpdate) RegrasSLACategorizacaoTriggerHandler.beforeUpdate(Trigger.new);
}