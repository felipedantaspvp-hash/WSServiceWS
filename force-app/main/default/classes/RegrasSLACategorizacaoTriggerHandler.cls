/**
 * @description       : Handler do trigger do objeto RegrasSLACategorizacao__c. Delega operações aos serviços correspondentes.
 * @author            : Triscal
 * @group             : Regras de SLA
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class RegrasSLACategorizacaoTriggerHandler {
    public static void beforeInsert(List<RegrasSLACategorizacao__c> rows){ RegrasSLACategorizacaoService.beforeSave(rows); }
    public static void beforeUpdate(List<RegrasSLACategorizacao__c> rows){ RegrasSLACategorizacaoService.beforeSave(rows); }
}