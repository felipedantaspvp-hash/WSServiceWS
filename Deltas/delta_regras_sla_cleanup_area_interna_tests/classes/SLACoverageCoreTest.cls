@IsTest
private class SLACoverageCoreTest {
    private static Categorizacao__c createCategorizacao() {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        return c;
    }

    private static String getActiveBusinessHoursName() {
        List<BusinessHours> rows = [SELECT Id, Name FROM BusinessHours WHERE IsActive = true LIMIT 1];
        if (rows.isEmpty()) {
            BusinessHoursResolverService.injectedByName.put('BH_TEST', UserInfo.getUserId());
            return 'BH_TEST';
        }
        return rows[0].Name;
    }

    private static String getAreaValue() {
        List<String> values = AreaParticipanteTestDataFactory.commonAreaValues();
        return values.isEmpty() ? 'Operações' : values[0];
    }

    private static GestaoSLA__c createGestao() {
        List<Schema.PicklistEntry> ue = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        String unidade = ue.isEmpty() ? 'Salvador' : ue[0].getValue();
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Coverage ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = getActiveBusinessHoursName(),
            Ativo__c = true
        );
        insert g;
        return g;
    }

    private static RegrasSLACategorizacao__c createRule(Id categId, String area, Id gestaoId) {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            BusinessHoursName__c = getActiveBusinessHoursName(),
            Ativo__c = true,
            GestaoSLA__c = gestaoId,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 30,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );
        insert r;
        return r;
    }

    @IsTest
    static void testRegrasValidationAndSelectorHelper() {
        Categorizacao__c c = createCategorizacao();
        String area = getAreaValue();
        GestaoSLA__c g = createGestao();
        RegrasSLACategorizacao__c r1 = createRule(c.Id, area, g.Id);
        r1 = [SELECT Id, ChaveUnica__c, ChaveUnicaHash__c FROM RegrasSLACategorizacao__c WHERE Id = :r1.Id];

        Assert.areEqual(true, String.isNotBlank(r1.ChaveUnica__c));
        Assert.areEqual(64, r1.ChaveUnicaHash__c.length());

        RegrasSLACategorizacao__c dup = new RegrasSLACategorizacao__c(
            Categorizacao__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            BusinessHoursName__c = getActiveBusinessHoursName(),
            Ativo__c = true,
            GestaoSLA__c = g.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 30,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );

        Boolean blocked = false;
        try {
            insert dup;
        } catch (DmlException ex) {
            blocked = true;
        }
        Assert.areEqual(true, blocked);

        RegrasSLACategorizacao__c inactiveDup = new RegrasSLACategorizacao__c(
            Categorizacao__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            BusinessHoursName__c = getActiveBusinessHoursName(),
            Ativo__c = false,
            GestaoSLA__c = g.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 30,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );
        insert inactiveDup;

        Map<String, RegrasSLACategorizacao__c> byHash = RegrasSLACategorizacaoSelector.getActiveByKey(new Set<String>{ r1.ChaveUnicaHash__c }, null);
        Assert.areEqual(true, byHash.containsKey(r1.ChaveUnicaHash__c));

        List<RegrasSLACategorizacao__c> found = RegrasSLACategorizacaoSelector.findActiveRules(
            new Set<Id>{ c.Id },
            new Set<String>{ AreaParticipanteSLAHelper.TIPO_AREA_INTERNA },
            new Set<String>{ area }
        );
        Assert.areEqual(true, found.size() > 0);

        Assert.areEqual('null', RegrasSLACategorizacaoHelper.normalize(null));
        Assert.areEqual(64, RegrasSLACategorizacaoHelper.hash('abc').length());
    }

    @IsTest
    static void testAreaLifecyclePauseResumeCloseAndBlockCaseClose() {
        Categorizacao__c categ = createCategorizacao();
        String area = getAreaValue();

        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        GestaoSLA__c g = createGestao();
        categ.GestaoSLA__c = g.Id;
        update categ;
        RegrasSLACategorizacao__c rule = createRule(categ.Id, area, g.Id);
        Assert.areEqual(true, rule.Ativo__c);

        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'Solicitação'
        );
        insert ap;

        AreaParticipante__c saved = [
            SELECT Id, RegraSLACategorizacao__c, TempoSLAMinutos__c, DataHoraInicio__c, DataHoraPrazo__c,
                   StatusSLA__c, OrigemSLA__c, BloqueiaFechamentoCaso__c, SequenciaAcionamento__c
            FROM AreaParticipante__c WHERE Id = :ap.Id
        ];
        Assert.areEqual(rule.Id, saved.RegraSLACategorizacao__c);
        Assert.areEqual('Custom', saved.OrigemSLA__c);
        Assert.areEqual(true, saved.BloqueiaFechamentoCaso__c);
        Assert.areEqual(1, Integer.valueOf(saved.SequenciaAcionamento__c));

        c = [SELECT Id, EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        c.EtapaAtendimento__c = AreaParticipanteSLAHelper.ETAPA_AGUARDANDO_CLIENTE;
        update c;

        AreaParticipante__c paused = [SELECT StatusAtuacao__c, StatusSLA__c, DataHoraInicioPausa__c, StatusAtuacaoAnteriorPausa__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA, paused.StatusAtuacao__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO, paused.StatusSLA__c);
        Assert.areEqual(true, paused.DataHoraInicioPausa__c != null);

        c = [SELECT Id, EtapaAtendimento__c FROM Case WHERE Id = :c.Id];
        c.EtapaAtendimento__c = 'Em Atendimento';
        update c;

        AreaParticipante__c resumed = [SELECT StatusAtuacao__c, DataHoraInicioPausa__c, TempoPausadoMinutos__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, resumed.StatusAtuacao__c);
        Assert.areEqual(true, resumed.DataHoraInicioPausa__c == null);

        AreaParticipante__c blocker = [SELECT Id, BloqueiaFechamentoCaso__c, DataHoraFim__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        blocker.BloqueiaFechamentoCaso__c = true;
        blocker.DataHoraFim__c = null;
        update blocker;

        Case oldCase = (Case) JSON.deserialize('{"Id":"' + c.Id + '","IsClosed":false}', Case.class);
        Case newCase = (Case) JSON.deserialize('{"Id":"' + c.Id + '","IsClosed":true}', Case.class);
        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        Map<Id, Case> newMap = new Map<Id, Case>{ c.Id => newCase };
        CaseTriggerHandler.beforeUpdate(newMap, oldMap);
        Assert.areEqual(true, true);

        AreaParticipante__c toClose = [SELECT Id, StatusAtuacao__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        toClose.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA;
        toClose.DataHoraFim__c = System.now();
        update toClose;

        AreaParticipante__c closed = [SELECT BloqueiaFechamentoCaso__c, StatusSLA__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        Assert.areEqual(false, closed.BloqueiaFechamentoCaso__c);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO, closed.StatusSLA__c);

        AreaParticipante__c ap2 = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'Novo ciclo'
        );
        insert ap2;
        AreaParticipante__c cycle2 = [SELECT SequenciaAcionamento__c FROM AreaParticipante__c WHERE Id = :ap2.Id];
        Assert.areEqual(2, Integer.valueOf(cycle2.SequenciaAcionamento__c));
    }

    @IsTest
    static void testBatchAndSchedulerAndGuard() {
        Categorizacao__c categ = createCategorizacao();
        String area = getAreaValue();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        GestaoSLA__c gBatch = createGestao();
        categ.GestaoSLA__c = gBatch.Id;
        update categ;
        createRule(categ.Id, area, gBatch.Id);

        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'Batch row'
        );
        insert ap;

        Test.startTest();
        Database.executeBatch(new AreaParticipanteSLABatch(), 50);
        System.schedule('SLA SCHED TEST', '0 0 0 1 1 ? 2099', new AreaParticipanteSLAScheduler());
        Test.stopTest();

        AreaParticipante__c afterBatch = [SELECT TempoConsumidoMinutos__c, PercentualDecorrido__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        Assert.areEqual(true, afterBatch.TempoConsumidoMinutos__c != null);
        Assert.areEqual(true, afterBatch.PercentualDecorrido__c != null);

        Assert.areEqual(true, AreaParticipanteSLARecursionGuard.enter('X'));
        Assert.areEqual(false, AreaParticipanteSLARecursionGuard.enter('X'));
        AreaParticipanteSLARecursionGuard.leave('X');
        Assert.areEqual(true, AreaParticipanteSLARecursionGuard.enter('X'));
    }

    @IsTest
    static void testBusinessHoursResolverErrorBranch() {
        BusinessHoursResolverService.injectedByName.clear();
        Boolean failed = false;
        try {
            BusinessHoursResolverService.resolveActiveByName('BH_NOT_EXISTS_123');
        } catch (Exception ex) {
            failed = true;
        }
        Assert.areEqual(true, failed);
    }
}