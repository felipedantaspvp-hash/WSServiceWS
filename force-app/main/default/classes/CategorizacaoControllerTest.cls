@IsTest
private class CategorizacaoControllerTest {
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

    private static String unidadeFromRt(String rtDevName) {
        String canonical = CaseCreationSelector.resolveCanonicalBusinessUnit(rtDevName);
        return String.isBlank(canonical)
            ? CaseCreationSelector.resolveCanonicalBusinessUnit('Tecon Salvador')
            : canonical;
    }

    private static void configureUnitAndQueue() {
        RecordType rt = currentRt();
        String unidade = unidadeFromRt(rt.DeveloperName);

        CategorizacaoSelector.UnidadeConfig cfg = new CategorizacaoSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = rt.DeveloperName;
        cfg.unidadeNegocio = unidade;
        CategorizacaoSelector.UnidadeConfig metadataCfg = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName().get(rt.DeveloperName);
        cfg.queuePrefix = metadataCfg == null || String.isBlank(metadataCfg.queuePrefix) ? 'TSV' : metadataCfg.queuePrefix;
        cfg.ativo = true;
        CategorizacaoSelector.testConfigs = new Map<String, CategorizacaoSelector.UnidadeConfig>{ rt.DeveloperName => cfg };

        String queueDeveloperName = cfg.queuePrefix + '_CTRL_TEST';
        CategorizacaoSelector.QueueData queue = new CategorizacaoSelector.QueueData();
        queue.id = UserInfo.getUserId();
        queue.name = queueDeveloperName;
        queue.developerName = queueDeveloperName;
        CategorizacaoSelector.testQueuesByDevName = new Map<String, CategorizacaoSelector.QueueData>{
            queueDeveloperName => queue
        };
    }

    @IsTest
    static void testControllerMethodsReturnData() {
        configureUnitAndQueue();
        List<CategorizacaoDTO.RecordTypeOption> recordTypes = CategorizacaoController.getAvailableRecordTypes();
        Assert.areEqual(true, recordTypes.isEmpty() == false);

        Map<String, List<CategorizacaoDTO.PicklistOption>> picklists = CategorizacaoController.getPicklistValues(null);
        Assert.areEqual(true, picklists.containsKey('TipoCaso__c'));
        Assert.areEqual(true, picklists.containsKey('Categoria__c'));

        List<CategorizacaoDTO.CasePicklistField> caseFields = CategorizacaoController.getCasePicklistFields();
        Assert.areEqual(true, caseFields.isEmpty() == false);

        RecordType rt = currentRt();
        List<CategorizacaoDTO.QueueOption> queues = CategorizacaoController.getQueues(unidadeFromRt(rt.DeveloperName));
        Assert.areEqual(true, queues.isEmpty() == false);
    }

    @IsTest
    static void testInitialStateSemRecordId() {
        configureUnitAndQueue();
        CategorizacaoDTO.InitialState s = CategorizacaoController.getInitialState(null);
        Assert.areEqual(true, s != null);
        Assert.areEqual(true, s.availableRecordTypes != null);
    }

    @IsTest
    static void testInitialStateComRecordIdCarregaDetalhe() {
        configureUnitAndQueue();
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        insert row;

        CategorizacaoDTO.InitialState s = CategorizacaoController.getInitialState(row.Id);

        Assert.areEqual(row.Id, s.registro.id);
        Assert.areEqual(row.UnidadeNegocios__c, s.registro.unidadeNegocio);
    }

    @IsTest
    static void testSaveRetornaErroAmigavel() {
        configureUnitAndQueue();
        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        CategorizacaoDTO.Response r = CategorizacaoController.save(req);
        Assert.areEqual(false, r.success);
        Assert.areEqual(true, String.isBlank(r.message) == false);
    }

    @IsTest
    static void testSaveSuccess() {
        configureUnitAndQueue();
        RecordType rt = currentRt();
        String unidade = unidadeFromRt(rt.DeveloperName);

        CategorizacaoSelector.UnidadeConfig cfg = new CategorizacaoSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = rt.DeveloperName;
        cfg.unidadeNegocio = unidade;
        CategorizacaoSelector.UnidadeConfig metadataCfg = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName().get(rt.DeveloperName);
        cfg.queuePrefix = metadataCfg == null || String.isBlank(metadataCfg.queuePrefix) ? 'TSV' : metadataCfg.queuePrefix;
        cfg.ativo = true;
        CategorizacaoSelector.testConfigs = new Map<String, CategorizacaoSelector.UnidadeConfig>{ rt.DeveloperName => cfg };

        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        req.recordTypeId = rt.Id;
        req.unidadeNegocio = unidade;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.subassunto = 'Alteração';
        req.ativo = true;
        req.distribuirParaFila = false;
        req.porCampoCustomizado = false;

        CategorizacaoDTO.Response response = CategorizacaoController.save(req);
        Assert.areEqual(true, response.success);
        Assert.areEqual(true, response.registro != null);
        Assert.areEqual(unidade, response.registro.unidadeNegocio);

        CategorizacaoSelector.testConfigs = null;
    }

