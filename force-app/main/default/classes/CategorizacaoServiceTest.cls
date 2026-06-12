@IsTest
private class CategorizacaoServiceTest {
    private static String unidadeFromRt(String rtDevName) {
        String canonical = CaseCreationSelector.resolveCanonicalBusinessUnit(rtDevName);
        return String.isBlank(canonical)
            ? CaseCreationSelector.resolveCanonicalBusinessUnit('Tecon Salvador')
            : canonical;
    }

    private static RecordType currentRt() {
        List<RecordType> preferred = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Categorizacao__c'
              AND DeveloperName IN ('AtendimentoTeconSalvador', 'TeconSalvador', 'Salvador')
            ORDER BY DeveloperName DESC
            LIMIT 1
        ];
        return preferred.isEmpty()
            ? [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Categorizacao__c' LIMIT 1]
            : preferred[0];
    }

    private static String queueDevNameFromRt(String rtDevName) {
        CategorizacaoSelector.UnidadeConfig cfg = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName().get(rtDevName);
        String prefix = cfg == null || String.isBlank(cfg.queuePrefix) ? 'TSV' : cfg.queuePrefix;
        return prefix + '_TEST';
    }

    private static void configureRuntimeOverrides() {
        RecordType rt = currentRt();
        CategorizacaoSelector.UnidadeConfig c = new CategorizacaoSelector.UnidadeConfig();
        c.recordTypeDeveloperName = rt.DeveloperName;
        c.unidadeNegocio = unidadeFromRt(rt.DeveloperName);
        CategorizacaoSelector.UnidadeConfig metadataCfg = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName().get(rt.DeveloperName);
        c.queuePrefix = metadataCfg == null || String.isBlank(metadataCfg.queuePrefix) ? 'TSV' : metadataCfg.queuePrefix;
        c.ativo = true;
        CategorizacaoSelector.testConfigs = new Map<String, CategorizacaoSelector.UnidadeConfig>{ rt.DeveloperName => c };

        String queueDeveloperName = c.queuePrefix + '_TEST';
        CategorizacaoSelector.QueueData queue = new CategorizacaoSelector.QueueData();
        queue.id = UserInfo.getUserId();
        queue.name = queueDeveloperName;
        queue.developerName = queueDeveloperName;
        CategorizacaoSelector.testQueuesByDevName = new Map<String, CategorizacaoSelector.QueueData>{
            queueDeveloperName => queue
        };
    }

    @IsTest
    static void testSemDistribuicaoGeraHash() {
        configureRuntimeOverrides();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        row.RecordTypeId = currentRt().Id;
        row.UnidadeNegocios__c = unidadeFromRt(currentRt().DeveloperName);
        insert row;
        Categorizacao__c saved = [SELECT ChaveNatural__c, ChaveNaturalHash__c, CampoDistribuicao__c FROM Categorizacao__c WHERE Id = :row.Id];
        Assert.areEqual(true, saved.ChaveNatural__c.contains('SEM_DISTRIBUICAO'));
        Assert.areEqual(64, saved.ChaveNaturalHash__c.length());
        Assert.areEqual(null, saved.CampoDistribuicao__c);
    }

    @IsTest
    static void testDuplicidadeBloqueia() {
        configureRuntimeOverrides();
        Categorizacao__c a = CategorizacaoTestDataFactory.base(false, false);
        a.RecordTypeId = currentRt().Id;
        a.UnidadeNegocios__c = unidadeFromRt(currentRt().DeveloperName);
        insert a;
        Categorizacao__c b = CategorizacaoTestDataFactory.base(false, false);
        b.RecordTypeId = a.RecordTypeId;
        b.UnidadeNegocios__c = unidadeFromRt(currentRt().DeveloperName);
        DmlException ex;
        try { insert b; } catch (DmlException e) { ex = e; }
        Assert.areEqual(true, ex.getMessage().contains('Já existe uma categorização equivalente cadastrada para esta Unidade de Negócio.'));
    }

    @IsTest
    static void testDistribuicaoPorCampoValidaPicklist() {
        configureRuntimeOverrides();
        String queueDeveloperName = queueDevNameFromRt(currentRt().DeveloperName);
        CategorizacaoSelector.QueueData qd = CategorizacaoSelector.testQueuesByDevName.get(queueDeveloperName);

        Categorizacao__c row = CategorizacaoTestDataFactory.base(true, false);
        row.RecordTypeId = currentRt().Id;
        row.UnidadeNegocios__c = unidadeFromRt(currentRt().DeveloperName);
        row.FilaDeveloperName__c = qd.developerName;
        row.CampoDistribuicao__c = 'Origin';
        row.ValorDistribuicao__c = 'Email';
        insert row;

        Categorizacao__c saved = [SELECT LabelCampoDistribuicao__c, LabelValorDistribuicao__c, FilaId__c FROM Categorizacao__c WHERE Id = :row.Id];
        Assert.areEqual(true, String.isBlank(saved.LabelCampoDistribuicao__c) == false);
        Assert.areEqual(true, String.isBlank(saved.LabelValorDistribuicao__c) == false);
        Assert.areEqual(String.valueOf(qd.id), saved.FilaId__c);
    }

