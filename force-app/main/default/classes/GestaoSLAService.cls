public inherited sharing class GestaoSLAService {
    public class FunctionalException extends Exception {}
    public static GestaoSLADTO.BootstrapResponse getBootstrap() {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        Set<String> allowedUnidades = GestaoSLAHelper.resolveAllowedUnidades(perms);
        if (allowedUnidades != null && allowedUnidades.isEmpty()) {
            throw new FunctionalException('Nenhuma Unidade de Negócio disponível para o seu usuário. Verifique o Record Type de Case atribuído ao seu perfil/permission set.');
        }

        GestaoSLADTO.BootstrapResponse response = new GestaoSLADTO.BootstrapResponse();
        response.permissions = perms;
        response.gestoes = new List<GestaoSLADTO.GestaoResumo>();
        response.unidadeNegocioOptions = GestaoSLAHelper.getActivePicklistOptions(GestaoSLA__c.UnidadeNegocio__c);
        response.tipoCasoOptions = GestaoSLAHelper.getActivePicklistOptions(Categorizacao__c.TipoCaso__c);
        response.categoriaPicklistOptions = GestaoSLAHelper.getActivePicklistOptions(Categorizacao__c.Categoria__c);
        response.assuntoOptions = GestaoSLAHelper.getActivePicklistOptions(Categorizacao__c.Assunto__c);
        response.subassuntoOptions = GestaoSLAHelper.getActivePicklistOptions(Categorizacao__c.Subassunto__c);
        response.unidadesDisponiveis = allowedUnidades == null ? null : new List<String>(allowedUnidades);
        response.unidadeUnica = (allowedUnidades != null && allowedUnidades.size() == 1)
            ? new List<String>(allowedUnidades)[0]
            : null;

        List<GestaoSLA__c> gestaoRows = allowedUnidades == null
            ? GestaoSLASelector.selectActive()
            : GestaoSLASelector.selectActiveByUnidades(allowedUnidades);
        for (GestaoSLA__c row : gestaoRows) {
            response.gestoes.add(toGestaoResumo(row, perms.canAdminTechnicalSettings));
        }
        return response;
    }

    public static GestaoSLADTO.GestaoDetailResponse getGestaoDetail(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        List<GestaoSLA__c> rows = GestaoSLASelector.selectById(gestaoSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Gestão de SLA não encontrada.');
        }
        GestaoSLAHelper.ensureUnidadeAllowed(rows[0].UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));

        Integer totalCategorias = GestaoSLACategoriaSelector.countByGestaoSLA(gestaoSLAId);
        Integer totalMarcosAtivos = GestaoSLAMarcoSelector.countActiveByGestaoSLA(gestaoSLAId);
        Integer totalRegrasAtivas = GestaoSLARegraSelector.countActiveByGestaoSLA(gestaoSLAId);
        List<AggregateResult> areasResult = GestaoSLARegraSelector.selectDistinctActiveAreasByGestaoSLA(gestaoSLAId);
        Integer totalAreasInternas = areasResult.size();

        GestaoSLADTO.GestaoDetailResponse response = new GestaoSLADTO.GestaoDetailResponse();
        response.permissions = perms;
        response.gestao = toGestaoResumo(rows[0], perms.canAdminTechnicalSettings);
        response.summary = new GestaoSLADTO.SummaryInfo();
        response.summary.totalCategorias = totalCategorias;
        response.summary.totalMarcosAtivos = totalMarcosAtivos;
        response.summary.totalRegrasAtivas = totalRegrasAtivas;
        response.summary.totalAreasInternas = totalAreasInternas;
        return response;
    }

    public static GestaoSLADTO.InactiveGestoesResponse getInactiveGestoes() {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (perms.canAdminTechnicalSettings != true) {
            throw new FunctionalException('Você não possui permissão para consultar Gestões de SLA inativas.');
        }

        GestaoSLADTO.InactiveGestoesResponse response = new GestaoSLADTO.InactiveGestoesResponse();
        response.permissions = perms;
        response.gestoesInativas = new List<GestaoSLADTO.GestaoResumo>();

        for (GestaoSLA__c row : GestaoSLASelector.selectInactive()) {
            response.gestoesInativas.add(toGestaoResumo(row, true));
        }

        return response;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static GestaoSLADTO.GestaoDetailResponse reactivateGestaoSLA(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (perms.canAdminTechnicalSettings != true) {
            throw new FunctionalException('Você não possui permissão para reativar Gestão de SLA.');
        }
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        List<GestaoSLA__c> rows = GestaoSLASelector.selectActivationFieldsById(gestaoSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Gestão de SLA não encontrada.');
        }

        GestaoSLA__c target = rows[0];
        if (target.Ativo__c == true) {
            return getGestaoDetail(target.Id);
        }

        Integer duplicidadeUnidade = GestaoSLASelector.countActiveByUnidadeNegocioExcluding(target.UnidadeNegocio__c, target.Id);
        if (duplicidadeUnidade > 0) {
            throw new FunctionalException('Já existe uma Gestão de SLA ativa para esta Unidade de Negócio.');
        }

        Integer duplicidadeEntitlement = GestaoSLASelector.countActiveByEntitlementProcessExcluding(target.EntitlementProcessName__c, target.Id);
        if (duplicidadeEntitlement > 0) {
            throw new FunctionalException('Já existe uma Gestão de SLA ativa para este Entitlement Process.');
        }

        GestaoSLA__c reactivation = (GestaoSLA__c) GestaoSLAHelper.sanitizeForUpdate(
            new GestaoSLA__c(Id = target.Id, Ativo__c = true),
            'Você não possui permissão (FLS/CRUD) para atualizar Gestões de SLA.'
        );
        update reactivation;
        return getGestaoDetail(target.Id);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static GestaoSLADTO.GestaoDetailResponse createGestaoSLA(GestaoSLADTO.CreateGestaoRequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (perms.canAdminTechnicalSettings != true) {
            throw new FunctionalException('Você não possui permissão para criar Gestão de SLA.');
        }
        if (request == null) {
            throw new FunctionalException('Nome da Gestão de SLA é obrigatório.');
        }
        if (String.isBlank(request.name)) {
            throw new FunctionalException('Nome da Gestão de SLA é obrigatório.');
        }
        if (String.isBlank(request.unidadeNegocio)) {
            throw new FunctionalException('Unidade de Negócio é obrigatória.');
        }
        if (String.isBlank(request.entitlementProcessName)) {
            throw new FunctionalException('Entitlement Process é obrigatório.');
        }
        if (String.isBlank(request.businessHoursName)) {
            throw new FunctionalException('Business Hours é obrigatório.');
        }
        validateTempoUnico('Triagem', request.usaTempoTriagem, request.tempoTriagemMinutos);
        validateTempoUnico('Resposta Chat', request.usaTempoRespostaChat, request.tempoRespostaChatMinutos);
        validateTempoUnico('Fila de Email', request.usaTempoFilaEmail, request.tempoFilaEmailMinutos);

        String unidade = request.unidadeNegocio.trim();
        String entitlementProcess = request.entitlementProcessName.trim();

        Integer duplicidadeUnidade = GestaoSLASelector.countActiveByUnidadeNegocio(unidade);
        if (duplicidadeUnidade > 0) {
            throw new FunctionalException('Já existe uma Gestão de SLA ativa para esta Unidade de Negócio.');
        }

        Integer duplicidadeEntitlement = GestaoSLASelector.countActiveByEntitlementProcess(entitlementProcess);
        if (duplicidadeEntitlement > 0) {
            throw new FunctionalException('Já existe uma Gestão de SLA ativa para este Entitlement Process.');
        }

        Boolean usaTriagem = request.usaTempoTriagem == true;
        Boolean usaRespostaChat = request.usaTempoRespostaChat == true;
        Boolean usaFilaEmail = request.usaTempoFilaEmail == true;

        GestaoSLA__c novaGestao = new GestaoSLA__c(
            Name = request.name.trim(),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = entitlementProcess,
            BusinessHoursName__c = request.businessHoursName.trim(),
            UsaTempoTriagem__c = usaTriagem,
            TempoTriagemMinutos__c = usaTriagem ? request.tempoTriagemMinutos : null,
            UsaTempoRespostaChat__c = usaRespostaChat,
            TempoRespostaChatMinutos__c = usaRespostaChat ? request.tempoRespostaChatMinutos : null,
            UsaTempoFilaEmail__c = usaFilaEmail,
            TempoFilaEmailMinutos__c = usaFilaEmail ? request.tempoFilaEmailMinutos : null,
            Descricao__c = String.isBlank(request.descricao) ? null : request.descricao.trim(),
            StaticResourceName__c = String.isBlank(request.staticResourceName) ? null : request.staticResourceName.trim(),
            Ativo__c = request.ativo == null ? true : request.ativo
        );
        novaGestao = (GestaoSLA__c) GestaoSLAHelper.sanitizeForCreate(
            novaGestao,
            'Você não possui permissão (FLS/CRUD) para criar Gestões de SLA.'
        );
        insert novaGestao;
        GestaoSLAMarcoService.syncMarcosUnicos(novaGestao.Id, usaTriagem, usaRespostaChat, usaFilaEmail);
        return getGestaoDetail(novaGestao.Id);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static GestaoSLADTO.GestaoDetailResponse updateGestaoSLA(GestaoSLADTO.UpdateGestaoRequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        Boolean isAdmin = perms.canAdminTechnicalSettings == true;
        Boolean isGestor = perms.canManageCategories == true;
        if (!isAdmin && !isGestor) {
            throw new FunctionalException('Você não possui permissão para editar Gestão de SLA.');
        }
        if (request == null || request.id == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        List<GestaoSLA__c> rows = GestaoSLASelector.selectEditableFieldsById(request.id);
        if (rows.isEmpty()) {
            throw new FunctionalException('Gestão de SLA não encontrada.');
        }
        GestaoSLA__c currentGestao = rows[0];
        GestaoSLAHelper.ensureUnidadeAllowed(currentGestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));

        // Gestor (GestaoSLAConfigurador / canManageCategories, não Admin Técnico) só edita os
        // valores de tempo dos marcos já habilitados. Campos estruturais e os checkboxes
        // "Usa Tempo de X?" são sempre preservados no valor atual, independentemente do que vier
        // no request — defesa em profundidade, já que a UI também desabilita esses campos para ele.
        if (!isAdmin) {
            request.name = currentGestao.Name;
            request.unidadeNegocio = currentGestao.UnidadeNegocio__c;
            request.entitlementProcessName = currentGestao.EntitlementProcessName__c;
            request.businessHoursName = currentGestao.BusinessHoursName__c;
            request.descricao = currentGestao.Descricao__c;
            request.staticResourceName = currentGestao.StaticResourceName__c;
            request.ativo = currentGestao.Ativo__c;
            request.usaTempoTriagem = currentGestao.UsaTempoTriagem__c;
            request.usaTempoRespostaChat = currentGestao.UsaTempoRespostaChat__c;
            request.usaTempoFilaEmail = currentGestao.UsaTempoFilaEmail__c;
        }

        if (String.isBlank(request.name)) {
            throw new FunctionalException('Nome da Gestão de SLA é obrigatório.');
        }
        if (String.isBlank(request.unidadeNegocio)) {
            throw new FunctionalException('Unidade de Negócio é obrigatória.');
        }
        if (String.isBlank(request.entitlementProcessName)) {
            throw new FunctionalException('Entitlement Process é obrigatório.');
        }
        if (String.isBlank(request.businessHoursName)) {
            throw new FunctionalException('Business Hours é obrigatório.');
        }

        validateTempoUnico('Triagem', request.usaTempoTriagem, request.tempoTriagemMinutos);
        validateTempoUnico('Resposta Chat', request.usaTempoRespostaChat, request.tempoRespostaChatMinutos);
        validateTempoUnico('Fila de Email', request.usaTempoFilaEmail, request.tempoFilaEmailMinutos);

        String unidade = request.unidadeNegocio.trim();
        String entitlementProcess = request.entitlementProcessName.trim();
        Boolean ativoFinal = request.ativo == null ? currentGestao.Ativo__c : request.ativo;

        if (ativoFinal) {
            Integer duplicidadeUnidade = GestaoSLASelector.countActiveByUnidadeNegocioExcluding(unidade, request.id);
            if (duplicidadeUnidade > 0) {
                throw new FunctionalException('Já existe uma Gestão de SLA ativa para esta Unidade de Negócio.');
            }

            Integer duplicidadeEntitlement = GestaoSLASelector.countActiveByEntitlementProcessExcluding(entitlementProcess, request.id);
            if (duplicidadeEntitlement > 0) {
                throw new FunctionalException('Já existe uma Gestão de SLA ativa para este Entitlement Process.');
            }
        }

        Boolean usaTriagem = request.usaTempoTriagem == true;
        Boolean usaRespostaChat = request.usaTempoRespostaChat == true;
        Boolean usaFilaEmail = request.usaTempoFilaEmail == true;

        GestaoSLA__c toUpdate = new GestaoSLA__c(
            Id = request.id,
            Name = request.name.trim(),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = entitlementProcess,
            BusinessHoursName__c = request.businessHoursName.trim(),
            UsaTempoTriagem__c = usaTriagem,
            TempoTriagemMinutos__c = usaTriagem ? request.tempoTriagemMinutos : null,
            UsaTempoRespostaChat__c = usaRespostaChat,
            TempoRespostaChatMinutos__c = usaRespostaChat ? request.tempoRespostaChatMinutos : null,
            UsaTempoFilaEmail__c = usaFilaEmail,
            TempoFilaEmailMinutos__c = usaFilaEmail ? request.tempoFilaEmailMinutos : null,
            Descricao__c = String.isBlank(request.descricao) ? null : request.descricao.trim(),
            StaticResourceName__c = String.isBlank(request.staticResourceName) ? null : request.staticResourceName.trim(),
            Ativo__c = ativoFinal
        );
        toUpdate = (GestaoSLA__c) GestaoSLAHelper.sanitizeForUpdate(
            toUpdate,
            'Você não possui permissão (FLS/CRUD) para atualizar Gestões de SLA.'
        );
        update toUpdate;
        GestaoSLAMarcoService.syncMarcosUnicos(request.id, usaTriagem, usaRespostaChat, usaFilaEmail);
        return getGestaoDetail(request.id);
    }

    /**
     * @description Valida que o tempo único de um marco foi informado (>0) quando o marco está marcado como utilizado.
     * Quando não utilizado, o valor é ignorado e o campo é limpo no momento da gravação.
     * @param label Nome funcional do marco, usado na mensagem de erro.
     * @param usa Flag "Usa Tempo de X?" vinda do request.
     * @param tempo Valor de tempo (minutos) informado para o marco.
     */
    private static void validateTempoUnico(String label, Boolean usa, Integer tempo) {
        if (usa == true && (tempo == null || tempo <= 0)) {
            throw new FunctionalException('Tempo de ' + label + ' deve ser maior que zero quando "Usa Tempo de ' + label + '?" estiver marcado.');
        }
    }

    /**
     * @description Exclui definitivamente uma Gestão de SLA. Bloqueia a exclusão se ainda existirem
     *              Categorizações vinculadas, para evitar órfãos (o relacionamento é Lookup, não cascade).
     *              Restrito ao Admin Técnico.
     * @param gestaoSLAId Id da GestaoSLA__c a excluir.
     **/
    public static void deleteGestaoSLA(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanDelete(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }
        if (!Schema.sObjectType.GestaoSLA__c.isDeletable()) {
            throw new FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Gestões de SLA.');
        }

        List<GestaoSLA__c> rows = GestaoSLASelector.selectGestaoIdById(gestaoSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Gestão de SLA não encontrada.');
        }

        Integer categoriasVinculadas = GestaoSLACategoriaSelector.countByGestaoSLA(gestaoSLAId);
        if (categoriasVinculadas > 0) {
            throw new FunctionalException('Não é possível excluir: existem Categorizações vinculadas a esta Gestão de SLA. Exclua ou reatribua as categorizações antes.');
        }

        delete rows[0];
    }

    private static GestaoSLADTO.GestaoResumo toGestaoResumo(GestaoSLA__c row, Boolean canAdminTechnicalSettings) {
        GestaoSLADTO.GestaoResumo dto = new GestaoSLADTO.GestaoResumo();
        dto.id = row.Id;
        dto.name = row.Name;
        dto.unidadeNegocio = row.UnidadeNegocio__c;
        dto.ativo = row.Ativo__c;
        dto.descricao = row.Descricao__c;
        dto.usaTempoTriagem = row.UsaTempoTriagem__c == true;
        dto.tempoTriagemMinutos = row.TempoTriagemMinutos__c;
        dto.usaTempoRespostaChat = row.UsaTempoRespostaChat__c == true;
        dto.tempoRespostaChatMinutos = row.TempoRespostaChatMinutos__c;
        dto.usaTempoFilaEmail = row.UsaTempoFilaEmail__c == true;
        dto.tempoFilaEmailMinutos = row.TempoFilaEmailMinutos__c;
        dto.staticResourceName = canAdminTechnicalSettings ? row.StaticResourceName__c : null;
        dto.entitlementProcessName = canAdminTechnicalSettings ? row.EntitlementProcessName__c : null;
        dto.businessHoursName = canAdminTechnicalSettings ? row.BusinessHoursName__c : null;
        return dto;
    }
}
