/**
 * @description       : Testes unitários de RegrasSLACategorizacaoService.
 * @author            : Triscal
 * @group             : Regras de SLA
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class RegrasSLACategorizacaoServiceTest {
    private static GestaoSLA__c createGestao() {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) unidade = entries[0].getValue();

        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Regras Test ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 10000)),
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
            Name = 'Marco Regras Test ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 10000)),
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

    private static RegrasSLACategorizacao__c novoBase(Id categId, Id gestaoId, Id marcoId, String escopo) {
        return new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            AreaAtendimento__c = AreaParticipanteTestDataFactory.commonAreaValues()[0],
            Ativo__c = true,
            GestaoSLA__c = gestaoId,
            MarcoSLA__c = marcoId,
            EscopoRegra__c = escopo,
            TempoBaixa__c = 20,
            TempoMedia__c = 40,
            TempoAlta__c = 60
        );
    }

    @IsTest
    static void testRegraNovaPorCategorizacaoValidaENaoExigeCamposLegados() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c g = createGestao();
        MarcoSLA__c m = createMarco(g.Id);

        RegrasSLACategorizacao__c r = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        insert r;
        Assert.areEqual(true, r.Id != null);
    }

    @IsTest
    static void testRegraNovaPorAreaInternaValida() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c g = createGestao();
        MarcoSLA__c m = createMarco(g.Id);

        RegrasSLACategorizacao__c r = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        insert r;
        Assert.areEqual(true, r.Id != null);
    }

    @IsTest
    static void testRegraNovaObrigatoriosEBloqueios() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c g = createGestao();
        MarcoSLA__c m = createMarco(g.Id);

        RegrasSLACategorizacao__c semGestao = novoBase(categ.Id, null, m.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        Boolean failedSemGestao = false;
        try { insert semGestao; } catch (DmlException ex) { failedSemGestao = true; }
        Assert.areEqual(true, failedSemGestao);

        RegrasSLACategorizacao__c semMarco = novoBase(categ.Id, g.Id, null, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        Boolean failedSemMarco = false;
        try { insert semMarco; } catch (DmlException ex) { failedSemMarco = true; }
        Assert.areEqual(true, failedSemMarco);

        RegrasSLACategorizacao__c semEscopo = novoBase(categ.Id, g.Id, m.Id, null);
        Boolean failedSemEscopo = false;
        try { insert semEscopo; } catch (DmlException ex) { failedSemEscopo = true; }
        Assert.areEqual(true, failedSemEscopo);

        RegrasSLACategorizacao__c semTempo = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        semTempo.TempoBaixa__c = null;
        semTempo.TempoMedia__c = null;
        semTempo.TempoAlta__c = null;
        Boolean failedSemTempo = false;
        try { insert semTempo; } catch (DmlException ex) { failedSemTempo = true; }
        Assert.areEqual(true, failedSemTempo);
    }

    @IsTest
    static void testBusinessHoursHerdadoDaGestaoSLANoInsert() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c g = createGestao();
        MarcoSLA__c m = createMarco(g.Id);

        RegrasSLACategorizacao__c r = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        insert r;

        RegrasSLACategorizacao__c inserted = [SELECT BusinessHoursName__c FROM RegrasSLACategorizacao__c WHERE Id = :r.Id];
        Assert.areEqual('Atendimento Salvador', inserted.BusinessHoursName__c, 'BusinessHoursName__c deve ser herdado da GestaoSLA');
    }

    @IsTest
    static void testBusinessHoursHerdadoDaGestaoSLANoUpdate() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c g = createGestao();
        MarcoSLA__c m = createMarco(g.Id);

        RegrasSLACategorizacao__c r = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA);
        insert r;

        r.BusinessHoursName__c = null;
        update r;

        RegrasSLACategorizacao__c updated = [SELECT BusinessHoursName__c FROM RegrasSLACategorizacao__c WHERE Id = :r.Id];
        Assert.areEqual('Atendimento Salvador', updated.BusinessHoursName__c, 'BusinessHoursName__c deve ser restaurado da GestaoSLA no update');
    }

    @IsTest
    static void testChaveNovaNaoIncluiPrioridadeEDuplicidadeAtiva() {
        Categorizacao__c categ = createCategorizacao();
        GestaoSLA__c g = createGestao();
        MarcoSLA__c m = createMarco(g.Id);

        RegrasSLACategorizacao__c r1 = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        insert r1;

        RegrasSLACategorizacao__c r2 = novoBase(categ.Id, g.Id, m.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);

        Boolean failed = false;
        try { insert r2; } catch (DmlException ex) { failed = true; }
        Assert.areEqual(true, failed);
    }
}