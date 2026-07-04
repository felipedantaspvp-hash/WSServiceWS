/**
 * @description CRUD administrativo de MarcoSLA__c para a tela de Gestão de SLA, extraído de
 * GestaoSLAService.cls (Pacote 44 — divisão do God Object em serviços por domínio). Lança
 * GestaoSLAService.FunctionalException (tipo mantido na fachada original para não alterar o
 * catch já existente em GestaoSLAController.cls).
 */
public inherited sharing class GestaoSLAMarcoService {

    public static GestaoSLADTO.MarcosResponse getMarcos(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }

        GestaoSLADTO.MarcosResponse response = new GestaoSLADTO.MarcosResponse();
        response.permissions = perms;
        response.marcos = new List<GestaoSLADTO.MarcoResumo>();

        for (MarcoSLA__c row : GestaoSLAMarcoSelector.selectMarcosByGestaoSLA(gestaoSLAId)) {
            response.marcos.add(toMarcoResumo(row, perms.canAdminTechnicalSettings == true));
        }

        return response;
    }

    /**
     * @description Cria um novo Marco SLA vinculado a uma Gestão de SLA. Restrito a quem administra
     * configurações técnicas (Custom Permission AdministrarConfiguracoesGestaoSLA).
     * @param request MarcoSLARequest com os dados do novo marco.
     * @return MarcoResumo com o registro criado.
     **/
    public static GestaoSLADTO.MarcoResumo createMarcoSLA(GestaoSLADTO.MarcoSLARequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanAdminTechnicalSettings(perms);
        validateMarcoRequest(request);

        GestaoSLA__c gestao = GestaoSLAHelper.loadGestaoOrThrow(request.gestaoSLAId);
        GestaoSLAHelper.ensureUnidadeAllowed(gestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
        validateMarcoDuplicateMilestoneType(request.gestaoSLAId, request.milestoneTypeName, null);

        MarcoSLA__c row = new MarcoSLA__c(
            Name = request.nomeMarco.trim(),
            GestaoSLA__c = request.gestaoSLAId,
            NomeMarco__c = request.nomeMarco.trim(),
            MilestoneTypeName__c = request.milestoneTypeName.trim()
        );
        applyMarcoFields(row, request);
        try {
            insert row;
        } catch (DmlException dmx) {
            throw new GestaoSLAService.FunctionalException(dmx.getDmlMessage(0));
        }
        return toMarcoResumo(queryMarcoById(row.Id), true);
    }

    /**
     * @description Atualiza os campos administráveis de um Marco SLA existente. Restrito a quem administra
     * configurações técnicas (Custom Permission AdministrarConfiguracoesGestaoSLA).
     * @param request MarcoSLARequest com id e campos a atualizar.
     * @return MarcoResumo com o registro atualizado.
     **/
    public static GestaoSLADTO.MarcoResumo updateMarcoSLA(GestaoSLADTO.MarcoSLARequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanAdminTechnicalSettings(perms);
        if (request == null || request.id == null) {
            throw new GestaoSLAService.FunctionalException('Marco SLA não encontrado.');
        }
        validateMarcoRequest(request);

        MarcoSLA__c existing = queryMarcoById(request.id);
        if (existing == null) {
            throw new GestaoSLAService.FunctionalException('Marco SLA não encontrado.');
        }
        if (request.gestaoSLAId == null || request.gestaoSLAId != existing.GestaoSLA__c) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestao = GestaoSLAHelper.loadGestaoOrThrow(existing.GestaoSLA__c);
        GestaoSLAHelper.ensureUnidadeAllowed(gestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
        validateMarcoDuplicateMilestoneType(existing.GestaoSLA__c, request.milestoneTypeName, existing.Id);

        existing.NomeMarco__c = request.nomeMarco.trim();
        existing.Name = request.nomeMarco.trim();
        existing.MilestoneTypeName__c = request.milestoneTypeName.trim();
        applyMarcoFields(existing, request);
        try {
            update existing;
        } catch (DmlException dmx) {
            throw new GestaoSLAService.FunctionalException(dmx.getDmlMessage(0));
        }
        return toMarcoResumo(queryMarcoById(existing.Id), true);
    }

    /**
     * @description Desativa um Marco SLA, impedindo que continue sendo usado em novas Regras de SLA.
     * Restrito a quem administra configurações técnicas (Custom Permission AdministrarConfiguracoesGestaoSLA).
     * @param marcoSLAId Id do MarcoSLA__c a desativar.
     * @return MarcoResumo com status atualizado para inativo.
     **/
    public static GestaoSLADTO.MarcoResumo deactivateMarcoSLA(Id marcoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanAdminTechnicalSettings(perms);
        MarcoSLA__c row = queryMarcoById(marcoSLAId);
        if (row == null) {
            throw new GestaoSLAService.FunctionalException('Marco SLA não encontrado.');
        }
        GestaoSLA__c gestao = GestaoSLAHelper.loadGestaoOrThrow(row.GestaoSLA__c);
        GestaoSLAHelper.ensureUnidadeAllowed(gestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));

        row.Ativo__c = false;
        update row;
        return toMarcoResumo(row, true);
    }

    /**
     * @description Reativa um Marco SLA previamente desativado. Restrito a quem administra configurações
     * técnicas (Custom Permission AdministrarConfiguracoesGestaoSLA).
     * @param marcoSLAId Id do MarcoSLA__c a reativar.
     * @return MarcoResumo com status atualizado para ativo.
     **/
    public static GestaoSLADTO.MarcoResumo reactivateMarcoSLA(Id marcoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanAdminTechnicalSettings(perms);
        MarcoSLA__c row = queryMarcoById(marcoSLAId);
        if (row == null) {
            throw new GestaoSLAService.FunctionalException('Marco SLA não encontrado.');
        }
        GestaoSLA__c gestao = GestaoSLAHelper.loadGestaoOrThrow(row.GestaoSLA__c);
        GestaoSLAHelper.ensureUnidadeAllowed(gestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
        if (row.Ativo__c == true) {
            return toMarcoResumo(row, true);
        }
        validateMarcoDuplicateMilestoneType(row.GestaoSLA__c, row.MilestoneTypeName__c, row.Id);

        row.Ativo__c = true;
        update row;
        return toMarcoResumo(row, true);
    }

    /**
     * @description Exclui definitivamente um Marco SLA. Bloqueia a exclusão se ainda existirem Regras de
     *              SLA vinculadas, para evitar que o lookup seja silenciosamente nulificado (deleteConstraint
     *              SetNull) e a regra perca o marco a que se aplica. Restrito ao Admin Técnico.
     * @param marcoSLAId Id do MarcoSLA__c a excluir.
     **/
    public static void deleteMarcoSLA(Id marcoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanDelete(perms);
        if (marcoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Marco SLA não informado.');
        }
        if (!Schema.sObjectType.MarcoSLA__c.isDeletable()) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Marcos de SLA.');
        }

        MarcoSLA__c row = queryMarcoById(marcoSLAId);
        if (row == null) {
            throw new GestaoSLAService.FunctionalException('Marco SLA não encontrado.');
        }

        Integer regrasVinculadas = GestaoSLARegraSelector.countByMarcoSLA(marcoSLAId);
        if (regrasVinculadas > 0) {
            throw new GestaoSLAService.FunctionalException('Não é possível excluir: existem Regras de SLA vinculadas a este Marco. Exclua ou reatribua as regras antes.');
        }

        delete row;
    }

    /**
     * @description Sincroniza os MarcoSLA__c de tempo único (Triagem, Resposta Chat, Fila Email) de uma Gestão de SLA
     * com os checkboxes "Usa Tempo de X?" definidos pelo Admin na tela. Cria o marco quando ainda não existir,
     * reativa quando estiver inativo, ou desativa quando deixar de ser utilizado — nunca exclui (preserva histórico
     * de CaseMilestone). O motor (CaseMilestoneTriggerTimeCalculator) lê esses marcos por MilestoneTypeName__c,
     * independente de como foram criados. Chamado por GestaoSLAService.createGestaoSLA/updateGestaoSLA.
     * @param gestaoId Id da Gestão de SLA afetada.
     * @param usaTriagem Estado atual do checkbox de Triagem.
     * @param usaRespostaChat Estado atual do checkbox de Resposta Chat.
     * @param usaFilaEmail Estado atual do checkbox de Fila de Email.
     */
    public static void syncMarcosUnicos(Id gestaoId, Boolean usaTriagem, Boolean usaRespostaChat, Boolean usaFilaEmail) {
        syncMarcoUnico(gestaoId, 'Triagem', usaTriagem, 1);
        syncMarcoUnico(gestaoId, 'Resposta Chat', usaRespostaChat, 2);
        syncMarcoUnico(gestaoId, 'Fila Email', usaFilaEmail, 3);
    }

    public static void syncMarcoUnico(Id gestaoId, String milestoneTypeName, Boolean usar, Integer ordem) {
        List<MarcoSLA__c> existing = GestaoSLAMarcoSelector.selectMarcoByGestaoAndMilestoneTypeName(gestaoId, milestoneTypeName);
        if (usar == true) {
            if (existing.isEmpty()) {
                insert new MarcoSLA__c(
                    Name = milestoneTypeName,
                    GestaoSLA__c = gestaoId,
                    NomeMarco__c = milestoneTypeName,
                    MilestoneTypeName__c = milestoneTypeName,
                    FonteTempo__c = 'GestaoSLA',
                    Ordem__c = ordem,
                    Recorrente__c = false,
                    TipoRecorrencia__c = 'NaoRecorrente',
                    UsaCategorizacao__c = false,
                    UsaAreaInterna__c = false,
                    UsaOrigem__c = false,
                    Ativo__c = true
                );
            } else if (existing[0].Ativo__c != true) {
                update new MarcoSLA__c(Id = existing[0].Id, Ativo__c = true);
            }
        } else if (!existing.isEmpty() && existing[0].Ativo__c == true) {
            update new MarcoSLA__c(Id = existing[0].Id, Ativo__c = false);
        }
    }

    private static void validateMarcoRequest(GestaoSLADTO.MarcoSLARequest request) {
        if (request == null || request.gestaoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }
        if (String.isBlank(request.nomeMarco)) {
            throw new GestaoSLAService.FunctionalException('Nome do Marco é obrigatório.');
        }
        if (String.isBlank(request.milestoneTypeName)) {
            throw new GestaoSLAService.FunctionalException('Nome do Milestone Type é obrigatório.');
        }
        if (request.recorrente == true && String.isBlank(request.tipoRecorrencia)) {
            throw new GestaoSLAService.FunctionalException('Tipo de Recorrência é obrigatório quando o marco é recorrente.');
        }
    }

    private static void validateMarcoDuplicateMilestoneType(Id gestaoSLAId, String milestoneTypeName, Id excludeMarcoId) {
        List<MarcoSLA__c> existing = GestaoSLAMarcoSelector.selectMarcoByGestaoAndMilestoneTypeName(gestaoSLAId, milestoneTypeName);
        if (!existing.isEmpty() && existing[0].Id != excludeMarcoId) {
            throw new GestaoSLAService.FunctionalException('Já existe um Marco SLA para este Milestone Type nesta Gestão de SLA.');
        }
    }

    private static void applyMarcoFields(MarcoSLA__c row, GestaoSLADTO.MarcoSLARequest request) {
        row.FonteTempo__c = String.isBlank(request.fonteTempo) ? null : request.fonteTempo.trim();
        row.Ordem__c = request.ordem;
        row.Recorrente__c = request.recorrente == true;
        row.TipoRecorrencia__c = request.recorrente == true ? request.tipoRecorrencia : null;
        row.UsaCategorizacao__c = request.usaCategorizacao == true;
        row.UsaAreaInterna__c = request.usaAreaInterna == true;
        row.UsaOrigem__c = request.usaOrigem == true;
        row.TempoFallbackMinutos__c = request.tempoFallbackMinutos;
        row.Ativo__c = request.ativo == null ? true : request.ativo;
    }

    private static MarcoSLA__c queryMarcoById(Id marcoId) {
        List<MarcoSLA__c> rows = GestaoSLAMarcoSelector.selectMarcoFullById(marcoId);
        return rows.isEmpty() ? null : rows[0];
    }

    private static GestaoSLADTO.MarcoResumo toMarcoResumo(MarcoSLA__c row, Boolean showTechnical) {
        GestaoSLADTO.MarcoResumo dto = new GestaoSLADTO.MarcoResumo();
        dto.id = row.Id;
        dto.gestaoSLAId = row.GestaoSLA__c;
        dto.name = row.Name;
        dto.nomeMarco = row.NomeMarco__c;
        dto.milestoneTypeName = showTechnical ? row.MilestoneTypeName__c : null;
        dto.fonteTempo = row.FonteTempo__c;
        dto.ordem = row.Ordem__c;
        dto.recorrente = row.Recorrente__c;
        dto.tipoRecorrencia = row.TipoRecorrencia__c;
        dto.usaCategorizacao = row.UsaCategorizacao__c;
        dto.usaAreaInterna = row.UsaAreaInterna__c;
        dto.usaOrigem = row.UsaOrigem__c;
        dto.tempoFallbackMinutos = showTechnical ? row.TempoFallbackMinutos__c : null;
        dto.ativo = row.Ativo__c;
        return dto;
    }
}
