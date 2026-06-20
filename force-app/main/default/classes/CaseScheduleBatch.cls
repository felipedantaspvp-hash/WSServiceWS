/**
 * Batch that loads active Agendamento__c records and delegates recurring Case generation.
 */
public with sharing class CaseScheduleBatch implements Database.Batchable<SObject> {
    /**
     * @param context Batch context.
     * @return Query locator with active schedules that have the minimum execution fields.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Name, Conta__c, Ativo__c, UnidadeNegocio__c, TipoCaso__c,
                Categoria__c, Assunto__c, Subassunto__c, DataInicio__c,
                DescricaoAtividade__c, UltimoErroExecucao__c, PularFimDeSemana__c,
                Frequencia__c, HorarioExecucao__c, OwnerType__c,
                OwnerQueueDeveloperName__c, OwnerUser__c, RecordTypeId,
                RecordType.DeveloperName
            FROM Agendamento__c
            WHERE Ativo__c = true
                AND Conta__c != null
                AND DataInicio__c != null
                AND HorarioExecucao__c != null
                AND Frequencia__c != null
        ]);
    }

    /**
     * @param context Batch context.
     * @param scope Batch scope.
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Agendamento__c> schedules = new List<Agendamento__c>();
        for (SObject row : scope) {
            schedules.add((Agendamento__c) row);
        }
        CaseScheduleService.processSchedules(schedules);
    }

    /**
     * @param context Batch context.
     */
    public void finish(Database.BatchableContext context) {
        return;
    }
}