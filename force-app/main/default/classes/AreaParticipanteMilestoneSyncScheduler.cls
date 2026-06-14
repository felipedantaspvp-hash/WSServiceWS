public inherited sharing class AreaParticipanteMilestoneSyncScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AreaParticipanteMilestoneSyncBatch(), 200);
    }

    public static String schedule(String cronExp) {
        String jobName = 'AreaParticipanteMilestoneSync_' + Datetime.now().format('yyyyMMddHHmmss');
        return System.schedule(jobName, cronExp, new AreaParticipanteMilestoneSyncScheduler());
    }
}
