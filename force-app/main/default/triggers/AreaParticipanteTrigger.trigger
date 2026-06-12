trigger AreaParticipanteTrigger on AreaParticipante__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) AreaParticipanteTriggerHandler.beforeInsert(Trigger.new);
    if (Trigger.isBefore && Trigger.isUpdate) AreaParticipanteTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    if (Trigger.isAfter && Trigger.isInsert) AreaParticipanteTriggerHandler.afterInsert(Trigger.new);
    if (Trigger.isAfter && Trigger.isUpdate) AreaParticipanteTriggerHandler.afterUpdate(Trigger.new);
}