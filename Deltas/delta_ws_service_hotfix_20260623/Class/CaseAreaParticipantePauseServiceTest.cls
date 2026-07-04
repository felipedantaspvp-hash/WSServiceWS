@IsTest
private class CaseAreaParticipantePauseServiceTest {
    private static Categorizacao__c createCategorizacao() {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        return c;
    }

    private static String getBhName() {
        String bhName = 'BH_PAUSE_TEST';
        BusinessHoursResolverService.injectedByName.put(bhName, (Id) '01m000000000001AAA');
        return bhName;
    }

    private static RegrasSLACategorizacao__c createRule(Id categId, String area) {
        List<Schema.PicklistEntry> ue = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        String unidade = ue.isEmpty() ? 'Salvador' : ue[0].getValue();
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Pause ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = getBhName(),
            Ativo__c = true
        );
        insert g;
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            AreaAtendimento__c = area,
            BusinessHoursName__c = getBhName(),
            Ativo__c = true,
            GestaoSLA__c = g.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 120,
            TempoMedia__c = 120,
            TempoAlta__c = 120
        );
        insert r;
        Categorizacao__c categ = new Categorizacao__c(Id = categId);
        categ.GestaoSLA__c = g.Id;
        update categ;
        return r;
    }

    private static String getNonInternalTipoAreaValue() {
        for (Schema.PicklistEntry entry : AreaParticipante__c.TipoAreaParticipante__c.getDescribe().getPicklistValues()) {
            if (!AreaParticipanteSLAHelper.isTipoInterna(entry.getValue())) {
                return entry.getValue();
            }
        }
        return AreaParticipanteSLAHelper.tipoAreaInternaApiValue();
    }

    private static AreaParticipante__c createOpenArea(Case c, String area) {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'pause test'
        );
        insert ap;
        return ap;
    }

    @IsTest
    static void testPauseOnEnteringAguardandoCliente() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;
        createRule(categ.Id, area);
        AreaParticipante__c ap = createOpenArea(c, area);

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = 'Em Atendimento';
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        AreaParticipante__c saved = [
            SELECT StatusAtuacao__c, StatusSLA__c, DataHoraInicioPausa__c, StatusAtuacaoAnteriorPausa__c, BloqueiaFechamentoCaso__c
            FROM AreaParticipante__c
            WHERE Id = :ap.Id
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA, saved.StatusAtuacao__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO, saved.StatusSLA__c);
        Assert.areEqual(true, saved.DataHoraInicioPausa__c != null);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, saved.StatusAtuacaoAnteriorPausa__c);
        Case caseAfter = [SELECT QtdAreasParticipantesAbertas__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(1, Integer.valueOf(caseAfter.QtdAreasParticipantesAbertas__c));
    }

    @IsTest
    static void testResumeRestoresStatusAndDeadlineAndSlaStatus() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;
        createRule(categ.Id, area);
        AreaParticipante__c ap = createOpenArea(c, area);

        Datetime oldDeadline = System.now().addMinutes(20);
        ap = [SELECT Id, StatusAtuacao__c, DataHoraPrazo__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        ap.StatusAtuacaoAnteriorPausa__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ANDAMENTO;
        ap.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA;
        ap.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
        ap.DataHoraInicioPausa__c = System.now().addMinutes(-15);
        ap.DataHoraPrazo__c = oldDeadline;
        update ap;

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = 'Em Atendimento';

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        AreaParticipante__c resumed = [
            SELECT StatusAtuacao__c, StatusSLA__c, DataHoraInicioPausa__c, StatusAtuacaoAnteriorPausa__c, TempoPausadoMinutos__c, DataHoraPrazo__c
            FROM AreaParticipante__c
            WHERE Id = :ap.Id
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ANDAMENTO, resumed.StatusAtuacao__c);
        Assert.areEqual(true, resumed.TempoPausadoMinutos__c > 0);
        Assert.areEqual(true, resumed.DataHoraPrazo__c > oldDeadline);
        Assert.areEqual(null, resumed.DataHoraInicioPausa__c);
        Assert.areEqual(null, resumed.StatusAtuacaoAnteriorPausa__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO, resumed.StatusSLA__c);
        Case caseAfter = [SELECT QtdAreasParticipantesAbertas__c, QtdAreasParticipantesVencidas__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(1, Integer.valueOf(caseAfter.QtdAreasParticipantesAbertas__c));
        Assert.areEqual(0, Integer.valueOf(caseAfter.QtdAreasParticipantesVencidas__c));
    }

    @IsTest
    static void testResumeKeepsVencidoWhenStillOverdue() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;
        createRule(categ.Id, area);
        AreaParticipante__c ap = createOpenArea(c, area);

        ap = [SELECT Id FROM AreaParticipante__c WHERE Id = :ap.Id];
        ap.StatusAtuacaoAnteriorPausa__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA;
        ap.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA;
        ap.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
        ap.DataHoraInicioPausa__c = System.now().addMinutes(-1);
        ap.DataHoraPrazo__c = System.now().addMinutes(-60);
        update ap;

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = 'Em Atendimento';

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        AreaParticipante__c resumed = [
            SELECT StatusSLA__c, ViolouSLA__c
            FROM AreaParticipante__c
            WHERE Id = :ap.Id
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO, resumed.StatusSLA__c);
        Assert.areEqual(true, resumed.ViolouSLA__c);
    }

    @IsTest
    static void testPauseSkipsNonInternalAndAlreadyPausedRows() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;
        createRule(categ.Id, area);

        AreaParticipante__c nonInternal = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = getNonInternalTipoAreaValue(),
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'skip non internal'
        );
        AreaParticipante__c alreadyPaused = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            ComentarioSolicitacao__c = 'skip paused'
        );
        insert new List<AreaParticipante__c>{ nonInternal, alreadyPaused };

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = 'Em Atendimento';
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        Map<Id, AreaParticipante__c> savedById = new Map<Id, AreaParticipante__c>([
            SELECT Id, StatusAtuacao__c, DataHoraInicioPausa__c
            FROM AreaParticipante__c
            WHERE Id IN :new Set<Id>{ nonInternal.Id, alreadyPaused.Id }
        ]);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, savedById.get(nonInternal.Id).StatusAtuacao__c);
        Assert.areEqual(null, savedById.get(nonInternal.Id).DataHoraInicioPausa__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA, savedById.get(alreadyPaused.Id).StatusAtuacao__c);
    }

    @IsTest
    static void testResumeUsesAndamentoWhenPreviousStatusIsBlank() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;
        createRule(categ.Id, area);
        AreaParticipante__c ap = createOpenArea(c, area);

        ap = [SELECT Id FROM AreaParticipante__c WHERE Id = :ap.Id];
        ap.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA;
        ap.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
        ap.StatusAtuacaoAnteriorPausa__c = null;
        ap.DataHoraInicioPausa__c = System.now().addMinutes(-10);
        ap.DataHoraPrazo__c = null;
        update ap;

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = 'Em Atendimento';

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        AreaParticipante__c resumed = [
            SELECT StatusAtuacao__c, StatusSLA__c, StatusAtuacaoAnteriorPausa__c, DataHoraInicioPausa__c, TempoPausadoMinutos__c
            FROM AreaParticipante__c
            WHERE Id = :ap.Id
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ANDAMENTO, resumed.StatusAtuacao__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO, resumed.StatusSLA__c);
        Assert.areEqual(null, resumed.StatusAtuacaoAnteriorPausa__c);
        Assert.areEqual(null, resumed.DataHoraInicioPausa__c);
        Assert.areEqual(true, resumed.TempoPausadoMinutos__c > 0);
    }

    @IsTest
    static void testPauseEnterSetsMilestonePauseField() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        CaseAreaParticipantePauseService.bypassCaseMilestoneDmlInTests = false;
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(
            AreaParticipanteTestDataFactory.commonAreaValues()[0], null
        );

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = 'Em Atendimento';
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        Case saved = [SELECT DataHoraPausaMilestone__c FROM Case WHERE Id = :c.Id];
        Assert.isTrue(saved.DataHoraPausaMilestone__c != null, 'DataHoraPausaMilestone__c deve ser preenchido ao entrar em Aguardando Cliente');
    }

    @IsTest
    static void testResumeExitClearsMilestonePauseField() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        CaseAreaParticipantePauseService.bypassCaseMilestoneDmlInTests = false;
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(
            AreaParticipanteTestDataFactory.commonAreaValues()[0], null
        );

        c.DataHoraPausaMilestone__c = System.now().addMinutes(-15);
        update c;

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = 'Em Atendimento';

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        Case saved = [SELECT DataHoraPausaMilestone__c FROM Case WHERE Id = :c.Id];
        Assert.isNull(saved.DataHoraPausaMilestone__c, 'DataHoraPausaMilestone__c deve ser limpo ao sair de Aguardando Cliente');
    }

    @IsTest
    static void testBypassSkipsCaseMilestoneDml() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        CaseAreaParticipantePauseService.bypassCaseMilestoneDmlInTests = true;
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(
            AreaParticipanteTestDataFactory.commonAreaValues()[0], null
        );

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = 'Em Atendimento';
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();

        Test.startTest();
        CaseAreaParticipantePauseService.handleEtapaChanges(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );
        Test.stopTest();

        Case saved = [SELECT DataHoraPausaMilestone__c FROM Case WHERE Id = :c.Id];
        Assert.isNull(saved.DataHoraPausaMilestone__c, 'Bypass deve impedir DML do campo milestone');
    }

    @IsTest
    static void testNoOpWhenRecursionGuardIsAlreadyEntered() {
        CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests = true;
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;
        createRule(categ.Id, area);
        AreaParticipante__c ap = createOpenArea(c, area);

        Case oldCase = (Case) c.clone(true, true, true, true);
        oldCase.EtapaAtendimento__c = 'Em Atendimento';
        Case newCase = (Case) c.clone(true, true, true, true);
        newCase.EtapaAtendimento__c = AreaParticipanteSLAHelper.etapaAguardandoCliente();

        AreaParticipanteSLARecursionGuard.enter('CASE_PAUSE_RESUME');
        try {
            Test.startTest();
            CaseAreaParticipantePauseService.handleEtapaChanges(
                new Map<Id, Case>{ c.Id => newCase },
                new Map<Id, Case>{ c.Id => oldCase }
            );
            Test.stopTest();
        } finally {
            AreaParticipanteSLARecursionGuard.leave('CASE_PAUSE_RESUME');
        }

        AreaParticipante__c saved = [
            SELECT StatusAtuacao__c, DataHoraInicioPausa__c
            FROM AreaParticipante__c
            WHERE Id = :ap.Id
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, saved.StatusAtuacao__c);
        Assert.areEqual(null, saved.DataHoraInicioPausa__c);
    }
}
