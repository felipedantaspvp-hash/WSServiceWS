/**
 * @description       : Handler do trigger do objeto Categorizacao__c. Delega operações aos serviços correspondentes.
 * @author            : Triscal
 * @group             : Categorização
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CategorizacaoTriggerHandler {
    public static void beforeInsert(List<Categorizacao__c> newList) {
        CategorizacaoService.beforeSave(newList);
    }

    public static void beforeUpdate(List<Categorizacao__c> newList) {
        CategorizacaoService.beforeSave(newList);
    }
}