@IsTest
private class CaseRecategorizationControllerTest {
    // Antes buscava DeveloperName='TeconSalvador' (nome errado — o real é
    // 'AtendimentoTeconSalvador'), então sempre caía no fallback "qualquer RT ativo",
    // que ocasionalmente sorteava Rebocadores e quebrava por Navio/Porto obrigatórios.
    private static RecordType anyCaseRt() {
        try {
            return TestDataFactory.recordTypeByDeveloperName('Case', 'AtendimentoTeconSalvador');
        } catch (Exception e) {
            return TestDataFactory.anyActiveRecordType('Case');
        }
    }

    @IsTest
    static void testRecategorizeControllerReturnsErrorDTO() {
        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        CaseRecategorizationDTO.RecategorizationResponseDTO out = CaseRecategorizationController.recategorize(req);
        Assert.areEqual(false, out.success);
        Assert.areEqual(true, out.error != null);
    }

    @IsTest
    static void testRecategorizeControllerReturnsErrorDTOForNull() {
        CaseRecategorizationDTO.RecategorizationResponseDTO out = CaseRecategorizationController.recategorize(null);
        Assert.areEqual(false, out.success);
        Assert.isNull(out.caseId);
        Assert.areEqual('REQUIRED_CASE_ID', out.error.code);
    }

    @IsTest
    static void testGetContextController() {
        RecordType rt = anyCaseRt();
        CaseCreationSelector.UnidadeConfig resolved = CaseCreationSelector.findConfigForCaseRecordType(rt.DeveloperName, rt.Name);
        CaseCreationSelector.UnidadeConfig cfg = new CaseCreationSelector.UnidadeConfig();
        cfg.recordTypeDeveloperName = rt.DeveloperName;
        cfg.unidadeNegocio = resolved != null && !String.isBlank(resolved.unidadeNegocio)
            ? resolved.unidadeNegocio
            : 'Atendimento Tecon Salvador';
        cfg.queueToken = resolved != null ? resolved.queueToken : 'TSV';
        cfg.ativo = true;
        CaseRecategorizationSelector.testConfigsByRtDevName = new Map<String, CaseCreationSelector.UnidadeConfig>{ rt.DeveloperName => cfg };
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{ rt.DeveloperName => cfg };

        Case c = TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => rt.Id,
            'Subject' => 'Teste Recateg',
            'Status' => 'New',
            'UnidadeNegocio__c' => cfg.unidadeNegocio
        });

        CaseRecategorizationDTO.CaseRecategorizationContextDTO ctx = CaseRecategorizationController.getContext(c.Id);
        Assert.areEqual(c.Id, ctx.caseId);
    }

    @IsTest
    static void testRecategorizeUnexpectedError() {
        ApexTestSeam.set('CaseRecategorizationController.testException', new IllegalArgumentException('forced'));
        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = '500000000000001AAA';
        Test.startTest();
        CaseRecategorizationDTO.RecategorizationResponseDTO out = CaseRecategorizationController.recategorize(req);
        Test.stopTest();
        ApexTestSeam.clear('CaseRecategorizationController.testException');
        Assert.areEqual(false, out.success);
        Assert.areEqual('UNEXPECTED_ERROR', out.error.code);
    }

    @IsTest
    static void testGetTreeOptionsController() {
        RecordType rt = anyCaseRt();
        CaseRecategorizationSelector.testCategorizacoes = new List<Categorizacao__c>();
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>();

        CaseRecategorizationDTO.TreeRequestDTO req = new CaseRecategorizationDTO.TreeRequestDTO();
        req.recordTypeId = rt.Id;
        req.recordTypeDeveloperName = rt.DeveloperName;
        req.unidadeNegocio = 'Atendimento Salvador';

        CaseRecategorizationDTO.TreeOptionsDTO opts = CaseRecategorizationController.getTreeOptions(req);
        Assert.isNotNull(opts);
    }
}