/**
 * @description Testes unitários de GestaoSLAMarcoService, extraídos de GestaoSLAServiceTest.cls
 * (Pacote 44 — divisão do God Object GestaoSLAService.cls em serviços por domínio).
 **/
@IsTest
private class GestaoSLAMarcoServiceTest {
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

    private static GestaoSLADTO.MarcoSLARequest buildMarcoRequestService(Id gestaoId) {
        GestaoSLADTO.MarcoSLARequest req = new GestaoSLADTO.MarcoSLARequest();
        req.gestaoSLAId = gestaoId;
        req.nomeMarco = 'Marco Service';
        req.milestoneTypeName = 'Marco Service';
        req.fonteTempo = 'RegraSLA';
        req.recorrente = false;
        req.ativo = true;
        return req;
    }

    @IsTest
    static void testGetMarcosOrdenacaoEOcultacaoMilestoneType() {
        GestaoSLA__c g = createGestao('Marcos', true);
        MarcoSLA__c m2 = createMarco(g.Id, 'Marco Z', 2, true);
        MarcoSLA__c m1 = createMarco(g.Id, 'Marco A', 1, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);
        GestaoSLADTO.MarcosResponse semTecnico = GestaoSLAMarcoService.getMarcos(g.Id);
        Assert.areEqual(2, semTecnico.marcos.size());
        Assert.areEqual(m1.Id, semTecnico.marcos[0].id);
        Assert.areEqual(m2.Id, semTecnico.marcos[1].id);
        Assert.areEqual(null, semTecnico.marcos[0].milestoneTypeName);

        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);
        GestaoSLADTO.MarcosResponse tecnico = GestaoSLAMarcoService.getMarcos(g.Id);
        Assert.areEqual('Marco A', tecnico.marcos[0].milestoneTypeName);
    }

    @IsTest
    static void testDeleteMarcoSLABlockedWhileRegrasLinked() {
        GestaoSLA__c g = createGestao('DelMarco', true);
        Categorizacao__c c = createCategoria(g.Id, 'DelMarco', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco DelMarco', 1, true);
        createRegra(g.Id, m.Id, c.Id, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        Boolean blocked = false;
        try {
            GestaoSLAMarcoService.deleteMarcoSLA(m.Id);
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
            Assert.areEqual(true, ex.getMessage().contains('Regras de SLA vinculadas'));
        }
        Assert.areEqual(true, blocked);
        Assert.areEqual(1, [SELECT COUNT() FROM MarcoSLA__c WHERE Id = :m.Id]);
    }

    @IsTest
    static void testDeleteMarcoSLASucceedsWithoutRegras() {
        GestaoSLA__c g = createGestao('DelMarcoSolo', true);
        MarcoSLA__c m = createMarco(g.Id, 'Marco DelMarcoSolo', 1, true);

        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLAMarcoService.deleteMarcoSLA(m.Id);
        Assert.areEqual(0, [SELECT COUNT() FROM MarcoSLA__c WHERE Id = :m.Id]);
    }

    @IsTest
    static void testCreateMarcoSLARequiresTipoRecorrenciaWhenRecorrente() {
        GestaoSLA__c g = createGestao('MarcoRecorrente', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.MarcoSLARequest req = buildMarcoRequestService(g.Id);
        req.recorrente = true;
        req.tipoRecorrencia = null;

        Boolean blocked = false;
        try {
            GestaoSLAMarcoService.createMarcoSLA(req);
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
            Assert.areEqual(true, ex.getMessage().contains('Tipo de Recorrência'));
        }
        Assert.areEqual(true, blocked);
    }

    @IsTest
    static void testUpdateMarcoSLABlockedWhenGestaoMismatch() {
        GestaoSLA__c g1 = createGestao('MarcoMismatch1', true);
        GestaoSLA__c g2 = createGestao('MarcoMismatch2', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.MarcoResumo created = GestaoSLAMarcoService.createMarcoSLA(buildMarcoRequestService(g1.Id));

        GestaoSLADTO.MarcoSLARequest updateReq = buildMarcoRequestService(g2.Id);
        updateReq.id = created.id;

        Boolean blocked = false;
        try {
            GestaoSLAMarcoService.updateMarcoSLA(updateReq);
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
        }
        Assert.areEqual(true, blocked);
    }

    @IsTest
    static void testReactivateMarcoSLAAlreadyActiveReturnsUnchanged() {
        GestaoSLA__c g = createGestao('MarcoJaAtivo', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.MarcoResumo created = GestaoSLAMarcoService.createMarcoSLA(buildMarcoRequestService(g.Id));
        GestaoSLADTO.MarcoResumo result = GestaoSLAMarcoService.reactivateMarcoSLA(created.id);
        Assert.areEqual(true, result.ativo);
    }

    @IsTest
    static void testCreateMarcoSLABlockedByExistingInactiveSameMilestoneType() {
        // O nome do Milestone Type mapeia 1:1 para uma entidade real no Entitlement Process: uma vez
        // usado nesta Gestão de SLA (ativo ou inativo), o caminho correto é reativar o registro existente,
        // nunca criar um segundo — por isso o bloqueio vale mesmo com o original inativo.
        GestaoSLA__c g = createGestao('MarcoReativarDuplicado', true);
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, true);

        GestaoSLADTO.MarcoResumo created = GestaoSLAMarcoService.createMarcoSLA(buildMarcoRequestService(g.Id));
        GestaoSLAMarcoService.deactivateMarcoSLA(created.id);

        GestaoSLADTO.MarcoSLARequest second = buildMarcoRequestService(g.Id);

        Boolean blocked = false;
        try {
            GestaoSLAMarcoService.createMarcoSLA(second);
        } catch (GestaoSLAService.FunctionalException ex) {
            blocked = true;
        }
        Assert.areEqual(true, blocked);

        GestaoSLADTO.MarcoResumo reactivated = GestaoSLAMarcoService.reactivateMarcoSLA(created.id);
        Assert.areEqual(true, reactivated.ativo);
    }
}