    @IsTest
    static void testBulk() {
        configureRuntimeOverrides();
        List<Categorizacao__c> rows = new List<Categorizacao__c>();
        List<String> assuntos = new List<String>{
            '2ª via de fatura',
            'Acesso',
            'Acesso Codeba',
            'Acesso ao terminal',
            'Acompanhamento de DAT',
            'Acompanhar divergências de agendamento',
            'Acompanhar veículo sem agendamento',
            'Agendamento',
            'Agendamento de container',
            'Agendamentos'
        };
        for (Integer i = 0; i < 10; i++) {
            Categorizacao__c r = CategorizacaoTestDataFactory.base(false, false);
            r.RecordTypeId = currentRt().Id;
            r.UnidadeNegocios__c = unidadeFromRt(currentRt().DeveloperName);
            r.Assunto__c = assuntos[i];
            rows.add(r);
        }
        insert rows;
        Assert.areEqual(10, [SELECT count() FROM Categorizacao__c WHERE Id IN :rows]);
    }

    @IsTest
    static void testAuxiliaryMethodsReturnExpectedData() {
        configureRuntimeOverrides();
        Map<String, List<CategorizacaoDTO.PicklistOption>> picklists = CategorizacaoService.getPicklists();
        Assert.areEqual(true, picklists.containsKey('TipoCaso__c'));
        Assert.areEqual(true, picklists.containsKey('Categoria__c'));

        List<CategorizacaoDTO.CasePicklistField> caseFields = CategorizacaoService.getCasePicklistFields();
        Assert.areEqual(true, caseFields.isEmpty() == false);

        List<CategorizacaoDTO.RecordTypeOption> recordTypes = CategorizacaoService.getAvailableRecordTypes();
        Assert.areEqual(true, recordTypes.isEmpty() == false);

        List<CategorizacaoDTO.QueueOption> queues = CategorizacaoService.getQueues(unidadeFromRt(currentRt().DeveloperName));
        Assert.areEqual(true, queues.isEmpty() == false);
    }

    @IsTest
    static void testSaveCreatesRecordSuccessfully() {
        configureRuntimeOverrides();
        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        req.recordTypeId = currentRt().Id;
        req.unidadeNegocio = unidadeFromRt(currentRt().DeveloperName);
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.subassunto = 'Alteração';
        req.ativo = true;
        req.distribuirParaFila = false;
        req.porCategorizacao = false;

        CategorizacaoDTO.Response res = CategorizacaoService.save(req);
        Assert.areEqual(true, res.success);
        Assert.areEqual(true, res.registro != null);
        Assert.areEqual(req.unidadeNegocio, res.registro.unidadeNegocio);
    }

    @IsTest
    static void testSelectorMethodsReturnCurrentData() {
        configureRuntimeOverrides();
        RecordType rt = currentRt();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        row.RecordTypeId = rt.Id;
        row.UnidadeNegocios__c = unidadeFromRt(rt.DeveloperName);
        insert row;

        Map<Id, RecordType> rtById = CategorizacaoSelector.getRecordTypesById(new Set<Id>{ rt.Id });
        Assert.areEqual(rt.DeveloperName, rtById.get(rt.Id).DeveloperName);

        Categorizacao__c fetched = CategorizacaoSelector.getById(row.Id);
        Assert.areEqual(row.Id, fetched.Id);

        Map<String, Categorizacao__c> existingByHash = CategorizacaoSelector.getExistingByHash(
            new Set<String>{ fetched.ChaveNaturalHash__c },
            new Set<Id>()
        );
        Assert.areEqual(true, existingByHash.containsKey(fetched.ChaveNaturalHash__c));

        String queueDeveloperName = queueDevNameFromRt(rt.DeveloperName);
        Map<String, CategorizacaoSelector.QueueData> queueByDeveloperName =
            CategorizacaoSelector.getCaseQueuesByDeveloperName(new Set<String>{ queueDeveloperName });
        Assert.areEqual(true, queueByDeveloperName.containsKey(queueDeveloperName));

        CategorizacaoSelector.testConfigs = null;
        Map<String, CategorizacaoSelector.UnidadeConfig> metadataConfigs = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName();
        Assert.areEqual(true, metadataConfigs.isEmpty() == false);

        List<CategorizacaoSelector.QueueData> prefixedQueues = CategorizacaoSelector.listCaseQueuesByPrefix(
            queueDeveloperName.substringBefore('_')
        );
        Assert.areEqual(true, prefixedQueues.isEmpty() == false);

        CategorizacaoDTO.InitialState state = CategorizacaoService.getInitialState(row.Id);
        Assert.areEqual(row.Id, state.registro.id);
        Assert.areEqual(true, state.regrasSla != null);
    }

