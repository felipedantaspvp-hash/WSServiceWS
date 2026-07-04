/**
 * @description       : Testes unitários de AreaParticipanteController. Cobre endpoints de leitura,
 *                      adição (unitária e bulk), encerramento, pausa, retomada e tratamento de exceções.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteControllerTest {
    private static void enableBhBypass() {
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
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
        ApexTestSeam.set('AreaParticipanteController.testException', new IllegalArgumentException('forced'));
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
        ApexTestSeam.clear('AreaParticipanteController.testException');

        Assert.isTrue(pauseThrew);
        Assert.isTrue(resumeThrew);
    }

    @IsTest
    static void testGetPanelDataUnexpectedException() {
        ApexTestSeam.set('AreaParticipanteController.testException', new IllegalArgumentException('forced'));
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.getPanelData(UserInfo.getUserId());
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        ApexTestSeam.clear('AreaParticipanteController.testException');
        Assert.isTrue(threw);
    }

    @IsTest
    static void testCloseParticipationUnexpectedException() {
        ApexTestSeam.set('AreaParticipanteController.testException', new IllegalArgumentException('forced'));
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.closeParticipation(new AreaParticipanteDTO.CloseRequestDTO());
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        ApexTestSeam.clear('AreaParticipanteController.testException');
        Assert.isTrue(threw);
    }

    @IsTest
    static void testGetParticipationDetailsUnexpectedException() {
        ApexTestSeam.set('AreaParticipanteController.testException', new IllegalArgumentException('forced'));
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.getParticipationDetails(UserInfo.getUserId());
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        ApexTestSeam.clear('AreaParticipanteController.testException');
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationUnexpectedException() {
        ApexTestSeam.set('AreaParticipanteController.testException', new IllegalArgumentException('forced'));
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.addParticipation(new AreaParticipanteDTO.AddRequestDTO());
            Test.stopTest();
        } catch (AuraHandledException ex) { threw = true; }
        ApexTestSeam.clear('AreaParticipanteController.testException');
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

    @IsTest
    static void testAddParticipationBlocksTerminalCase() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        update new Case(Id = c.Id, EtapaAtendimento__c = 'Concluído');

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = area1;
        req.comentarioSolicitacao = 'Solicitação bloqueada por caso concluído';

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

    @IsTest
    static void testAddParticipationBulkSuccess() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        String area2 = areas.size() > 1 ? areas[1] : null;
        Case c = AreaParticipanteTestDataFactory.createCase(area1, area2);

        AreaParticipanteDTO.AddBulkRequestDTO req = new AreaParticipanteDTO.AddBulkRequestDTO();
        req.caseId = c.Id;
        req.items = new List<AreaParticipanteDTO.AddBulkItemDTO>();

        AreaParticipanteDTO.AddBulkItemDTO item1 = new AreaParticipanteDTO.AddBulkItemDTO();
        item1.area = area1;
        item1.comentarioSolicitacao = 'Solicitação área 1';
        req.items.add(item1);

        if (!String.isBlank(area2) && area1 != area2) {
            AreaParticipanteDTO.AddBulkItemDTO item2 = new AreaParticipanteDTO.AddBulkItemDTO();
            item2.area = area2;
            item2.comentarioSolicitacao = 'Solicitação área 2';
            req.items.add(item2);
        }

        Test.startTest();
        AreaParticipanteDTO.AddBulkResponseDTO res = AreaParticipanteController.addParticipationBulk(req);
        Test.stopTest();

        Assert.areEqual(true, res.success);
        Assert.isTrue(res.count >= 1);
        Assert.isTrue(res.count == req.items.size());
    }

    @IsTest
    static void testAddParticipationBulkBlocksCanceledCase() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        update new Case(Id = c.Id, EtapaAtendimento__c = 'Cancelado');

        AreaParticipanteDTO.AddBulkItemDTO item = new AreaParticipanteDTO.AddBulkItemDTO();
        item.area = area1;
        item.comentarioSolicitacao = 'Solicitação bloqueada por caso cancelado';

        AreaParticipanteDTO.AddBulkRequestDTO req = new AreaParticipanteDTO.AddBulkRequestDTO();
        req.caseId = c.Id;
        req.items = new List<AreaParticipanteDTO.AddBulkItemDTO>{ item };

        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.addParticipationBulk(req);
            Test.stopTest();
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationBulkFunctionalException() {
        Boolean threw = false;
        try {
            AreaParticipanteController.addParticipationBulk(null);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Assert.isTrue(threw);
    }

    @IsTest
    static void testAddParticipationBulkUnexpectedException() {
        ApexTestSeam.set('AreaParticipanteController.testException', new IllegalArgumentException('forced'));
        Boolean threw = false;
        try {
            Test.startTest();
            AreaParticipanteController.addParticipationBulk(new AreaParticipanteDTO.AddBulkRequestDTO());
            Test.stopTest();
        } catch (AuraHandledException ex) {
            threw = true;
        }
        ApexTestSeam.clear('AreaParticipanteController.testException');
        Assert.isTrue(threw);
    }
}