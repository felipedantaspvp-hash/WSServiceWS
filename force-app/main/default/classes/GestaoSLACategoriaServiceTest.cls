/**
 * @description Testes unitários de GestaoSLACategoriaService, extraídos de GestaoSLAServiceTest.cls
 * (Pacote 44 — divisão do God Object GestaoSLAService.cls em serviços por domínio).
 **/
@IsTest
private class GestaoSLACategoriaServiceTest {
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

    private static User createAdminUser(String aliasSeed) {
        Profile profile = [SELECT Id FROM Profile WHERE PermissionsModifyAllData = true LIMIT 1];
        return TestDataFactory.createUser(aliasSeed, new Map<String, Object>{ 'ProfileId' => profile.Id });
    }

    @IsTest
    static void testCreateCategoriaBloqueadaParaUnidadeNaoPermitida() {
        GestaoSLA__c rioGrande = createGestao('RioGrandeBloqueio', true);
        rioGrande.UnidadeNegocio__c = 'Atendimento Tecon Rio Grande';
        update rioGrande;

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);
        GestaoSLAHelper.setAllowedUnidadesOverride(new Set<String>{ 'Atendimento Tecon Salvador' });

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = rioGrande.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Operação';
        req.assunto = 'Acesso';

        Boolean failed = false;
        try {
            GestaoSLACategoriaService.createCategoria(req);
        } catch (GestaoSLAService.FunctionalException ex) {
            failed = true;
        }
        Assert.areEqual(true, failed, 'Usuário restrito à unidade Salvador não pode criar Categorização para Gestão de SLA de outra unidade (Rio Grande).');
    }

    @IsTest
    static void testGetCategoriasBloqueadaParaUnidadeNaoPermitida() {
        GestaoSLA__c rioGrande = createGestao('RioGrandeGetCat', true);
        rioGrande.UnidadeNegocio__c = 'Atendimento Tecon Rio Grande';
        update rioGrande;
        createCategoria(rioGrande.Id, 'X', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);
        GestaoSLAHelper.setAllowedUnidadesOverride(new Set<String>{ 'Atendimento Tecon Salvador' });

        Boolean failed = false;
        try {
            GestaoSLACategoriaService.getCategorias(rioGrande.Id, null, null, null, null, null);
        } catch (GestaoSLAService.FunctionalException ex) {
            failed = true;
        }
        Assert.areEqual(true, failed, 'Usuário restrito à unidade Salvador não pode listar Categorizações de Gestão de SLA de outra unidade (Rio Grande).');
    }

    @IsTest
    static void testGetCategoriasComFiltros() {
        GestaoSLA__c g1 = createGestao('Categorias1', true);
        Categorizacao__c c1 = createCategoria(g1.Id, 'Alpha', true);
        MarcoSLA__c m = createMarco(g1.Id, 'Marco Cat', 1, true);
        createRegra(g1.Id, m.Id, c1.Id, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);

        GestaoSLADTO.CategoriasResponse all = GestaoSLACategoriaService.getCategorias(g1.Id, null, null, null, null, null);
        Assert.areEqual(1, all.categorias.size());

        GestaoSLADTO.CategoriasResponse filtered = GestaoSLACategoriaService.getCategorias(g1.Id, 'Cadastro', null, null, null, true);
        Assert.areEqual(1, filtered.categorias.size());
        Assert.areEqual(c1.Id, filtered.categorias[0].id);
        Assert.areEqual(1, filtered.categorias[0].totalRegrasAtivas);
    }

    @IsTest
    static void testCreateCategoriaComPermissao() {
        GestaoSLA__c g = createGestao('CAT_CREATE_OK', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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

        GestaoSLADTO.CategoriaResumo response = GestaoSLACategoriaService.createCategoria(req);
        Assert.areEqual(g.UnidadeNegocio__c, response.unidadeNegocio);
        Assert.areEqual(true, response.ativo);
        Assert.areEqual(false, response.distribuirParaFila, 'Sem solicitação de distribuição, DistribuirParaFila__c deve ficar Não.');
    }

    @IsTest
    static void testCreateCategoriaComDistribuicaoSemFilaLancaErroFuncionalAmigavel() {
        GestaoSLA__c g = createGestao('CAT_DIST_SEM_FILA', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = g.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.ativo = true;
        req.distribuirParaFila = true;
        req.porCampoCustomizado = false;
        // Fila intencionalmente omitida para validar a obrigatoriedade aplicada por
        // CategorizacaoTriggerHandler -> CategorizacaoService.beforeSave (item 6.3.5 da especificação).

        Boolean failed = false;
        try {
            GestaoSLACategoriaService.createCategoria(req);
        } catch (GestaoSLAService.FunctionalException ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Fila'), 'Mensagem de erro deve ser amigável e mencionar a Fila, não um stacktrace de DmlException cru.');
        }
        Assert.areEqual(true, failed, 'Distribuir para fila sem informar a Fila deve falhar com erro funcional amigável.');
    }

    @IsTest
    static void testCreateCategoriaComDistribuicaoPorCampoSemValorLancaErroFuncionalAmigavel() {
        GestaoSLA__c g = createGestao('CAT_DIST_SEM_VALOR', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.gestaoSLAId = g.Id;
        req.tipoCaso = 'Solicitação';
        req.categoria = 'Solicitação';
        req.assunto = 'Cadastro';
        req.ativo = true;
        req.distribuirParaFila = true;
        req.porCampoCustomizado = true;
        req.campoDistribuicao = 'Origin';
        // Valor de distribuição intencionalmente omitido.

        Boolean failed = false;
        try {
            GestaoSLACategoriaService.createCategoria(req);
        } catch (GestaoSLAService.FunctionalException ex) {
            failed = true;
        }
        Assert.areEqual(true, failed, 'Distribuir por campo sem informar o Valor deve falhar com erro funcional amigável.');
    }

    @IsTest
    static void testUpdateCategoriaPersisteCamposDeDistribuicaoQuandoValidos() {
        GestaoSLA__c g = createGestao('CAT_UPDATE_DIST', true);
        Categorizacao__c c = createCategoria(g.Id, 'UpdateDist', true);
        User adminUser = createAdminUser('catupd1');

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);

        GestaoSLADTO.CategoriaRequest req = new GestaoSLADTO.CategoriaRequest();
        req.id = c.Id;
        req.gestaoSLAId = g.Id;
        req.tipoCaso = c.TipoCaso__c;
        req.categoria = c.Categoria__c;
        req.assunto = c.Assunto__c;
        req.ativo = true;
        req.distribuirParaFila = false;

        System.runAs(adminUser) {
            GestaoSLADTO.CategoriaResumo response = GestaoSLACategoriaService.updateCategoria(req);
            Assert.areEqual(false, response.distribuirParaFila);
            Assert.areEqual(null, response.filaDeveloperName);
        }
    }

    @IsTest
    static void testCreateCategoriaPermiteSubassuntoEPrioridadeVazios() {
        GestaoSLA__c g = createGestao('CAT_CREATE_NULLS', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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

        GestaoSLADTO.CategoriaResumo response = GestaoSLACategoriaService.createCategoria(req);
        Assert.areEqual(null, response.subassunto);
        Assert.areEqual(null, response.prioridadeSugerida);
    }

    @IsTest
    static void testCreateCategoriaSemPermissao() {
        GestaoSLA__c g = createGestao('CAT_CREATE_SEM_PERM', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
            GestaoSLACategoriaService.createCategoria(req);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLACategoriaService.createCategoria(baseReq);

        Boolean dupFailed = false;
        try {
            GestaoSLACategoriaService.createCategoria(baseReq);
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
            GestaoSLACategoriaService.createCategoria(invalidPrio);
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
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
        GestaoSLACategoriaService.createCategoria(req);

        Boolean dupFailed = false;
        try {
            GestaoSLACategoriaService.createCategoria(req);
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
        User adminUser = createAdminUser('catupd2');

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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

        System.runAs(adminUser) {
            GestaoSLADTO.CategoriaResumo updated = GestaoSLACategoriaService.updateCategoria(req);
            Assert.areEqual(c.Assunto__c, updated.assunto);
            Assert.areEqual(null, updated.subassunto);
            Assert.areEqual(null, updated.prioridadeSugerida);

            GestaoSLADTO.CategoriaResumo deactivated = GestaoSLACategoriaService.deactivateCategoria(c.Id);
            Assert.areEqual(false, deactivated.ativo);
        }
    }

    @IsTest
    static void testUpdateCategoriaBloqueiaPrioridadeInvalidaQuandoPreenchida() {
        GestaoSLA__c g = createGestao('CAT_UPD_INVALID_PRIO', true);
        Categorizacao__c c = createCategoria(g.Id, 'CAT_UPD_INVALID_PRIO', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
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
            GestaoSLACategoriaService.updateCategoria(req);
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Prioridade'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testReactivateCategoriaBloqueadaPorDuplicidadeAtiva() {
        // Inativa uma Categorizacao e depois cria outra ATIVA com a mesma combinação
        // (cenário real: duplicidade resolvida via inativação). Reativar a antiga deve
        // continuar bloqueado enquanto a nova ativa existir, mesmo após o ajuste que faz
        // o hash único (CategorizacaoSelector.getExistingByHash) ignorar inativas.
        GestaoSLA__c g = createGestao('REACT_DUP', true);
        Categorizacao__c original = createCategoria(g.Id, 'REACT_DUP', true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        User adminUser = createAdminUser('catupd3');

        System.runAs(adminUser) {
            GestaoSLADTO.CategoriaResumo deactivated = GestaoSLACategoriaService.deactivateCategoria(original.Id);
            Assert.areEqual(false, deactivated.ativo);
        }

        GestaoSLADTO.CategoriaRequest createReq = new GestaoSLADTO.CategoriaRequest();
        createReq.gestaoSLAId = g.Id;
        createReq.tipoCaso = original.TipoCaso__c;
        createReq.categoria = original.Categoria__c;
        createReq.assunto = original.Assunto__c;
        createReq.subassunto = original.Subassunto__c;
        createReq.ativo = true;
        GestaoSLADTO.CategoriaResumo novaAtiva;
        System.runAs(adminUser) {
            novaAtiva = GestaoSLACategoriaService.createCategoria(createReq);
        }
        Assert.areEqual(true, novaAtiva.ativo);

        Boolean failed = false;
        try {
            System.runAs(adminUser) {
                GestaoSLACategoriaService.reactivateCategoria(original.Id);
            }
        } catch (Exception ex) {
            failed = true;
            Assert.areEqual(true, ex.getMessage().contains('Já existe uma categorização ativa'));
        }
        Assert.areEqual(true, failed);
    }

    @IsTest
    static void testDeleteCategoriaCascadesRegrasSLA() {
        GestaoSLA__c g = createGestao('DelCateg', true);
        Categorizacao__c c = createCategoria(g.Id, 'DelCateg', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco DelCateg', 1, true);
        createRegra(g.Id, m.Id, c.Id, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLACategoriaService.deleteCategoria(c.Id);

        Assert.areEqual(0, [SELECT COUNT() FROM Categorizacao__c WHERE Id = :c.Id]);
        Assert.areEqual(0, [SELECT COUNT() FROM RegrasSLACategorizacao__c WHERE Categorizacao__c = :c.Id]);
    }

}
