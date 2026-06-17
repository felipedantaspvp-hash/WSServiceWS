/**
 * @description       : Testes unitários de CaseEntitlementAssignmentService.
 * @author            : Triscal
 * @group             : Case Entitlement
 * @last modified on  : 06-12-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class CaseEntitlementAssignmentServiceTest {
    private static String configuredBusinessUnit() {
        return CaseCreationSelector.resolveCanonicalBusinessUnit('AtendimentoTeconSalvador');
    }

    private static GestaoSLA__c createGestaoAtiva() {
        return new GestaoSLA__c(
            Name = 'Gestao SLA Teste ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = configuredBusinessUnit(),
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true
        );
    }

    @IsTest
    static void testAssignForSalvadorByInjectedEntitlement() {
        Account acc = new Account(Name = 'ACC SLA ENT');
        insert acc;

        Id fakeEntitlementId = UserInfo.getUserId();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.clear();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.put(acc.Id, fakeEntitlementId);

        Case c = new Case(AccountId = acc.Id);
        c.put('UnidadeNegocio__c', configuredBusinessUnit());

        CaseEntitlementAssignmentService.assignForSalvador(new List<Case>{ c });
        Assert.areEqual(fakeEntitlementId, c.EntitlementId);
    }

    @IsTest
    static void testIgnoreNullAndEmptyInputs() {
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.clear();
        CaseEntitlementAssignmentService.assignForSalvador(null);
        CaseEntitlementAssignmentService.assignForSalvador(new List<Case>());
        Assert.areEqual(0, CaseEntitlementAssignmentService.injectedEntitlementByAccount.size());
    }

    @IsTest
    static void testIgnoreCasesWithoutConfiguredUnitOrWithoutAccount() {
        Account acc = new Account(Name = 'ACC OTHER');
        insert acc;

        Id fakeEntitlementId = UserInfo.getUserId();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.clear();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.put(acc.Id, fakeEntitlementId);

        Case rio = new Case(AccountId = acc.Id);
        rio.put('UnidadeNegocio__c', 'Unidade Sem Configuracao');

        Case noAccount = new Case();
        noAccount.put('UnidadeNegocio__c', configuredBusinessUnit());

        CaseEntitlementAssignmentService.assignForSalvador(new List<Case>{ rio, noAccount });
        Assert.areEqual(null, rio.EntitlementId);
        Assert.areEqual(null, noAccount.EntitlementId);
    }

    @IsTest
    static void testKeepExistingEntitlement() {
        Account acc = new Account(Name = 'ACC KEEP ENT');
        insert acc;

        Id existingEntitlementId = UserInfo.getProfileId();
        Id injectedEntitlementId = UserInfo.getUserId();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.clear();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.put(acc.Id, injectedEntitlementId);

        Case c = new Case(AccountId = acc.Id, EntitlementId = existingEntitlementId);
        c.put('UnidadeNegocio__c', configuredBusinessUnit());

        CaseEntitlementAssignmentService.assignForSalvador(new List<Case>{ c });
        Assert.areEqual(existingEntitlementId, c.EntitlementId);
    }

    @IsTest
    static void testInjectedMapWithoutMatchingAccountDoesNotAssign() {
        Account acc = new Account(Name = 'ACC NO MATCH');
        insert acc;

        CaseEntitlementAssignmentService.injectedEntitlementByAccount.clear();
        CaseEntitlementAssignmentService.injectedEntitlementByAccount.put(UserInfo.getUserId(), UserInfo.getProfileId());

        Case c = new Case(AccountId = acc.Id);
        c.put('UnidadeNegocio__c', configuredBusinessUnit());

        CaseEntitlementAssignmentService.assignForSalvador(new List<Case>{ c });
        Assert.areEqual(null, c.EntitlementId);
    }

    @IsTest
    static void testQueryBranchWithoutInjectedMapKeepsEntitlementNullWhenNoMatchExists() {
        Account acc = new Account(Name = 'ACC QUERY BRANCH');
        insert acc;

        insert createGestaoAtiva();

        CaseEntitlementAssignmentService.injectedEntitlementByAccount.clear();

        Case c = new Case(AccountId = acc.Id);
        c.put('UnidadeNegocio__c', configuredBusinessUnit());

        Test.startTest();
        CaseEntitlementAssignmentService.assignForSalvador(new List<Case>{ c });
        Test.stopTest();

        Assert.areEqual(null, c.EntitlementId);
    }

    @IsTest
    static void testGetEntitlementNameByBusinessUnitReturnsConfiguredName() {
        insert createGestaoAtiva();

        Map<String, String> byUnit = CaseEntitlementAssignmentService.getEntitlementNameByBusinessUnit(
            new Set<String>{ configuredBusinessUnit() }
        );

        Assert.areEqual('Atendimento Salvador', byUnit.get(configuredBusinessUnit()));
    }

    @IsTest
    static void testResolveCanonicalBusinessUnitUsesMetadataMapping() {
        Assert.areEqual(
            configuredBusinessUnit(),
            CaseEntitlementAssignmentService.resolveCanonicalBusinessUnit('AtendimentoTeconSalvador')
        );
    }
}