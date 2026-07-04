@IsTest
private class CaseRecategorizationServiceTest {
    private static final String DEFAULT_QUEUE_TOKEN_SALVADOR = 'TSV_';
    private static final String DEFAULT_QUEUE_TOKEN_RIO_GRANDE = 'TRG_';

    private static String pickValue(String fieldApiName, Integer index) {
        Map<String, Schema.SObjectField> fields = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        List<Schema.PicklistEntry> values = fields.get(fieldApiName).getDescribe().getPicklistValues();
        Integer safeIndex = values.size() > index ? index : 0;
        return values[safeIndex].getValue();
    }

    private static String anyClosedStatus() {
        return [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true LIMIT 1].MasterLabel;
    }

    private static RecordType anyCaseRt() {
        List<RecordType> preferred = [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' AND DeveloperName = 'TeconSalvador' LIMIT 1];
        return preferred.isEmpty() ? [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' LIMIT 1] : preferred[0];
    }

    private static String unidadeFor(RecordType rt) {
        CaseCreationSelector.UnidadeConfig cfg = CaseCreationSelector.findConfigForCaseRecordType(rt.DeveloperName, rt.Name);
        return cfg != null ? cfg.unidadeNegocio : 'Atendimento Rio Grande';
    }

    private static String queueTokenFor(String unidade) {
        String normalized = CaseRecategorizationHelper.normalizeText(unidade);
        if (normalized.contains('riogrande')) return DEFAULT_QUEUE_TOKEN_RIO_GRANDE;
        return DEFAULT_QUEUE_TOKEN_SALVADOR;
    }

    private static CaseCreationSelector.UnidadeConfig buildConfig(RecordType rt, String unidade) {
        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = rt.DeveloperName;
        cfg.unidadeNegocio = unidade;
        cfg.queueToken = queueTokenFor(unidade);
        cfg.ativo = true;
        return cfg;
    }

    private static void setConfigOverride(RecordType rt, String unidade) {
        CaseCreationSelector.UnidadeConfig cfg = buildConfig(rt, unidade);
        Map<String, CaseCreationSelector.UnidadeConfig> configs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            rt.DeveloperName => cfg
        };
        CaseRecategorizationSelector.testConfigsByRtDevName = configs;
        CaseCreationSelector.testConfigs = configs;
    }

    private static void clearOverrides() {
        CaseRecategorizationSelector.testCategorizacoes = null;
        CaseRecategorizationSelector.testOwnerQueue = null;
        CaseRecategorizationSelector.testConfigsByRtDevName = null;
        CaseCreationSelector.testConfigs = null;
        CaseCreationSelector.testCategorizacoes = null;
    }

    private static String resolveValidCaseUnitForRt(RecordType rt) {
        String preferred = unidadeFor(rt);
        List<String> candidates = new List<String>();
        for (String item : new List<String>{
            preferred,
            'Atendimento Salvador',
            'Tecon Salvador',
            'Atendimento Rio Grande',
            'Tecon Rio Grande',
            'Centro Logístico',
            'Rebocadores'
        }) {
            if (!String.isBlank(item) && !candidates.contains(item)) {
                candidates.add(item);
            }
        }

        String tipo = tipoValue(0);
        String categoria = categoriaValue(0);
        String assunto = assuntoValue(0);
        String subassunto = subassuntoValue(0);
        String status = pickValue('Status', 0);

        for (String candidate : candidates) {
            Savepoint sp = Database.setSavepoint();
            Database.SaveResult sr = Database.insert(
                CaseRecategorizationTestDataFactory.buildCase(rt.Id, candidate, tipo, categoria, assunto, subassunto, status),
                false
            );
            Database.rollback(sp);
            if (sr.isSuccess()) return candidate;
        }

        return preferred;
    }

    private static Case buildUncategorizedCase(Id recordTypeId, String unidade, String status) {
        Case c = new Case(
            Subject = 'Caso sem categorização',
            RecordTypeId = recordTypeId,
            UnidadeNegocio__c = unidade,
            Origin = 'Manual',
            Status = status
        );
        List<RecordType> rts = [SELECT DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1];
        if (!rts.isEmpty() && rts[0].DeveloperName == 'AtendimentoRebocadores') {
            c.NavioNome__c = 'Navio Teste';
            c.PortoNome__c = 'Porto Teste';
        }
        return c;
    }

    private static Group createCaseQueue(String developerName, String name) {
        Group queueGroup;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queueGroup = new Group(Name = name, DeveloperName = developerName, Type = 'Queue');
            insert queueGroup;
            insert new QueueSobject(QueueId = queueGroup.Id, SobjectType = 'Case');
        }
        return queueGroup;
    }

