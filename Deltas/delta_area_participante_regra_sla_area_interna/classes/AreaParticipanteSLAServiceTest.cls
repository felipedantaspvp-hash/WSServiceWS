@IsTest
private class AreaParticipanteSLAServiceTest {
    private static void enableDeterministicBusinessHoursMath() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
        BusinessHoursResolverService.injectedByName.put('BH_SLA_SERVICE_TEST', (Id) '01m000000000001AAA');
    }

    private static String getAnyUnidadeGestao() {
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        return entries.isEmpty() ? null : entries[0].getValue();
    }

    private static GestaoSLA__c createGestao() {
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao SLA Service ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = getAnyUnidadeGestao(),
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'BH_SLA_SERVICE_TEST',
            Ativo__c = true
        );
        insert g;
        return g;
    }

    private static MarcoSLA__c createMarcoN3(Id gestaoId, String suffix) {
        MarcoSLA__c m = new MarcoSLA__c(
            Name = 'Marco N3 ' + suffix,
            GestaoSLA__c = gestaoId,
            NomeMarco__c = 'Atendimento N3',
            MilestoneTypeName__c = 'Atendimento N3',
            FonteTempo__c = 'RegraSLA',
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = true
        );
        insert m;
        return m;
    }

    private static Categorizacao__c createCategorizacao(Id gestaoId) {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        c.GestaoSLA__c = gestaoId;
        update c;
        return c;
    }

    private static Case createCase(Id categId, String prioridade, String origem) {
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categId;
        c.Priority = prioridade;
        c.Origin = origem;
        update c;
        return c;
    }

    private static RegrasSLACategorizacao__c createRegraNova(
        Id categId,
        Id gestaoId,
        Id marcoSlaId,
        String area,
        String escopo
    ) {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'BH_SLA_SERVICE_TEST',
            Ativo__c = true,
            GestaoSLA__c = gestaoId,
            MarcoSLA__c = marcoSlaId,
            EscopoRegra__c = escopo,
            TempoBaixa__c = 10,
            TempoMedia__c = 20,
            TempoAlta__c = 30
        );
        insert r;
        return r;
    }

    private static RegrasSLACategorizacao__c createRegraLegada(Id categId, String area, Integer tempo) {
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Legado ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = getAnyUnidadeGestao(),
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'BH_SLA_SERVICE_TEST',
            Ativo__c = true
        );
        insert g;
        MarcoSLA__c m = new MarcoSLA__c(
            Name = 'Marco Legado ' + String.valueOf(Crypto.getRandomInteger()),
            GestaoSLA__c = g.Id,
            NomeMarco__c = AreaParticipanteSLAHelper.MARCO_ATENDIMENTO_N3,
            MilestoneTypeName__c = AreaParticipanteSLAHelper.MARCO_ATENDIMENTO_N3,
            FonteTempo__c = 'RegraSLA',
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = true
        );
        insert m;
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'BH_SLA_SERVICE_TEST',
            Ativo__c = true,
            GestaoSLA__c = g.Id,
            MarcoSLA__c = m.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = tempo,
            TempoMedia__c = tempo,
            TempoAlta__c = tempo
        );
        insert r;
        return r;
    }

    private static AreaParticipante__c createAreaParticipante(Id caseId, String area) {
        return new AreaParticipante__c(
            Caso__c = caseId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'Teste SLA N3'
        );
    }

    @IsTest
    static void testRegraNovaUnicaAtendeLowMediumHigh() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marcoN3 = createMarcoN3(gestao.Id, 'principal');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(
            categ.Id,
            gestao.Id,
            marcoN3.Id,
            area,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );

        Case cLow = createCase(categ.Id, 'Low', 'Manual');
        Case cMedium = createCase(categ.Id, 'Medium', 'Manual');
        Case cHigh = createCase(categ.Id, 'High', 'Manual');

        insert new List<AreaParticipante__c>{
            createAreaParticipante(cLow.Id, area),
            createAreaParticipante(cMedium.Id, area),
            createAreaParticipante(cHigh.Id, area)
        };

        Map<Id, AreaParticipante__c> byCase = new Map<Id, AreaParticipante__c>();
        for (AreaParticipante__c a : [SELECT Id, Caso__c, TempoSLAMinutos__c FROM AreaParticipante__c WHERE Caso__c IN :new Set<Id>{cLow.Id, cMedium.Id, cHigh.Id}]) {
            byCase.put(a.Caso__c, a);
        }
        Assert.areEqual(10, Integer.valueOf(String.valueOf(byCase.get(cLow.Id).TempoSLAMinutos__c)));
        Assert.areEqual(20, Integer.valueOf(String.valueOf(byCase.get(cMedium.Id).TempoSLAMinutos__c)));
        Assert.areEqual(30, Integer.valueOf(String.valueOf(byCase.get(cHigh.Id).TempoSLAMinutos__c)));
    }

    @IsTest
    static void testRegraAtiva() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marcoN3 = createMarcoN3(gestao.Id, 'ativa');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        RegrasSLACategorizacao__c regra = createRegraNova(
            categ.Id,
            gestao.Id,
            marcoN3.Id,
            area,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );

        Case c = createCase(categ.Id, 'High', 'Email');
        AreaParticipante__c a = createAreaParticipante(c.Id, area);
        insert a;

        a = [SELECT Id, RegraSLACategorizacao__c FROM AreaParticipante__c WHERE Id = :a.Id];
        Assert.areEqual(regra.Id, a.RegraSLACategorizacao__c);
    }

    @IsTest
    static void testSemRegraAtivaNaoAtribuiRegra() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        createMarcoN3(gestao.Id, 'macro');
        Categorizacao__c categ = createCategorizacao(gestao.Id);

        Case c = createCase(categ.Id, 'High', 'Manual');
        Boolean failed = false;
        try {
            insert createAreaParticipante(c.Id, area);
        } catch (DmlException ex) {
            failed = true;
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testRegraNovaInativaIgnorada() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marcoN3 = createMarcoN3(gestao.Id, 'inativa');
        Categorizacao__c categ = createCategorizacao(gestao.Id);

        RegrasSLACategorizacao__c regraInativa = createRegraNova(
            categ.Id,
            gestao.Id,
            marcoN3.Id,
            area,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        regraInativa.Ativo__c = false;
        update regraInativa;

        Case c = createCase(categ.Id, 'High', 'Manual');
        Boolean failed = false;
        try {
            insert createAreaParticipante(c.Id, area);
        } catch (DmlException ex) {
            failed = true;
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testRegraAreaInternaAtribuiCorretamente() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marcoN3 = createMarcoN3(gestao.Id, 'area-interna');
        Categorizacao__c categ = createCategorizacao(gestao.Id);

        RegrasSLACategorizacao__c regra = createRegraNova(
            categ.Id,
            gestao.Id,
            marcoN3.Id,
            area,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );

        Case c = createCase(categ.Id, 'High', 'Manual');
        AreaParticipante__c a = createAreaParticipante(c.Id, area);
        insert a;

        a = [SELECT Id, RegraSLACategorizacao__c, TempoSLAMinutos__c FROM AreaParticipante__c WHERE Id = :a.Id];
        Assert.areEqual(regra.Id, a.RegraSLACategorizacao__c);
        Assert.areEqual(30, Integer.valueOf(String.valueOf(a.TempoSLAMinutos__c)));
    }

    @IsTest
    static void testErroQuandoNaoExisteRegraNovaNemLegada() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        createMarcoN3(gestao.Id, 'sem-regra');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        Case c = createCase(categ.Id, 'High', 'Manual');

        Boolean failed = false;
        try {
            insert createAreaParticipante(c.Id, area);
        } catch (DmlException ex) {
            failed = true;
            Assert.areEqual(true, ex.getDmlMessage(0).contains('Não existe regra de SLA ativa'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testPrioridadeInvalidaRetornaErro() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarcoN3(gestao.Id, 'prio-invalida');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(categ.Id, gestao.Id, marco.Id, area, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        Case c = createCase(categ.Id, 'Low', 'Manual');
        c.Priority = 'Critical';
        update c;

        Boolean failed = false;
        try {
            insert createAreaParticipante(c.Id, area);
        } catch (DmlException ex) {
            failed = true;
            Assert.areEqual(true, ex.getDmlMessage(0).contains('inválida') || ex.getDmlMessage(0).contains('Prioridade'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testRegistroCriadoGravaCamposCorretos() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarcoN3(gestao.Id, 'campos');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        RegrasSLACategorizacao__c regra = createRegraNova(categ.Id, gestao.Id, marco.Id, area, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        Case c = createCase(categ.Id, 'High', 'Manual');

        insert createAreaParticipante(c.Id, area);
        AreaParticipante__c a = [
            SELECT TipoAreaParticipante__c, OrigemSLA__c, DataHoraInicio__c,
                   DataHoraPrazo__c, BloqueiaFechamentoCaso__c, RegraSLACategorizacao__c,
                   TempoSLAMinutos__c, ViolouSLA__c
            FROM AreaParticipante__c WHERE Caso__c = :c.Id LIMIT 1
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.TIPO_AREA_INTERNA, a.TipoAreaParticipante__c);
        Assert.areEqual(AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM, a.OrigemSLA__c);
        Assert.isNotNull(a.DataHoraInicio__c);
        Assert.isNotNull(a.DataHoraPrazo__c);
        Assert.areEqual(true, a.BloqueiaFechamentoCaso__c);
        Assert.areEqual(regra.Id, a.RegraSLACategorizacao__c);
        Assert.areEqual(30, Integer.valueOf(String.valueOf(a.TempoSLAMinutos__c)));
        Assert.areEqual(false, a.ViolouSLA__c);
    }

    @IsTest
    static void testSequenciaAcionamentoIncrementa() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarcoN3(gestao.Id, 'seq');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(categ.Id, gestao.Id, marco.Id, area, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        Case c = createCase(categ.Id, 'High', 'Manual');

        AreaParticipante__c a1 = createAreaParticipante(c.Id, area);
        insert a1;
        a1 = [SELECT SequenciaAcionamento__c FROM AreaParticipante__c WHERE Id = :a1.Id];
        Assert.areEqual(1, Integer.valueOf(String.valueOf(a1.SequenciaAcionamento__c)));

        a1.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA;
        a1.DataHoraFim__c = System.now();
        update a1;

        AreaParticipante__c a2 = createAreaParticipante(c.Id, area);
        insert a2;
        a2 = [SELECT SequenciaAcionamento__c FROM AreaParticipante__c WHERE Id = :a2.Id];
        Assert.areEqual(2, Integer.valueOf(String.valueOf(a2.SequenciaAcionamento__c)));
    }

    @IsTest
    static void testDuplicidadeAreaAbertaBloqueada() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarcoN3(gestao.Id, 'dup');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(categ.Id, gestao.Id, marco.Id, area, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        Case c = createCase(categ.Id, 'High', 'Manual');

        insert createAreaParticipante(c.Id, area);

        Boolean failed = false;
        try {
            insert createAreaParticipante(c.Id, area);
        } catch (DmlException ex) {
            failed = true;
            Assert.areEqual(true, ex.getDmlMessage(0).contains('aberto') || ex.getDmlMessage(0).contains('Já existe'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testMesmaAreaPermitidaAposConclusao() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarcoN3(gestao.Id, 'reabert');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(categ.Id, gestao.Id, marco.Id, area, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        Case c = createCase(categ.Id, 'High', 'Manual');

        AreaParticipante__c a1 = createAreaParticipante(c.Id, area);
        insert a1;
        a1.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA;
        a1.DataHoraFim__c = System.now();
        update a1;

        Boolean threw = false;
        try {
            insert createAreaParticipante(c.Id, area);
        } catch (DmlException ex) {
            threw = true;
        }
        Assert.areEqual(false, threw, 'Mesma área deve ser permitida após conclusão');
        Assert.areEqual(2, [SELECT COUNT() FROM AreaParticipante__c WHERE Caso__c = :c.Id]);
    }

    @IsTest
    static void testAreasDiferentesAbertasSimultaneamente() {
        enableDeterministicBusinessHoursMath();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        if (areas.size() < 2) return;
        String area1 = areas[0];
        String area2 = areas[1];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarcoN3(gestao.Id, 'multi');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(categ.Id, gestao.Id, marco.Id, area1, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        createRegraNova(categ.Id, gestao.Id, marco.Id, area2, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        Case c = createCase(categ.Id, 'High', 'Manual');

        insert new List<AreaParticipante__c>{
            createAreaParticipante(c.Id, area1),
            createAreaParticipante(c.Id, area2)
        };
        Assert.areEqual(2, [SELECT COUNT() FROM AreaParticipante__c WHERE Caso__c = :c.Id]);
    }

    @IsTest
    static void testMarcosDuplicadosNaGestaoNaoImpedeSLAComRegra() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco1 = createMarcoN3(gestao.Id, 'dup-1');
        createMarcoN3(gestao.Id, 'dup-2');
        Categorizacao__c categ = createCategorizacao(gestao.Id);
        createRegraNova(
            categ.Id, gestao.Id, marco1.Id, area,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        Case c = createCase(categ.Id, 'High', 'Manual');

        AreaParticipante__c ap = createAreaParticipante(c.Id, area);
        insert ap;
        ap = [SELECT Id, RegraSLACategorizacao__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        Assert.isNotNull(ap.RegraSLACategorizacao__c, 'Regra SLA deve ser atribuída mesmo com múltiplos marcos na gestão');
    }
}