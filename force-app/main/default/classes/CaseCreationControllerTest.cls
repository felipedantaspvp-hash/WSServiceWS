@IsTest
private class CaseCreationControllerTest {
    @TestSetup
    static void setupData() {
        TestDataFactory.createQueue('TSV_Q_CC_TEST');
    }

    @IsTest
    static void testBuildDefaultValuesErrorDTO() {
        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationController.buildDefaultValues(req);
        Assert.areEqual(false, out.success);
        Assert.areEqual(true, out.error != null);
    }

    @IsTest
    static void testGetInitialContext() {
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>();
        CaseCreationDTO.InitialContextDTO ctx = CaseCreationController.getInitialContext();
        Assert.isNotNull(ctx);
        Assert.areEqual(true, ctx.recordTypes.size() > 0);
    }

    @IsTest
    static void testGetTreeOptions() {
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Case' AND IsActive=true LIMIT 1];
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>();
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>();
        CaseCreationDTO.CategorizationRequestDTO req = new CaseCreationDTO.CategorizationRequestDTO();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.unidadeNegocio = 'Atendimento Salvador';
        CaseCreationDTO.TreeOptionsDTO opts = CaseCreationController.getTreeOptions(req);
        Assert.isNotNull(opts);
    }

    @IsTest
    static void testResolveCategorizationSelection() {
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Case' AND IsActive=true LIMIT 1];
        Categorizacao__c fake = new Categorizacao__c(TipoCaso__c = 'Solicitação', Categoria__c = 'Comercial');
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{ fake };
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>();
        CaseCreationDTO.CategorizationRequestDTO req = new CaseCreationDTO.CategorizationRequestDTO();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.unidadeNegocio = 'Atendimento Salvador';
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Comercial';
        CaseCreationDTO.ResolveSelectionResponseDTO res = CaseCreationController.resolveCategorizationSelection(req);
        Assert.isNotNull(res);
        Assert.areEqual(false, res.hasParametrizedQueue);
    }

    @IsTest
    static void testGetAvailableQueues() {
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Case' AND IsActive=true LIMIT 1];
        List<CaseCreationDTO.QueueOptionDTO> queues = CaseCreationController.getAvailableQueues(rt.DeveloperName, null);
        Assert.isNotNull(queues);
    }

    @IsTest
    static void testBuildDefaultValuesUnexpectedError() {
        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationController.buildDefaultValues(null);
        Assert.areEqual(false, out.success);
        Assert.areEqual(true, out.error != null);
    }

    @IsTest
    static void testBuildDefaultValuesGenericException() {
        CaseCreationController.testException = new IllegalArgumentException('forced');
        CaseCreationDTO.BuildDefaultValuesRequestDTO req = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        Test.startTest();
        CaseCreationDTO.BuildDefaultValuesResponseDTO out = CaseCreationController.buildDefaultValues(req);
        Test.stopTest();
        CaseCreationController.testException = null;
        Assert.areEqual(false, out.success);
        Assert.areEqual('UNEXPECTED_ERROR', out.error.code);
    }
}