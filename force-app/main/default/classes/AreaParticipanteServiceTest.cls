@IsTest
private class AreaParticipanteServiceTest {
    @IsTest
    static void testGetPanelDataWithoutAreas() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);

        Test.startTest();
        AreaParticipanteDTO.PanelDTO panel = AreaParticipanteService.getPanelData(c.Id);
        Test.stopTest();

        Assert.areEqual(c.Id, panel.caseId);
        Assert.areEqual(0, panel.items.size());
    }

    @IsTest
    static void testGetPanelDataWithOpenAndOverdue() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        String area2 = areas.size() > 1 ? areas[1] : areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, area2);
        String openStatus = AreaParticipanteTestDataFactory.openStatus();
        AreaParticipanteTestDataFactory.createArea(c.Id, area1, openStatus, 4);
        AreaParticipanteTestDataFactory.createArea(c.Id, area2, openStatus, -1);

        Test.startTest();
        AreaParticipanteDTO.PanelDTO panel = AreaParticipanteService.getPanelData(c.Id);
        Test.stopTest();

        Assert.areEqual(2, panel.items.size());
        Assert.areEqual(2, panel.totalAbertas);
        Assert.areEqual(1, panel.totalVencidas);
    }

    @IsTest
    static void testCloseParticipationSyncsCase() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        String area2 = areas.size() > 1 ? areas[1] : areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, area2);
        String openStatus = AreaParticipanteTestDataFactory.openStatus();
        AreaParticipante__c area = AreaParticipanteTestDataFactory.createArea(c.Id, area1, openStatus, 2);

        AreaParticipanteDTO.CloseRequestDTO req = new AreaParticipanteDTO.CloseRequestDTO();
        req.areaParticipanteId = area.Id;
        req.comentarioRetorno = 'Retorno teste';
        req.solucaoRetorno = 'Solucao teste';
        req.requerRetornoCliente = true;

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO res = AreaParticipanteService.closeParticipation(req);
        Test.stopTest();

        Case updatedCase = [SELECT Id, OwnerId, Status, AreasParticipantesSLA__c, EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        AreaParticipante__c updatedArea = [SELECT Id, StatusAtuacao__c, ComentarioRetorno__c, SolucaoTomada__c, DataHoraFim__c FROM AreaParticipante__c WHERE Id = :area.Id];

        Assert.areEqual(true, res.success);
        if (AreaParticipanteHelper.normalizeText(area1) != AreaParticipanteHelper.normalizeText(area2)) {
            Assert.areEqual(true, AreaParticipanteHelper.containsValue(updatedCase.AreasParticipantesSLA__c, area2));
        }
        Assert.areEqual(false, AreaParticipanteHelper.containsValue(updatedCase.AreasParticipantesSLA__c, area1));
        Assert.areEqual('Retorno teste', updatedArea.ComentarioRetorno__c);
        Assert.areEqual('Solucao teste', updatedArea.SolucaoTomada__c);
        Assert.areEqual(true, updatedArea.DataHoraFim__c != null);
    }

    @IsTest
    static void testCloseLastParticipationUpdatesEtapa() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        String openStatus = AreaParticipanteTestDataFactory.openStatus();
        AreaParticipante__c area = AreaParticipanteTestDataFactory.createArea(c.Id, area1, openStatus, -2);

        AreaParticipanteDTO.CloseRequestDTO req = new AreaParticipanteDTO.CloseRequestDTO();
        req.areaParticipanteId = area.Id;
        req.comentarioRetorno = 'Retorno final';
        req.solucaoRetorno = 'Solucao final';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO res = AreaParticipanteService.closeParticipation(req);
        Test.stopTest();

        Case updatedCase = [SELECT AreasParticipantesSLA__c, EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(false, AreaParticipanteHelper.containsValue(updatedCase.AreasParticipantesSLA__c, area1));
        Assert.areEqual(true, res.success);
    }

    @IsTest
    static void testCloseParticipationRequiresFields() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        AreaParticipante__c area = AreaParticipanteTestDataFactory.createArea(c.Id, area1, AreaParticipanteTestDataFactory.openStatus(), 1);

        AreaParticipanteDTO.CloseRequestDTO req = new AreaParticipanteDTO.CloseRequestDTO();
        req.areaParticipanteId = area.Id;
        req.comentarioRetorno = '';
        req.solucaoRetorno = '';

        Boolean threw = false;
        try {
            AreaParticipanteService.closeParticipation(req);
        } catch (Exception ex) {
            threw = true;
        }
        Assert.areEqual(true, threw);
    }

    @IsTest
    static void testAddParticipationRequiresSlaRule() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = areas[0];
        req.comentarioSolicitacao = 'Solicitacao teste';

        Boolean threw = false;
        try {
            AreaParticipanteService.addParticipation(req);
        } catch (AreaParticipanteService.FunctionalException ex) {
            threw = true;
            Assert.areEqual('SLA_RULE_NOT_FOUND', ex.code);
        }
        Assert.areEqual(true, threw);
    }

    @IsTest
    static void testHelperMultipicklist() {
        String base = 'Financeiro;TI;Faturamento';
        String removed = AreaParticipanteHelper.removeValue(base, 'ti');
        Assert.areEqual(true, AreaParticipanteHelper.containsValue(removed, 'Financeiro'));
        Assert.areEqual(false, AreaParticipanteHelper.containsValue(removed, 'TI'));

        Set<String> tokens = AreaParticipanteHelper.parseMultiPicklist(base);
        Assert.areEqual(3, tokens.size());
    }
}