/**
 * @description       : Scheduler que agenda execução periódica do batch de SLA do módulo AreaParticipante.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteSLAScheduler implements Schedulable {
    public void execute(SchedulableContext sc){ Database.executeBatch(new AreaParticipanteSLABatch(), 200); }
}