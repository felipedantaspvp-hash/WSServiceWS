/**
 * @description Serviço de CRUD administrativo de Regras de SLA (RegrasSLACategorizacao__c),
 * extraído de GestaoSLAService.cls (Pacote 44 — divisão do God Object em serviços por domínio).
 */
public inherited sharing class GestaoSLARegraService {
    public static GestaoSLADTO.RegrasSLAResponse getRegrasSLA(
        Id gestaoSLAId,
        Id categorizacaoId,
        Id marcoSLAId,
        String escopo,
        String areaAtendimento,
        Boolean ativo
    ) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }

        String normalizedEscopo = GestaoSLAHelper.normalizeOptionalFilter(escopo);
        String normalizedArea = GestaoSLAHelper.normalizeOptionalFilter(areaAtendimento);

        GestaoSLADTO.RegrasSLAResponse response = new GestaoSLADTO.RegrasSLAResponse();
        response.permissions = perms;
        response.regras = new List<GestaoSLADTO.RegraSLAResumo>();

        for (RegrasSLACategorizacao__c row : GestaoSLARegraSelector.selectRegrasByGestaoSLA(gestaoSLAId)) {
            if (categorizacaoId != null && row.Categorizacao__c != categorizacaoId) continue;
            if (marcoSLAId != null && row.MarcoSLA__c != null && row.MarcoSLA__c != marcoSLAId) continue;
            if (ativo != null && row.Ativo__c != ativo) continue;
            if (!String.isBlank(normalizedEscopo) && GestaoSLAHelper.normalizeText(row.EscopoRegra__c) != normalizedEscopo) continue;
            if (!String.isBlank(normalizedArea) && GestaoSLAHelper.normalizeText(row.AreaAtendimento__c) != normalizedArea) continue;

            response.regras.add(toRegraSLAResumo(row));
        }

        return response;
    }

    public static GestaoSLADTO.RegraSLAResumo createRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageRules(perms);
        validateRegraSLARequest(request, false);

        validateRegraReferences(request);
        request.ativo = true;
        validateRegraDuplicateActive(request, null);

        RegrasSLACategorizacao__c row = new RegrasSLACategorizacao__c(
            GestaoSLA__c = request.gestaoSLAId,
            Categorizacao__c = request.categorizacaoId,
            MarcoSLA__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO ? request.marcoSLAId : null,
            EscopoRegra__c = request.escopoRegra,
            AreaAtendimento__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA ? GestaoSLAHelper.normalizeOptionalText(request.areaAtendimento) : null,
            TempoBaixa__c = request.tempoBaixa,
            TempoMedia__c = request.tempoMedia,
            TempoAlta__c = request.tempoAlta,
            Ativo__c = true
        );
        insert row;
        return loadRegraResumoById(row.Id);
    }

    public static GestaoSLADTO.RegraSLAResumo updateRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageRules(perms);
        if (request == null || request.id == null) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }
        validateRegraSLARequest(request, true);

        List<RegrasSLACategorizacao__c> rows = GestaoSLARegraSelector.selectRegraById(request.id);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }
        if (request.gestaoSLAId == null || request.gestaoSLAId != rows[0].GestaoSLA__c) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }

        request.ativo = rows[0].Ativo__c;
        validateRegraReferences(request);
        validateRegraDuplicateActive(request, request.id);

        RegrasSLACategorizacao__c row = new RegrasSLACategorizacao__c(
            Id = request.id,
            Categorizacao__c = request.categorizacaoId,
            MarcoSLA__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO ? request.marcoSLAId : null,
            EscopoRegra__c = request.escopoRegra,
            AreaAtendimento__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA ? GestaoSLAHelper.normalizeOptionalText(request.areaAtendimento) : null,
            TempoBaixa__c = request.tempoBaixa,
            TempoMedia__c = request.tempoMedia,
            TempoAlta__c = request.tempoAlta,
            Ativo__c = rows[0].Ativo__c
        );
        update row;
        return loadRegraResumoById(row.Id);
    }

    public static GestaoSLADTO.RegraSLAResumo deactivateRegraSLA(Id regraSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageRules(perms);
        if (regraSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLARegraSelector.selectRegraById(regraSLAId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }

        RegrasSLACategorizacao__c row = rows[0];
        row.Ativo__c = false;
        update row;
        return loadRegraResumoById(row.Id);
    }

    public static GestaoSLADTO.RegraSLAResumo activateRegraSLA(Id regraSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageRules(perms);
        if (regraSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLARegraSelector.selectRegraById(regraSLAId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }

        RegrasSLACategorizacao__c row = rows[0];
        row.Ativo__c = true;
        update row;
        return loadRegraResumoById(row.Id);
    }

    public static List<String> getAreasInternas() {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        return GestaoSLAHelper.getActivePicklistValues(RegrasSLACategorizacao__c.AreaAtendimento__c);
    }

    public static List<GestaoSLADTO.RegraSLAResumo> createRegrasSLABulk(List<GestaoSLADTO.RegraSLARequest> requests) {
        if (requests == null || requests.isEmpty()) return new List<GestaoSLADTO.RegraSLAResumo>();

        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageRules(perms);

        Id gestaoSLAId = requests[0].gestaoSLAId;
        Id categorizacaoId = requests[0].categorizacaoId;

        GestaoSLAHelper.loadGestaoOrThrow(gestaoSLAId);
        if (categorizacaoId != null) {
            List<Categorizacao__c> cats = GestaoSLACategoriaSelector.selectCategoriaByIdAndGestaoSLA(categorizacaoId, gestaoSLAId);
            if (cats.isEmpty()) {
                throw new GestaoSLAService.FunctionalException('Categorização não pertence à Gestão de SLA informada.');
            }
        }

        Map<String, RegrasSLACategorizacao__c> existingByArea = new Map<String, RegrasSLACategorizacao__c>();
        for (RegrasSLACategorizacao__c r : GestaoSLARegraSelector.selectActiveAreaRulesByGestaoCategorizacao(gestaoSLAId, categorizacaoId)) {
            existingByArea.put(GestaoSLAHelper.normalizeOptionalText(r.AreaAtendimento__c), r);
        }

        List<RegrasSLACategorizacao__c> toInsert = new List<RegrasSLACategorizacao__c>();
        List<RegrasSLACategorizacao__c> toUpdate = new List<RegrasSLACategorizacao__c>();
        Set<String> processedAreas = new Set<String>();

        for (GestaoSLADTO.RegraSLARequest request : requests) {
            request.escopoRegra = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA;
            request.gestaoSLAId = gestaoSLAId;
            request.categorizacaoId = categorizacaoId;
            request.ativo = true;
            validateRegraSLARequest(request, false);

            String normalizedArea = GestaoSLAHelper.normalizeOptionalText(request.areaAtendimento);
            if (processedAreas.contains(normalizedArea)) {
                throw new GestaoSLAService.FunctionalException('Área duplicada na mesma requisição: ' + request.areaAtendimento);
            }
            processedAreas.add(normalizedArea);

            RegrasSLACategorizacao__c existing = existingByArea.get(normalizedArea);
            if (existing != null) {
                existing.TempoBaixa__c = request.tempoBaixa;
                existing.TempoMedia__c = request.tempoMedia;
                existing.TempoAlta__c = request.tempoAlta;
                toUpdate.add(existing);
            } else {
                toInsert.add(new RegrasSLACategorizacao__c(
                    GestaoSLA__c = gestaoSLAId,
                    Categorizacao__c = categorizacaoId,
                    MarcoSLA__c = null,
                    EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
                    AreaAtendimento__c = normalizedArea,
                    TempoBaixa__c = request.tempoBaixa,
                    TempoMedia__c = request.tempoMedia,
                    TempoAlta__c = request.tempoAlta,
                    Ativo__c = true
                ));
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;

        Set<Id> affectedIds = new Set<Id>();
        for (RegrasSLACategorizacao__c r : toInsert) affectedIds.add(r.Id);
        for (RegrasSLACategorizacao__c r : toUpdate) affectedIds.add(r.Id);

        List<GestaoSLADTO.RegraSLAResumo> results = new List<GestaoSLADTO.RegraSLAResumo>();
        for (RegrasSLACategorizacao__c r : GestaoSLARegraSelector.selectRegraDetailByIds(affectedIds)) {
            results.add(toRegraSLAResumo(r));
        }
        return results;
    }

    /**
     * @description Exclui definitivamente uma Regra de SLA. Restrito ao Admin Técnico.
     * @param regraSLAId Id da RegrasSLACategorizacao__c a excluir.
     **/
    public static void deleteRegraSLA(Id regraSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanDelete(perms);
        if (regraSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não informada.');
        }
        if (!Schema.sObjectType.RegrasSLACategorizacao__c.isDeletable()) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Regras de SLA.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLARegraSelector.selectRegraById(regraSLAId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }
        delete rows[0];
    }

    /**
     * @description Exclui definitivamente um conjunto de Regras de SLA de Área Interna como
     *              consequência de limpar os campos de tempo na grid de edição em lote. Usa a
     *              mesma permissão de gerenciamento de regras (não exige Admin Técnico), pois é
     *              parte do fluxo normal de edição da grid.
     * @param regraIds Ids das RegrasSLACategorizacao__c a excluir.
     **/
    public static void deleteRegrasSLABulk(List<Id> regraIds) {
        if (regraIds == null || regraIds.isEmpty()) return;

        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageRules(perms);
        if (!Schema.sObjectType.RegrasSLACategorizacao__c.isDeletable()) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Regras de SLA.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLARegraSelector.selectByIds(new Set<Id>(regraIds));
        if (!rows.isEmpty()) delete rows;
    }

    private static void validateRegraSLARequest(GestaoSLADTO.RegraSLARequest request, Boolean isUpdate) {
        if (request == null) throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        if (request.gestaoSLAId == null) throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        if (String.isBlank(request.escopoRegra)) throw new GestaoSLAService.FunctionalException('Tipo de regra é obrigatório.');
        request.escopoRegra = normalizeEscopoRegra(request.escopoRegra);

        if (!hasPositiveTime(request)) {
            throw new GestaoSLAService.FunctionalException('Informe pelo menos um tempo de SLA maior que zero.');
        }
        validatePositiveTime(request.tempoBaixa, 'Tempo Baixa');
        validatePositiveTime(request.tempoMedia, 'Tempo Média');
        validatePositiveTime(request.tempoAlta, 'Tempo Alta');

        if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO) {
            if (request.marcoSLAId == null) {
                throw new GestaoSLAService.FunctionalException('Marco SLA é obrigatório para regra de Atendimento.');
            }
            if (request.categorizacaoId == null) {
                throw new GestaoSLAService.FunctionalException('Categorização é obrigatória para regra de Atendimento.');
            }
        } else if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA) {
            if (request.categorizacaoId == null) {
                throw new GestaoSLAService.FunctionalException('Categorização é obrigatória para regra de Área Interna.');
            }
            if (String.isBlank(request.areaAtendimento)) {
                throw new GestaoSLAService.FunctionalException('Área interna é obrigatória para regra de Área Interna.');
            }
        }

        request.areaAtendimento = GestaoSLAHelper.normalizeOptionalText(request.areaAtendimento);
        GestaoSLAHelper.validatePicklistValue('Área interna', RegrasSLACategorizacao__c.AreaAtendimento__c, request.areaAtendimento);
    }

    private static void validateRegraReferences(GestaoSLADTO.RegraSLARequest request) {
        GestaoSLAHelper.loadGestaoOrThrow(request.gestaoSLAId);

        if (request.marcoSLAId != null) {
            List<MarcoSLA__c> marcos = GestaoSLAMarcoSelector.selectMarcoByIdAndGestaoSLA(request.marcoSLAId, request.gestaoSLAId);
            if (marcos.isEmpty()) {
                throw new GestaoSLAService.FunctionalException('Marco SLA não pertence à Gestão de SLA informada.');
            }
        }

        if (request.categorizacaoId != null) {
            List<Categorizacao__c> categoriasRows = GestaoSLACategoriaSelector.selectCategoriaByIdAndGestaoSLA(request.categorizacaoId, request.gestaoSLAId);
            if (categoriasRows.isEmpty()) {
                throw new GestaoSLAService.FunctionalException('Categorização não pertence à Gestão de SLA informada.');
            }
        }
    }

    private static void validateRegraDuplicateActive(GestaoSLADTO.RegraSLARequest request, Id excludeId) {
        if (request.ativo == false) {
            return;
        }

        if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO) {
            for (RegrasSLACategorizacao__c row : GestaoSLARegraSelector.selectActiveByGestaoMarcoEscopo(request.gestaoSLAId, request.marcoSLAId, request.escopoRegra)) {
                if (excludeId != null && row.Id == excludeId) continue;
                if (row.Categorizacao__c == request.categorizacaoId) {
                    throw new GestaoSLAService.FunctionalException('Já existe uma regra de SLA ativa com esta combinação.');
                }
            }
        } else if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA) {
            String normalizedArea = GestaoSLAHelper.normalizeOptionalText(request.areaAtendimento);
            for (RegrasSLACategorizacao__c row : GestaoSLARegraSelector.selectActiveByGestaoCategorizacaoEscopo(request.gestaoSLAId, request.categorizacaoId, request.escopoRegra)) {
                if (excludeId != null && row.Id == excludeId) continue;
                if (GestaoSLAHelper.normalizeOptionalText(row.AreaAtendimento__c) == normalizedArea) {
                    throw new GestaoSLAService.FunctionalException('Já existe uma regra de SLA ativa com esta combinação.');
                }
            }
        }
    }

    private static GestaoSLADTO.RegraSLAResumo loadRegraResumoById(Id regraId) {
        List<RegrasSLACategorizacao__c> rows = GestaoSLARegraSelector.selectRegraDetailById(regraId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Regra de SLA não encontrada.');
        }
        return toRegraSLAResumo(rows[0]);
    }

    private static String normalizeEscopoRegra(String escopo) {
        String normalized = GestaoSLAHelper.normalizeText(escopo);
        if (normalized == GestaoSLAHelper.normalizeText(RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO)) {
            return RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO;
        }
        if (normalized == GestaoSLAHelper.normalizeText(RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA)) {
            return RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA;
        }
        throw new GestaoSLAService.FunctionalException('Tipo de regra inválido. Use "Atendimento" ou "Area Interna".');
    }

    private static Boolean hasPositiveTime(GestaoSLADTO.RegraSLARequest request) {
        return isPositive(request.tempoBaixa) || isPositive(request.tempoMedia) || isPositive(request.tempoAlta);
    }

    private static Boolean isPositive(Integer value) {
        return value != null && value > 0;
    }

    private static void validatePositiveTime(Integer value, String label) {
        if (value != null && value <= 0) {
            throw new GestaoSLAService.FunctionalException(label + ' deve ser maior que zero.');
        }
    }

    private static GestaoSLADTO.RegraSLAResumo toRegraSLAResumo(RegrasSLACategorizacao__c row) {
        GestaoSLADTO.RegraSLAResumo dto = new GestaoSLADTO.RegraSLAResumo();
        dto.id = row.Id;
        dto.gestaoSLAId = row.GestaoSLA__c;
        dto.categorizacaoId = row.Categorizacao__c;
        dto.categorizacaoNome = GestaoSLACategoriaService.buildCategorizacaoLabel(row.Categorizacao__r);
        dto.marcoSLAId = row.MarcoSLA__c;
        dto.marcoNome = row.MarcoSLA__r == null
            ? null
            : (String.isBlank(row.MarcoSLA__r.NomeMarco__c) ? row.MarcoSLA__r.Name : row.MarcoSLA__r.NomeMarco__c);
        dto.escopoRegra = row.EscopoRegra__c;
        dto.areaAtendimento = row.AreaAtendimento__c;
        dto.tempoBaixa = GestaoSLAHelper.toInteger(row.TempoBaixa__c);
        dto.tempoMedia = GestaoSLAHelper.toInteger(row.TempoMedia__c);
        dto.tempoAlta = GestaoSLAHelper.toInteger(row.TempoAlta__c);
        dto.ativo = row.Ativo__c;
        return dto;
    }
}