    @IsTest
    static void testSelectorGuardClausesAndNullScenarios() {
        configureRuntimeOverrides();
        Assert.areEqual(null, CategorizacaoSelector.getById('001000000000000AAA'));

        Map<Id, RecordType> emptyRecordTypes = CategorizacaoSelector.getRecordTypesById(new Set<Id>());
        Assert.areEqual(0, emptyRecordTypes.size());

        CategorizacaoSelector.testQueuesByDevName = null;
        Map<String, CategorizacaoSelector.QueueData> emptyQueues =
            CategorizacaoSelector.getCaseQueuesByDeveloperName(new Set<String>());
        Assert.areEqual(0, emptyQueues.size());
        configureRuntimeOverrides();

        List<CategorizacaoSelector.QueueData> blankPrefixQueues = CategorizacaoSelector.listCaseQueuesByPrefix(null);
        Assert.areEqual(0, blankPrefixQueues.size());

        Map<String, Categorizacao__c> emptyHashes =
            CategorizacaoSelector.getExistingByHash(new Set<String>(), new Set<Id>());
        Assert.areEqual(0, emptyHashes.size());

        List<RegrasSLACategorizacao__c> emptyRules = CategorizacaoSelector.getRegrasSlaByCategorizacao(null);
        Assert.areEqual(0, emptyRules.size());
    }

    @IsTest
    static void testSelectorIgnoreIdsAndQueueFiltering() {
        configureRuntimeOverrides();
        RecordType rt = currentRt();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        row.RecordTypeId = rt.Id;
        row.UnidadeNegocios__c = unidadeFromRt(rt.DeveloperName);
        insert row;

        Map<String, Categorizacao__c> ignoredExisting = CategorizacaoSelector.getExistingByHash(
            new Set<String>{ row.ChaveNaturalHash__c },
            new Set<Id>{ row.Id }
        );
        Assert.areEqual(0, ignoredExisting.size());

        CategorizacaoSelector.testQueuesByDevName = new Map<String, CategorizacaoSelector.QueueData>();
        Map<String, CategorizacaoSelector.QueueData> queueByDevName =
            CategorizacaoSelector.getCaseQueuesByDeveloperName(new Set<String>{ 'NON_CASE_QUEUE' });
        Assert.areEqual(false, queueByDevName.containsKey('NON_CASE_QUEUE'));
    }

    @IsTest
    static void testGetRegrasSlaByCategorizacaoReturnsRows() {
        configureRuntimeOverrides();
        RecordType rt = currentRt();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        row.RecordTypeId = rt.Id;
        row.UnidadeNegocios__c = unidadeFromRt(rt.DeveloperName);
        insert row;

        List<Schema.PicklistEntry> ue = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        String unidade = ue.isEmpty() ? 'Salvador' : ue[0].getValue();
        GestaoSLA__c gestao = new GestaoSLA__c(
            Name = 'Gestao CT ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true
        );
        insert gestao;
        MarcoSLA__c marco = new MarcoSLA__c(
            Name = 'Marco CT',
            GestaoSLA__c = gestao.Id,
            NomeMarco__c = 'Atendimento N3',
            MilestoneTypeName__c = 'Atendimento N3',
            FonteTempo__c = 'RegraSLA',
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = true
        );
        insert marco;
        RegrasSLACategorizacao__c regra = new RegrasSLACategorizacao__c(
            Categorizacao__c = row.Id,
            TipoAreaParticipante__c = 'SLA Total',
            Origem__c = 'Qualquer',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestao.Id,
            MarcoSLA__c = marco.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_GLOBAL,
            TempoMedia__c = 30
        );
        insert regra;

        List<RegrasSLACategorizacao__c> regras = CategorizacaoSelector.getRegrasSlaByCategorizacao(row.Id);
        Assert.areEqual(1, regras.size());
        Assert.areEqual(regra.Id, regras[0].Id);
    }

    @IsTest
    static void testSelectorQueriesRealCaseEnabledQueuesOnly() {
        CategorizacaoSelector.testQueuesByDevName = null;
        Group enabledQueue = createQueueSetupOnly('CATSEL_ENABLED', true);
        Group disabledQueue = createQueueSetupOnly('CATSEL_DISABLED', false);

        Map<String, CategorizacaoSelector.QueueData> queueByDeveloperName =
            CategorizacaoSelector.getCaseQueuesByDeveloperName(
                new Set<String>{ enabledQueue.DeveloperName, disabledQueue.DeveloperName }
            );

        Assert.areEqual(true, queueByDeveloperName.containsKey(enabledQueue.DeveloperName));
        Assert.areEqual(false, queueByDeveloperName.containsKey(disabledQueue.DeveloperName));
        Assert.areEqual(enabledQueue.Id, queueByDeveloperName.get(enabledQueue.DeveloperName).id);
    }

