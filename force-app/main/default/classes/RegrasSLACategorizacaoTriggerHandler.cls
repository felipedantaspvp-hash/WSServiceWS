public inherited sharing class RegrasSLACategorizacaoTriggerHandler {
    public static void beforeInsert(List<RegrasSLACategorizacao__c> rows){ RegrasSLACategorizacaoService.beforeSave(rows); }
    public static void beforeUpdate(List<RegrasSLACategorizacao__c> rows){ RegrasSLACategorizacaoService.beforeSave(rows); }
}