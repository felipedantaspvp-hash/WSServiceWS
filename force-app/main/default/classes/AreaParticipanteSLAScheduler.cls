public inherited sharing class AreaParticipanteSLAScheduler implements Schedulable {
    public void execute(SchedulableContext sc){ Database.executeBatch(new AreaParticipanteSLABatch(), 200); }
}