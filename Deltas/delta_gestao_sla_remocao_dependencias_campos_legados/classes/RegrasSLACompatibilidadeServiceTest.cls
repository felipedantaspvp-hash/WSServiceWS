@IsTest
private class RegrasSLACompatibilidadeServiceTest {
    private static Categorizacao__c createCategorizacao() {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        return c;
    }

    private static GestaoSLA__c createGestao() {
        String unidadeNegocio = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) {
            unidadeNegocio = entries[0].getValue();
        }
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Teste',
            UnidadeNegocio__c = unidadeNegocio,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true
        );
        insert g;
        return g;
    }

    private static MarcoSLA__c createMarco(Id gestaoId) {
        MarcoSLA__c m = new MarcoSLA__c(
            Name = 'Marco Teste',
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

    private static RegrasSLACategorizacao__c createRegra(
        Id categId,
        Id gestaoId,
        Id marcoSlaId
    ) {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = AreaParticipanteTestDataFactory.commonAreaValues()[0],
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestaoId,
            MarcoSLA__c = marcoSlaId,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 60,
            TempoMedia__c = 120,
            TempoAlta__c = 180
        );
        insert r;
        return r;
    }

    @IsTest
    static void testResolveTempoNovoPorPrioridade() {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            TempoBaixa__c = 10, TempoMedia__c = 20, TempoAlta__c = 30, GestaoSLA__c = UserInfo.getUserId()
        );
        Assert.areEqual(10, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'Baixa'));
        Assert.areEqual(10, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'Low'));
        Assert.areEqual(20, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'Média'));
        Assert.areEqual(20, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'Media'));
        Assert.areEqual(20, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'Medium'));
        Assert.areEqual(30, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'Alta'));
        Assert.areEqual(30, RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'High'));
    }

    @IsTest
    static void testPrioridadeNaoSuportada() {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            TempoBaixa__c = 10, TempoMedia__c = 20, TempoAlta__c = 30, GestaoSLA__c = UserInfo.getUserId()
        );
        Boolean falhou = false;
        try {
            RegrasSLACompatibilidadeService.resolveTempoNovoPorPrioridade(r, 'NaoMapeada');
        } catch (Exception ex) {
            falhou = true;
        }
        Assert.areEqual(true, falhou);
    }

    @IsTest
    static void testResolveTempoCompativel() {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            TempoBaixa__c = 10, TempoMedia__c = 20, TempoAlta__c = 30
        );
        Assert.areEqual(10, RegrasSLACompatibilidadeService.resolveTempoCompativel(r, 'Low'));
        Assert.areEqual(20, RegrasSLACompatibilidadeService.resolveTempoCompativel(r, 'Medium'));
        Assert.areEqual(30, RegrasSLACompatibilidadeService.resolveTempoCompativel(r, 'High'));
    }

    @IsTest
    static void testBuildKeys() {
        Id anyId = UserInfo.getUserId();
        String keyNovo = RegrasSLACompatibilidadeService.buildKeyNovo(
            anyId, anyId, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO, anyId, 'Operações'
        );
        Assert.areEqual(true, keyNovo.contains(String.valueOf(anyId)));
        Assert.areEqual(true, String.isNotBlank(keyNovo));
    }

    @IsTest
    static void testSelectorCompatibilidadeComCamposNovos() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarco(gestao.Id);

        RegrasSLACategorizacao__c regra = createRegra(categ.Id, gestao.Id, marco.Id);
        Assert.areEqual(true, regra.Id != null);

        List<RegrasSLACategorizacao__c> rows = RegrasSLACompatibilidadeService.loadActiveRulesForCompatibility();
        RegrasSLACategorizacao__c found;
        for (RegrasSLACategorizacao__c r : rows) {
            if (r.Id == regra.Id) {
                found = r;
                break;
            }
        }
        Assert.areEqual(true, found != null);
        Assert.areEqual(gestao.Id, found.GestaoSLA__c);
        Assert.areEqual(marco.Id, found.MarcoSLA__c);
        Assert.areEqual(60, Integer.valueOf(String.valueOf(found.TempoBaixa__c)));
        Assert.areEqual(120, Integer.valueOf(String.valueOf(found.TempoMedia__c)));
        Assert.areEqual(180, Integer.valueOf(String.valueOf(found.TempoAlta__c)));
        Assert.areEqual(true, String.isNotBlank(found.ChaveUnicaHash__c));
    }

    @IsTest
    static void testBulkCompatibilidadeSemSoqlEmLoop() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarco(gestao.Id);
        List<String> areaValues = AreaParticipanteTestDataFactory.commonAreaValues();
        Assert.areEqual(true, areaValues.size() > 0);

        List<RegrasSLACategorizacao__c> regras = new List<RegrasSLACategorizacao__c>();
        for (Integer i = 0; i < 5; i++) {
            String area = areaValues[Math.mod(i, areaValues.size())];
            regras.add(new RegrasSLACategorizacao__c(
                Categorizacao__c = categ.Id,
                TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
                AreaAtendimento__c = area,
                BusinessHoursName__c = 'Atendimento Salvador',
                Ativo__c = true,
                GestaoSLA__c = gestao.Id,
                MarcoSLA__c = marco.Id,
                EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
                TempoBaixa__c = 40 + i,
                TempoMedia__c = 50 + i,
                TempoAlta__c = 60 + i
            ));
        }
        insert regras;

        List<RegrasSLACategorizacao__c> loaded = RegrasSLACompatibilidadeService.loadActiveRulesForCompatibility();
        Assert.areEqual(true, loaded.size() >= 5);

        Integer countResolved = 0;
        for (RegrasSLACategorizacao__c r : loaded) {
            if (r.GestaoSLA__c == gestao.Id && r.MarcoSLA__c == marco.Id) {
                Integer tempo = RegrasSLACompatibilidadeService.resolveTempoCompativel(r, 'Medium');
                Assert.areEqual(true, tempo > 0);
                countResolved++;
            }
        }
        Assert.areEqual(true, countResolved >= 5);
    }

    @IsTest
    static void testSelectorLegacyMethodsCoverage() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c gestao = createGestao();
        MarcoSLA__c marco = createMarco(gestao.Id);
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];

        RegrasSLACategorizacao__c regra = createRegra(categ.Id, gestao.Id, marco.Id);
        RegrasSLACategorizacao__c saved = [
            SELECT Id, ChaveUnicaHash__c
            FROM RegrasSLACategorizacao__c
            WHERE Id = :regra.Id
        ];

        Map<String, RegrasSLACategorizacao__c> byHash = RegrasSLACategorizacaoSelector.getActiveByKey(
            new Set<String>{ saved.ChaveUnicaHash__c },
            new Set<Id>()
        );
        Assert.areEqual(true, byHash.containsKey(saved.ChaveUnicaHash__c));

        List<RegrasSLACategorizacao__c> found = RegrasSLACategorizacaoSelector.findActiveRules(
            new Set<Id>{ categ.Id },
            new Set<String>{ AreaParticipanteSLAHelper.tipoAreaInternaApiValue() },
            new Set<String>{ area }
        );
        Assert.areEqual(true, found.size() > 0);
    }
}