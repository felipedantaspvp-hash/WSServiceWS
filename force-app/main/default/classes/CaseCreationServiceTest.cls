@IsTest
private class CaseCreationServiceTest {
    @TestSetup
    static void setupData() {
        Group g = new Group(Name='TSV Queue Test', DeveloperName='TSV_Q_TEST', Type='Queue');
        insert g;
        insert new QueueSobject(QueueId=g.Id, SobjectType='Case');
    }

    @IsTest
    static void testGetInitialContext() {
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>();
        CaseCreationDTO.InitialContextDTO ctx = CaseCreationService.getInitialContext();
        Assert.areEqual(true, ctx.recordTypes.size() > 0);
        Assert.areEqual(UserInfo.getUserId(), ctx.userId);
    }

    @IsTest
    static void testResolveWithParametrizedQueue() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id)
        };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;

        CaseCreationDTO.ResolveSelectionResponseDTO res = CaseCreationService.resolveCategorizationSelection(req);
        Assert.areEqual(true, res.hasParametrizedQueue);
        Assert.areEqual('TSV_Q_TEST', res.queue.developerName);
    }

    @IsTest
    static void testBuildDefaultsAssumir() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(false, false, null, rt.Id);
        cat.Prioridade__c = 'High';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'ASSUMIR';
        req.originalDefaults = new Map<String, String>{ 'AccountId' => '001000000000001AAA' };

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        String unidadeEsperada = CaseCreationSelector.resolveCanonicalBusinessUnit(req.categorization.unidadeNegocio);
        Assert.areEqual(true, out.success);
        Assert.areEqual('Assumir', out.defaultValues.get('AcaoPosCategorizacao__c'));
        Assert.areEqual(unidadeEsperada, out.defaultValues.get('UnidadeNegocio__c'));
        Assert.areEqual('001000000000001AAA', out.defaultValues.get('AccountId'));
        Assert.areEqual('High', out.defaultValues.get('Priority'));
    }

    @IsTest
    static void testFindConfigIgnoresInactiveExactWhenActiveAliasExists() {
        CaseCreationSelector.UnidadeConfig inactiveExact = new CaseCreationSelector.UnidadeConfig();
        inactiveExact.recordTypeDeveloperName = 'TeconRioGrande';
        inactiveExact.unidadeNegocio = 'Tecon Rio Grande';
        inactiveExact.queueToken = 'TRG';
        inactiveExact.ativo = false;

        CaseCreationSelector.UnidadeConfig activeAlias = new CaseCreationSelector.UnidadeConfig();
        activeAlias.recordTypeDeveloperName = 'RioGrande';
        activeAlias.unidadeNegocio = 'Tecon Rio Grande';
        activeAlias.queueToken = 'TRG';
        activeAlias.ativo = true;

        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            'TeconRioGrande' => inactiveExact,
            'RioGrande' => activeAlias
        };

        CaseCreationSelector.UnidadeConfig resolved = CaseCreationSelector.findConfigForCaseRecordType('TeconRioGrande', 'Tecon Rio Grande');
        Assert.areEqual(true, resolved.ativo);
        Assert.areEqual('RioGrande', resolved.recordTypeDeveloperName);
    }

    @IsTest
    static void testBuildDefaultsDistribuirManualWithoutQueueFails() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(false, false, null, rt.Id)
        };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'DISTRIBUIR';

        Boolean threw = false;
        try {
            CaseCreationService.buildDefaultValues(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
    }

    @IsTest
    static void testGetTreeOptionsBuildsDependentLists() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c first = CaseCreationTestDataFactory.catRow(false, false, null, rt.Id);
        Categorizacao__c second = CaseCreationTestDataFactory.catRow(false, false, null, rt.Id);
        second.Categoria__c = 'Financeiro';
        second.Assunto__c = 'Fatura';
        second.Subassunto__c = 'Reenvio';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ first, second };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Operação';
        req.assunto = 'Acesso';

        CaseCreationDTO.TreeOptionsDTO out = CaseCreationService.getTreeOptions(req);
        Assert.areEqual(1, out.tipoCasoOptions.size());
        Assert.areEqual(2, out.categoriaOptions.size());
        Assert.areEqual(1, out.assuntoOptions.size());
        Assert.areEqual(1, out.subassuntoOptions.size());
    }

    @IsTest
    static void testBuildDefaultsEncerrarNormalizesUnit() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(false, false, null, rt.Id)
        };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'ENCERRAR';

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        String unidadeEsperada = CaseCreationSelector.resolveCanonicalBusinessUnit(req.categorization.unidadeNegocio);
        Assert.areEqual('Fechado', out.defaultValues.get('Status'));
        Assert.areEqual('Encerrar', out.defaultValues.get('AcaoPosCategorizacao__c'));
        Assert.areEqual(unidadeEsperada, out.defaultValues.get('UnidadeNegocio__c'));
    }

    @IsTest
    static void testBuildDefaultsDistribuirManualWithAllowedQueue() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = rt.DeveloperName;
        cfg.unidadeNegocio = 'Salvador';
        cfg.queueToken = 'TSV';
        cfg.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{ rt.DeveloperName => cfg };
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(false, false, null, rt.Id)
        };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'DISTRIBUIR';
        req.destination.selectedQueueDeveloperName = 'TSV_Q_TEST';

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        Assert.areEqual(true, out.success);
        Assert.areEqual('Distribuir', out.defaultValues.get('AcaoPosCategorizacao__c'));
        Assert.areEqual('TSV_Q_TEST', out.defaultValues.get('FilaDestinoDeveloperName__c'));
        Assert.areEqual('Seleção Manual', out.defaultValues.get('OrigemDistribuicao__c'));
    }

    @IsTest
    static void testSelectorQueriesAndHelperUtilities() {
        CaseCreationSelector.testConfigs = null;
        CaseCreationSelector.testCategorizacoes = null;

        Map<String, CaseCreationSelector.UnidadeConfig> configs = CaseCreationSelector.getUnidadeConfigByRtDevName();
        Assert.areEqual(true, configs.size() >= 0);

        Set<Id> categRtIds = CaseCreationSelector.getCategorizacaoRecordTypeIdsForCaseRt('TeconRioGrande', 'Tecon Rio Grande');
        Assert.areEqual(true, categRtIds.size() >= 0);
        CaseCreationSelector.getActiveCategorizacoes('TeconRioGrande', 'Tecon Rio Grande');
        CaseCreationSelector.getQueuesByDeveloperName(new Set<String>{ 'TSV_Q_TEST' });
        Set<Id> queueIds = new Set<Id>();
        for (Group g : CaseCreationSelector.getCaseQueuesByToken('TSV')) queueIds.add(g.Id);
        CaseCreationSelector.getCaseEnabledQueueIds(queueIds);

        Assert.areEqual('riogrande', CaseCreationHelper.normalizeKey('Rio Grande'));
        Assert.areEqual(true, CaseCreationHelper.keyMatches('Tecon Rio Grande', 'RioGrande'));
        Assert.areEqual(true, CaseCreationHelper.sameNormalizedValue('Solicitação', 'Solicitacao'));
        Assert.areEqual(true, CaseCreationHelper.isBlank(null));
        Assert.areEqual('abc', CaseCreationHelper.nv(' abc '));
        Assert.areEqual(true, CaseCreationHelper.isTrueFlag('Sim'));
        Assert.areEqual(false, CaseCreationHelper.isTrueFlag('Não'));
        Assert.areEqual(
            CaseCreationSelector.resolveCanonicalBusinessUnit('Rio Grande'),
            CaseCreationHelper.normalizeBusinessUnitForCase('Rio Grande')
        );

        Map<String, String> values = new Map<String, String>();
        CaseCreationHelper.putIfNotBlank(values, 'Subject', 'Teste');
        Assert.areEqual('Teste', values.get('Subject'));
        Assert.areEqual('A', CaseCreationHelper.toOption('A').value);
        Assert.areEqual(2, CaseCreationHelper.toSortedOptions(new Set<String>{ 'B', 'A' }).size());
        Assert.areEqual(true, CaseCreationHelper.toSortedTranslatedOptions(new Set<String>{ 'Manual' }, 'Origin').size() > 0);
        Assert.areEqual(true, CaseCreationHelper.toSortedOptionsWithLabels(new Set<String>{ 'Solicitação' }, new Map<String, String>{ 'Solicitação' => 'Solicitação' }, 'TipoCaso__c').size() > 0);
    }
}