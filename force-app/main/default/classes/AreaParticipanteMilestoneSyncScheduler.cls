/**
 * @description       : Scheduler que agenda execução periódica do batch de sincronização de milestones do módulo AreaParticipante.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteMilestoneSyncScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AreaParticipanteMilestoneSyncBatch(), 200);
    }

    public static String schedule(String cronExp) {
        String jobName = 'AreaParticipanteMilestoneSync_' + Datetime.now().format('yyyyMMddHHmmss');
        return System.schedule(jobName, cronExp, new AreaParticipanteMilestoneSyncScheduler());
    }
}