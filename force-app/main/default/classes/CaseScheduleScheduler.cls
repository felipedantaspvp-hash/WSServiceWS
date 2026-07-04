/**
 * Schedules the recurring Case generation batch for active Agendamento__c records.
 * Scheduled job "Case Schedule - Geracao Diaria" runs daily at 00:01 (America/Sao_Paulo)
 * in WS_SERVICE — see CR-016 do CodeReview.md.
 */
public with sharing class CaseScheduleScheduler implements Schedulable {
    /**
     * @param context Salesforce scheduler context.
     */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new CaseScheduleBatch(), 100);
    }
}