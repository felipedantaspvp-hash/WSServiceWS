@IsTest
private class AreaParticipanteServiceTest {
    private static void enableBhBypass() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
        BusinessHoursResolverService.injectedByName.put('Tecon Salvador', (Id) '01m000000000001AAA');
    }

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
        enableBhBypass();
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
        enableBhBypass();
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
        enableBhBypass();
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
        enableBhBypass();
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
    static void testAddParticipationCriaCamposCorretos() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
        BusinessHoursResolverService.injectedByName.put('Tecon Salvador', (Id) '01m000000000001AAA');

        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = areas[0];
        req.comentarioSolicitacao = 'Teste 17A';

        Test.startTest();
        AreaParticipanteDTO.AddResponseDTO res = AreaParticipanteService.addParticipation(req);
        Test.stopTest();

        Assert.areEqual(true, res.success);
        Assert.isNotNull(res.areaParticipanteId);

        AreaParticipante__c a = [
            SELECT TipoAreaParticipante__c, OrigemAtuacao__c, DataHoraInicio__c,
                   DataHoraPrazo__c, TempoSLAMinutos__c, BloqueiaFechamentoCaso__c,
                   RegraSLACategorizacao__c
            FROM AreaParticipante__c WHERE Id = :res.areaParticipanteId
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.TIPO_AREA_INTERNA, a.TipoAreaParticipante__c);
        Assert.areEqual('Manual', a.OrigemAtuacao__c);
        Assert.isNotNull(a.DataHoraInicio__c);
        Assert.isNotNull(a.DataHoraPrazo__c);
        Assert.isNotNull(a.TempoSLAMinutos__c);
        Assert.areEqual(true, a.BloqueiaFechamentoCaso__c);
        Assert.isNotNull(a.RegraSLACategorizacao__c);
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

    @IsTest
    static void testAddParticipationSetsEtapaAguardandoAreaInterna() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        update new Case(Id = c.Id, EtapaAtendimento__c = 'Em Atendimento');

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = area1;
        req.comentarioSolicitacao = 'Teste etapa add';

        Test.startTest();
        AreaParticipanteDTO.AddResponseDTO res = AreaParticipanteService.addParticipation(req);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, res.success);
        Assert.areEqual('Aguardando Área Interna', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testAddParticipationDoesNotChangeEtapaForCancelledCase() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        update new Case(Id = c.Id, EtapaAtendimento__c = 'Cancelado');

        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = area1;
        req.comentarioSolicitacao = 'Teste terminal add';

        Test.startTest();
        AreaParticipanteDTO.AddResponseDTO res = AreaParticipanteService.addParticipation(req);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, res.success);
        Assert.areEqual('Cancelado', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testCloseLastCustomInternaMovesEtapaToPreparandoRetorno() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);

        AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
        addReq.caseId = c.Id;
        addReq.area = area1;
        addReq.comentarioSolicitacao = 'Abertura única';
        AreaParticipanteDTO.AddResponseDTO addRes = AreaParticipanteService.addParticipation(addReq);

        AreaParticipanteDTO.CloseRequestDTO closeReq = new AreaParticipanteDTO.CloseRequestDTO();
        closeReq.areaParticipanteId = addRes.areaParticipanteId;
        closeReq.comentarioRetorno = 'Retorno teste';
        closeReq.solucaoRetorno = 'Solução teste';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO closeRes = AreaParticipanteService.closeParticipation(closeReq);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, closeRes.success);
        Assert.areEqual(true, closeRes.etapaAtualizada);
        Assert.areEqual('Preparando Retorno ao Cliente', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testCloseWithOtherOpenCustomInternaKeepsEtapa() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        if (areas.size() < 2) return;
        String area1 = areas[0];
        String area2 = areas[1];
        if (AreaParticipanteHelper.normalizeText(area1) == AreaParticipanteHelper.normalizeText(area2)) return;
        Case c = AreaParticipanteTestDataFactory.createCase(area1, area2);

        AreaParticipanteDTO.AddRequestDTO addReq1 = new AreaParticipanteDTO.AddRequestDTO();
        addReq1.caseId = c.Id; addReq1.area = area1; addReq1.comentarioSolicitacao = 'Área 1';
        AreaParticipanteDTO.AddResponseDTO addRes1 = AreaParticipanteService.addParticipation(addReq1);

        AreaParticipanteDTO.AddRequestDTO addReq2 = new AreaParticipanteDTO.AddRequestDTO();
        addReq2.caseId = c.Id; addReq2.area = area2; addReq2.comentarioSolicitacao = 'Área 2';
        AreaParticipanteService.addParticipation(addReq2);

        AreaParticipanteDTO.CloseRequestDTO closeReq = new AreaParticipanteDTO.CloseRequestDTO();
        closeReq.areaParticipanteId = addRes1.areaParticipanteId;
        closeReq.comentarioRetorno = 'Retorno parcial';
        closeReq.solucaoRetorno = 'Solução parcial';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO closeRes = AreaParticipanteService.closeParticipation(closeReq);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, closeRes.success);
        Assert.areEqual(false, closeRes.etapaAtualizada);
        Assert.areEqual('Aguardando Área Interna', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testCloseWithStandardOnlyRemainingMovesEtapa() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);

        AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
        addReq.caseId = c.Id; addReq.area = area1; addReq.comentarioSolicitacao = 'Custom única';
        AreaParticipanteDTO.AddResponseDTO addRes = AreaParticipanteService.addParticipation(addReq);

        AreaParticipante__c stdAp = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            BloqueiaFechamentoCaso__c = false,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            DataHoraInicio__c = System.now()
        );
        insert stdAp;

        AreaParticipanteDTO.CloseRequestDTO closeReq = new AreaParticipanteDTO.CloseRequestDTO();
        closeReq.areaParticipanteId = addRes.areaParticipanteId;
        closeReq.comentarioRetorno = 'Retorno Standard';
        closeReq.solucaoRetorno = 'Solução Standard';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO closeRes = AreaParticipanteService.closeParticipation(closeReq);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, closeRes.success);
        Assert.areEqual('Preparando Retorno ao Cliente', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testCloseStandardApDoesNotUpdateEtapa() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);

        AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
        addReq.caseId = c.Id; addReq.area = area1; addReq.comentarioSolicitacao = 'Custom aberta';
        AreaParticipanteService.addParticipation(addReq);

        AreaParticipante__c stdAp = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            BloqueiaFechamentoCaso__c = false,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            DataHoraInicio__c = System.now()
        );
        insert stdAp;

        AreaParticipanteDTO.CloseRequestDTO closeReq = new AreaParticipanteDTO.CloseRequestDTO();
        closeReq.areaParticipanteId = stdAp.Id;
        closeReq.comentarioRetorno = 'Retorno Standard';
        closeReq.solucaoRetorno = 'Solução Standard';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO closeRes = AreaParticipanteService.closeParticipation(closeReq);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, closeRes.success);
        Assert.areEqual(false, closeRes.etapaAtualizada);
        Assert.areEqual('Aguardando Área Interna', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testCloseDoesNotUpdateEtapaWhenCaseIsFechado() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);

        AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
        addReq.caseId = c.Id; addReq.area = area1; addReq.comentarioSolicitacao = 'Test Status Fechado guard';
        AreaParticipanteDTO.AddResponseDTO addRes = AreaParticipanteService.addParticipation(addReq);

        Case refreshed = [SELECT Id, AreasParticipantesSLA__c, AreasParticipantes__c, EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        AreaParticipanteSelector.testCase = new Case(
            Id = refreshed.Id,
            Status = 'Fechado',
            EtapaAtendimento__c = refreshed.EtapaAtendimento__c,
            AreasParticipantesSLA__c = refreshed.AreasParticipantesSLA__c,
            AreasParticipantes__c = refreshed.AreasParticipantes__c
        );

        AreaParticipanteDTO.CloseRequestDTO closeReq = new AreaParticipanteDTO.CloseRequestDTO();
        closeReq.areaParticipanteId = addRes.areaParticipanteId;
        closeReq.comentarioRetorno = 'Retorno Status Fechado';
        closeReq.solucaoRetorno = 'Solução Status Fechado';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO closeRes = AreaParticipanteService.closeParticipation(closeReq);
        Test.stopTest();

        AreaParticipanteSelector.testCase = null;

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, closeRes.success);
        Assert.areEqual(false, closeRes.etapaAtualizada);
        Assert.areEqual('Aguardando Área Interna', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testCloseDoesNotUpdateEtapaForTerminalCase() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, null);
        update new Case(Id = c.Id, EtapaAtendimento__c = 'Cancelado');

        AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
        addReq.caseId = c.Id; addReq.area = area1; addReq.comentarioSolicitacao = 'Terminal close test';
        AreaParticipanteDTO.AddResponseDTO addRes = AreaParticipanteService.addParticipation(addReq);

        AreaParticipanteDTO.CloseRequestDTO closeReq = new AreaParticipanteDTO.CloseRequestDTO();
        closeReq.areaParticipanteId = addRes.areaParticipanteId;
        closeReq.comentarioRetorno = 'Retorno terminal';
        closeReq.solucaoRetorno = 'Solução terminal';

        Test.startTest();
        AreaParticipanteDTO.CloseResponseDTO closeRes = AreaParticipanteService.closeParticipation(closeReq);
        Test.stopTest();

        Case updatedCase = [SELECT EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, closeRes.success);
        Assert.areEqual(false, closeRes.etapaAtualizada);
        Assert.areEqual('Cancelado', updatedCase.EtapaAtendimento__c);
    }

    @IsTest
    static void testPauseManualCustomAreaSuccess() {
        enableBhBypass();
        Id areaId = createOpenManualCustomArea();

        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = areaId;

        Test.startTest();
        AreaParticipanteDTO.PauseResumeResponseDTO res = AreaParticipanteService.pauseParticipation(req);
        Test.stopTest();

        AreaParticipante__c saved = [
            SELECT DataHoraInicioPausa__c, StatusAtuacao__c, StatusAtuacaoAnteriorPausa__c, StatusSLA__c
            FROM AreaParticipante__c
            WHERE Id = :areaId
        ];
        Assert.areEqual(true, res.success);
        Assert.isNotNull(saved.DataHoraInicioPausa__c, 'A pausa deve registrar inicio.');
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, saved.StatusAtuacao__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, saved.StatusAtuacaoAnteriorPausa__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO, saved.StatusSLA__c);
    }

    @IsTest
    static void testResumeManualCustomAreaAccumulatesPausedTime() {
        enableBhBypass();
        Id areaId = createOpenManualCustomArea();

        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = areaId;
        AreaParticipanteService.pauseParticipation(req);

        update new AreaParticipante__c(
            Id = areaId,
            DataHoraInicioPausa__c = System.now().addMinutes(-30),
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO
        );

        Test.startTest();
        AreaParticipanteDTO.PauseResumeResponseDTO res = AreaParticipanteService.resumeParticipation(req);
        Test.stopTest();

        AreaParticipante__c saved = [
            SELECT DataHoraInicioPausa__c, TempoPausadoMinutos__c, StatusSLA__c
            FROM AreaParticipante__c
            WHERE Id = :areaId
        ];
        Assert.areEqual(true, res.success);
        Assert.areEqual(null, saved.DataHoraInicioPausa__c);
        Assert.areEqual(30, saved.TempoPausadoMinutos__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO, saved.StatusSLA__c);
    }

    @IsTest
    static void testPauseRejectsStandardArea() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);
        AreaParticipante__c standardArea = new AreaParticipante__c(
            Caso__c = c.Id,
            AreaAtendimento__c = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            DataHoraInicio__c = System.now()
        );
        insert standardArea;

        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = standardArea.Id;

        try {
            AreaParticipanteService.pauseParticipation(req);
            Assert.fail('Standard nao deve ser pausado.');
        } catch (AreaParticipanteService.FunctionalException ex) {
            Assert.areEqual('NOT_CUSTOM_INTERNAL_AREA', ex.code);
        }
    }

    @IsTest
    static void testResumeRejectsStandardArea() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);
        AreaParticipante__c standardArea = new AreaParticipante__c(
            Caso__c = c.Id,
            AreaAtendimento__c = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicioPausa__c = System.now().addMinutes(-5),
            DataHoraInicio__c = System.now().addHours(-1)
        );
        insert standardArea;

        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = standardArea.Id;

        try {
            AreaParticipanteService.resumeParticipation(req);
            Assert.fail('Standard nao deve ser retomado.');
        } catch (AreaParticipanteService.FunctionalException ex) {
            Assert.areEqual('NOT_CUSTOM_INTERNAL_AREA', ex.code);
        }
    }

    @IsTest
    static void testPauseRejectsClosedAndCanceledArea() {
        enableBhBypass();
        List<Id> areaIds = createOpenManualCustomAreas(2);
        if (areaIds.size() < 2) return;
        Id closedId = areaIds[0];
        Id canceledId = areaIds[1];
        update new List<AreaParticipante__c>{
            new AreaParticipante__c(Id = closedId, StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA, DataHoraFim__c = System.now()),
            new AreaParticipante__c(Id = canceledId, StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CANCELADA)
        };

        assertPauseFails(closedId, 'ALREADY_CLOSED');
        assertPauseFails(canceledId, 'ALREADY_CANCELED');
    }

    @IsTest
    static void testResumeRejectsNotPausedAndPauseRejectsDuplicate() {
        enableBhBypass();
        Id areaId = createOpenManualCustomArea();

        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = areaId;
        try {
            AreaParticipanteService.resumeParticipation(req);
            Assert.fail('Area nao pausada nao deve ser retomada.');
        } catch (AreaParticipanteService.FunctionalException ex) {
            Assert.areEqual('NOT_PAUSED', ex.code);
        }

        AreaParticipanteService.pauseParticipation(req);
        try {
            AreaParticipanteService.pauseParticipation(req);
            Assert.fail('Pausa duplicada nao deve ser aceita.');
        } catch (AreaParticipanteService.FunctionalException ex) {
            Assert.areEqual('ALREADY_PAUSED', ex.code);
        }
    }

    @IsTest
    static void testPauseResumeRowsBulk() {
        enableBhBypass();
        List<Id> areaIds = createOpenManualCustomAreas(2);
        if (areaIds.size() < 2) return;
        Id areaOneId = areaIds[0];
        Id areaTwoId = areaIds[1];
        List<AreaParticipante__c> rows = AreaParticipanteSelector.getAreasByIds(new Set<Id>{ areaOneId, areaTwoId });

        Test.startTest();
        AreaParticipanteService.pauseRows(rows, System.now());
        for (AreaParticipante__c row : rows) {
            row.DataHoraInicioPausa__c = System.now().addMinutes(-10);
            row.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
        }
        AreaParticipanteService.resumeRows(rows, System.now());
        Test.stopTest();

        List<AreaParticipante__c> savedRows = [
            SELECT DataHoraInicioPausa__c, TempoPausadoMinutos__c
            FROM AreaParticipante__c
            WHERE Id IN :new Set<Id>{ areaOneId, areaTwoId }
        ];
        Assert.areEqual(2, savedRows.size());
        for (AreaParticipante__c row : savedRows) {
            Assert.areEqual(null, row.DataHoraInicioPausa__c);
            Assert.areEqual(10, row.TempoPausadoMinutos__c);
        }
    }

    private static Id createOpenManualCustomArea() {
        return createOpenManualCustomAreas(1)[0];
    }

    private static List<Id> createOpenManualCustomAreas(Integer count) {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        String area2 = areas.size() > 1 ? areas[1] : null;
        Case c = AreaParticipanteTestDataFactory.createCase(area1, count > 1 ? area2 : null);
        List<Id> out = new List<Id>();
        for (Integer i = 0; i < count && i < areas.size(); i++) {
            AreaParticipanteDTO.AddRequestDTO addReq = new AreaParticipanteDTO.AddRequestDTO();
            addReq.caseId = c.Id;
            addReq.area = areas[i];
            addReq.comentarioSolicitacao = 'Pausa retomada manual ' + String.valueOf(i);
            out.add(AreaParticipanteService.addParticipation(addReq).areaParticipanteId);
        }
        return out;
    }

    private static void assertPauseFails(Id areaId, String expectedCode) {
        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = areaId;
        try {
            AreaParticipanteService.pauseParticipation(req);
            Assert.fail('Pausa deveria falhar.');
        } catch (AreaParticipanteService.FunctionalException ex) {
            Assert.areEqual(expectedCode, ex.code);
        }
    }
}
