/**
 * @description       : Testes unitários de CaseMilestoneTriggerTimeCalculator.
 * @author            : Triscal
 * @group             : Case Milestone
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class CaseMilestoneTriggerTimeCalculatorTest {
    private static String anyUnidadeCase() {
        List<Schema.PicklistEntry> entries = Case.UnidadeNegocio__c.getDescribe().getPicklistValues();
        return entries.isEmpty() ? null : entries[0].getValue();
    }

    private static String anyUnidadeGestao() {
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        return entries.isEmpty() ? null : entries[0].getValue();
    }

    private static String tipoAreaNaoInterna() {
        for (Schema.PicklistEntry p : RegrasSLACategorizacao__c.TipoAreaParticipante__c.getDescribe().getPicklistValues()) {
            String n = p.getValue() == null ? '' : p.getValue().toLowerCase();
            if (!n.contains('interna')) return p.getValue();
        }
        return RegrasSLACategorizacao__c.TipoAreaParticipante__c.getDescribe().getPicklistValues()[0].getValue();
    }

    private static String normalize(String value) {
        if (String.isBlank(value)) return '';
        String v = value.toLowerCase();
        v = v.replace('á', 'a').replace('à', 'a').replace('â', 'a').replace('ã', 'a').replace('ä', 'a');
        v = v.replace('é', 'e').replace('è', 'e').replace('ê', 'e').replace('ë', 'e');
        v = v.replace('í', 'i').replace('ì', 'i').replace('î', 'i').replace('ï', 'i');
        v = v.replace('ó', 'o').replace('ò', 'o').replace('ô', 'o').replace('õ', 'o').replace('ö', 'o');
        v = v.replace('ú', 'u').replace('ù', 'u').replace('û', 'u').replace('ü', 'u');
        v = v.replace('ç', 'c');
        return v;
    }

    private static GestaoSLA__c createGestao(Integer triagem, Integer chat) {
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = anyUnidadeGestao(),
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            TempoTriagemMinutos__c = triagem,
            TempoRespostaChatMinutos__c = chat,
            Ativo__c = true
        );
        insert g;
        return g;
    }

    private static Categorizacao__c createCategorizacao(Id gestaoId) {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        c.GestaoSLA__c = gestaoId;
        update c;
        return c;
    }

    private static Case createCase(Id categId, String priority, String origin, String etapa) {
        Case c = new Case(
            Subject = 'Case Calc ' + String.valueOf(Crypto.getRandomInteger()),
            Status = 'New',
            Priority = priority,
            Origin = origin,
            UnidadeNegocio__c = anyUnidadeCase(),
            EtapaAtendimento__c = etapa
        );
        if (categId != null) c.Categorizacao__c = categId;
        insert c;
        return c;
    }

    private static MarcoSLA__c createMarco(Id gestaoId, String milestoneName, String fonteTempo, Boolean ativo) {
        MarcoSLA__c m = new MarcoSLA__c(
            Name = milestoneName + ' ' + String.valueOf(Crypto.getRandomInteger()),
            GestaoSLA__c = gestaoId,
            NomeMarco__c = milestoneName,
            MilestoneTypeName__c = milestoneName,
            FonteTempo__c = fonteTempo,
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = ativo
        );
        insert m;
        return m;
    }

    private static RegrasSLACategorizacao__c createRegra(
        Id categId,
        Id gestaoId,
        Id marcoSlaId,
        String escopo,
        Boolean ativa,
        String areaAtendimento,
        Integer tempoAlta
    ) {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = areaAtendimento == null ? tipoAreaNaoInterna() : AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = areaAtendimento,
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = ativa,
            GestaoSLA__c = gestaoId,
            MarcoSLA__c = marcoSlaId,
            EscopoRegra__c = escopo,
            TempoBaixa__c = 30,
            TempoMedia__c = 60,
            TempoAlta__c = tempoAlta
        );
        insert r;
        return r;
    }

    @IsTest
    static void testTriagemUsaTempoGestaoSemPrioridadeECategorizacao() {
        GestaoSLA__c g = createGestao(25, 12);
        Case c = createCase(null, 'High', 'Email', 'Novo');
        MarcoSLA__c m = createMarco(g.Id, 'Triagem', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_GESTAO, true);
        Assert.areEqual(true, m.Id != null);

        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Triagem', Date.today());
        Assert.areEqual(25, minutes);
    }

    @IsTest
    static void testRespostaChatUsaTempoGestaoSemPrioridadeECategorizacao() {
        GestaoSLA__c g = createGestao(25, 9);
        Case c = createCase(null, 'Low', 'Web', 'Novo');
        c.UnidadeNegocio__c = g.UnidadeNegocio__c;
        update c;
        createMarco(g.Id, 'Resposta Chat', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_GESTAO, true);

        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Resposta Chat', Date.today());
        Assert.areEqual(9, minutes);
    }

    private static void assertMarcoRegraSla(String marcoName) {
        GestaoSLA__c g = createGestao(20, 8);
        Categorizacao__c categ = createCategorizacao(g.Id);
        Case c = createCase(categ.Id, 'High', 'Phone', 'Em Atendimento');
        MarcoSLA__c marco = createMarco(g.Id, marcoName, CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);
        createRegra(
            categ.Id,
            g.Id,
            marco.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            true,
            null,
            111
        );
        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, marcoName, Date.today());
        Assert.areEqual(111, minutes);
    }

    @IsTest
    static void testPrimeiraRespostaUsaRegraSla() {
        assertMarcoRegraSla('Primeira Resposta');
    }

    @IsTest
    static void testAtendimentoUsaRegraSla() {
        assertMarcoRegraSla('Atendimento');
    }

    @IsTest
    static void testAtendimentoN3UsaRegraMacro() {
        assertMarcoRegraSla('Atendimento N3');
    }

    @IsTest
    static void testRetornoN3UsaRegraSla() {
        assertMarcoRegraSla('Retorno N3');
    }

    @IsTest
    static void testAcompanhamentoUsaRegraSla() {
        assertMarcoRegraSla('Acompanhamento');
    }

    @IsTest
    static void testSlaTotalUsaRegraSla() {
        assertMarcoRegraSla('SLA Total');
    }

    @IsTest
    static void testRegraNovaUnicaAtendeLowMediumHigh() {
        GestaoSLA__c g = createGestao(20, 8);
        Categorizacao__c categ = createCategorizacao(g.Id);
        MarcoSLA__c marco = createMarco(g.Id, 'Atendimento', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);
        createRegra(
            categ.Id, g.Id, marco.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            true, null, 120
        );

        Case cLow = createCase(categ.Id, 'Low', 'Phone', 'Em Atendimento');
        Case cMedium = createCase(categ.Id, 'Medium', 'Phone', 'Em Atendimento');
        Case cHigh = createCase(categ.Id, 'High', 'Phone', 'Em Atendimento');

        Integer mLow = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(cLow.Id, 'Atendimento', Date.today());
        Integer mMedium = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(cMedium.Id, 'Atendimento', Date.today());
        Integer mHigh = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(cHigh.Id, 'Atendimento', Date.today());

        Assert.areEqual(30, mLow);
        Assert.areEqual(60, mMedium);
        Assert.areEqual(120, mHigh);
    }

    @IsTest
    static void testAtendimentoN3MacroNaoUsaRegraAreaInterna() {
        GestaoSLA__c g = createGestao(20, 8);
        Categorizacao__c categ = createCategorizacao(g.Id);
        Case c = createCase(categ.Id, 'High', 'Phone', 'Aguardando Área Interna');
        MarcoSLA__c marco = createMarco(g.Id, 'Atendimento N3', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);

        createRegra(
            categ.Id, g.Id, null, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            true, AreaParticipanteTestDataFactory.commonAreaValues()[0], 5
        );
        createRegra(
            categ.Id, g.Id, marco.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            true, null, 150
        );

        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Atendimento N3', Date.today());
        Assert.areEqual(150, minutes);
    }

    @IsTest
    static void testFallbacksControladosConfiguracaoInvalida() {
        GestaoSLA__c g = createGestao(20, 8);
        Categorizacao__c categ = createCategorizacao(g.Id);
        Case c = createCase(categ.Id, 'High', 'Phone', 'Em Atendimento');

        Integer noMarco = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Marco Inexistente', Date.today());
        Assert.areEqual(CaseMilestoneTriggerTimeCalculator.DEFAULT_FALLBACK_MINUTES, noMarco);

        createMarco(g.Id, 'Atendimento', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);
        createMarco(g.Id, 'Atendimento', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);
        Integer duplicatedMarco = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Atendimento', Date.today());
        Assert.areEqual(CaseMilestoneTriggerTimeCalculator.DEFAULT_FALLBACK_MINUTES, duplicatedMarco);
    }

    @IsTest
    static void testRegraInativaRetornaFallback() {
        GestaoSLA__c g = createGestao(20, 8);
        Categorizacao__c categ = createCategorizacao(g.Id);
        Case c = createCase(categ.Id, 'High', 'Email', 'Em Atendimento');
        MarcoSLA__c marco = createMarco(g.Id, 'Atendimento', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);

        createRegra(
            categ.Id, g.Id, marco.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            false, null, 10
        );

        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Atendimento', Date.today());
        Assert.areEqual(CaseMilestoneTriggerTimeCalculator.DEFAULT_FALLBACK_MINUTES, minutes);
    }

    @IsTest
    static void testRegraAtivaRetornaTempoCorreto() {
        GestaoSLA__c g = createGestao(20, 8);
        Categorizacao__c categ = createCategorizacao(g.Id);
        Case c = createCase(categ.Id, 'High', 'Email', 'Em Atendimento');
        MarcoSLA__c marco = createMarco(g.Id, 'Atendimento', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_REGRA, true);

        createRegra(
            categ.Id, g.Id, marco.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            true, null, 130
        );

        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Atendimento', Date.today());
        Assert.areEqual(130, minutes);
    }

    @IsTest
    static void testCalculateMilestoneTriggerTimeComEntradaInvalida() {
        CaseMilestoneTriggerTimeCalculator calc = new CaseMilestoneTriggerTimeCalculator();
        Assert.areEqual(
            CaseMilestoneTriggerTimeCalculator.DEFAULT_FALLBACK_MINUTES,
            calc.calculateMilestoneTriggerTime(null, null)
        );
    }

    @IsTest
    static void testAmbiguousGestaoByUnidadeReturnsFallback() {
        String unidade = anyUnidadeCase();
        String unidadeGestao = anyUnidadeGestao();

        GestaoSLA__c g1 = new GestaoSLA__c(
            Name = 'Gestao Amb 1',
            UnidadeNegocio__c = unidadeGestao,
            EntitlementProcessName__c = 'EP Amb 1',
            BusinessHoursName__c = 'BH Amb',
            TempoTriagemMinutos__c = 10,
            Ativo__c = true
        );
        insert g1;
        GestaoSLA__c g2 = new GestaoSLA__c(
            Name = 'Gestao Amb 2',
            UnidadeNegocio__c = unidadeGestao,
            EntitlementProcessName__c = 'EP Amb 2',
            BusinessHoursName__c = 'BH Amb',
            TempoTriagemMinutos__c = 15,
            Ativo__c = true
        );
        insert g2;

        Case c = new Case(Subject = 'Case Amb', Status = 'New', UnidadeNegocio__c = unidadeGestao);
        insert c;

        createMarco(g1.Id, 'Triagem', CaseMilestoneTriggerTimeCalculator.FONTE_TEMPO_GESTAO, true);

        Integer minutes = CaseMilestoneTriggerTimeCalculator.calculateForCaseAndMilestoneName(c.Id, 'Triagem', Date.today());
        Assert.areEqual(CaseMilestoneTriggerTimeCalculator.DEFAULT_FALLBACK_MINUTES, minutes);
    }

    @IsTest
    static void testCalculateMilestoneTriggerTimeComCaseESemMilestoneType() {
        CaseMilestoneTriggerTimeCalculator calc = new CaseMilestoneTriggerTimeCalculator();
        GestaoSLA__c g = createGestao(25, 10);
        Case c = createCase(null, 'High', 'Email', 'Novo');
        String fakeTypeId = UserInfo.getUserId();
        Integer result = calc.calculateMilestoneTriggerTime(String.valueOf(c.Id), fakeTypeId);
        Assert.areEqual(CaseMilestoneTriggerTimeCalculator.DEFAULT_FALLBACK_MINUTES, result);
    }
}