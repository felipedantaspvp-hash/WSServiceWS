/**
 * @description       : Serviço de negócio para o módulo CaseEntitlementAssignment. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : Case Entitlement
 * @last modified on  : 06-12-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseEntitlementAssignmentService {
    private static final String UNIDADE_SALVADOR = 'Atendimento Tecon Salvador';
    private static final String ENTITLEMENT_NAME = 'Atendimento Salvador';
    @TestVisible private static Map<Id, Id> injectedEntitlementByAccount = new Map<Id, Id>();

    public static void assignForSalvador(List<Case> rows) {
        if (rows == null || rows.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        for (Case c : rows) {
            if (c == null) continue;
            if (String.valueOf(c.UnidadeNegocio__c) != UNIDADE_SALVADOR) continue;
            if (c.EntitlementId != null) continue;
            if (c.AccountId != null) accountIds.add(c.AccountId);
        }
        if (accountIds.isEmpty()) return;

        if (Test.isRunningTest() && !injectedEntitlementByAccount.isEmpty()) {
            for (Case c : rows) {
                if (c == null || c.AccountId == null || c.EntitlementId != null) continue;
                if (String.valueOf(c.UnidadeNegocio__c) != UNIDADE_SALVADOR) continue;
                if (injectedEntitlementByAccount.containsKey(c.AccountId)) {
                    c.EntitlementId = injectedEntitlementByAccount.get(c.AccountId);
                }
            }
            return;
        }

        Map<Id, Entitlement> byAccount = new Map<Id, Entitlement>();
        for (Entitlement e : [
            SELECT Id, AccountId
            FROM Entitlement
            WHERE Name = :ENTITLEMENT_NAME
              AND AccountId IN :accountIds
            ORDER BY EndDate DESC NULLS LAST, CreatedDate DESC
        ]) {
            if (!byAccount.containsKey(e.AccountId)) byAccount.put(e.AccountId, e);
        }

        for (Case c : rows) {
            if (c == null || c.AccountId == null) continue;
            if (String.valueOf(c.UnidadeNegocio__c) != UNIDADE_SALVADOR) continue;
            if (c.EntitlementId != null) continue;
            Entitlement match = byAccount.get(c.AccountId);
            if (match != null) c.EntitlementId = match.Id;
        }
    }

    public static Map<String, String> getEntitlementNameByBusinessUnit(Set<String> businessUnits) {
        Map<String, String> result = new Map<String, String>();
        if (businessUnits == null || businessUnits.isEmpty()) return result;
        for (GestaoSLA__c g : [
            SELECT UnidadeNegocio__c, EntitlementProcessName__c
            FROM GestaoSLA__c
            WHERE Ativo__c = true
              AND UnidadeNegocio__c IN :businessUnits
            ORDER BY CreatedDate DESC
        ]) {
            if (!result.containsKey(g.UnidadeNegocio__c)) {
                result.put(g.UnidadeNegocio__c, g.EntitlementProcessName__c);
            }
        }
        return result;
    }

    public static String resolveCanonicalBusinessUnit(String businessUnit) {
        return CaseCreationSelector.resolveCanonicalBusinessUnit(businessUnit);
    }
}