    @IsTest
    static void testSelectorListsRealQueuesByPrefixSorted() {
        CategorizacaoSelector.testQueuesByDevName = null;
        String prefix = 'CATSEL_SORT';
        Group queueB = createQueueSetupOnly(prefix + '_B', true);
        Group queueA = createQueueSetupOnly(prefix + '_A', true);
        createQueueSetupOnly(prefix + '_NOCASE', false);

        List<CategorizacaoSelector.QueueData> queues = CategorizacaoSelector.listCaseQueuesByPrefix(prefix);

        Assert.areEqual(2, queues.size());
        Assert.areEqual(queueA.DeveloperName, queues[0].developerName);
        Assert.areEqual(queueB.DeveloperName, queues[1].developerName);
    }

    @IsTest
    static void testSaveUpdatePreservesExistingValuesWhenRequestLeavesFieldsBlank() {
        configureRuntimeOverrides();
        RecordType rt = currentRt();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        row.RecordTypeId = rt.Id;
        row.UnidadeNegocios__c = unidadeFromRt(rt.DeveloperName);
        row.Assunto__c = 'Cadastro';
        row.Subassunto__c = 'Alteração';
        row.Prioridade__c = 'Low';
        row.Descricao__c = 'Descrição original';
        insert row;

        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        req.id = row.Id;
        req.regrasSla = new List<CategorizacaoDTO.RegraSLARequest>();

        CategorizacaoDTO.Response response = CategorizacaoService.save(req);
        Assert.areEqual(true, response.success);

        Categorizacao__c saved = [
            SELECT RecordTypeId, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c,
                   Subassunto__c, Prioridade__c, Descricao__c, Ativo__c
            FROM Categorizacao__c
            WHERE Id = :row.Id
        ];
        Assert.areEqual(rt.Id, saved.RecordTypeId);
        Assert.areEqual(unidadeFromRt(rt.DeveloperName), saved.UnidadeNegocios__c);
        Assert.areEqual('Solicitação', saved.TipoCaso__c);
        Assert.areEqual('Solicitação', saved.Categoria__c);
        Assert.areEqual('Cadastro', saved.Assunto__c);
        Assert.areEqual('Alteração', saved.Subassunto__c);
        Assert.areEqual('Low', saved.Prioridade__c);
        Assert.areEqual('Descrição original', saved.Descricao__c);
        Assert.areEqual(true, saved.Ativo__c);
    }

    @IsTest
    static void testSaveDeletesExistingRegrasWhenRequestListIsEmpty() {
        configureRuntimeOverrides();
        RecordType rt = currentRt();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        row.RecordTypeId = rt.Id;
        row.UnidadeNegocios__c = unidadeFromRt(rt.DeveloperName);
        insert row;

        List<Schema.PicklistEntry> ue2 = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        String unidade2 = ue2.isEmpty() ? 'Salvador' : ue2[0].getValue();
        GestaoSLA__c gestao2 = new GestaoSLA__c(
            Name = 'Gestao CT2 ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = unidade2,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true
        );
        insert gestao2;
        MarcoSLA__c marco2 = new MarcoSLA__c(
            Name = 'Marco CT2',
            GestaoSLA__c = gestao2.Id,
            NomeMarco__c = 'Atendimento N3',
            MilestoneTypeName__c = 'Atendimento N3',
            FonteTempo__c = 'RegraSLA',
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = true
        );
        insert marco2;
        insert new RegrasSLACategorizacao__c(
            Categorizacao__c = row.Id,
            TipoAreaParticipante__c = 'SLA Total',
            Origem__c = 'Qualquer',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestao2.Id,
            MarcoSLA__c = marco2.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_GLOBAL,
            TempoMedia__c = 30
        );

        Assert.areEqual(1, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :row.Id]);

        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        req.id = row.Id;
        req.regrasSla = new List<CategorizacaoDTO.RegraSLARequest>();

        CategorizacaoDTO.Response response = CategorizacaoService.save(req);
        Assert.areEqual(true, response.success);
        Assert.areEqual(0, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :row.Id]);
    }

    private static Group createQueueSetupOnly(String developerName, Boolean enableForCase) {
        Group queue;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queue = new Group(Name = developerName, DeveloperName = developerName, Type = 'Queue');
            insert queue;
            if (enableForCase) {
                insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
            }
        }
        return queue;
    }
}