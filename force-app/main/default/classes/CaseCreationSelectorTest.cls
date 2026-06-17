/**
 * @description       : Testes unitários de CaseCreationSelector.
 * @author            : Triscal
 * @group             : Case Creation
 * @last modified on  : 06-12-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class CaseCreationSelectorTest {
    @IsTest
    static void testFindConfigFuzzyMatchNoMatch() {
        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = 'TeconSalvador';
        cfg.unidadeNegocio = 'SalvadorUnidade';
        cfg.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            'TeconSalvador' => cfg
        };

        CaseCreationSelector.UnidadeConfig result = CaseCreationSelector.findConfigForCaseRecordType(
            'XyzCompletamenteDesconhecido',
            'XyzLabel'
        );

        Assert.isNull(result);
    }

    @IsTest
    static void testFindConfigFuzzyMatchByUnidadeNegocio() {
        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = 'UniquePrefixRT';
        cfg.unidadeNegocio = 'SalvadorUnidade';
        cfg.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            'UniquePrefixRT' => cfg
        };

        CaseCreationSelector.UnidadeConfig result = CaseCreationSelector.findConfigForCaseRecordType(
            'SalvadorUnidade',
            'SalvadorLabel'
        );

        Assert.isNotNull(result);
    }

    @IsTest
    static void testFindConfigInactiveSkipped() {
        CaseCreationSelector.UnidadeConfig inactive = new CaseCreationSelector.UnidadeConfig();
        inactive.recordTypeDeveloperName = 'InactiveRT';
        inactive.unidadeNegocio = 'SomeUnidade';
        inactive.ativo = false;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            'InactiveRT' => inactive
        };

        CaseCreationSelector.UnidadeConfig result = CaseCreationSelector.findConfigForCaseRecordType(
            'InactiveRT',
            'InactiveLabel'
        );

        Assert.isNull(result);
    }

    @IsTest
    static void testFindConfigCentroLogistico() {
        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = 'CentroLogistico';
        cfg.unidadeNegocio = 'CentroLogistico';
        cfg.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            'CentroLogistico' => cfg
        };

        CaseCreationSelector.UnidadeConfig result = CaseCreationSelector.findConfigForCaseRecordType(
            'centrologistico',
            'logistica'
        );

        Assert.isNotNull(result);
    }

    @IsTest
    static void testGetQueuesByDeveloperName() {
        Set<String> names = new Set<String>{ 'NonExistentQueueDEV12345' };
        Map<String, Group> result = CaseCreationSelector.getQueuesByDeveloperName(names);
        Assert.isNotNull(result);
    }

    @IsTest
    static void testGetCaseEnabledQueueIds() {
        Set<Id> emptyIds = new Set<Id>();
        Set<Id> result = CaseCreationSelector.getCaseEnabledQueueIds(emptyIds);
        Assert.areEqual(0, result.size());
    }

    @IsTest
    static void testGetCaseQueuesByTokenBlank() {
        List<Group> result = CaseCreationSelector.getCaseQueuesByToken(null);
        Assert.areEqual(0, result.size());
    }

    @IsTest
    static void testGetBusinessUnitAliasesTeconSalvador() {
        Set<String> aliases = CaseCreationSelector.getBusinessUnitAliases('Atendimento Salvador');
        Assert.areEqual(true, aliases.contains('Atendimento Salvador'));
        Assert.areEqual(true, aliases.contains('Salvador'));
        Assert.areEqual(true, aliases.contains('Tecon Salvador'));
    }

    @IsTest
    static void testGetBusinessUnitAliasesTeconRioGrande() {
        Set<String> aliases = CaseCreationSelector.getBusinessUnitAliases('Atendimento Rio Grande');
        Assert.areEqual(true, aliases.contains('Atendimento Rio Grande'));
        Assert.areEqual(true, aliases.contains('Atendimento Tecon Rio Grande'));
        Assert.areEqual(true, aliases.contains('Rio Grande'));
        Assert.areEqual(true, aliases.contains('Tecon Rio Grande'));
    }

    @IsTest
    static void testResolveCanonicalBusinessUnitFromLegacyAlias() {
        CaseCreationSelector.UnidadeConfig salvadorCfg = CaseCreationSelector.findConfigForBusinessUnit('Tecon Salvador');
        CaseCreationSelector.UnidadeConfig rioGrandeCfg = CaseCreationSelector.findConfigForBusinessUnit('Rio Grande');
        Assert.areEqual(
            salvadorCfg != null ? salvadorCfg.unidadeNegocio : CaseCreationHelper.normalizeBusinessUnitForCase('Tecon Salvador'),
            CaseCreationSelector.resolveCanonicalBusinessUnit('Tecon Salvador')
        );
        Assert.areEqual(
            rioGrandeCfg != null ? rioGrandeCfg.unidadeNegocio : CaseCreationHelper.normalizeBusinessUnitForCase('Rio Grande'),
            CaseCreationSelector.resolveCanonicalBusinessUnit('Rio Grande')
        );
    }

    @IsTest
    static void testGetCategorizacaoRecordTypeIdsForCaseRt() {
        CaseCreationSelector.testConfigs = null;
        Test.startTest();
        Set<Id> ids = CaseCreationSelector.getCategorizacaoRecordTypeIdsForCaseRt('TeconSalvador', 'Atendimento Salvador');
        Test.stopTest();
        Assert.isNotNull(ids);
    }
}