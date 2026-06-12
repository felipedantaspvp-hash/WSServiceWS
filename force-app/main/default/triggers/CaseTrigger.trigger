trigger CaseTrigger on Case (before insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) CaseTriggerHandler.beforeInsert(Trigger.new);
    if (Trigger.isBefore && Trigger.isUpdate) CaseTriggerHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
    if (Trigger.isAfter && Trigger.isUpdate) CaseTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
}