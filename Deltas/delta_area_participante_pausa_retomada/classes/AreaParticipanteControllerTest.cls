@IsTest
private class AreaParticipanteControllerTest {
    private static void enableBhBypass() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        if (!bhs.isEmpty()) { BusinessHoursResolverService.injectedByName.put('Tecon Salvador', bhs[0].Id); }
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
    static void testPauseAndResumeParticipationSuccess() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);

        AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
        addReq.caseId = c.Id;
        addReq.area = area1;
        addReq.comentarioSolicitacao = 'Solicitacao pausa controller';
        AreaParticipanteDTO.AddResponseDTO addRes = AreaParticipanteController.addParticipation(addReq);

        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = addRes.areaParticipanteId;

        Test.startTest();
        AreaParticipanteDTO.PauseResumeResponseDTO pauseRes = AreaParticipanteController.pauseParticipation(req);
        update new AreaParticipante__c(
            Id = addRes.areaParticipanteId,
            DataHoraInicioPausa__c = System.now().addMinutes(-5),
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO
        );
        AreaParticipanteDTO.PauseResumeResponseDTO resumeRes = AreaParticipanteController.resumeParticipation(req);
        Test.stopTest();

        Assert.areEqual(true, pauseRes.success);
        Assert.areEqual(true, resumeRes.success);
        Assert.areEqual(addRes.areaParticipanteId, resumeRes.areaParticipanteId);
    }

    @IsTest
    static void testPauseResumeFunctionalExceptions() {
        Boolean pauseThrew = false;
        try {
            AreaParticipanteController.pauseParticipation(null);
        } catch (AuraHandledException ex) {
            pauseThrew = true;
        }
        Assert.isTrue(pauseThrew);

        Boolean resumeThrew = false;
        try {
            AreaParticipanteController.resumeParticipation(null);
        } catch (AuraHandledException ex) {
            resumeThrew = true;
        }
        Assert.isTrue(resumeThrew);
    }

    @IsTest
    static void testPauseResumeUnexpectedExceptions() {
        AreaParticipanteController.testException = new IllegalArgumentException('forced');
        Boolean pauseThrew = false;
        Test.startTest();
        try {
            AreaParticipanteController.pauseParticipation(new AreaParticipanteDTO.PauseResumeRequestDTO());
        } catch (AuraHandledException ex) {
            pauseThrew = true;
        }

        Boolean resumeThrew = false;
        try {
            AreaParticipanteController.resumeParticipation(new AreaParticipanteDTO.PauseResumeRequestDTO());
        } catch (AuraHandledException ex) {
            resumeThrew = true;
        }
        Test.stopTest();
        AreaParticipanteController.testException = null;

        Assert.isTrue(pauseThrew);
        Assert.isTrue(resumeThrew);
    }

    @IsTest
    static void testGetPanelDataUnexpectedException() {
        AreaParticipanteController.testException = new IllegalArgumentException('forced');
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.getPanelData(UserInfo.getUserId());
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
            AreaParticipanteController.getParticipationDetails(UserInfo.getUserId());
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
