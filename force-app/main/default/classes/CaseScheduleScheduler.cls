/**
 * Schedules the recurring Case generation batch for active Agendamento__c records.
 */
public with sharing class CaseScheduleScheduler implements Schedulable {
    /**
     * @param context Salesforce scheduler context.
     */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new CaseScheduleBatch(), 100);
    }
}