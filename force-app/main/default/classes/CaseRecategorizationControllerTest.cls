/**
 * @description       : Testes unitários de CaseRecategorizationController.
 * @author            : Triscal
 * @group             : Case Recategorização
 * @last modified on  : 06-12-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class CaseRecategorizationControllerTest {
    private static RecordType anyCaseRt() {
        List<RecordType> preferred = [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' AND DeveloperName = 'TeconSalvador' LIMIT 1];
        return preferred.isEmpty() ? [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' LIMIT 1] : preferred[0];
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

        Case c = new Case(Subject = 'Teste Recateg', RecordTypeId = rt.Id, Status = 'New', UnidadeNegocio__c = cfg.unidadeNegocio);
        insert c;

        CaseRecategorizationDTO.CaseRecategorizationContextDTO ctx = CaseRecategorizationController.getContext(c.Id);
        Assert.areEqual(c.Id, ctx.caseId);
    }

    @IsTest
    static void testRecategorizeUnexpectedError() {
        CaseRecategorizationController.testException = new IllegalArgumentException('forced');
        CaseRecategorizationDTO.RecategorizationRequestDTO req = new CaseRecategorizationDTO.RecategorizationRequestDTO();
        req.caseId = '500000000000001AAA';
        Test.startTest();
        CaseRecategorizationDTO.RecategorizationResponseDTO out = CaseRecategorizationController.recategorize(req);
        Test.stopTest();
        CaseRecategorizationController.testException = null;
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