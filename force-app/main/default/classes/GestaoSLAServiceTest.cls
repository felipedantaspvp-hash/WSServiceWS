/**
 * @description       : Testes unitários de GestaoSLAService.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class GestaoSLAServiceTest {
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

    private static GestaoSLADTO.CreateGestaoRequest buildCreateRequest(String suffix) {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) {
            unidade = entries[0].getValue();
        }
        GestaoSLADTO.CreateGestaoRequest req = new GestaoSLADTO.CreateGestaoRequest();
        req.name = 'Nova Gestão ' + suffix;
        req.unidadeNegocio = unidade;
        req.entitlementProcessName = 'Entitlement ' + suffix;
        req.businessHoursName = 'BH ' + suffix;
        req.tempoTriagemMinutos = 120;
        req.tempoRespostaChatMinutos = 60;
        req.descricao = 'Descrição ' + suffix;
        req.staticResourceName = 'resource_' + suffix;
        req.ativo = true;
        return req;
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
    static void testSemPermissaoDeAcessoBloqueia() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, false);

        Boolean failed = false;
        try {
            GestaoSLAService.getBootstrap();
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testBootstrapComPermissoesEOcultacaoTecnica() {
        GestaoSLA__c active = createGestao('A', true);
        createGestao('B', false);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.BootstrapResponse response = GestaoSLAService.getBootstrap();
        Assert.areEqual(true, response.permissions.canAccessGestaoSLA);
        Assert.areEqual(true, response.permissions.canManageCategories);
        Assert.areEqual(true, response.permissions.canManageRules);
        Assert.areEqual(false, response.permissions.canAdminTechnicalSettings);
        Assert.areEqual(1, response.gestoes.size());
        Assert.areEqual(active.Id, response.gestoes[0].id);
        Assert.areNotEqual(null, response.tipoCasoOptions);
        Assert.areNotEqual(null, response.categoriaPicklistOptions);
        Assert.areNotEqual(null, response.assuntoOptions);
        Assert.areNotEqual(null, response.subassuntoOptions);
        Assert.areEqual(null, response.gestoes[0].entitlementProcessName);
        Assert.areEqual(null, response.gestoes[0].businessHoursName);
        Assert.areEqual(null, response.gestoes[0].staticResourceName);
    }

    @IsTest
    static void testGetGestaoDetailComContadoresECamposTecnicos() {
        GestaoSLA__c g = createGestao('Detail', true);
        Categorizacao__c c1 = createCategoria(g.Id, '1', true);
        MarcoSLA__c m1 = createMarco(g.Id, 'Marco A', 1, true);
        createMarco(g.Id, 'Marco B', 2, false);
        createRegra(g.Id, m1.Id, c1.Id, true);
        createRegra(g.Id, m1.Id, c1.Id, false);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.getGestaoDetail(g.Id);
        Assert.areEqual(g.Id, response.gestao.id);
        Assert.areEqual(1, response.summary.totalCategorias);
        Assert.areEqual(1, response.summary.totalMarcosAtivos);
        Assert.areEqual(1, response.summary.totalRegrasAtivas);
        Assert.areEqual('Atendimento Salvador', response.gestao.entitlementProcessName);
        Assert.areEqual('Atendimento Salvador', response.gestao.businessHoursName);
        Assert.areEqual('banner_sla', response.gestao.staticResourceName);
    }

    @IsTest
    static void testGetGestaoDetailErros() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);

        Boolean nullFailed = false;
        try {
            GestaoSLAService.getGestaoDetail(null);
        } catch (Exception ex) {
            nullFailed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, nullFailed);

        Boolean notFoundFailed = false;
        try {
            GestaoSLAService.getGestaoDetail('a00000000000000000');
        } catch (Exception ex) {
            notFoundFailed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, notFoundFailed);
    }

    @IsTest
    static void testGetCategoriasComFiltros() {
        GestaoSLA__c g1 = createGestao('Categorias1', true);
        Categorizacao__c c1 = createCategoria(g1.Id, 'Alpha', true);
        MarcoSLA__c m = createMarco(g1.Id, 'Marco Cat', 1, true);
        createRegra(g1.Id, m.Id, c1.Id, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);

        GestaoSLADTO.CategoriasResponse all = GestaoSLAService.getCategorias(g1.Id, null, null, null, null, null);
        Assert.areEqual(1, all.categorias.size());

        GestaoSLADTO.CategoriasResponse filtered = GestaoSLAService.getCategorias(g1.Id, 'Cadastro', null, null, null, true);
        Assert.areEqual(1, filtered.categorias.size());
        Assert.areEqual(c1.Id, filtered.categorias[0].id);
        Assert.areEqual(1, filtered.categorias[0].totalRegrasAtivas);
    }

    @IsTest
    static void testGetMarcosOrdenacaoEOcultacaoMilestoneType() {
        GestaoSLA__c g = createGestao('Marcos', true);
        MarcoSLA__c m2 = createMarco(g.Id, 'Marco Z', 2, true);
        MarcoSLA__c m1 = createMarco(g.Id, 'Marco A', 1, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);
        GestaoSLADTO.MarcosResponse semTecnico = GestaoSLAService.getMarcos(g.Id);
        Assert.areEqual(2, semTecnico.marcos.size());
        Assert.areEqual(m1.Id, semTecnico.marcos[0].id);
        Assert.areEqual(m2.Id, semTecnico.marcos[1].id);
        Assert.areEqual(null, semTecnico.marcos[0].milestoneTypeName);

        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);
        GestaoSLADTO.MarcosResponse tecnico = GestaoSLAService.getMarcos(g.Id);
        Assert.areEqual('Marco A', tecnico.marcos[0].milestoneTypeName);
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);

        GestaoSLADTO.RegrasSLAResponse all = GestaoSLAService.getRegrasSLA(g1.Id, null, null, null, null, null);
        Assert.areEqual(2, all.regras.size());
        Assert.areEqual(ativa.Id, all.regras[0].id);
        Assert.areEqual(c1.Id, all.regras[0].categorizacaoId);
        Assert.areEqual(m1.Id, all.regras[0].marcoSLAId);
        Assert.areEqual(10, all.regras[0].tempoBaixa);
        Assert.areEqual(20, all.regras[0].tempoMedia);
        Assert.areEqual(30, all.regras[0].tempoAlta);

        GestaoSLADTO.RegrasSLAResponse byCategoria = GestaoSLAService.getRegrasSLA(g1.Id, c1.Id, null, null, null, null);
        Assert.areEqual(2, byCategoria.regras.size());

        GestaoSLADTO.RegrasSLAResponse byMarco = GestaoSLAService.getRegrasSLA(g1.Id, null, m2.Id, null, null, null);
        Assert.areEqual(1, byMarco.regras.size());
        Assert.areEqual(inativa.Id, byMarco.regras[0].id);

        GestaoSLADTO.RegrasSLAResponse byEscopo = GestaoSLAService.getRegrasSLA(
            g1.Id,
            null,
            null,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO,
            null,
            null
        );
        Assert.areEqual(2, byEscopo.regras.size());

        GestaoSLADTO.RegrasSLAResponse byAtivo = GestaoSLAService.getRegrasSLA(g1.Id, null, null, null, null, true);
        Assert.areEqual(1, byAtivo.regras.size());
        Assert.areEqual(true, byAtivo.regras[0].ativo);
    }

    @IsTest
    static void testGetRegrasSLASemPermissaoBloqueia() {
        GestaoSLA__c g = createGestao('REGRAS_SEM_PERM', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, false);

        Boolean failed = false;
        try {
            GestaoSLAService.getRegrasSLA(g.Id, null, null, null, null, null);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateGestaoSLAComSucesso() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.CreateGestaoRequest req = buildCreateRequest('OK');
        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.createGestaoSLA(req);
        Assert.areEqual(req.name, response.gestao.name);
        Assert.areEqual(req.unidadeNegocio, response.gestao.unidadeNegocio);
        Assert.areEqual(true, response.gestao.ativo);
    }

    @IsTest
    static void testCreateGestaoSLAComTemposOpcionais() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.CreateGestaoRequest req = buildCreateRequest('SEM_TEMPO');
        req.tempoTriagemMinutos = null;
        req.tempoRespostaChatMinutos = null;

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.createGestaoSLA(req);
        Assert.areEqual(req.name, response.gestao.name);
        Assert.areEqual(null, response.gestao.tempoTriagemMinutos);
        Assert.areEqual(null, response.gestao.tempoRespostaChatMinutos);
    }

    @IsTest
    static void testCreateGestaoSLASemPermissaoTecnica() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        Boolean failed = false;
        try {
            GestaoSLAService.createGestaoSLA(buildCreateRequest('SEM_ADMIN'));
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('permissão'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateGestaoSLAValidacoesObrigatorias() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        List<GestaoSLADTO.CreateGestaoRequest> requests = new List<GestaoSLADTO.CreateGestaoRequest>();
        GestaoSLADTO.CreateGestaoRequest semNome = buildCreateRequest('A');
        semNome.name = null;
        requests.add(semNome);
        GestaoSLADTO.CreateGestaoRequest semUnidade = buildCreateRequest('B');
        semUnidade.unidadeNegocio = null;
        requests.add(semUnidade);
        GestaoSLADTO.CreateGestaoRequest semEntitlement = buildCreateRequest('C');
        semEntitlement.entitlementProcessName = null;
        requests.add(semEntitlement);
        GestaoSLADTO.CreateGestaoRequest semBh = buildCreateRequest('D');
        semBh.businessHoursName = null;
        requests.add(semBh);
        GestaoSLADTO.CreateGestaoRequest triagemInvalida = buildCreateRequest('E');
        triagemInvalida.tempoTriagemMinutos = 0;
        requests.add(triagemInvalida);
        GestaoSLADTO.CreateGestaoRequest respostaInvalida = buildCreateRequest('F');
        respostaInvalida.tempoRespostaChatMinutos = -1;
        requests.add(respostaInvalida);

        Integer failures = 0;
        for (GestaoSLADTO.CreateGestaoRequest req : requests) {
            try {
                GestaoSLAService.createGestaoSLA(req);
            } catch (Exception ex) {
                failures++;
                Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
            }
        }
        Assert.areEqual(requests.size(), failures);
    }

    @IsTest
    static void testCreateGestaoSLABloqueiaDuplicidadesAtivas() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.CreateGestaoRequest req = buildCreateRequest('DUP');
        GestaoSLAService.createGestaoSLA(req);

        Boolean failedUnidade = false;
        try {
            GestaoSLADTO.CreateGestaoRequest dupUnidade = buildCreateRequest('DUP2');
            dupUnidade.unidadeNegocio = req.unidadeNegocio;
            GestaoSLAService.createGestaoSLA(dupUnidade);
        } catch (Exception ex) {
            failedUnidade = true;
            Assert.areEqual(true, ex.getMessage().contains('Unidade de Negócio'));
        }
        Assert.areEqual(true, failedUnidade);

        Boolean failedEntitlement = false;
        try {
            GestaoSLADTO.CreateGestaoRequest dupEntitlement = buildCreateRequest('DUP3');
            dupEntitlement.entitlementProcessName = req.entitlementProcessName;
            List<Schema.PicklistEntry> unidades = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
            if (unidades.size() > 1) {
                dupEntitlement.unidadeNegocio = unidades[1].getValue();
            }
            GestaoSLAService.createGestaoSLA(dupEntitlement);
        } catch (Exception ex) {
            failedEntitlement = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failedEntitlement);
    }

    @IsTest
    static void testUpdateGestaoSLAConfiguradorSemAdminTecnicoBloqueado() {
        GestaoSLA__c g = createGestao('EDIT_NON_ADMIN', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name;
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.tempoTriagemMinutos = null;
        req.tempoRespostaChatMinutos = null;
        req.ativo = true;

        Boolean failed = false;
        try {
            GestaoSLAService.updateGestaoSLA(req);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('permissão para editar Gestão de SLA'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testUpdateGestaoSLAAdminPermiteTemposNulos() {
        GestaoSLA__c g = createGestao('EDIT_ADMIN', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name + ' Atualizada';
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.tempoTriagemMinutos = null;
        req.tempoRespostaChatMinutos = null;
        req.ativo = false;
        req.descricao = 'Descrição editada';

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.updateGestaoSLA(req);
        Assert.areEqual(req.name, response.gestao.name);
        Assert.areEqual(null, response.gestao.tempoTriagemMinutos);
        Assert.areEqual(null, response.gestao.tempoRespostaChatMinutos);
        Assert.areEqual('Descrição editada', response.gestao.descricao);
        Assert.areEqual(false, response.gestao.ativo);
    }

    @IsTest
    static void testUpdateGestaoSLANonAdminNaoPodeAlterarStatus() {
        GestaoSLA__c g = createGestao('EDIT_STATUS_NON_ADMIN', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name;
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.tempoTriagemMinutos = 10;
        req.tempoRespostaChatMinutos = 20;
        req.ativo = false;

        Boolean failed = false;
        try {
            GestaoSLAService.updateGestaoSLA(req);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('permissão para editar Gestão de SLA'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testGetInactiveGestoesSomenteAdminTecnico() {
        GestaoSLA__c inactive = createGestao('INATIVA_LISTA', false);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.InactiveGestoesResponse response = GestaoSLAService.getInactiveGestoes();
        Assert.areEqual(true, response.permissions.canAdminTechnicalSettings);
        Assert.areEqual(true, response.gestoesInativas.size() > 0);
        Assert.areEqual(true, response.gestoesInativas[0].id != null);

        Boolean found = false;
        for (GestaoSLADTO.GestaoResumo g : response.gestoesInativas) {
            if (g.id == inactive.Id) {
                found = true;
                Assert.areEqual('Atendimento Salvador', g.entitlementProcessName);
                Assert.areEqual('Atendimento Salvador', g.businessHoursName);
            }
        }
        Assert.areEqual(true, found);
    }

    @IsTest
    static void testReactivateGestaoSLAComSucessoEBloqueioConflito() {
        GestaoSLA__c inactive = createGestao('REATIVAR_OK', false);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.GestaoDetailResponse okResponse = GestaoSLAService.reactivateGestaoSLA(inactive.Id);
        Assert.areEqual(inactive.Id, okResponse.gestao.id);
        Assert.areEqual(true, okResponse.gestao.ativo);

        GestaoSLA__c conflictBase = createGestao('REATIVAR_CONFLICT_BASE', true);
        GestaoSLA__c inactiveConflict = createGestao('REATIVAR_CONFLICT_TARGET', false);
        inactiveConflict.UnidadeNegocio__c = conflictBase.UnidadeNegocio__c;
        inactiveConflict.EntitlementProcessName__c = 'Entitlement Conflito Único';
        update inactiveConflict;

        Boolean failed = false;
        try {
            GestaoSLAService.reactivateGestaoSLA(inactiveConflict.Id);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Unidade de Negócio'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateCategoriaComPermissao() {
        GestaoSLA__c g = createGestao('CAT_CREATE_OK', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = g.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.subassunto = 'Alteração';
        req.prioridadeSugerida = 'Low';
        req.ativo = true;

        GestaoSLADTO.CategoriaResumo response = GestaoSLAService.createCategoria(req);
        Assert.areEqual(g.UnidadeNegocio__c, response.unidadeNegocio);
        Assert.areEqual(true, response.ativo);
    }

    @IsTest
    static void testCreateCategoriaPermiteSubassuntoEPrioridadeVazios() {
        GestaoSLA__c g = createGestao('CAT_CREATE_NULLS', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = g.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.subassunto = null;
        req.prioridadeSugerida = null;
        req.ativo = true;

        GestaoSLADTO.CategoriaResumo response = GestaoSLAService.createCategoria(req);
        Assert.areEqual(null, response.subassunto);
        Assert.areEqual(null, response.prioridadeSugerida);
    }

    @IsTest
    static void testCreateCategoriaSemPermissao() {
        GestaoSLA__c g = createGestao('CAT_CREATE_SEM_PERM', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, false);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = g.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.subassunto = 'Alteração';
        req.prioridadeSugerida = 'Low';
        req.ativo = true;

        Boolean failed = false;
        try {
            GestaoSLAService.createCategoria(req);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('permissão'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateCategoriaBloqueiaDuplicidadeEPrioridadeInvalida() {
        GestaoSLA__c g = createGestao('CAT_DUP', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest baseReq = new GestaoSLADTO.CategoriaRequest();
        baseReq.gestaoSLAId = g.Id;
        baseReq.tipoCaso = 'Solicitação';
        baseReq.categoria = 'Solicitação';
        baseReq.assunto = 'Cadastro';
        baseReq.subassunto = 'Alteração';
        baseReq.prioridadeSugerida = 'Low';
        baseReq.ativo = true;
        GestaoSLAService.createCategoria(baseReq);

        Boolean dupFailed = false;
        try {
            GestaoSLAService.createCategoria(baseReq);
        } catch (Exception ex) {
            dupFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe'));
        }
        Assert.areEqual(true, dupFailed);

        Boolean prioFailed = false;
        try {
            GestaoSLADTO.CategoriaRequest invalidPrio = new GestaoSLADTO.CategoriaRequest();
            invalidPrio.gestaoSLAId = g.Id;
            invalidPrio.tipoCaso = 'Solicitação';
            invalidPrio.categoria = 'Solicitação';
            invalidPrio.assunto = 'Cadastro';
            invalidPrio.subassunto = null;
            invalidPrio.prioridadeSugerida = 'NaoMapeada';
            invalidPrio.ativo = true;
            GestaoSLAService.createCategoria(invalidPrio);
        } catch (Exception ex) {
            prioFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Prioridade'));
        }
        Assert.areEqual(true, prioFailed);
    }

    @IsTest
    static void testCreateCategoriaBloqueiaDuplicidadeComSubassuntoVazio() {
        GestaoSLA__c g = createGestao('CAT_DUP_EMPTY_SUB', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = g.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.subassunto = '';
        req.prioridadeSugerida = '';
        req.ativo = true;
        GestaoSLAService.createCategoria(req);

        Boolean dupFailed = false;
        try {
            GestaoSLAService.createCategoria(req);
        } catch (Exception ex) {
            dupFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe'));
        }
        Assert.areEqual(true, dupFailed);
    }

    @IsTest
    static void testUpdateEDeactivateCategoria() {
        GestaoSLA__c g = createGestao('CAT_UPD', true);
        Categorizacao__c c = createCategoria(g.Id, 'CAT_UPD', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.id = c.Id;
        req.gestaoSLAId = g.Id;
        req.tipoCaso = c.TipoCaso__c;
        req.categoria = c.Categoria__c;
        req.assunto = c.Assunto__c;
        req.subassunto = null;
        req.prioridadeSugerida = null;
        req.ativo = true;

        GestaoSLADTO.CategoriaResumo updated = GestaoSLAService.updateCategoria(req);
        Assert.areEqual(c.Assunto__c, updated.assunto);
        Assert.areEqual(null, updated.subassunto);
        Assert.areEqual(null, updated.prioridadeSugerida);

        GestaoSLADTO.CategoriaResumo deactivated = GestaoSLAService.deactivateCategoria(c.Id);
        Assert.areEqual(false, deactivated.ativo);
    }

    @IsTest
    static void testUpdateCategoriaBloqueiaPrioridadeInvalidaQuandoPreenchida() {
        GestaoSLA__c g = createGestao('CAT_UPD_INVALID_PRIO', true);
        Categorizacao__c c = createCategoria(g.Id, 'CAT_UPD_INVALID_PRIO', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.id = c.Id;
        req.gestaoSLAId = g.Id;
        req.tipoCaso = c.TipoCaso__c;
        req.categoria = c.Categoria__c;
        req.assunto = c.Assunto__c;
        req.subassunto = c.Subassunto__c;
        req.prioridadeSugerida = 'NaoMapeada';
        req.ativo = true;

        Boolean failed = false;
        try {
            GestaoSLAService.updateCategoria(req);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Prioridade'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testCreateUpdateDeactivateRegraSLAComPermissao() {
        GestaoSLA__c g = createGestao('REGRA_CRUD', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_CRUD', true);
        MarcoSLA__c m = createMarco(g.Id, 'Atendimento N3 CRUD', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            m.Id,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        GestaoSLADTO.RegraSLAResumo created = GestaoSLAService.createRegraSLA(req);
        Assert.areEqual(g.Id, created.gestaoSLAId);
        Assert.areEqual(c.Id, created.categorizacaoId);
        Assert.areEqual(m.Id, created.marcoSLAId);
        Assert.areEqual(10, created.tempoBaixa);
        Assert.areEqual(true, created.ativo);

        req.id = created.id;
        req.tempoBaixa = 15;
        req.tempoMedia = null;
        req.ativo = false;
        GestaoSLADTO.RegraSLAResumo updated = GestaoSLAService.updateRegraSLA(req);
        Assert.areEqual(15, updated.tempoBaixa);
        Assert.areEqual(null, updated.tempoMedia);
        Assert.areEqual(true, updated.ativo);

        GestaoSLADTO.RegraSLAResumo inactive = GestaoSLAService.deactivateRegraSLA(created.id);
        Assert.areEqual(false, inactive.ativo);
    }

    @IsTest
    static void testUpdateRegraSLAInativaNaoReativa() {
        GestaoSLA__c g = createGestao('REGRA_INATIVA_EDIT', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_INATIVA_EDIT', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco Inativa Edit', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            m.Id,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        req.ativo = false;
        GestaoSLADTO.RegraSLAResumo created = GestaoSLAService.createRegraSLA(req);
        Assert.areEqual(true, created.ativo);

        GestaoSLAService.deactivateRegraSLA(created.id);
        req.id = created.id;
        req.tempoAlta = 45;
        req.ativo = true;

        GestaoSLADTO.RegraSLAResumo updated = GestaoSLAService.updateRegraSLA(req);
        Assert.areEqual(45, updated.tempoAlta);
        Assert.areEqual(false, updated.ativo);
    }

    @IsTest
    static void testRegraSLABloqueiaSemPermissaoDeGerenciarRegras() {
        GestaoSLA__c g = createGestao('REGRA_SEM_PERM', true);
        Categorizacao__c c = createCategoria(g.Id, 'REGRA_SEM_PERM', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco Sem Perm', 1, true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, false);

        Boolean failed = false;
        try {
            GestaoSLAService.createRegraSLA(buildRegraRequest(
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            null,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        GestaoSLADTO.RegraSLAResumo created = GestaoSLAService.createRegraSLA(req);
        Assert.areEqual(area, created.areaAtendimento);
        Assert.areEqual(null, created.marcoSLAId);
        Assert.areEqual(RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA, created.escopoRegra);

        GestaoSLADTO.RegrasSLAResponse response = GestaoSLAService.getRegrasSLA(
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
                GestaoSLAService.createRegraSLA(req);
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id,
            m.Id,
            c.Id,
            RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        GestaoSLADTO.RegraSLAResumo first = GestaoSLAService.createRegraSLA(req);
        Assert.areEqual(true, first.ativo);

        Boolean dupFailed = false;
        try {
            GestaoSLAService.createRegraSLA(req);
        } catch (Exception ex) {
            dupFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe'));
        }
        Assert.areEqual(true, dupFailed);

        GestaoSLAService.deactivateRegraSLA(first.id);
        GestaoSLADTO.RegraSLAResumo second = GestaoSLAService.createRegraSLA(req);
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        Boolean failed = false;
        try {
            GestaoSLAService.createRegraSLA(buildRegraRequest(
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id, m.Id, c.Id, RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
        );
        req.areaAtendimento = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        GestaoSLADTO.RegraSLAResumo created = GestaoSLAService.createRegraSLA(req);
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(
            g.Id, null, c.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        req.marcoSLAId = m.Id;
        GestaoSLADTO.RegraSLAResumo created = GestaoSLAService.createRegraSLA(req);
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
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];

        GestaoSLADTO.RegraSLARequest req1 = buildRegraRequest(
            g.Id, null, c1.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        GestaoSLAService.createRegraSLA(req1);

        GestaoSLADTO.RegraSLARequest req2 = buildRegraRequest(
            g.Id, null, c2.Id, RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
        );
        GestaoSLADTO.RegraSLAResumo segundo = GestaoSLAService.createRegraSLA(req2);
        Assert.areEqual(area, segundo.areaAtendimento);

        Boolean dupFailed = false;
        try {
            GestaoSLAService.createRegraSLA(req1);
        } catch (Exception ex) {
            dupFailed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe'));
        }
        Assert.areEqual(true, dupFailed);
    }

}