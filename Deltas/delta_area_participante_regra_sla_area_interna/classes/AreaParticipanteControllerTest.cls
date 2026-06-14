@IsTest
private class AreaParticipanteControllerTest {
    private static void enableBhBypass() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
        BusinessHoursResolverService.injectedByName.put('Tecon Salvador', (Id) '01m000000000001AAA');
    }

    @IsTest
    static void testControllerGetPanelDataAndDetail() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        AreaParticipante__c area = AreaParticipanteTestDataFactory.createArea(c.Id, area1, AreaParticipanteTestDataFactory.openStatus(), 2);

        Test.startTest();
        AreaParticipanteDTO.PanelDTO panel = AreaParticipanteController.getPanelData(c.Id);
        AreaParticipanteDTO.DetailDTO detail = AreaParticipanteController.getParticipationDetails(area.Id);
        Test.stopTest();

        Assert.areEqual(c.Id, panel.caseId);
        Assert.areEqual(area.Id, detail.item.id);
    }

    @IsTest
    static void testControllerClose() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        AreaParticipante__c area = AreaParticipanteTestDataFactory.createArea(c.Id, area1, AreaParticipanteTestDataFactory.openStatus(), 2);

        AreaParticipanteDTO.CloseRequestDTO req = new AreaParticipanteDTO.CloseRequestDTO();
        req.areaParticipanteId = area.Id;
        req.comentarioRetorno = 'ok';
        req.solucaoRetorno = 'ok';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO res = AreaParticipanteController.closeParticipation(req);
        Test.stopTest();

        Assert.areEqual(true, res.success);
    }

    @IsTest
    static void testGetPanelDataFresh() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);

        Test.startTest();
        AreaParticipanteDTO.PanelDTO panel = AreaParticipanteController.getPanelDataFresh(c.Id, 'refresh-token');
        Test.stopTest();

        Assert.areEqual(c.Id, panel.caseId);
    }

    @IsTest
    static void testGetPanelDataFunctionalException() {
        Boolean threw = false;
        try {
            AreaParticipanteController.getPanelData(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }

    @IsTest
    static void testCloseParticipationFunctionalException() {
        Boolean threw = false;
        try {
            AreaParticipanteController.closeParticipation(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }

    @IsTest
    static void testGetParticipationDetailsFunctionalException() {
        Boolean threw = false;
        try {
            AreaParticipanteController.getParticipationDetails(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationFunctionalException() {
        Boolean threw = false;
        try {
            AreaParticipanteController.addParticipation(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationSuccess() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = area1;
        req.comentarioSolicitacao = 'Solicitação de teste para coverage';

        Test.startTest();
        AreaParticipanteDTO.AddResponseDTO res = AreaParticipanteController.addParticipation(req);
        Test.stopTest();

        Assert.areEqual(true, res.success);
        Assert.isNotNull(res.areaParticipanteId);
        Assert.areEqual(c.Id, res.caseId);
    }

    @IsTest
    static void testGetPanelDataUnexpectedException() {
        AreaParticipanteController.testException = new IllegalArgumentException('forced');
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.getPanelData('500000000000001AAA');
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        AreaParticipanteController.testException = null;
        Assert.isTrue(threw);
    }

    @IsTest
    static void testCloseParticipationUnexpectedException() {
        AreaParticipanteController.testException = new IllegalArgumentException('forced');
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.closeParticipation(new AreaParticipanteDTO.CloseRequestDTO());
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        AreaParticipanteController.testException = null;
        Assert.isTrue(threw);
    }

    @IsTest
    static void testGetParticipationDetailsUnexpectedException() {
        AreaParticipanteController.testException = new IllegalArgumentException('forced');
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.getParticipationDetails('500000000000002AAA');
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        AreaParticipanteController.testException = null;
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationUnexpectedException() {
        AreaParticipanteController.testException = new IllegalArgumentException('forced');
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.addParticipation(new AreaParticipanteDTO.AddRequestDTO());
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        AreaParticipanteController.testException = null;
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationNoSlaRule() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area1, null);

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = area1;
        req.comentarioSolicitacao = 'Test comment';

        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.addParticipation(req);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }
}