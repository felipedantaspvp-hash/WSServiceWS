public inherited sharing class AreaParticipanteSLABatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc){
        String tipoAreaInterna = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA;
        String statusAberta = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA;
        String statusAndamento = AreaParticipanteSLAHelper.STATUS_ATUACAO_ANDAMENTO;
        String statusVencida = AreaParticipanteSLAHelper.STATUS_ATUACAO_VENCIDA;
        return Database.getQueryLocator([
            SELECT Id,Caso__c,TipoAreaParticipante__c,StatusAtuacao__c,DataHoraFim__c,DataHoraInicio__c,DataHoraInicioPausa__c,TempoSLAMinutos__c,TempoPausadoMinutos__c,DataHoraPrazo__c,TempoConsumidoMinutos__c,TempoRestanteMinutos__c,PercentualDecorrido__c,StatusSLA__c,ViolouSLA__c
            FROM AreaParticipante__c
            WHERE DataHoraFim__c = null
            AND TipoAreaParticipante__c = :tipoAreaInterna
            AND StatusAtuacao__c IN :new Set<String>{ statusAberta, statusAndamento, statusVencida }
        ]);
    }
    public void execute(Database.BatchableContext bc, List<AreaParticipante__c> scope){
        Set<Id> caseIds = new Set<Id>();
        for (AreaParticipante__c a : scope){ AreaParticipanteSLAService.calculateCache(a); caseIds.add(a.Caso__c); }
        if (!scope.isEmpty()) update scope;
        CaseAreaParticipanteAggregationService.refreshForCases(caseIds);
    }
    public void finish(Database.BatchableContext bc){}
}