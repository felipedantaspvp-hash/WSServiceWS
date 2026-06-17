/**
 * @description       : Batch Apex para reprocessamento em massa de SLA do módulo AreaParticipante. Atualiza marcos vencidos agendadamente.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteSLABatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id,Caso__c,TipoAreaParticipante__c,StatusAtuacao__c,DataHoraFim__c,DataHoraInicio__c,TempoSLAMinutos__c,TempoPausadoMinutos__c,DataHoraPrazo__c,TempoConsumidoMinutos__c,TempoRestanteMinutos__c,PercentualDecorrido__c,StatusSLA__c,ViolouSLA__c FROM AreaParticipante__c WHERE DataHoraFim__c = null AND TipoAreaParticipante__c = 'Área Interna' AND StatusAtuacao__c IN ('Aberta','Em Andamento','Vencida')]);
    }
    public void execute(Database.BatchableContext bc, List<AreaParticipante__c> scope){
        Set<Id> caseIds = new Set<Id>();
        for (AreaParticipante__c a : scope){ AreaParticipanteSLAService.calculateCache(a); caseIds.add(a.Caso__c); }
        if (!scope.isEmpty()) update scope;
        CaseAreaParticipanteAggregationService.refreshForCases(caseIds);
    }
    public void finish(Database.BatchableContext bc){}
}