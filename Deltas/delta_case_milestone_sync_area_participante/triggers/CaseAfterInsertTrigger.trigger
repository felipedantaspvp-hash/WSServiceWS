trigger CaseAfterInsertTrigger on Case (after insert) {
    CaseAfterInsertTriggerHandler.afterInsert(Trigger.new);
}