    private static Id anyCategRtId() {
        List<RecordType> preferred = [SELECT Id FROM RecordType WHERE SObjectType='Categorizacao__c' AND DeveloperName = 'TeconSalvador' LIMIT 1];
        return preferred.isEmpty() ? [SELECT Id FROM RecordType WHERE SObjectType='Categorizacao__c' LIMIT 1].Id : preferred[0].Id;
    }

    private static String tipoValue(Integer index) {
        return index == 0 ? 'Solicitação' : 'Informação';
    }

    private static String categoriaValue(Integer index) {
        return index == 0 ? 'Atendimento' : 'Agendamento';
    }

    private static String assuntoValue(Integer index) {
        return index == 0 ? 'Acesso' : 'Agendamento';
    }

    private static String subassuntoValue(Integer index) {
        return index == 0 ? 'Acesso indisponível' : 'Alteração';
    }

    @IsTest
    static void testGetContextAndTreeOptions() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);
        String tipo = tipoValue(0);
        String categoria = categoriaValue(0);
        String assunto = assuntoValue(0);
        String subassunto = subassuntoValue(0);
        Case c = CaseRecategorizationTestDataFactory.buildCase(rt.Id, unidade, tipo, categoria, assunto, subassunto, pickValue('Status', 0));
        insert c;

        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipo, categoria, assunto, subassunto, true)
        };

        CaseRecategorizationDTO.CaseRecategorizationContextDTO context = CaseRecategorizationService.getContext(c.Id);
        Assert.areEqual(c.Id, context.caseId);
        Assert.areEqual(unidade, context.unidadeNegocio);

        CaseRecategorizationDTO.TreeRequestDTO req = new CaseRecategorizationDTO.TreeRequestDTO();
        req.caseId = c.Id;
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.unidadeNegocio = unidade;
        req.selectedTipoCaso = tipo;
        req.selectedCategoria = categoria;

        CaseRecategorizationDTO.TreeOptionsDTO opts = CaseRecategorizationService.getTreeOptions(req);
        Assert.areEqual(true, opts.tipoCasoOptions.size() > 0);
        Assert.areEqual(true, opts.categoriaOptions.size() > 0);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeSuccessWithoutOwnerStatusChange() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);
        String tipoAtual = tipoValue(0);
        String categoriaAtual = categoriaValue(0);
        String assuntoAtual = assuntoValue(0);
        String subassuntoAtual = subassuntoValue(0);
        String tipoNovo = tipoValue(1);
        String categoriaNovo = categoriaValue(1);
        String assuntoNovo = assuntoValue(1);
        String subassuntoNovo = subassuntoValue(1);
        Case c = CaseRecategorizationTestDataFactory.buildCase(rt.Id, unidade, tipoAtual, categoriaAtual, assuntoAtual, subassuntoAtual, pickValue('Status', 0));
        insert c;

        Case insertedCase = [SELECT OwnerId, Status FROM Case WHERE Id = :c.Id];
        Id originalOwnerId = insertedCase.OwnerId;
        String originalStatus = insertedCase.Status;

        Categorizacao__c cat = CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipoNovo, categoriaNovo, assuntoNovo, subassuntoNovo, true);
        cat.Prioridade__c = 'High';
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoNovo;
        req.categoria = categoriaNovo;
        req.assunto = assuntoNovo;
        req.subassunto = subassuntoNovo;

        CaseRecategorizationDTO.RecategorizationResponseDTO res = CaseRecategorizationService.recategorize(req);
        Assert.areEqual(true, res.success);

        Case updated = [SELECT OwnerId, Status, Priority, TipoCaso__c, Categoria__c, Assunto__c, Subassunto__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(originalOwnerId, updated.OwnerId);
        Assert.areEqual(originalStatus, updated.Status);
        Assert.areEqual(tipoNovo, updated.TipoCaso__c);
        Assert.areEqual(categoriaNovo, updated.Categoria__c);
        Assert.areEqual(assuntoNovo, updated.Assunto__c);
        Assert.areEqual(subassuntoNovo, updated.Subassunto__c);
        Assert.areEqual('High', updated.Priority);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeBlockedClosed() {
        RecordType rt = anyCaseRt();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);
        Case c = CaseRecategorizationTestDataFactory.buildCase(
            rt.Id,
            unidade,
            tipoValue(0),
            categoriaValue(0),
            assuntoValue(0),
            subassuntoValue(0),
            anyClosedStatus()
        );
        insert c;

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = 'X';
        req.categoria = 'Y';

        Boolean threw = false;
        try {
            CaseRecategorizationService.recategorize(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeInvalidCombination() {
        RecordType rt = anyCaseRt();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);
        Case c = CaseRecategorizationTestDataFactory.buildCase(
            rt.Id,
            unidade,
            tipoValue(0),
            categoriaValue(0),
            assuntoValue(0),
            subassuntoValue(0),
            pickValue('Status', 0)
        );
        insert c;
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>();

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);

        Boolean threw = false;
        try {
            CaseRecategorizationService.recategorize(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
        clearOverrides();
    }

    @IsTest
    static void testGetContextInfersUnidadeFromOwnerQueueWhenBlank() {
        RecordType rt = anyCaseRt();
        List<RecordType> rioGrandeRt = [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' AND DeveloperName = 'TeconRioGrande' LIMIT 1];
        if (!rioGrandeRt.isEmpty()) rt = rioGrandeRt[0];
        String tipo = tipoValue(0);
        String categoria = categoriaValue(0);
        String assunto = assuntoValue(0);
        String subassunto = subassuntoValue(0);
        String openStatus = pickValue('Status', 0);

        Group ownerQueue;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            ownerQueue = new Group(Name = 'Queue RG', DeveloperName = 'WS_TRG_QUEUE_TEST', Type = 'Queue');
            insert ownerQueue;
            insert new QueueSobject(QueueId = ownerQueue.Id, SobjectType = 'Case');
        }

        Case c = new Case(
            Subject = 'Caso sem unidade',
            RecordTypeId = rt.Id,
            UnidadeNegocio__c = null,
            TipoCaso__c = tipo,
            Categoria__c = categoria,
            Assunto__c = assunto,
            Subassunto__c = subassunto,
            Origin = 'Manual',
            Status = openStatus,
            OwnerId = ownerQueue.Id
        );
        if (rt.DeveloperName == 'AtendimentoRebocadores') { c.NavioNome__c = 'Navio Teste'; c.PortoNome__c = 'Porto Teste'; }
        insert c;

        String unidadeEsperada = CaseCreationSelector.resolveCanonicalBusinessUnit('Tecon Rio Grande');
        CaseCreationSelector.UnidadeConfig cfg = buildConfig(rt, unidadeEsperada);
        cfg.queueToken = 'WS_TRG_';
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{
            rt.DeveloperName => cfg
        };

        CaseRecategorizationSelector.testOwnerQueue = ownerQueue;
        CaseRecategorizationSelector.testConfigsByRtDevName = new Map<String, CaseCreationSelector.UnidadeConfig>{
            rt.DeveloperName => cfg
        };

        CaseRecategorizationDTO.CaseRecategorizationContextDTO context = CaseRecategorizationService.getContext(c.Id);
        Assert.areEqual(unidadeEsperada, context.unidadeNegocio);
        clearOverrides();
    }

    @IsTest
    static void testGetContextWithClosedCaseSetsBlockedReason() {
        RecordType rt = anyCaseRt();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = CaseRecategorizationTestDataFactory.buildCase(
            rt.Id,
            unidade,
            tipoValue(0),
            categoriaValue(0),
            assuntoValue(0),
            subassuntoValue(0),
            anyClosedStatus()
        );
        insert c;

        CaseRecategorizationDTO.CaseRecategorizationContextDTO context = CaseRecategorizationService.getContext(c.Id);
        Assert.areEqual(false, context.canRecategorize);
        Assert.areEqual(true, String.isNotBlank(context.blockedReason));
        clearOverrides();
    }

    @IsTest
    static void testGetContextInfersUnidadeFromRecordTypeWhenConfigMissing() {
        RecordType rt = anyCaseRt();
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>();
        CaseRecategorizationSelector.testConfigsByRtDevName = new Map<String, CaseCreationSelector.UnidadeConfig>();

        Case c = new Case(
            Subject = 'Caso inferência por RT',
            RecordTypeId = rt.Id,
            UnidadeNegocio__c = null,
            TipoCaso__c = tipoValue(0),
            Categoria__c = categoriaValue(0),
            Assunto__c = assuntoValue(0),
            Subassunto__c = subassuntoValue(0),
            Origin = 'Manual',
            Status = pickValue('Status', 0)
        );
        if (rt.DeveloperName == 'AtendimentoRebocadores') { c.NavioNome__c = 'Navio Teste'; c.PortoNome__c = 'Porto Teste'; }
        insert c;

        Boolean threw = false;
        try {
            CaseRecategorizationService.getContext(c.Id);
        } catch (CaseRecategorizationService.FunctionalException ex) {
            threw = true;
            Assert.areEqual('REQUIRED_UNIDADE', ex.code);
        }
        Assert.areEqual(true, threw);
        clearOverrides();
    }

    @IsTest
    static void testGetTreeOptionsRequiresUnidade() {
        Boolean threw = false;
        try {
            CaseRecategorizationDTO.TreeRequestDTO request = new CaseRecategorizationDTO.TreeRequestDTO();
            request.recordTypeDeveloperName = 'TeconSalvador';
            CaseRecategorizationService.getTreeOptions(request);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
    }

    @IsTest
    static void testGetTreeOptionsIncludesSubassuntoOptions() {
        RecordType rt = anyCaseRt();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Categorizacao__c row = CaseRecategorizationTestDataFactory.catRow(
            anyCategRtId(),
            unidade,
            tipoValue(0),
            categoriaValue(0),
            assuntoValue(0),
            subassuntoValue(0),
            true
        );
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{ row };

        CaseRecategorizationDTO.TreeRequestDTO request = new CaseRecategorizationDTO.TreeRequestDTO();
        request.recordTypeDeveloperName = rt.DeveloperName;
        request.unidadeNegocio = unidade;
        request.selectedTipoCaso = tipoValue(0);
        request.selectedCategoria = categoriaValue(0);
        request.selectedAssunto = assuntoValue(0);

        CaseRecategorizationDTO.TreeOptionsDTO out = CaseRecategorizationService.getTreeOptions(request);
        Assert.areEqual(1, out.subassuntoOptions.size());
        Assert.areEqual(subassuntoValue(0), out.subassuntoOptions[0].value);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeRequiresCaseId() {
        Boolean threw = false;
        try {
            CaseRecategorizationService.recategorize(new CaseRecategorizationDTO.RecategorizationRequestDTO());
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
    }

    @IsTest
    static void testRecategorizeInvalidDestinationActionThrows() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipoValue(0), categoriaValue(0), assuntoValue(0), subassuntoValue(0), true)
        };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);
        req.destinationAction = 'QUALQUER';

        Boolean threw = false;
        try {
            CaseRecategorizationService.recategorize(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeDefaultAssumirForUncategorizedCase() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        Categorizacao__c cat = CaseRecategorizationTestDataFactory.catRow(
            categRtId,
            unidade,
            tipoValue(0),
            categoriaValue(0),
            assuntoValue(0),
            subassuntoValue(0),
            true
        );
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{ cat };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);

        CaseRecategorizationService.recategorize(req);

        Case updated = [SELECT OwnerId, AcaoPosCategorizacao__c, DistribuicaoSolicitada__c, Status, EtapaAtendimento__c
                        FROM Case WHERE Id = :c.Id];
        Assert.areEqual(UserInfo.getUserId(), updated.OwnerId);
        Assert.areEqual('Assumir', updated.AcaoPosCategorizacao__c);
        Assert.areEqual(false, updated.DistribuicaoSolicitada__c);
        Assert.areEqual('Aberto', updated.Status);
        Assert.areEqual('Em Atendimento', updated.EtapaAtendimento__c);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeEncerrarForUncategorizedCase() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipoValue(0), categoriaValue(0), assuntoValue(0), subassuntoValue(0), true)
        };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);
        req.destinationAction = 'ENCERRAR';

        CaseRecategorizationService.recategorize(req);

        Case updated = [SELECT OwnerId, AcaoPosCategorizacao__c, DistribuicaoSolicitada__c, Status, EtapaAtendimento__c
                        FROM Case WHERE Id = :c.Id];
        Assert.areEqual(UserInfo.getUserId(), updated.OwnerId);
        Assert.areEqual('Encerrar', updated.AcaoPosCategorizacao__c);
        Assert.areEqual(false, updated.DistribuicaoSolicitada__c);
        Assert.areEqual('Fechado', updated.Status);
        Assert.areEqual('Concluído', updated.EtapaAtendimento__c);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeDistribuirManualQueueForUncategorizedCase() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        Group manualQueue = createCaseQueue('CASE_RECAT_QUEUE_OK', 'Queue Recategorizacao');
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipoValue(0), categoriaValue(0), assuntoValue(0), subassuntoValue(0), true)
        };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);
        req.destinationAction = 'DISTRIBUIR';
        req.selectedQueueDeveloperName = manualQueue.DeveloperName;

        CaseRecategorizationService.recategorize(req);

        Case updated = [SELECT OwnerId, AcaoPosCategorizacao__c, DistribuicaoSolicitada__c, OrigemDistribuicao__c,
                               FilaDestinoDeveloperName__c, Status, EtapaAtendimento__c
                        FROM Case WHERE Id = :c.Id];
        Assert.areEqual(manualQueue.Id, updated.OwnerId);
        Assert.areEqual('Distribuir', updated.AcaoPosCategorizacao__c);
        Assert.areEqual(true, updated.DistribuicaoSolicitada__c);
        Assert.areEqual('Seleção Manual', updated.OrigemDistribuicao__c);
        Assert.areEqual(manualQueue.DeveloperName, updated.FilaDestinoDeveloperName__c);
        Assert.areEqual('Aberto', updated.Status);
        Assert.areEqual('Em Triagem', updated.EtapaAtendimento__c);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeDistribuirAutomaticQueueFromCategorization() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        Group autoQueue = createCaseQueue('CASE_RECAT_AUTO_QUEUE', 'Queue Auto Recategorizacao');
        Categorizacao__c row = CaseRecategorizationTestDataFactory.catRow(
            categRtId,
            unidade,
            tipoValue(0),
            categoriaValue(0),
            assuntoValue(0),
            subassuntoValue(0),
            true
        );
        row.DistribuirParaFila__c = 'Sim';
        row.PorCampoCustomizado__c = 'Não';
        row.FilaDeveloperName__c = autoQueue.DeveloperName;
        row.EtapaAtendimentoDistribuicao__c = 'Aguardando Área Interna';
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{ row };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);
        req.destinationAction = 'DISTRIBUIR';

        CaseRecategorizationService.recategorize(req);

        Case updated = [SELECT OwnerId, OrigemDistribuicao__c, FilaDestinoDeveloperName__c, EtapaAtendimento__c
                        FROM Case WHERE Id = :c.Id];
        Assert.areEqual(autoQueue.Id, updated.OwnerId);
        Assert.areEqual('Categorização', updated.OrigemDistribuicao__c);
        Assert.areEqual(autoQueue.DeveloperName, updated.FilaDestinoDeveloperName__c);
        Assert.areEqual('Aguardando Área Interna', updated.EtapaAtendimento__c, 'Deve usar a etapa configurada na Categorização em vez do valor fixo "Em Triagem".');
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeDistribuirInvalidQueueThrows() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipoValue(0), categoriaValue(0), assuntoValue(0), subassuntoValue(0), true)
        };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);
        req.destinationAction = 'DISTRIBUIR';
        req.selectedQueueDeveloperName = 'QUEUE_INEXISTENTE';

        Boolean threw = false;
        try {
            CaseRecategorizationService.recategorize(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
        clearOverrides();
    }

    @IsTest
    static void testRecategorizeDistribuirRequiresQueueWhenNoAutoQueue() {
        RecordType rt = anyCaseRt();
        Id categRtId = anyCategRtId();
        String unidade = resolveValidCaseUnitForRt(rt);
        setConfigOverride(rt, unidade);

        Case c = buildUncategorizedCase(rt.Id, unidade, pickValue('Status', 0));
        insert c;

        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseRecategorizationTestDataFactory.catRow(categRtId, unidade, tipoValue(0), categoriaValue(0), assuntoValue(0), subassuntoValue(0), true)
        };

        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = c.Id;
        req.tipoCaso = tipoValue(0);
        req.categoria = categoriaValue(0);
        req.assunto = assuntoValue(0);
        req.subassunto = subassuntoValue(0);
        req.destinationAction = 'DISTRIBUIR';

        Boolean threw = false;
        try {
            CaseRecategorizationService.recategorize(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
        clearOverrides();
    }

    @IsTest
    static void testSelectorGetQueueByIdAndConfigsWithoutOverride() {
        Group queueGroup = createCaseQueue('CASE_RECAT_SELECTOR', 'Queue Selector');
        Group found = CaseRecategorizationSelector.getQueueById(queueGroup.Id);
        Assert.areEqual(queueGroup.Id, found.Id);
        Assert.areEqual(null, CaseRecategorizationSelector.getQueueById(null));

        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = 'TeconSalvador';
        cfg.unidadeNegocio = 'Atendimento Salvador';
        cfg.queueToken = DEFAULT_QUEUE_TOKEN_SALVADOR;
        cfg.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{ 'TeconSalvador' => cfg };
        Map<String, CaseCreationSelector.UnidadeConfig> out = CaseRecategorizationSelector.getUnidadeConfigs();
        Assert.areEqual(true, out.containsKey('TeconSalvador'));
        clearOverrides();
    }

    @IsTest
    static void testSelectorGetActiveCategorizacoesWithoutOverride() {
        Categorizacao__c row = new Categorizacao__c();
        row.TipoCaso__c = tipoValue(0);
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ row };

        List<Categorizacao__c> out = CaseRecategorizationSelector.getActiveCategorizacoes('TeconSalvador', 'Atendimento Salvador');
        Assert.areEqual(1, out.size());
        Assert.areEqual(tipoValue(0), out[0].TipoCaso__c);
        clearOverrides();
    }
}