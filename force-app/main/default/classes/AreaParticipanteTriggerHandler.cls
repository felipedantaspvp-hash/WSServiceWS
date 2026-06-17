/**
 * @description       : Handler do trigger do objeto AreaParticipante__c. Delega operações aos serviços correspondentes.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteTriggerHandler {
    public static void beforeInsert(List<AreaParticipante__c> newList){ AreaParticipanteSLAService.beforeSave(newList, null); }
    public static void beforeUpdate(List<AreaParticipante__c> newList, Map<Id, AreaParticipante__c> oldMap){ AreaParticipanteSLAService.beforeSave(newList, oldMap); AreaParticipanteSLAService.closeSLA(newList); }
    public static void afterInsert(List<AreaParticipante__c> newList){ Set<Id> caseIds = new Set<Id>(); for (AreaParticipante__c a : newList) if (a.Caso__c != null) caseIds.add(a.Caso__c); CaseAreaParticipanteAggregationService.refreshForCases(caseIds); }
    public static void afterUpdate(List<AreaParticipante__c> newList){ Set<Id> caseIds = new Set<Id>(); for (AreaParticipante__c a : newList) if (a.Caso__c != null) caseIds.add(a.Caso__c); CaseAreaParticipanteAggregationService.refreshForCases(caseIds); }
}