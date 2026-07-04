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
    static void testResolveWithCustomFieldValueMatched() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, false, 'TSV_Q_TEST', rt.Id);
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.customFieldValue = 'High';

        CaseCreationDTO.ResolveSelectionResponseDTO res = CaseCreationService.resolveCategorizationSelection(req);
        Assert.areEqual(true, res.usaCampoCustomizado);
        Assert.areEqual('Priority', res.campoDistribuicao);
        Assert.areEqual(true, res.valorDistribuicaoAtendido);
        Assert.areEqual(true, res.hasParametrizedQueue);
        Assert.areEqual('TSV_Q_TEST', res.queue.developerName);
    }

    @IsTest
    static void testResolveWithCustomFieldValueNotMatched() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, false, 'TSV_Q_TEST', rt.Id);
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.customFieldValue = 'Low';

        CaseCreationDTO.ResolveSelectionResponseDTO res = CaseCreationService.resolveCategorizationSelection(req);
        Assert.areEqual(true, res.usaCampoCustomizado);
        Assert.areEqual('Priority', res.campoDistribuicao);
        Assert.areEqual('High', res.valorDistribuicao);
        Assert.areEqual(false, res.valorDistribuicaoAtendido);
        Assert.areEqual(false, res.hasParametrizedQueue);
        Assert.areEqual(true, res.campoDistribuicaoOptions.size() > 0);
    }

    @IsTest
    static void testResolveWithCustomFieldValueNotMatchedUsaFilaFallback() {
        Group fallbackQueue = new Group(Name = 'TSV Queue Fallback', DeveloperName = 'TSV_Q_TEST_FALLBACK', Type = 'Queue');
        insert fallbackQueue;
        insert new QueueSobject(QueueId = fallbackQueue.Id, SobjectType = 'Case');

        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, false, 'TSV_Q_TEST', rt.Id);
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        cat.FilaDeveloperNameFallback__c = 'TSV_Q_TEST_FALLBACK';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.customFieldValue = 'Low';

        CaseCreationDTO.ResolveSelectionResponseDTO res = CaseCreationService.resolveCategorizationSelection(req);
        Assert.areEqual(false, res.valorDistribuicaoAtendido);
        Assert.areEqual(true, res.hasParametrizedQueue);
        Assert.areEqual('TSV_Q_TEST_FALLBACK', res.queue.developerName);
    }

    @IsTest
    static void testResolveExpoePermiteAssumirComFilaParametrizada() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id);
        cat.PermiteAssumirComFilaParametrizada__c = 'Não';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;

        CaseCreationDTO.ResolveSelectionResponseDTO res = CaseCreationService.resolveCategorizationSelection(req);
        Assert.areEqual(true, res.hasParametrizedQueue);
        Assert.areEqual(false, res.permiteAssumirComFilaParametrizada);
    }

    @IsTest
    static void testBuildDefaultsDistribuirComCampoCustomizadoAtendido() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, false, 'TSV_Q_TEST', rt.Id);
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.categorization.customFieldValue = 'High';
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'DISTRIBUIR';

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        Assert.areEqual(true, out.success);
        Assert.areEqual('High', out.defaultValues.get('Priority'));
        Assert.areEqual('TSV_Q_TEST', out.defaultValues.get('FilaDestinoDeveloperName__c'));
        Assert.areEqual('Categorização', out.defaultValues.get('OrigemDistribuicao__c'));
    }

    @IsTest
    static void testBuildDefaultsAssumirBloqueadoQuandoCategorizacaoNaoPermite() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id);
        cat.PermiteAssumirComFilaParametrizada__c = 'Não';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'ASSUMIR';

        Boolean threw = false;
        try {
            CaseCreationService.buildDefaultValues(req);
        } catch (CaseCreationService.FunctionalException ex) {
            threw = true;
            Assert.areEqual('ASSUMIR_NAO_PERMITIDO', ex.code);
        }
        Assert.areEqual(true, threw, 'Assumir deve ser bloqueado no servidor quando a Categorização não permite, não só escondido na UI.');
    }

    @IsTest
    static void testBuildDefaultsAssumirPermitidoQuandoCategorizacaoPermite() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id);
        cat.PermiteAssumirComFilaParametrizada__c = 'Sim';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'ASSUMIR';

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        Assert.areEqual(true, out.success);
        Assert.areEqual('Assumir', out.defaultValues.get('AcaoPosCategorizacao__c'));
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
    static void testGetTreeOptionsThrowsWhenReadAccessIsDenied() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;

        ApexTestSeam.set('CaseCreationService.caseReadAccess', false);
        try {
            CaseCreationService.getTreeOptions(req);
            Assert.fail('Era esperado bloquear a leitura da árvore quando o acesso ao objeto Case é negado.');
        } catch (CaseCreationService.FunctionalException ex) {
            Assert.areEqual('CRUD_DENIED', ex.code);
        } finally {
            ApexTestSeam.clear('CaseCreationService.caseReadAccess');
            ApexTestSeam.clear('CaseCreationService.categorizacaoReadAccess');
        }
    }

    @IsTest
    static void testResolveCategorizationSelectionThrowsWhenReadAccessIsDenied() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id);
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.CategorizationRequestDTO req = CaseCreationTestDataFactory.baseCategorization();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;

        ApexTestSeam.set('CaseCreationService.categorizacaoReadAccess', false);
        try {
            CaseCreationService.resolveCategorizationSelection(req);
            Assert.fail('Era esperado bloquear a leitura da categorização quando o acesso é negado.');
        } catch (CaseCreationService.FunctionalException ex) {
            Assert.areEqual('CRUD_DENIED', ex.code);
        } finally {
            ApexTestSeam.clear('CaseCreationService.caseReadAccess');
            ApexTestSeam.clear('CaseCreationService.categorizacaoReadAccess');
            CaseCreationSelector.testCategorizacoes = null;
        }
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
    static void testBuildDefaultsDistribuirUsaEtapaConfiguradaNaCategorizacao() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        Categorizacao__c cat = CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id);
        cat.EtapaAtendimentoDistribuicao__c = 'Aguardando Cliente';
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'DISTRIBUIR';

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        Assert.areEqual(true, out.success);
        Assert.areEqual('Aguardando Cliente', out.defaultValues.get('EtapaAtendimento__c'));
    }

    @IsTest
    static void testBuildDefaultsDistribuirSemEtapaConfiguradaUsaFallbackEmTriagem() {
        RecordType rt = CaseCreationTestDataFactory.anyCaseRt();
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(true, true, 'TSV_Q_TEST', rt.Id)
        };

        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        req.categorization = CaseCreationTestDataFactory.baseCategorization();
        req.categorization.recordTypeId = rt.Id;
        req.categorization.recordTypeDeveloperName = rt.DeveloperName;
        req.destination = new CaseCreationDTO.DestinationRequestDTO();
        req.destination.action = 'DISTRIBUIR';

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationService.buildDefaultValues(req);
        Assert.areEqual('Em Triagem', out.defaultValues.get('EtapaAtendimento__c'));
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

    private static RecordType salvadorCategorizacaoRt() {
        return [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Categorizacao__c' AND DeveloperName = 'AtendimentoTeconSalvador' LIMIT 1];
    }

    private static RecordType salvadorCaseRt() {
        return [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'AtendimentoTeconSalvador' LIMIT 1];
    }

    @IsTest
    static void testApplyCategorizacaoDistributionOverridesOwnerWhenFieldMatches() {
        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, false);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c, FilaId__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'TSV_Q_TEST' LIMIT 1];

        Case c = new Case(
            Subject = 'Teste distribuição por campo customizado',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Aberto',
            Priority = 'High',
            Categorizacao__c = cat.Id
        );
        insert c;

        Case saved = [SELECT OwnerId, DistribuicaoSolicitada__c, OrigemDistribuicao__c, FilaDestinoDeveloperName__c, FilaDestinoId__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(queue.Id, saved.OwnerId, 'Owner deve ser sobrescrito para a fila quando o valor do campo customizado bate com o configurado.');
        Assert.areEqual(true, saved.DistribuicaoSolicitada__c);
        Assert.areEqual('Categorização', saved.OrigemDistribuicao__c);
        Assert.areEqual('TSV_Q_TEST', saved.FilaDestinoDeveloperName__c);
        Assert.areEqual(queue.Id, saved.FilaDestinoId__c);
    }

    @IsTest
    static void testApplyCategorizacaoDistributionUsaFilaFallbackQuandoValorNaoBate() {
        Group fallbackQueue = new Group(Name = 'TSV Queue Fallback Test', DeveloperName = 'TSV_Q_TEST_FALLBACK', Type = 'Queue');
        insert fallbackQueue;
        insert new QueueSobject(QueueId = fallbackQueue.Id, SobjectType = 'Case');

        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, false);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        cat.FilaDeveloperNameFallback__c = 'TSV_Q_TEST_FALLBACK';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Case c = new Case(
            Subject = 'Teste fila de fallback quando valor não bate',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Aberto',
            Priority = 'Low',
            Categorizacao__c = cat.Id
        );
        insert c;

        Case saved = [SELECT OwnerId, DistribuicaoSolicitada__c, FilaDestinoDeveloperName__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(fallbackQueue.Id, saved.OwnerId, 'Owner deve ser a fila de fallback quando o valor do campo não bate e há fallback configurado.');
        Assert.areEqual(true, saved.DistribuicaoSolicitada__c);
        Assert.areEqual('TSV_Q_TEST_FALLBACK', saved.FilaDestinoDeveloperName__c);
    }

    @IsTest
    static void testApplyCategorizacaoDistributionNaoSobrescreveOwnerQuandoValorNaoBateESemFallback() {
        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, false);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.CampoDistribuicao__c = 'Priority';
        cat.ValorDistribuicao__c = 'High';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Id currentUserId = UserInfo.getUserId();
        Case c = new Case(
            Subject = 'Teste distribuição por campo customizado - valor diferente',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Aberto',
            Priority = 'Low',
            Categorizacao__c = cat.Id,
            OwnerId = currentUserId
        );
        insert c;

        Case saved = [SELECT OwnerId, DistribuicaoSolicitada__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(currentUserId, saved.OwnerId, 'Owner não deve ser alterado quando o valor do campo não bate e não há fila de fallback.');
        Assert.areEqual(false, saved.DistribuicaoSolicitada__c);
    }

    @IsTest
    static void testApplyCategorizacaoDistributionFilaFixaSemAcaoForcaOwnerParaFila() {
        // Simula carga em massa/integração: Categorizacao__c com fila fixa (sem campo customizado),
        // Case criado sem nenhuma das telas (AcaoPosCategorizacao__c em branco) — desde o Pacote 28
        // essa distribuição é sempre reforçada pelo trigger, não só sugerida no wizard.
        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, true);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.EtapaAtendimentoDistribuicao__c = 'Em Atendimento';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'TSV_Q_TEST' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();
        Case c = new Case(
            Subject = 'Teste fila fixa via carga, sem AcaoPosCategorizacao__c',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Aberto',
            Priority = 'High',
            EtapaAtendimento__c = 'Novo',
            Categorizacao__c = cat.Id,
            OwnerId = currentUserId
        );
        insert c;

        Case saved = [SELECT OwnerId, EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(queue.Id, saved.OwnerId, 'Carga sem ação explícita deve sempre respeitar a fila parametrizada da Categorização.');
        Assert.areEqual('Em Atendimento', saved.EtapaAtendimento__c, 'A etapa configurada na Categorização deve ser aplicada ao forçar a distribuição.');
    }

    @IsTest
    static void testApplyCategorizacaoDistributionAssumirPermitidoNaoSobrescreveOwner() {
        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, true);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.PermiteAssumirComFilaParametrizada__c = 'Sim';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Id currentUserId = UserInfo.getUserId();
        Case c = new Case(
            Subject = 'Teste Assumir permitido mesmo com fila parametrizada',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Aberto',
            Priority = 'High',
            Categorizacao__c = cat.Id,
            OwnerId = currentUserId,
            AcaoPosCategorizacao__c = 'Assumir'
        );
        insert c;

        Case saved = [SELECT OwnerId, DistribuicaoSolicitada__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(currentUserId, saved.OwnerId, 'Quando a Categorização permite assumir, o bypass explícito (Assumir) não deve ser sobrescrito.');
        Assert.areEqual(false, saved.DistribuicaoSolicitada__c);
    }

    @IsTest
    static void testApplyCategorizacaoDistributionAssumirNaoPermitidoForcaOwnerParaFila() {
        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, true);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.PermiteAssumirComFilaParametrizada__c = 'Não';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'TSV_Q_TEST' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();
        Case c = new Case(
            Subject = 'Teste Assumir bloqueado pela Categorização',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Aberto',
            Priority = 'High',
            Categorizacao__c = cat.Id,
            OwnerId = currentUserId,
            AcaoPosCategorizacao__c = 'Assumir'
        );
        insert c;

        Case saved = [SELECT OwnerId, DistribuicaoSolicitada__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(queue.Id, saved.OwnerId, 'Quando a Categorização não permite assumir, mesmo um Assumir explícito deve ser sobrescrito para a fila.');
        Assert.areEqual(true, saved.DistribuicaoSolicitada__c);
    }

    @IsTest
    static void testApplyCategorizacaoDistributionEncerrarNuncaEnfileira() {
        Categorizacao__c cat = CategorizacaoTestDataFactory.base(true, true);
        cat.RecordTypeId = salvadorCategorizacaoRt().Id;
        cat.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        cat.FilaDeveloperName__c = 'TSV_Q_TEST';
        cat.PermiteAssumirComFilaParametrizada__c = 'Não';
        insert cat;
        cat = [SELECT Id, UnidadeNegocios__c FROM Categorizacao__c WHERE Id = :cat.Id];

        Id currentUserId = UserInfo.getUserId();
        Case c = new Case(
            Subject = 'Teste Case fechado na criação nunca é enfileirado',
            RecordTypeId = salvadorCaseRt().Id,
            UnidadeNegocio__c = 'Atendimento Tecon Salvador',
            Origin = 'Manual',
            Status = 'Fechado',
            Priority = 'High',
            Categorizacao__c = cat.Id,
            OwnerId = currentUserId,
            AcaoPosCategorizacao__c = 'Encerrar'
        );
        insert c;

        Case saved = [SELECT OwnerId, DistribuicaoSolicitada__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(currentUserId, saved.OwnerId, 'Encerrar na criação nunca deve enfileirar o Case, mesmo sem permissão de Assumir.');
        Assert.areEqual(false, saved.DistribuicaoSolicitada__c);
    }
}