    @IsTest
    static void testReadAccessDeniedThrowsFunctionalError() {
        configureUnitAndQueue();
        CategorizacaoController.categorizacaoReadAccessOverride = false;
        Boolean failed = false;
        try {
            CategorizacaoController.getInitialState(null);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Usuário sem permissão de leitura para Categorização.'));
        } finally {
            CategorizacaoController.categorizacaoReadAccessOverride = null;
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testSaveReturnsFriendlyErrorWhenRulesManageAccessDenied() {
        configureUnitAndQueue();
        CategorizacaoController.regrasManageAccessOverride = false;

        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        req.id = UserInfo.getUserId();

        CategorizacaoDTO.Response response = CategorizacaoController.save(req);
        Assert.areEqual(false, response.success);
        Assert.areEqual('CRUD_DENIED', response.error.code);
        Assert.areEqual(true, response.message.contains('Regras SLA'));

        CategorizacaoController.regrasManageAccessOverride = null;
    }

    @IsTest
    static void testSelectorQueueLookupAndExistingHash() {
        configureUnitAndQueue();
        RecordType rt = currentRt();
        List<CategorizacaoDTO.QueueOption> queueOptions = CategorizacaoController.getQueues(unidadeFromRt(rt.DeveloperName));
        Assert.areEqual(true, queueOptions.isEmpty() == false);

        Set<String> developerNames = new Set<String>{ queueOptions[0].developerName };
        Map<String, CategorizacaoSelector.QueueData> queuesByDeveloperName =
            CategorizacaoSelector.getCaseQueuesByDeveloperName(developerNames);
        Assert.areEqual(true, queuesByDeveloperName.containsKey(queueOptions[0].developerName));
        Assert.areEqual(queueOptions[0].id, queuesByDeveloperName.get(queueOptions[0].developerName).id);

        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        insert row;
        row = [SELECT Id, ChaveNaturalHash__c FROM Categorizacao__c WHERE Id = :row.Id];

        Map<String, Categorizacao__c> existingByHash =
            CategorizacaoSelector.getExistingByHash(new Set<String>{ row.ChaveNaturalHash__c }, new Set<Id>());
        Assert.areEqual(row.Id, existingByHash.get(row.ChaveNaturalHash__c).Id);

        Map<String, Categorizacao__c> ignoredByHash =
            CategorizacaoSelector.getExistingByHash(new Set<String>{ row.ChaveNaturalHash__c }, new Set<Id>{ row.Id });
        Assert.areEqual(true, ignoredByHash.isEmpty());
    }

    @IsTest
    static void testSaveCreateAccessDenied() {
        configureUnitAndQueue();
        CategorizacaoController.categorizacaoCreateAccessOverride = false;
        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        CategorizacaoDTO.Response r = CategorizacaoController.save(req);
        CategorizacaoController.categorizacaoCreateAccessOverride = null;
        Assert.areEqual(false, r.success);
        Assert.areEqual('CRUD_DENIED', r.error.code);
    }

    @IsTest
    static void testSaveUpdateAccessDenied() {
        configureUnitAndQueue();
        CategorizacaoController.categorizacaoUpdateAccessOverride = false;
        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        req.id = UserInfo.getUserId();
        CategorizacaoDTO.Response r = CategorizacaoController.save(req);
        CategorizacaoController.categorizacaoUpdateAccessOverride = null;
        Assert.areEqual(false, r.success);
        Assert.areEqual('CRUD_DENIED', r.error.code);
    }

    @IsTest
    static void testSaveRegrasReadAccessDenied() {
        configureUnitAndQueue();
        CategorizacaoController.regrasReadAccessOverride = false;
        CategorizacaoDTO.Request req = new CategorizacaoDTO.Request();
        CategorizacaoDTO.Response r = CategorizacaoController.save(req);
        CategorizacaoController.regrasReadAccessOverride = null;
        Assert.areEqual(false, r.success);
        Assert.areEqual('CRUD_DENIED', r.error.code);
    }

    @IsTest
    static void testDtoRegraSlaRequestPropertiesAndSelectorNullRuleList() {
        configureUnitAndQueue();
        CategorizacaoDTO.RegraSLARequest regra = new CategorizacaoDTO.RegraSLARequest();
        regra.id = UserInfo.getUserId();
        regra.tipoAreaParticipante = 'Área Interna';
        regra.areaAtendimento = 'N1';
        regra.origem = 'Qualquer';
        regra.businessHoursName = 'Atendimento Salvador';
        regra.ativo = true;
        regra.markedForDelete = false;

        Assert.areEqual('Área Interna', regra.tipoAreaParticipante);
        Assert.areEqual('N1', regra.areaAtendimento);
        Assert.areEqual('Qualquer', regra.origem);
        Assert.areEqual('Atendimento Salvador', regra.businessHoursName);
        Assert.areEqual(true, regra.ativo);
        Assert.areEqual(false, regra.markedForDelete);

        Assert.areEqual(0, CategorizacaoSelector.getRegrasSlaByCategorizacao(null).size());
    }
}