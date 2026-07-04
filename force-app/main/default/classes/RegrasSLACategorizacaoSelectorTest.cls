@IsTest
private class RegrasSLACategorizacaoSelectorTest {
    private static Categorizacao__c createCategorizacao() {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        return c;
    }

    private static GestaoSLA__c createGestao() {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) unidade = entries[0].getValue();

        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Selector Test ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 10000)),
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
            Name = 'Marco Selector Test ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 10000)),
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

    @IsTest
    static void testFindAllActiveForCompatibilityReturnsExpectedFields() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c gestao = createGestao();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];

        RegrasSLACategorizacao__c activeRule = new RegrasSLACategorizacao__c(
            Categorizacao__c = categ.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestao.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 15,
            TempoMedia__c = 30,
            TempoAlta__c = 60
        );
        insert activeRule;

        RegrasSLACategorizacao__c inactiveRule = activeRule.clone(false, true, false, false);
        inactiveRule.Ativo__c = false;
        insert inactiveRule;

        List<RegrasSLACategorizacao__c> rows = RegrasSLACategorizacaoSelector.findAllActiveForCompatibility();
        RegrasSLACategorizacao__c found;
        for (RegrasSLACategorizacao__c r : rows) {
            if (r.Id == activeRule.Id) found = r;
            Assert.areEqual(true, r.Ativo__c);
        }

        Assert.areEqual(true, found != null);
        Assert.areEqual(categ.Id, found.Categorizacao__c);
        Assert.areEqual(gestao.Id, found.GestaoSLA__c);
        Assert.areEqual(null, found.MarcoSLA__c);
        Assert.areEqual(true, String.isNotBlank(found.ChaveUnica__c));
        Assert.areEqual(true, String.isNotBlank(found.ChaveUnicaHash__c));
        Assert.areEqual(15, Integer.valueOf(String.valueOf(found.TempoBaixa__c)));
        Assert.areEqual(30, Integer.valueOf(String.valueOf(found.TempoMedia__c)));
        Assert.areEqual(60, Integer.valueOf(String.valueOf(found.TempoAlta__c)));
    }

    @IsTest
    static void testFindActiveRulesAndByMarcoAndByHash() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c gestao = createGestao();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();

        List<RegrasSLACategorizacao__c> inserts = new List<RegrasSLACategorizacao__c>();
        for (Integer i = 0; i < 2; i++) {
            inserts.add(new RegrasSLACategorizacao__c(
                Categorizacao__c = categ.Id,
                TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
                AreaAtendimento__c = areas[Math.mod(i, areas.size())],
                BusinessHoursName__c = 'Atendimento Salvador',
                Ativo__c = true,
                GestaoSLA__c = gestao.Id,
                EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
                TempoBaixa__c = 10 + i,
                TempoMedia__c = 20 + i,
                TempoAlta__c = 30 + i
            ));
        }
        insert inserts;

        Set<String> tipos = new Set<String>{ AreaParticipanteSLAHelper.TIPO_AREA_INTERNA };
        Set<String> areasSet = new Set<String>{ inserts[0].AreaAtendimento__c, inserts[1].AreaAtendimento__c };

        List<RegrasSLACategorizacao__c> found = RegrasSLACategorizacaoSelector.findActiveRules(
            new Set<Id>{ categ.Id },
            tipos,
            areasSet
        );
        Assert.areEqual(2, found.size());

        Set<String> hashes = new Set<String>();
        for (RegrasSLACategorizacao__c row : [SELECT Id, ChaveUnicaHash__c FROM RegrasSLACategorizacao__c WHERE Id IN :inserts]) {
            hashes.add(row.ChaveUnicaHash__c);
        }
        Map<String, RegrasSLACategorizacao__c> byHash = RegrasSLACategorizacaoSelector.getActiveByKey(hashes, new Set<Id>());
        Assert.areEqual(2, byHash.size());

        Map<String, RegrasSLACategorizacao__c> byHashIgnoringOne = RegrasSLACategorizacaoSelector.getActiveByKey(
            hashes,
            new Set<Id>{ inserts[0].Id }
        );
        Assert.areEqual(1, byHashIgnoringOne.size());
    }

    @IsTest
    static void testFindActiveRulesNovoN3Coverage() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarco(gestao.Id);
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];

        RegrasSLACategorizacao__c rule = new RegrasSLACategorizacao__c(
            Categorizacao__c = categ.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestao.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 25,
            TempoMedia__c = 35,
            TempoAlta__c = 45
        );
        insert rule;

        List<RegrasSLACategorizacao__c> rows = RegrasSLACategorizacaoSelector.findActiveRulesNovoN3(
            new Set<Id>{ gestao.Id },
            new Set<Id>{ marco.Id },
            new Set<Id>{ categ.Id },
            new Set<String>{ area }
        );
        Assert.areEqual(0, rows.size());

        List<RegrasSLACategorizacao__c> emptyRows = RegrasSLACategorizacaoSelector.findActiveRulesNovoN3(
            new Set<Id>(),
            new Set<Id>{ marco.Id },
            new Set<Id>{ categ.Id },
            new Set<String>{ area }
        );
        Assert.areEqual(0, emptyRows.size());
    }
}