@IsTest
private class RegrasSLACategorizacaoHelperTest {
    private static GestaoSLA__c createGestao() {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) unidade = entries[0].getValue();

        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Key Test',
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true
        );
        insert g;
        return g;
    }

    private static MarcoSLA__c createMarco(Id gestaoId) {
        MarcoSLA__c m = new MarcoSLA__c(
            Name = 'Marco Key Test',
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

    private static Categorizacao__c createCategorizacao() {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        return c;
    }

    @IsTest
    static void testBuildKeyNovoNaoIncluiPrioridade() {
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarco(gestao.Id);
        Categorizacao__c categ = createCategorizacao();

        RegrasSLACategorizacao__c r1 = new RegrasSLACategorizacao__c(
            GestaoSLA__c = gestao.Id,
            MarcoSLA__c = marco.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_POR_CATEGORIZACAO,
            Categorizacao__c = categ.Id,
            Origem__c = 'Email',
            TempoBaixa__c = 10
        );
        RegrasSLACategorizacao__c r2 = r1.clone(false, true, false, false);

        String k1 = RegrasSLACategorizacaoHelper.buildKey(r1);
        String k2 = RegrasSLACategorizacaoHelper.buildKey(r2);
        Assert.areEqual(k1, k2);
    }

    @IsTest
    static void testBuildKeyNovoMudaComCamposDaChave() {
        GestaoSLA__c g1 = createGestao();
        MarcoSLA__c m1 = createMarco(g1.Id);
        Categorizacao__c c1 = createCategorizacao();

        GestaoSLA__c g2 = createGestao();
        MarcoSLA__c m2 = createMarco(g2.Id);

        RegrasSLACategorizacao__c base = new RegrasSLACategorizacao__c(
            GestaoSLA__c = g1.Id,
            MarcoSLA__c = m1.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_POR_AREA_INTERNA,
            Categorizacao__c = c1.Id,
            AreaAtendimento__c = AreaParticipanteTestDataFactory.commonAreaValues()[0],
            Origem__c = 'Email',
            TempoBaixa__c = 20
        );

        String kBase = RegrasSLACategorizacaoHelper.buildKey(base);

        RegrasSLACategorizacao__c vGestao = base.clone(false, true, false, false);
        vGestao.GestaoSLA__c = g2.Id;
        Assert.areNotEqual(kBase, RegrasSLACategorizacaoHelper.buildKey(vGestao));

        RegrasSLACategorizacao__c vMarco = base.clone(false, true, false, false);
        vMarco.MarcoSLA__c = m2.Id;
        Assert.areNotEqual(kBase, RegrasSLACategorizacaoHelper.buildKey(vMarco));

        RegrasSLACategorizacao__c vEscopo = base.clone(false, true, false, false);
        vEscopo.EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_POR_CATEGORIZACAO;
        Assert.areNotEqual(kBase, RegrasSLACategorizacaoHelper.buildKey(vEscopo));

        RegrasSLACategorizacao__c vCateg = base.clone(false, true, false, false);
        vCateg.Categorizacao__c = g2.Id;
        Assert.areNotEqual(kBase, RegrasSLACategorizacaoHelper.buildKey(vCateg));

        RegrasSLACategorizacao__c vArea = base.clone(false, true, false, false);
        vArea.AreaAtendimento__c = AreaParticipanteTestDataFactory.commonAreaValues().size() > 1
            ? AreaParticipanteTestDataFactory.commonAreaValues()[1]
            : base.AreaAtendimento__c + ' X';
        Assert.areNotEqual(kBase, RegrasSLACategorizacaoHelper.buildKey(vArea));

        RegrasSLACategorizacao__c vOrigem = base.clone(false, true, false, false);
        vOrigem.Origem__c = 'Manual';
        Assert.areNotEqual(kBase, RegrasSLACategorizacaoHelper.buildKey(vOrigem));
    }

    @IsTest
    static void testBuildKeyEscopo() {
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarco(gestao.Id);
        Categorizacao__c categ = createCategorizacao();

        RegrasSLACategorizacao__c rGlobal = new RegrasSLACategorizacao__c(
            GestaoSLA__c = gestao.Id,
            MarcoSLA__c = marco.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_GLOBAL,
            Origem__c = 'Email',
            TempoBaixa__c = 10
        );
        String kGlobal = RegrasSLACategorizacaoHelper.buildKey(rGlobal);
        Assert.areEqual(true, String.isNotBlank(kGlobal));
        Assert.areEqual(true, kGlobal.contains(String.valueOf(gestao.Id)));
    }
}