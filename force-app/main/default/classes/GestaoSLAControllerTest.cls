/**
 * @description       : Testes unitários de GestaoSLAController.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-13-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class GestaoSLAControllerTest {
    private static GestaoSLA__c createGestao() {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) {
            unidade = entries[0].getValue();
        }
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Controller',
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Atendimento Salvador',
            Ativo__c = true
        );
        insert g;
        return g;
    }

    private static GestaoSLA__c createGestaoInativa(String suffix) {
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) {
            unidade = entries[0].getValue();
        }
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Inativa ' + suffix,
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Entitlement Inativo ' + suffix,
            BusinessHoursName__c = 'BH Inativo ' + suffix,
            Ativo__c = false
        );
        insert g;
        return g;
    }

    private static Categorizacao__c createCategoria(Id gestaoId) {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        c.Ativo__c = true;
        insert c;
        c.GestaoSLA__c = gestaoId;
        update c;
        return c;
    }

    private static MarcoSLA__c createMarco(Id gestaoId) {
        MarcoSLA__c m = new MarcoSLA__c(
            Name = 'Marco Controller',
            GestaoSLA__c = gestaoId,
            NomeMarco__c = 'Marco Controller',
            MilestoneTypeName__c = 'Marco Controller',
            FonteTempo__c = 'RegraSLA',
            Ordem__c = 1,
            Recorrente__c = false,
            TipoRecorrencia__c = 'NaoRecorrente',
            Ativo__c = true
        );
        insert m;
        return m;
    }

    private static GestaoSLADTO.RegraSLARequest buildRegraRequest(Id gestaoId, Id marcoId, Id categoriaId) {
        GestaoSLADTO.RegraSLARequest req = new GestaoSLADTO.RegraSLARequest();
        req.gestaoSLAId = gestaoId;
        req.marcoSLAId = marcoId;
        req.categorizacaoId = categoriaId;
        req.escopoRegra = RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO;
        req.tempoBaixa = 10;
        req.tempoMedia = 20;
        req.tempoAlta = 30;
        req.ativo = true;
        return req;
    }

    @IsTest
    static void testControllerMethodsSuccess() {
        GestaoSLA__c g = createGestao();
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.BootstrapResponse b = GestaoSLAController.getBootstrap();
        Assert.areEqual(true, b.permissions.canAccessGestaoSLA);

        GestaoSLADTO.GestaoDetailResponse d = GestaoSLAController.getGestaoDetail(g.Id);
        Assert.areEqual(g.Id, d.gestao.id);

        GestaoSLADTO.CategoriasResponse c = GestaoSLAController.getCategorias(g.Id, null, null, null, null, null);
        Assert.areEqual(true, c.categorias != null);

        GestaoSLADTO.MarcosResponse m = GestaoSLAController.getMarcos(g.Id);
        Assert.areEqual(true, m.marcos != null);

        GestaoSLADTO.RegrasSLAResponse r = GestaoSLAController.getRegrasSLA(g.Id, null, null, null, null, null);
        Assert.areEqual(true, r.regras != null);
    }

    @IsTest
    static void testControllerThrowsAuraHandledWhenNoPermission() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, false);
        GestaoSLA__c g = createGestao();

        Boolean failedBootstrap = false;
        try {
            GestaoSLAController.getBootstrap();
        } catch (AuraHandledException ex) {
            failedBootstrap = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failedBootstrap);

        Boolean failedDetail = false;
        try {
            GestaoSLAController.getGestaoDetail(g.Id);
        } catch (AuraHandledException ex) {
            failedDetail = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failedDetail);

        Boolean failedCategorias = false;
        try {
            GestaoSLAController.getCategorias(g.Id, null, null, null, null, null);
        } catch (AuraHandledException ex) {
            failedCategorias = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failedCategorias);

        Boolean failedMarcos = false;
        try {
            GestaoSLAController.getMarcos(g.Id);
        } catch (AuraHandledException ex) {
            failedMarcos = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failedMarcos);

        Boolean failedRegras = false;
        try {
            GestaoSLAController.getRegrasSLA(g.Id, null, null, null, null, null);
        } catch (AuraHandledException ex) {
            failedRegras = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failedRegras);
    }

    @IsTest
    static void testControllerCreateGestaoSLA() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);
        String unidade = 'Salvador';
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        if (!entries.isEmpty()) {
            unidade = entries[0].getValue();
        }

        GestaoSLADTO.CreateGestaoRequest req = new GestaoSLADTO.CreateGestaoRequest();
        req.name = 'Gestão Controller Create';
        req.unidadeNegocio = unidade;
        req.entitlementProcessName = 'Entitlement Controller';
        req.businessHoursName = 'BH Controller';
        req.tempoTriagemMinutos = 120;
        req.tempoRespostaChatMinutos = 60;
        req.ativo = true;

        GestaoSLADTO.GestaoDetailResponse detail = GestaoSLAController.createGestaoSLA(req);
        Assert.areEqual(req.name, detail.gestao.name);
        Assert.areEqual(true, detail.gestao.ativo);
    }

    @IsTest
    static void testControllerUpdateGestaoSLA() {
        GestaoSLA__c g = createGestao();
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name + ' Editada';
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.tempoTriagemMinutos = null;
        req.tempoRespostaChatMinutos = null;
        req.ativo = true;

        GestaoSLADTO.GestaoDetailResponse detail = GestaoSLAController.updateGestaoSLA(req);
        Assert.areEqual(req.name, detail.gestao.name);
    }

    @IsTest
    static void testControllerUpdateGestaoSLABloqueiaSemAdminTecnico() {
        GestaoSLA__c g = createGestao();
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        GestaoSLADTO.UpdateGestaoRequest req = new GestaoSLADTO.UpdateGestaoRequest();
        req.id = g.Id;
        req.name = g.Name + ' Editada';
        req.unidadeNegocio = g.UnidadeNegocio__c;
        req.entitlementProcessName = g.EntitlementProcessName__c;
        req.businessHoursName = g.BusinessHoursName__c;
        req.tempoTriagemMinutos = 10;
        req.tempoRespostaChatMinutos = 20;
        req.ativo = true;

        Boolean failed = false;
        try {
            GestaoSLAController.updateGestaoSLA(req);
        } catch (AuraHandledException ex) {
            failed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testControllerGetInactiveAndReactivate() {
        GestaoSLA__c gInativa = createGestaoInativa('A');
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.InactiveGestoesResponse inativas = GestaoSLAController.getInactiveGestoes();
        Assert.areEqual(true, inativas.gestoesInativas.size() > 0);

        GestaoSLADTO.GestaoDetailResponse reativada = GestaoSLAController.reactivateGestaoSLA(gInativa.Id);
        Assert.areEqual(gInativa.Id, reativada.gestao.id);
        Assert.areEqual(true, reativada.gestao.ativo);
    }

    @IsTest
    static void testControllerCategoriaCrud() {
        GestaoSLA__c g = createGestao();
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest createReq = new GestaoSLADTO.CategoriaRequest();
        createReq.gestaoSLAId = g.Id;
        createReq.tipoCaso = 'Solicitação';
        createReq.categoria = 'Solicitação';
        createReq.assunto = 'Cadastro';
        createReq.subassunto = 'Alteração';
        createReq.prioridadeSugerida = 'Low';
        createReq.ativo = true;

        GestaoSLADTO.CategoriaResumo created = GestaoSLAController.createCategoria(createReq);
        Assert.areEqual(true, created.id != null);

        GestaoSLADTO.CategoriaRequest updateReq = new GestaoSLADTO.CategoriaRequest();
        updateReq.id = created.id;
        updateReq.gestaoSLAId = g.Id;
        updateReq.tipoCaso = created.tipoCaso;
        updateReq.categoria = created.categoria;
        updateReq.assunto = created.assunto;
        updateReq.subassunto = created.subassunto;
        updateReq.prioridadeSugerida = 'Medium';
        updateReq.ativo = true;

        GestaoSLADTO.CategoriaResumo updated = GestaoSLAController.updateCategoria(updateReq);
        Assert.areEqual(created.assunto, updated.assunto);

        GestaoSLADTO.CategoriaResumo deactivated = GestaoSLAController.deactivateCategoria(created.id);
        Assert.areEqual(false, deactivated.ativo);
    }

    @IsTest
    static void testControllerCategoriaCrudSemPermissao() {
        GestaoSLA__c g = createGestao();
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

        Boolean createFailed = false;
        try {
            GestaoSLAController.createCategoria(req);
        } catch (AuraHandledException ex) {
            createFailed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, createFailed);

        Boolean updateFailed = false;
        try {
            GestaoSLAController.updateCategoria(req);
        } catch (AuraHandledException ex) {
            updateFailed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, updateFailed);

        Boolean deactivateFailed = false;
        try {
            GestaoSLAController.deactivateCategoria(null);
        } catch (AuraHandledException ex) {
            deactivateFailed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, deactivateFailed);
    }

    @IsTest
    static void testControllerRegraSLACrud() {
        GestaoSLA__c g = createGestao();
        Categorizacao__c c = createCategoria(g.Id);
        MarcoSLA__c m = createMarco(g.Id);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, true);

        GestaoSLADTO.RegraSLARequest req = buildRegraRequest(g.Id, m.Id, c.Id);
        GestaoSLADTO.RegraSLAResumo created = GestaoSLAController.createRegraSLA(req);
        Assert.areEqual(true, created.id != null);

        req.id = created.id;
        req.tempoAlta = 45;
        GestaoSLADTO.RegraSLAResumo updated = GestaoSLAController.updateRegraSLA(req);
        Assert.areEqual(45, updated.tempoAlta);

        GestaoSLADTO.RegraSLAResumo deactivated = GestaoSLAController.deactivateRegraSLA(created.id);
        Assert.areEqual(false, deactivated.ativo);
    }

    @IsTest
    static void testControllerRegraSLAConverteErroFuncional() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, false);

        Boolean failed = false;
        try {
            GestaoSLAController.createRegraSLA(new GestaoSLADTO.RegraSLARequest());
        } catch (AuraHandledException ex) {
            failed = true;
            Assert.areEqual(true, String.isNotBlank(ex.getMessage()));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testControllerGetInactiveCategoriasAndReactivate() {
        GestaoSLA__c g = createGestao();
        Categorizacao__c c = createCategoria(g.Id);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaResumo deactivated = GestaoSLAController.deactivateCategoria(c.Id);
        Assert.areEqual(false, deactivated.ativo);

        GestaoSLADTO.InactiveCategoriasResponse inativas = GestaoSLAController.getInactiveCategorias(g.Id);
        Assert.isNotNull(inativas);
        Assert.areEqual(true, inativas.categoriasInativas.size() > 0);

        GestaoSLADTO.CategoriaResumo reativada = GestaoSLAController.reactivateCategoria(c.Id);
        Assert.areEqual(true, reativada.ativo);
    }

    @IsTest
    static void testControllerRegraSLAUpdateDeactivateSemPermissao() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, false);

        Boolean updateFailed = false;
        try {
            GestaoSLAController.updateRegraSLA(new GestaoSLADTO.RegraSLARequest());
        } catch (AuraHandledException ex) {
            updateFailed = true;
        }
        Assert.isTrue(updateFailed);

        Boolean deactivateFailed = false;
        try {
            GestaoSLAController.deactivateRegraSLA(null);
        } catch (AuraHandledException ex) {
            deactivateFailed = true;
        }
        Assert.isTrue(deactivateFailed);
    }
}