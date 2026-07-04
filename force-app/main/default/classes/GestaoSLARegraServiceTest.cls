/**
 * @description       : Testes unitários de GestaoSLARegraService (RegrasSLACategorizacao__c),
 *                       migrados de GestaoSLAServiceTest.cls (Pacote 44 — Fase D).
 **/
@IsTest
private class GestaoSLARegraServiceTest {
    private static GestaoSLA__c createGestao(String suffix, Boolean ativo) {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) {
            unidade = entries[0].getValue();
        }
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao ' + suffix,
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            TempoTriagemMinutos__c = 10,
            TempoRespostaChatMinutos__c = 20,
            StaticResourceName__c = 'banner_sla',
            Ativo__c = ativo
        );
        insert g;
        return g;
    }

    private static Categorizacao__c createCategoria(Id gestaoId, String nameSuffix, Boolean ativo) {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        c.Ativo__c = ativo;
        insert c;
        c.GestaoSLA__c = gestaoId;
        update c;
        return c;
    }

    private static MarcoSLA__c createMarco(Id gestaoId, String nome, Integer ordem, Boolean ativo) {
        MarcoSLA__c m = new MarcoSLA__c(
            Name = nome,
            GestaoSLA__c = gestaoId,
            NomeMarco__c = nome,
            MilestoneTypeName__c = nome,
            FonteTempo__c = 'RegraSLA',
            Ordem__c = ordem,
            Recorrente__c = false,
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = ativo
        );
        insert m;
        return m;
    }

    private static void createRegra(Id gestaoId, Id marcoId, Id categId, Boolean ativo) {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = ativo,
            GestaoSLA__c = gestaoId,
            MarcoSLA__c = marcoId,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            TempoBaixa__c = 10,
            TempoMedia__c = 20,
            TempoAlta__c = 30
        );
        insert r;
    }

    private static RegrasSLACategorizacao__c createRegraDetalhada(
        Id gestaoId,
        Id marcoId,
        Id categId,
        String escopo,
        String area,
        Boolean ativo
    ) {
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.tipoAreaInternaApiValue(),
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = ativo,
            GestaoSLA__c = gestaoId,
            MarcoSLA__c = marcoId,
            EscopoRegra__c = escopo,
            TempoBaixa__c = 10,
            TempoMedia__c = 20,
            TempoAlta__c = 30
        );
        insert r;
        return r;
    }

    private static GestaoSLADTO.RegraSLARequest buildRegraRequest(
        Id gestaoId,
        Id marcoId,
        Id categId,
        String escopo
    ) {
        GestaoSLADTO.RegraSLARequest req = new GestaoSLADTO.RegraSLARequest();
        req.gestaoSLAId = gestaoId;
        req.marcoSLAId = escopo == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA ? null : marcoId;
        req.categorizacaoId = categId;
        req.escopoRegra = escopo;
        req.areaAtendimento = escopo == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
            ? AreaParticipanteTestDataFactory.commonAreaValues()[0]
            : null;
        req.tempoBaixa = 10;
        req.tempoMedia = 20;
        req.tempoAlta = 30;
        req.ativo = true;
        return req;
    }

    @IsTest
    static void testGetRegrasSLAComFiltros() {
        GestaoSLA__c g1 = createGestao('REGRAS_1', true);
        GestaoSLA__c g2 = createGestao('REGRAS_2', false);
        Categorizacao__c c1 = createCategoria(g1.Id, 'REGRAS_CAT_1', true);
        MarcoSLA__c m1 = createMarco(g1.Id, 'Atendimento N3', 1, true);
        MarcoSLA__c m2 = createMarco(g1.Id, 'Retorno N3', 2, true);
        MarcoSLA__c mOther = createMarco(g2.Id, 'Atendimento N3', 1, true);
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];

        RegrasSLACategorizacao__c ativa = createRegraDetalhada(
            g1.Id,
            m1.Id,
            c1.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            area,
            true
        );
        RegrasSLACategorizacao__c inativa = createRegraDetalhada(
            g1.Id,
            m2.Id,
            c1.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            area,
            false
        );
        createRegraDetalhada(
            g2.Id,
            mOther.Id,
            c1.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            area,
            true
        );

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);

        GestaoSLADTO.RegrasSLAResponse all = GestaoSLARegraService.getRegrasSLA(g1.Id, null, null, null, null, null);
        Assert.areEqual(2, all.regras.size());
        Assert.areEqual(ativa.Id, all.regras[0].id);
        Assert.areEqual(c1.Id, all.regras[0].categorizacaoId);
        Assert.areEqual(m1.Id, all.regras[0].marcoSLAId);
        Assert.areEqual(10, all.regras[0].tempoBaixa);
        Assert.areEqual(20, all.regras[0].tempoMedia);
        Assert.areEqual(30, all.regras[0].tempoAlta);

        GestaoSLADTO.RegrasSLAResponse byCategoria = GestaoSLARegraService.getRegrasSLA(g1.Id, c1.Id, null, null, null, null);
        Assert.areEqual(2, byCategoria.regras.size());

        GestaoSLADTO.RegrasSLAResponse byMarco = GestaoSLARegraService.getRegrasSLA(g1.Id, null, m2.Id, null, null, null);
        Assert.areEqual(1, byMarco.regras.size());
        Assert.areEqual(inativa.Id, byMarco.regras[0].id);

        GestaoSLADTO.RegrasSLAResponse byEscopo = GestaoSLARegraService.getRegrasSLA(
            g1.Id,
            null,
            null,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            null,
            null
        );
        Assert.areEqual(2, byEscopo.regras.size());

        GestaoSLADTO.RegrasSLAResponse byAtivo = GestaoSLARegraService.getRegrasSLA(g1.Id, null, null, null, null, true);
        Assert.areEqual(1, byAtivo.regras.size());
        Assert.areEqual(true, byAtivo.regras[0].ativo);
    }

    @IsTest
    static void testGetRegrasSLASemPermissaoBloqueia() {
        GestaoSLA__c g = createGestao('REGRAS_SEM_PERM', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, false);

        Boolean failed = false;
        try {
            GestaoSLARegraService.getRegrasSLA(g.Id, null, null, null, null, null);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateUpdateDeactivateRegraSLAComPermissao() {
        GestaoSLA__c g = createGestao('REGRA_CRUD', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_CRUD', true);
        MarcoSLA__c m = createMarco(g.Id, 'Atendimento N3 CRUD', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            m.Id,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        GestaoSLADTO.RegraSLAResumo created = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(g.Id, created.gestaoSLAId);
        Assert.areEqual(c.Id, created.categorizacaoId);
        Assert.areEqual(m.Id, created.marcoSLAId);
        Assert.areEqual(10, created.tempoBaixa);
        Assert.areEqual(true, created.ativo);

        req.id = created.id;
        req.tempoBaixa = 15;
        req.tempoMedia = null;
        req.ativo = false;
        GestaoSLADTO.RegraSLAResumo updated = GestaoSLARegraService.updateRegraSLA(req);
        Assert.areEqual(15, updated.tempoBaixa);
        Assert.areEqual(null, updated.tempoMedia);
        Assert.areEqual(true, updated.ativo);

        GestaoSLADTO.RegraSLAResumo inactive = GestaoSLARegraService.deactivateRegraSLA(created.id);
        Assert.areEqual(false, inactive.ativo);
    }

    @IsTest
    static void testUpdateRegraSLAInativaNaoReativa() {
        GestaoSLA__c g = createGestao('REGRA_INATIVA_EDIT', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_INATIVA_EDIT', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco Inativa Edit', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            m.Id,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        req.ativo = false;
        GestaoSLADTO.RegraSLAResumo created = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(true, created.ativo);

        GestaoSLARegraService.deactivateRegraSLA(created.id);
        req.id = created.id;
        req.tempoAlta = 45;
        req.ativo = true;

        GestaoSLADTO.RegraSLAResumo updated = GestaoSLARegraService.updateRegraSLA(req);
        Assert.areEqual(45, updated.tempoAlta);
        Assert.areEqual(false, updated.ativo);
    }

    @IsTest
    static void testRegraSLABloqueiaSemPermissaoDeGerenciarRegras() {
        GestaoSLA__c g = createGestao('REGRA_SEM_PERM', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_SEM_PERM', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco Sem Perm', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, false);

        Boolean failed = false;
        try {
            GestaoSLARegraService.createRegraSLA(buildRegraRequest(
                g.Id,
                m.Id,
                c.Id,
                RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
            ));
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('permissão'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateRegraSLAAreaInternaComSucesso() {
        GestaoSLA__c g = createGestao('REGRA_AREA_INTERNA', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_AREA_INTERNA', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            null,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        GestaoSLADTO.RegraSLAResumo created = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(area, created.areaAtendimento);
        Assert.areEqual(null, created.marcoSLAId);
        Assert.areEqual(RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA, created.escopoRegra);

        GestaoSLADTO.RegrasSLAResponse response = GestaoSLARegraService.getRegrasSLA(
            g.Id, null, null, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA, null, true
        );
        Assert.areEqual(1, response.regras.size());
        Assert.areEqual(area, response.regras[0].areaAtendimento);
    }

    @IsTest
    static void testRegraSLAValidacoesDeEscopoTempoEVigencia() {
        GestaoSLA__c g = createGestao('REGRA_VALID', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_VALID', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco Valid', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        List<GestaoSLADTO.RegraSLARequest> invalids = new List<GestaoSLADTO.RegraSLARequest>();
        GestaoSLADTO.RegraSLARequest semMarco = buildRegraRequest(g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        semMarco.marcoSLAId = null;
        invalids.add(semMarco);
        GestaoSLADTO.RegraSLARequest semCategoria = buildRegraRequest(g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        semCategoria.categorizacaoId = null;
        invalids.add(semCategoria);
        GestaoSLADTO.RegraSLARequest areaSemArea = new GestaoSLADTO.RegraSLARequest();
        areaSemArea.gestaoSLAId = g.Id;
        areaSemArea.categorizacaoId = c.Id;
        areaSemArea.escopoRegra = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA;
        areaSemArea.areaAtendimento = null;
        areaSemArea.tempoBaixa = 10; areaSemArea.tempoMedia = 20; areaSemArea.tempoAlta = 30;
        areaSemArea.ativo = true;
        invalids.add(areaSemArea);
        GestaoSLADTO.RegraSLARequest semTempo = buildRegraRequest(g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        semTempo.tempoBaixa = null;
        semTempo.tempoMedia = null;
        semTempo.tempoAlta = null;
        invalids.add(semTempo);
        GestaoSLADTO.RegraSLARequest tempoZero = buildRegraRequest(g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        tempoZero.tempoBaixa = 0;
        invalids.add(tempoZero);
        GestaoSLADTO.RegraSLARequest escopoInvalido = buildRegraRequest(g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO);
        escopoInvalido.escopoRegra = 'EscopoInexistente';
        invalids.add(escopoInvalido);

        Integer failures = 0;
        for (GestaoSLADTO.RegraSLARequest req : invalids) {
            try {
                GestaoSLARegraService.createRegraSLA(req);
            } catch (Exception ex) {
                failures++;
                Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
            }
        }
        Assert.areEqual(invalids.size(), failures);
    }

    @IsTest
    static void testRegraSLABloqueiaDuplicidadeAtivaEPermiteDuplicidadeInativa() {
        GestaoSLA__c g = createGestao('REGRA_DUP', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_DUP', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco Dup', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            m.Id,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        GestaoSLADTO.RegraSLAResumo first = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(true, first.ativo);

        Boolean dupFailed = false;
        try {
            GestaoSLARegraService.createRegraSLA(req);
        } catch (Exception ex) {
            dupFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe'));
        }
        Assert.areEqual(true, dupFailed);

        GestaoSLARegraService.deactivateRegraSLA(first.id);
        GestaoSLADTO.RegraSLAResumo second = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(true, second.ativo);
        Assert.areNotEqual(first.id, second.id);
    }

    @IsTest
    static void testRegraSLAValidaReferenciasDaGestao() {
        GestaoSLA__c g1 = createGestao('REGRA_REF_1', true);
        GestaoSLA__c g2 = createGestao('REGRA_REF_2', false);
        Categorizacao__c c1 = createCategoria(g1.Id, 'REGRA_REF', true);
        MarcoSLA__c m2 = createMarco(g2.Id, 'Marco Outro', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        Boolean failed = false;
        try {
            GestaoSLARegraService.createRegraSLA(buildRegraRequest(
                g1.Id,
                m2.Id,
                c1.Id,
                RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
            ));
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Marco SLA'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testAtendimentoNaoGravaAreaAtendimento() {
        GestaoSLA__c g = createGestao('AT_NO_AREA', true);
        Categorizacao__c c = createCategoria(g.Id, 'AT_NO_AREA', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco AT', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        req.areaAtendimento = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLADTO.RegraSLAResumo created = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(null, created.areaAtendimento);
        Assert.areEqual(m.Id, created.marcoSLAId);
        Assert.areEqual(RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO, created.escopoRegra);
    }

    @IsTest
    static void testAreaInternaNaoGravaMarcoSLA() {
        GestaoSLA__c g = createGestao('AI_NO_MARCO', true);
        Categorizacao__c c = createCategoria(g.Id, 'AI_NO_MARCO', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco AI', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id, null, c.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        req.marcoSLAId = m.Id;
        GestaoSLADTO.RegraSLAResumo created = GestaoSLARegraService.createRegraSLA(req);
        Assert.areEqual(null, created.marcoSLAId);
        Assert.areEqual(AreaParticipanteTestDataFactory.commonAreaValues()[0], created.areaAtendimento);
        Assert.areEqual(RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA, created.escopoRegra);
    }

    @IsTest
    static void testAreaInternaDuplicidadeConsideraCategorizacao() {
        GestaoSLA__c g = createGestao('AI_DUP_CATEG', true);
        Categorizacao__c c1 = createCategoria(g.Id, 'AI_DUP_C1', true);
        // c2 precisa de combinação diferente de c1 para não acionar a VR de unicidade por UnidadeNegocio
        Categorizacao__c c2base = CategorizacaoTestDataFactory.base(false, false);
        c2base.Subassunto__c = null;
        c2base.Ativo__c = true;
        insert c2base;
        c2base.GestaoSLA__c = g.Id;
        update c2base;
        Categorizacao__c c2 = c2base;
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];

        GestaoSLADTO.RegraSLARequest req1 = buildRegraRequest(
            g.Id, null, c1.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        GestaoSLARegraService.createRegraSLA(req1);

        GestaoSLADTO.RegraSLARequest req2 = buildRegraRequest(
            g.Id, null, c2.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        GestaoSLADTO.RegraSLAResumo segundo = GestaoSLARegraService.createRegraSLA(req2);
        Assert.areEqual(area, segundo.areaAtendimento);

        Boolean dupFailed = false;
        try {
            GestaoSLARegraService.createRegraSLA(req1);
        } catch (Exception ex) {
            dupFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe'));
        }
        Assert.areEqual(true, dupFailed);
    }

    @IsTest
    static void testCreateRegrasSLABulkUpsertsExistingArea() {
        GestaoSLA__c g = createGestao('BULK_UPSERT', true);
        Categorizacao__c c = createCategoria(g.Id, 'BULK_UPSERT', true);
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        String area2 = areas[1];

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req1 = new GestaoSLADTO.RegraSLARequest();
        req1.gestaoSLAId = g.Id;
        req1.categorizacaoId = c.Id;
        req1.areaAtendimento = area1;
        req1.tempoBaixa = 10;
        req1.tempoMedia = 20;
        req1.tempoAlta = 30;

        List<GestaoSLADTO.RegraSLAResumo> firstBatch = GestaoSLARegraService.createRegrasSLABulk(
            new List<GestaoSLADTO.RegraSLARequest>{ req1 }
        );
        Assert.areEqual(1, firstBatch.size());
        Id existingRuleId = firstBatch[0].id;

        GestaoSLADTO.RegraSLARequest req1Updated = new GestaoSLADTO.RegraSLARequest();
        req1Updated.gestaoSLAId = g.Id;
        req1Updated.categorizacaoId = c.Id;
        req1Updated.areaAtendimento = area1;
        req1Updated.tempoBaixa = 11;
        req1Updated.tempoMedia = 22;
        req1Updated.tempoAlta = 33;

        GestaoSLADTO.RegraSLARequest req2New = new GestaoSLADTO.RegraSLARequest();
        req2New.gestaoSLAId = g.Id;
        req2New.categorizacaoId = c.Id;
        req2New.areaAtendimento = area2;
        req2New.tempoBaixa = 10;
        req2New.tempoMedia = 20;
        req2New.tempoAlta = 30;

        List<GestaoSLADTO.RegraSLAResumo> secondBatch = GestaoSLARegraService.createRegrasSLABulk(
            new List<GestaoSLADTO.RegraSLARequest>{ req1Updated, req2New }
        );
        Assert.areEqual(2, secondBatch.size());

        Assert.areEqual(1, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :c.Id AND AreaAtendimento__c = :area1]);
        RegrasSLACategorizacao__c updated = [SELECT Id, TempoBaixa__c, TempoMedia__c, TempoAlta__c FROM RegrasSLACategorizacao__c WHERE Id = :existingRuleId];
        Assert.areEqual(existingRuleId, updated.Id);
        Assert.areEqual(33, updated.TempoAlta__c);

        Assert.areEqual(1, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :c.Id AND AreaAtendimento__c = :area2]);
    }

    @IsTest
    static void testDeleteRegrasSLABulkOnlyRequiresManageRules() {
        GestaoSLA__c g = createGestao('BULK_DEL', true);
        Categorizacao__c c = createCategoria(g.Id, 'BULK_DEL', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco BulkDel', 1, true);
        createRegra(g.Id, m.Id, c.Id, true);
        RegrasSLACategorizacao__c regra = [SELECT Id FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :c.Id LIMIT 1];

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, false);

        Boolean blocked = false;
        try {
            GestaoSLARegraService.deleteRegrasSLABulk(new List<Id>{ regra.Id });
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
        }
        Assert.areEqual(true, blocked);
        Assert.areEqual(1, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Id = :regra.Id]);

        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);
        GestaoSLARegraService.deleteRegrasSLABulk(new List<Id>{ regra.Id });
        Assert.areEqual(0, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Id = :regra.Id]);
    }

    @IsTest
    static void testDeleteRegraSLARequiresAdminTechnicalSettings() {
        GestaoSLA__c g = createGestao('DelRegra', true);
        Categorizacao__c c = createCategoria(g.Id, 'DelRegra', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco DelRegra', 1, true);
        createRegra(g.Id, m.Id, c.Id, true);
        RegrasSLACategorizacao__c regra = [SELECT Id FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :c.Id LIMIT 1];

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        Boolean blocked = false;
        try {
            GestaoSLARegraService.deleteRegraSLA(regra.Id);
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
        }
        Assert.areEqual(true, blocked);
        Assert.areEqual(1, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Id = :regra.Id]);

        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);
        GestaoSLARegraService.deleteRegraSLA(regra.Id);
        Assert.areEqual(0, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Id = :regra.Id]);
    }
}
