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
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
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
        req.usaTempoTriagem = true;
        req.tempoTriagemMinutos = 120;
        req.usaTempoRespostaChat = true;
        req.tempoRespostaChatMinutos = 60;
        req.usaTempoFilaEmail = false;
        req.tempoFilaEmailMinutos = null;
        req.descricao = 'Descrição ' + suffix;
        req.staticResourceName = 'resource_' + suffix;
        req.ativo = true;
        return req;
    }

    @IsTest
    static void testSemPermissaoDeAcessoBloqueia() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
    static void testBootstrapRestritoAUmaUnidadeAutoSelecionaEFiltraLista() {
        GestaoSLA__c salvador = createGestao('Salvador', true);
        salvador.UnidadeNegocio__c = 'Atendimento Tecon Salvador';
        update salvador;
        GestaoSLA__c rioGrande = createGestao('RioGrande', true);
        rioGrande.UnidadeNegocio__c = 'Atendimento Tecon Rio Grande';
        update rioGrande;

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);
        GestaoSLAHelper.setAllowedUnidadesOverride(new Set<String>{ 'Atendimento Tecon Salvador' });

        GestaoSLADTO.BootstrapResponse response = GestaoSLAService.getBootstrap();
        Assert.areEqual(1, response.gestoes.size(), 'Usuário restrito a uma unidade deve ver apenas a Gestão de SLA dessa unidade.');
        Assert.areEqual(salvador.Id, response.gestoes[0].id);
        Assert.areEqual(1, response.unidadesDisponiveis.size());
        Assert.areEqual('Atendimento Tecon Salvador', response.unidadeUnica, 'Deve indicar a única unidade disponível para auto-seleção na tela.');
    }

    @IsTest
    static void testBootstrapAdminTecnicoVeTodasAsUnidadesMesmoComRestricaoDeRecordType() {
        createGestao('Salvador', true);
        GestaoSLA__c rioGrande = createGestao('RioGrande', true);
        rioGrande.UnidadeNegocio__c = 'Atendimento Tecon Rio Grande';
        update rioGrande;

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);
        GestaoSLAHelper.setAllowedUnidadesOverride(new Set<String>{ 'Atendimento Tecon Salvador' });

        GestaoSLADTO.BootstrapResponse response = GestaoSLAService.getBootstrap();
        Assert.areEqual(2, response.gestoes.size(), 'Admin Técnico deve ter acesso irrestrito, ignorando o Record Type disponível.');
        Assert.areEqual(null, response.unidadesDisponiveis);
        Assert.areEqual(null, response.unidadeUnica);
    }

    @IsTest
    static void testBootstrapSemUnidadeDisponivelLancaErroFuncional() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);
        GestaoSLAHelper.setAllowedUnidadesOverride(new Set<String>());

        Boolean failed = false;
        try {
            GestaoSLAService.getBootstrap();
        } catch (GestaoSLAService.FunctionalException ex) {
            failed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failed, 'Usuário sem nenhuma Unidade de Negócio disponível deve receber erro funcional, não lista vazia silenciosa.');
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
    static void testCreateGestaoSLAComSucesso() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.CreateGestaoRequest req = buildCreateRequest('SEM_TEMPO');
        req.usaTempoTriagem = false;
        req.tempoTriagemMinutos = null;
        req.usaTempoRespostaChat = false;
        req.tempoRespostaChatMinutos = null;

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.createGestaoSLA(req);
        Assert.areEqual(req.name, response.gestao.name);
        Assert.areEqual(null, response.gestao.tempoTriagemMinutos);
        Assert.areEqual(null, response.gestao.tempoRespostaChatMinutos);
    }

    @IsTest
    static void testCreateGestaoSLASemPermissaoTecnica() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
    static void testCreateGestaoSLACriaMarcosUnicosConformeCheckboxes() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.CreateGestaoRequest req = buildCreateRequest('MARCOS');
        req.usaTempoTriagem = true;
        req.tempoTriagemMinutos = 30;
        req.usaTempoRespostaChat = false;
        req.tempoRespostaChatMinutos = null;
        req.usaTempoFilaEmail = true;
        req.tempoFilaEmailMinutos = 45;

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.createGestaoSLA(req);

        Map<String, MarcoSLA__c> marcosByName = new Map<String, MarcoSLA__c>();
        for (MarcoSLA__c m : [SELECT MilestoneTypeName__c, Ativo__c, FonteTempo__c FROM MarcoSLA__c WHERE GestaoSLA__c = :response.gestao.id]) {
            marcosByName.put(m.MilestoneTypeName__c, m);
        }
        Assert.areEqual(true, marcosByName.containsKey('Triagem'), 'Marco Triagem deveria ter sido criado.');
        Assert.areEqual(true, marcosByName.get('Triagem').Ativo__c);
        Assert.areEqual('GestaoSLA', marcosByName.get('Triagem').FonteTempo__c);
        Assert.areEqual(false, marcosByName.containsKey('Resposta Chat'), 'Marco Resposta Chat não deveria ter sido criado quando não utilizado.');
        Assert.areEqual(true, marcosByName.containsKey('Fila Email'), 'Marco Fila Email deveria ter sido criado.');
        Assert.areEqual(true, marcosByName.get('Fila Email').Ativo__c);
    }

    @IsTest
    static void testUpdateGestaoSLADesativaEReativaMarcoUnicoConformeCheckbox() {
        GestaoSLA__c g = createGestao('MARCO_TOGGLE', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name;
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.usaTempoTriagem = true;
        req.tempoTriagemMinutos = 20;
        req.ativo = true;

        GestaoSLAService.updateGestaoSLA(req);
        List<MarcoSLA__c> created = [SELECT Id, Ativo__c FROM MarcoSLA__c WHERE GestaoSLA__c = :g.Id AND MilestoneTypeName__c = 'Triagem'];
        Assert.areEqual(1, created.size());
        Assert.areEqual(true, created[0].Ativo__c);

        req.usaTempoTriagem = false;
        req.tempoTriagemMinutos = null;
        GestaoSLAService.updateGestaoSLA(req);
        List<MarcoSLA__c> afterDisable = [SELECT Id, Ativo__c FROM MarcoSLA__c WHERE GestaoSLA__c = :g.Id AND MilestoneTypeName__c = 'Triagem'];
        Assert.areEqual(1, afterDisable.size(), 'Marco não deve ser excluído, apenas desativado.');
        Assert.areEqual(false, afterDisable[0].Ativo__c);

        req.usaTempoTriagem = true;
        req.tempoTriagemMinutos = 15;
        GestaoSLAService.updateGestaoSLA(req);
        List<MarcoSLA__c> afterReenable = [SELECT Id, Ativo__c FROM MarcoSLA__c WHERE GestaoSLA__c = :g.Id AND MilestoneTypeName__c = 'Triagem'];
        Assert.areEqual(1, afterReenable.size(), 'Marco existente deve ser reativado, não duplicado.');
        Assert.areEqual(true, afterReenable[0].Ativo__c);
    }

    @IsTest
    static void testUpdateGestaoSLABloqueiaTempoFilaEmailSemValorQuandoUtilizado() {
        GestaoSLA__c g = createGestao('FILA_EMAIL_VALIDA', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name;
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.usaTempoFilaEmail = true;
        req.tempoFilaEmailMinutos = null;
        req.ativo = true;

        Boolean failed = false;
        try {
            GestaoSLAService.updateGestaoSLA(req);
        } catch (GestaoSLAService.FunctionalException ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Fila de Email'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testUpdateGestaoSLASemNenhumaPermissaoDeEdicaoBloqueado() {
        // Apenas AcessarGestaoSLA (leitura) — sem GerenciarCategorias (Gestor) nem Admin Técnico.
        GestaoSLA__c g = createGestao('EDIT_NO_PERM', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, false);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name;
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
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
    static void testUpdateGestaoSLAGestorPodeAlterarTempoDeMarcoJaHabilitado() {
        // Gestor (GestaoSLAConfigurador / GerenciarCategorias) não é Admin Técnico, mas pode
        // editar o valor de tempo de um marco que já está habilitado para a Gestão.
        GestaoSLA__c g = createGestao('EDIT_GESTOR_TEMPO', true);
        g.UsaTempoTriagem__c = true;
        g.TempoTriagemMinutos__c = 10;
        update g;

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.tempoTriagemMinutos = 99;
        // Tenta também alterar campos estruturais — devem ser ignorados silenciosamente.
        req.name = 'Nome Forjado Pelo Gestor';
        req.ativo = false;
        req.usaTempoRespostaChat = true;
        req.tempoRespostaChatMinutos = 50;

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.updateGestaoSLA(req);
        Assert.areEqual(99, response.gestao.tempoTriagemMinutos, 'Gestor pode alterar o tempo de um marco já habilitado.');
        Assert.areEqual(g.Name, response.gestao.name, 'Nome deve permanecer o original — Gestor não edita campo estrutural.');
        Assert.areEqual(true, response.gestao.ativo, 'Status deve permanecer ativo — Gestor não edita Status.');
        Assert.areEqual(false, response.gestao.usaTempoRespostaChat, 'Gestor não pode habilitar um novo marco único.');
        Assert.areEqual(null, response.gestao.tempoRespostaChatMinutos, 'Tempo de marco não habilitado pelo Admin deve ficar nulo.');
    }

    @IsTest
    static void testUpdateGestaoSLAAdminPermiteTemposNulos() {
        GestaoSLA__c g = createGestao('EDIT_ADMIN', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
    static void testUpdateGestaoSLAGestorNaoPodeAlterarStatus() {
        GestaoSLA__c g = createGestao('EDIT_STATUS_NON_ADMIN', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name;
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.ativo = false;

        GestaoSLADTO.GestaoDetailResponse response = GestaoSLAService.updateGestaoSLA(req);
        Assert.areEqual(true, response.gestao.ativo, 'Gestor não pode alterar o Status — valor atual (ativo=true) deve ser preservado.');
    }

    @IsTest
    static void testGetInactiveGestoesSomenteAdminTecnico() {
        GestaoSLA__c inactive = createGestao('INATIVA_LISTA', false);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
    static void testDeleteGestaoSLABlockedWhileCategoriasLinked() {
        GestaoSLA__c g = createGestao('DelGestao', true);
        createCategoria(g.Id, 'DelGestaoCateg', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        Boolean blocked = false;
        try {
            GestaoSLAService.deleteGestaoSLA(g.Id);
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
            Assert.areEqual(true, ex.getMessage().contains('Categorizações vinculadas'));
        }
        Assert.areEqual(true, blocked);
        Assert.areEqual(1, [SELECT COUNT() FROM GestaoSLA__c WHERE Id = :g.Id]);
    }

    @IsTest
    static void testDeleteGestaoSLASucceedsWithoutCategorias() {
        GestaoSLA__c g = createGestao('DelGestaoSolo', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLAService.deleteGestaoSLA(g.Id);
        Assert.areEqual(0, [SELECT COUNT() FROM GestaoSLA__c WHERE Id = :g.Id]);
    }

}
