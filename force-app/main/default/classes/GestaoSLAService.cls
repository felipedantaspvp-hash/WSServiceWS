public inherited sharing class GestaoSLAService {
    public class FunctionalException extends Exception {}
    public static GestaoSLADTO.BootstrapResponse getBootstrap() {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        Set<String> allowedUnidades = resolveAllowedUnidades(perms);
        if (allowedUnidades != null && allowedUnidades.isEmpty()) {
            throw new FunctionalException('Nenhuma Unidade de Negócio disponível para o seu usuário. Verifique o Record Type de Case atribuído ao seu perfil/permission set.');
        }

        GestaoSLADTO.BootstrapResponse response = new GestaoSLADTO.BootstrapResponse();
        response.permissions = perms;
        response.gestoes = new List<GestaoSLADTO.GestaoResumo>();
        response.unidadeNegocioOptions = getActivePicklistOptions(GestaoSLA__c.UnidadeNegocio__c);
        response.tipoCasoOptions = getActivePicklistOptions(Categorizacao__c.TipoCaso__c);
        response.categoriaPicklistOptions = getActivePicklistOptions(Categorizacao__c.Categoria__c);
        response.assuntoOptions = getActivePicklistOptions(Categorizacao__c.Assunto__c);
        response.subassuntoOptions = getActivePicklistOptions(Categorizacao__c.Subassunto__c);
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
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        List<GestaoSLA__c> rows = GestaoSLASelector.selectById(gestaoSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Gestão de SLA não encontrada.');
        }
        ensureUnidadeAllowed(rows[0].UnidadeNegocio__c, resolveAllowedUnidades(perms));

        Integer totalCategorias = GestaoSLASelector.countCategoriasByGestaoSLA(gestaoSLAId);
        Integer totalMarcosAtivos = GestaoSLASelector.countActiveMarcosByGestaoSLA(gestaoSLAId);
        Integer totalRegrasAtivas = GestaoSLASelector.countActiveRegrasByGestaoSLA(gestaoSLAId);
        List<AggregateResult> areasResult = GestaoSLASelector.selectDistinctActiveAreasByGestaoSLA(gestaoSLAId);
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

    public static GestaoSLADTO.CategoriasResponse getCategorias(
        Id gestaoSLAId,
        String searchTerm,
        String tipoCaso,
        String categoria,
        String assunto,
        Boolean ativo
    ) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestaoCtx = loadGestaoOrThrow(gestaoSLAId);
        ensureUnidadeAllowed(gestaoCtx.UnidadeNegocio__c, resolveAllowedUnidades(perms));

        List<Categorizacao__c> categoriasRows = GestaoSLASelector.selectCategoriasByGestaoSLA(gestaoSLAId);

        Map<Id, Integer> regrasAtivasByCateg = new Map<Id, Integer>();
        for (AggregateResult ar : GestaoSLASelector.countActiveRegrasByCategorizacao(gestaoSLAId)) {
            regrasAtivasByCateg.put((Id) ar.get('categId'), (Integer) ar.get('total'));
        }

        String normalizedSearch = GestaoSLAHelper.normalizeText(searchTerm);
        String normalizedTipoCaso = GestaoSLAHelper.normalizeText(tipoCaso);
        String normalizedCategoria = GestaoSLAHelper.normalizeText(categoria);
        String normalizedAssunto = GestaoSLAHelper.normalizeText(assunto);

        GestaoSLADTO.CategoriasResponse response = new GestaoSLADTO.CategoriasResponse();
        response.permissions = perms;
        response.categorias = new List<GestaoSLADTO.CategoriaResumo>();

        for (Categorizacao__c row : categoriasRows) {
            if (!String.isBlank(normalizedSearch)) {
                String haystack = GestaoSLAHelper.normalizeText(
                    String.valueOf(row.Name) + ' ' + String.valueOf(row.Categoria__c) + ' ' +
                    String.valueOf(row.Assunto__c) + ' ' + String.valueOf(row.Subassunto__c)
                );
                if (!haystack.contains(normalizedSearch)) continue;
            }
            if (!String.isBlank(normalizedTipoCaso) && GestaoSLAHelper.normalizeText(row.TipoCaso__c) != normalizedTipoCaso) continue;
            if (!String.isBlank(normalizedCategoria) && GestaoSLAHelper.normalizeText(row.Categoria__c) != normalizedCategoria) continue;
            if (!String.isBlank(normalizedAssunto) && GestaoSLAHelper.normalizeText(row.Assunto__c) != normalizedAssunto) continue;
            if (ativo != null && row.Ativo__c != ativo) continue;

            Integer totalRegrasAtivas = regrasAtivasByCateg.containsKey(row.Id) ? regrasAtivasByCateg.get(row.Id) : 0;
            response.categorias.add(toCategoriaResumo(row, totalRegrasAtivas));
        }

        return response;
    }

    public static GestaoSLADTO.MarcosResponse getMarcos(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        GestaoSLADTO.MarcosResponse response = new GestaoSLADTO.MarcosResponse();
        response.permissions = perms;
        response.marcos = new List<GestaoSLADTO.MarcoResumo>();

        for (MarcoSLA__c row : GestaoSLASelector.selectMarcosByGestaoSLA(gestaoSLAId)) {
            GestaoSLADTO.MarcoResumo dto = new GestaoSLADTO.MarcoResumo();
            dto.id = row.Id;
            dto.name = row.Name;
            dto.nomeMarco = row.NomeMarco__c;
            dto.milestoneTypeName = perms.canAdminTechnicalSettings ? row.MilestoneTypeName__c : null;
            dto.fonteTempo = row.FonteTempo__c;
            dto.ordem = row.Ordem__c;
            dto.recorrente = row.Recorrente__c;
            dto.tipoRecorrencia = row.TipoRecorrencia__c;
            dto.usaCategorizacao = row.UsaCategorizacao__c;
            dto.usaAreaInterna = row.UsaAreaInterna__c;
            dto.usaOrigem = row.UsaOrigem__c;
            dto.ativo = row.Ativo__c;
            response.marcos.add(dto);
        }

        return response;
    }

    public static GestaoSLADTO.RegrasSLAResponse getRegrasSLA(
        Id gestaoSLAId,
        Id categorizacaoId,
        Id marcoSLAId,
        String escopo,
        String areaAtendimento,
        Boolean ativo
    ) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        String normalizedEscopo = normalizeOptionalFilter(escopo);
        String normalizedArea = normalizeOptionalFilter(areaAtendimento);

        GestaoSLADTO.RegrasSLAResponse response = new GestaoSLADTO.RegrasSLAResponse();
        response.permissions = perms;
        response.regras = new List<GestaoSLADTO.RegraSLAResumo>();

        for (RegrasSLACategorizacao__c row : GestaoSLASelector.selectRegrasByGestaoSLA(gestaoSLAId)) {
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
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageRules(perms);
        validateRegraSLARequest(request, false);

        validateRegraReferences(request);
        request.ativo = true;
        validateRegraDuplicateActive(request, null);

        RegrasSLACategorizacao__c row = new RegrasSLACategorizacao__c(
            GestaoSLA__c = request.gestaoSLAId,
            Categorizacao__c = request.categorizacaoId,
            MarcoSLA__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO ? request.marcoSLAId : null,
            EscopoRegra__c = request.escopoRegra,
            AreaAtendimento__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA ? normalizeOptionalText(request.areaAtendimento) : null,
            TempoBaixa__c = request.tempoBaixa,
            TempoMedia__c = request.tempoMedia,
            TempoAlta__c = request.tempoAlta,
            Ativo__c = true
        );
        insert row;
        return loadRegraResumoById(row.Id);
    }

    public static GestaoSLADTO.RegraSLAResumo updateRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageRules(perms);
        if (request == null || request.id == null) {
            throw new FunctionalException('Regra de SLA não encontrada.');
        }
        validateRegraSLARequest(request, true);

        List<RegrasSLACategorizacao__c> rows = GestaoSLASelector.selectRegraById(request.id);
        if (rows.isEmpty()) {
            throw new FunctionalException('Regra de SLA não encontrada.');
        }
        if (request.gestaoSLAId == null || request.gestaoSLAId != rows[0].GestaoSLA__c) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }

        request.ativo = rows[0].Ativo__c;
        validateRegraReferences(request);
        validateRegraDuplicateActive(request, request.id);

        RegrasSLACategorizacao__c row = new RegrasSLACategorizacao__c(
            Id = request.id,
            Categorizacao__c = request.categorizacaoId,
            MarcoSLA__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO ? request.marcoSLAId : null,
            EscopoRegra__c = request.escopoRegra,
            AreaAtendimento__c = request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA ? normalizeOptionalText(request.areaAtendimento) : null,
            TempoBaixa__c = request.tempoBaixa,
            TempoMedia__c = request.tempoMedia,
            TempoAlta__c = request.tempoAlta,
            Ativo__c = rows[0].Ativo__c
        );
        update row;
        return loadRegraResumoById(row.Id);
    }

    public static GestaoSLADTO.RegraSLAResumo deactivateRegraSLA(Id regraSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageRules(perms);
        if (regraSLAId == null) {
            throw new FunctionalException('Regra de SLA não encontrada.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLASelector.selectRegraById(regraSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Regra de SLA não encontrada.');
        }

        RegrasSLACategorizacao__c row = rows[0];
        row.Ativo__c = false;
        update row;
        return loadRegraResumoById(row.Id);
    }

    public static GestaoSLADTO.RegraSLAResumo activateRegraSLA(Id regraSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageRules(perms);
        if (regraSLAId == null) {
            throw new FunctionalException('Regra de SLA não encontrada.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLASelector.selectRegraById(regraSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Regra de SLA não encontrada.');
        }

        RegrasSLACategorizacao__c row = rows[0];
        row.Ativo__c = true;
        update row;
        return loadRegraResumoById(row.Id);
    }

    public static List<String> getAreasInternas() {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        return getActivePicklistValues(RegrasSLACategorizacao__c.AreaAtendimento__c);
    }

    public static List<GestaoSLADTO.RegraSLAResumo> createRegrasSLABulk(List<GestaoSLADTO.RegraSLARequest> requests) {
        if (requests == null || requests.isEmpty()) return new List<GestaoSLADTO.RegraSLAResumo>();

        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageRules(perms);

        Id gestaoSLAId = requests[0].gestaoSLAId;
        Id categorizacaoId = requests[0].categorizacaoId;

        loadGestaoOrThrow(gestaoSLAId);
        if (categorizacaoId != null) {
            List<Categorizacao__c> cats = GestaoSLASelector.selectCategoriaByIdAndGestaoSLA(categorizacaoId, gestaoSLAId);
            if (cats.isEmpty()) {
                throw new FunctionalException('Categorização não pertence à Gestão de SLA informada.');
            }
        }

        Map<String, RegrasSLACategorizacao__c> existingByArea = new Map<String, RegrasSLACategorizacao__c>();
        for (RegrasSLACategorizacao__c r : GestaoSLASelector.selectActiveAreaRulesByGestaoCategorizacao(gestaoSLAId, categorizacaoId)) {
            existingByArea.put(normalizeOptionalText(r.AreaAtendimento__c), r);
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

            String normalizedArea = normalizeOptionalText(request.areaAtendimento);
            if (processedAreas.contains(normalizedArea)) {
                throw new FunctionalException('Área duplicada na mesma requisição: ' + request.areaAtendimento);
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
        for (RegrasSLACategorizacao__c r : GestaoSLASelector.selectRegraDetailByIds(affectedIds)) {
            results.add(toRegraSLAResumo(r));
        }
        return results;
    }

    public static GestaoSLADTO.CategoriaResumo createCategoria(GestaoSLADTO.CategoriaRequest request) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageCategories(perms);
        validateCategoriaRequest(request, false);

        GestaoSLA__c gestao = loadGestaoOrThrow(request.gestaoSLAId);
        ensureUnidadeAllowed(gestao.UnidadeNegocio__c, resolveAllowedUnidades(perms));
        String prioridade = String.isBlank(request.prioridadeSugerida)
            ? null
            : normalizePrioridadeOrThrow(request.prioridadeSugerida);
        String subassunto = String.isBlank(request.subassunto) ? null : request.subassunto.trim();
        validateCategoriaDuplicateActive(
            request.gestaoSLAId,
            request.tipoCaso,
            request.categoria,
            request.assunto,
            subassunto,
            null
        );

        Categorizacao__c row = new Categorizacao__c(
            GestaoSLA__c = request.gestaoSLAId,
            UnidadeNegocios__c = normalizeUnidadeNegocioForCategorizacao(gestao.UnidadeNegocio__c),
            TipoCaso__c = request.tipoCaso.trim(),
            Categoria__c = request.categoria.trim(),
            Assunto__c = request.assunto.trim(),
            Subassunto__c = subassunto,
            Prioridade__c = prioridade,
            Ativo__c = request.ativo == null ? true : request.ativo
        );
        applyDistribuicaoRequest(row, request);
        try {
            insert row;
        } catch (DmlException dmx) {
            throw new FunctionalException(dmx.getDmlMessage(0));
        }
        return toCategoriaResumo(queryCategoriaById(row.Id), 0);
    }

    public static GestaoSLADTO.CategoriaResumo updateCategoria(GestaoSLADTO.CategoriaRequest request) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageCategories(perms);
        if (request == null || request.id == null) {
            throw new FunctionalException('Categorização não encontrada.');
        }
        validateCategoriaRequest(request, true);

        List<Categorizacao__c> rows = GestaoSLASelector.selectCategoriaById(request.id);
        if (rows.isEmpty()) {
            throw new FunctionalException('Categorização não encontrada.');
        }

        Categorizacao__c existing = rows[0];
        if (request.gestaoSLAId == null || request.gestaoSLAId != existing.GestaoSLA__c) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestao = loadGestaoOrThrow(existing.GestaoSLA__c);
        ensureUnidadeAllowed(gestao.UnidadeNegocio__c, resolveAllowedUnidades(perms));
        String prioridade = String.isBlank(request.prioridadeSugerida)
            ? null
            : normalizePrioridadeOrThrow(request.prioridadeSugerida);
        String subassunto = String.isBlank(request.subassunto) ? null : request.subassunto.trim();

        validateCategoriaDuplicateActive(
            existing.GestaoSLA__c,
            request.tipoCaso,
            request.categoria,
            request.assunto,
            subassunto,
            existing.Id
        );

        // UnidadeNegocios__c is a mirrored classification attribute and is not editable in this flow.
        // Preserve the stored value to avoid cross-object picklist mismatch in update operations.
        existing.TipoCaso__c = request.tipoCaso.trim();
        existing.Categoria__c = request.categoria.trim();
        existing.Assunto__c = request.assunto.trim();
        existing.Subassunto__c = subassunto;
        existing.Prioridade__c = prioridade;
        existing.Ativo__c = request.ativo == null ? existing.Ativo__c : request.ativo;
        applyDistribuicaoRequest(existing, request);
        try {
            update existing;
        } catch (DmlException dmx) {
            throw new FunctionalException(dmx.getDmlMessage(0));
        }
        return toCategoriaResumo(queryCategoriaById(existing.Id), 0);
    }

    /**
     * @description Aplica os campos de distribuição (fila/campo/valor) ao registro de Categorizacao__c
     * a partir do request da tela. As regras de obrigatoriedade (fila obrigatória, campo+valor obrigatórios
     * quando não é por categorização) são validadas pelo CategorizacaoTriggerHandler -> CategorizacaoService.beforeSave,
     * que roda em qualquer insert/update do objeto — não precisam ser duplicadas aqui.
     * @param row Registro de Categorizacao__c a ser gravado (criação ou edição).
     * @param request Dados de distribuição informados na tela de Gestão de SLA.
     */
    private static void applyDistribuicaoRequest(Categorizacao__c row, GestaoSLADTO.CategoriaRequest request) {
        Boolean distribuir = request != null && request.distribuirParaFila == true;
        row.DistribuirParaFila__c = distribuir ? 'Sim' : 'Não';
        if (!distribuir) {
            row.PorCampoCustomizado__c = 'Não';
            row.FilaDeveloperName__c = null;
            row.CampoDistribuicao__c = null;
            row.ValorDistribuicao__c = null;
            return;
        }
        Boolean porCampoCustomizado = request.porCampoCustomizado == true;
        row.PorCampoCustomizado__c = porCampoCustomizado ? 'Sim' : 'Não';
        row.FilaDeveloperName__c = String.isBlank(request.filaDeveloperName) ? null : request.filaDeveloperName.trim();
        if (!porCampoCustomizado) {
            row.CampoDistribuicao__c = null;
            row.ValorDistribuicao__c = null;
        } else {
            row.CampoDistribuicao__c = String.isBlank(request.campoDistribuicao) ? null : request.campoDistribuicao.trim();
            row.ValorDistribuicao__c = String.isBlank(request.valorDistribuicao) ? null : request.valorDistribuicao.trim();
        }
    }

    private static Categorizacao__c queryCategoriaById(Id categoriaId) {
        List<Categorizacao__c> rows = GestaoSLASelector.selectCategoriaById(categoriaId);
        return rows.isEmpty() ? null : rows[0];
    }

    public static GestaoSLADTO.CategoriaResumo deactivateCategoria(Id categoriaId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageCategories(perms);
        if (categoriaId == null) {
            throw new FunctionalException('Categorização não encontrada.');
        }

        List<Categorizacao__c> rows = GestaoSLASelector.selectCategoriaById(categoriaId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Categorização não encontrada.');
        }

        Categorizacao__c row = rows[0];
        GestaoSLA__c gestaoCtxDeactivate = loadGestaoOrThrow(row.GestaoSLA__c);
        ensureUnidadeAllowed(gestaoCtxDeactivate.UnidadeNegocio__c, resolveAllowedUnidades(perms));
        row.Ativo__c = false;
        row.MotivoInativacao__c = 'Inativação via Gestão de SLA';
        update row;
        return toCategoriaResumo(row, 0);
    }

    public static GestaoSLADTO.InactiveCategoriasResponse getInactiveCategorias(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageCategories(perms);
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestaoCtxInactive = loadGestaoOrThrow(gestaoSLAId);
        ensureUnidadeAllowed(gestaoCtxInactive.UnidadeNegocio__c, resolveAllowedUnidades(perms));

        GestaoSLADTO.InactiveCategoriasResponse response = new GestaoSLADTO.InactiveCategoriasResponse();
        response.permissions = perms;
        response.categoriasInativas = new List<GestaoSLADTO.CategoriaResumo>();

        for (Categorizacao__c row : GestaoSLASelector.selectInactiveCategoriasByGestaoSLA(gestaoSLAId)) {
            response.categoriasInativas.add(toCategoriaResumo(row, 0));
        }

        return response;
    }

    public static GestaoSLADTO.CategoriaResumo reactivateCategoria(Id categoriaId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageCategories(perms);
        if (categoriaId == null) {
            throw new FunctionalException('Categorização não encontrada.');
        }

        List<Categorizacao__c> rows = GestaoSLASelector.selectCategoriaById(categoriaId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Categorização não encontrada.');
        }

        Categorizacao__c row = rows[0];
        GestaoSLA__c gestaoCtxReactivate = loadGestaoOrThrow(row.GestaoSLA__c);
        ensureUnidadeAllowed(gestaoCtxReactivate.UnidadeNegocio__c, resolveAllowedUnidades(perms));
        if (row.Ativo__c == true) {
            return toCategoriaResumo(row, 0);
        }
        validateCategoriaDuplicateActive(
            row.GestaoSLA__c,
            row.TipoCaso__c,
            row.Categoria__c,
            row.Assunto__c,
            row.Subassunto__c,
            row.Id
        );
        row.Ativo__c = true;
        row.MotivoInativacao__c = null;
        update row;
        return toCategoriaResumo(row, 0);
    }

    public static GestaoSLADTO.InactiveGestoesResponse getInactiveGestoes() {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
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

    public static GestaoSLADTO.GestaoDetailResponse reactivateGestaoSLA(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
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

        update new GestaoSLA__c(Id = target.Id, Ativo__c = true);
        return getGestaoDetail(target.Id);
    }

    public static GestaoSLADTO.GestaoDetailResponse createGestaoSLA(GestaoSLADTO.CreateGestaoRequest request) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
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
        insert novaGestao;
        syncMarcosUnicos(novaGestao.Id, usaTriagem, usaRespostaChat, usaFilaEmail);
        return getGestaoDetail(novaGestao.Id);
    }

    public static GestaoSLADTO.GestaoDetailResponse updateGestaoSLA(GestaoSLADTO.UpdateGestaoRequest request) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
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
        ensureUnidadeAllowed(currentGestao.UnidadeNegocio__c, resolveAllowedUnidades(perms));

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
        update toUpdate;
        syncMarcosUnicos(request.id, usaTriagem, usaRespostaChat, usaFilaEmail);
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
     * @description Sincroniza os MarcoSLA__c de tempo único (Triagem, Resposta Chat, Fila Email) de uma Gestão de SLA
     * com os checkboxes "Usa Tempo de X?" definidos pelo Admin na tela. Cria o marco quando ainda não existir,
     * reativa quando estiver inativo, ou desativa quando deixar de ser utilizado — nunca exclui (preserva histórico
     * de CaseMilestone). O motor (CaseMilestoneTriggerTimeCalculator) lê esses marcos por MilestoneTypeName__c,
     * independente de como foram criados.
     * @param gestaoId Id da Gestão de SLA afetada.
     * @param usaTriagem Estado atual do checkbox de Triagem.
     * @param usaRespostaChat Estado atual do checkbox de Resposta Chat.
     * @param usaFilaEmail Estado atual do checkbox de Fila de Email.
     */
    private static void syncMarcosUnicos(Id gestaoId, Boolean usaTriagem, Boolean usaRespostaChat, Boolean usaFilaEmail) {
        syncMarcoUnico(gestaoId, 'Triagem', usaTriagem, 1);
        syncMarcoUnico(gestaoId, 'Resposta Chat', usaRespostaChat, 2);
        syncMarcoUnico(gestaoId, 'Fila Email', usaFilaEmail, 3);
    }

    private static void syncMarcoUnico(Id gestaoId, String milestoneTypeName, Boolean usar, Integer ordem) {
        List<MarcoSLA__c> existing = GestaoSLASelector.selectMarcoByGestaoAndMilestoneTypeName(gestaoId, milestoneTypeName);
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

    /**
     * @description Resolve as Unidades de Negócio que o usuário corrente pode acessar na Gestão de SLA.
     * Admin Técnico (canAdminTechnicalSettings) tem acesso irrestrito (retorna null).
     * Demais usuários são restritos às unidades derivadas do Record Type de Case disponível para eles.
     * @param perms Permissões já resolvidas do usuário corrente.
     * @return Set de Unidades de Negócio permitidas, ou null se irrestrito.
     */
    private static Set<String> resolveAllowedUnidades(GestaoSLADTO.PermissionInfo perms) {
        if (perms != null && perms.canAdminTechnicalSettings == true) {
            return null;
        }
        return GestaoSLAHelper.getAllowedUnidadesNegocio();
    }

    /**
     * @description Garante que a Unidade de Negócio de um registro está dentro do conjunto permitido
     * para o usuário corrente. Não faz nada quando allowedUnidades é null (acesso irrestrito).
     * @param unidadeNegocio Unidade de Negócio do registro sendo acessado/alterado.
     * @param allowedUnidades Unidades permitidas para o usuário, ou null se irrestrito.
     */
    private static void ensureUnidadeAllowed(String unidadeNegocio, Set<String> allowedUnidades) {
        if (allowedUnidades == null) {
            return;
        }
        if (String.isBlank(unidadeNegocio) || !allowedUnidades.contains(unidadeNegocio)) {
            throw new FunctionalException('Você não possui Record Type disponível para a Unidade de Negócio "' + unidadeNegocio + '".');
        }
    }

    private static GestaoSLADTO.PermissionInfo buildPermissionInfo() {
        GestaoSLADTO.PermissionInfo perms = new GestaoSLADTO.PermissionInfo();
        perms.canAccessGestaoSLA = GestaoSLAHelper.canAccessGestaoSLA();
        perms.canManageCategories = GestaoSLAHelper.canManageCategories();
        perms.canManageRules = GestaoSLAHelper.canManageRules();
        perms.canAdminTechnicalSettings = GestaoSLAHelper.canAdminTechnicalSettings();
        return perms;
    }

    private static void ensureCanAccess(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canAccessGestaoSLA != true) {
            throw new FunctionalException('Você não possui permissão para acessar a Gestão de SLA.');
        }
    }

    private static void ensureCanManageCategories(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canManageCategories != true) {
            throw new FunctionalException('Você não possui permissão para gerenciar categorias.');
        }
    }

    private static void ensureCanManageRules(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canManageRules != true) {
            throw new FunctionalException('Você não possui permissão para gerenciar regras de SLA.');
        }
    }

    private static void ensureCanDelete(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canAdminTechnicalSettings != true) {
            throw new FunctionalException('Você não possui permissão para excluir registros de Gestão de SLA.');
        }
    }

    /**
     * @description Exclui definitivamente uma Regra de SLA. Restrito ao Admin Técnico.
     * @param regraSLAId Id da RegrasSLACategorizacao__c a excluir.
     **/
    public static void deleteRegraSLA(Id regraSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanDelete(perms);
        if (regraSLAId == null) {
            throw new FunctionalException('Regra de SLA não informada.');
        }
        if (!Schema.sObjectType.RegrasSLACategorizacao__c.isDeletable()) {
            throw new FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Regras de SLA.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLASelector.selectRegraById(regraSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Regra de SLA não encontrada.');
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

        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanManageRules(perms);
        if (!Schema.sObjectType.RegrasSLACategorizacao__c.isDeletable()) {
            throw new FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Regras de SLA.');
        }

        List<RegrasSLACategorizacao__c> rows = GestaoSLASelector.selectByIds(new Set<Id>(regraIds));
        if (!rows.isEmpty()) delete rows;
    }

    /**
     * @description Exclui definitivamente uma Categorização e, por master-detail, suas Regras de SLA filhas.
     *              Restrito ao Admin Técnico.
     * @param categoriaId Id da Categorizacao__c a excluir.
     **/
    public static void deleteCategoria(Id categoriaId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanDelete(perms);
        if (categoriaId == null) {
            throw new FunctionalException('Categorização não informada.');
        }
        if (!Schema.sObjectType.Categorizacao__c.isDeletable()) {
            throw new FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Categorizações.');
        }

        List<Categorizacao__c> rows = GestaoSLASelector.selectCategoriaIdById(categoriaId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Categorização não encontrada.');
        }
        delete rows[0];
    }

    /**
     * @description Exclui definitivamente uma Gestão de SLA. Bloqueia a exclusão se ainda existirem
     *              Categorizações vinculadas, para evitar órfãos (o relacionamento é Lookup, não cascade).
     *              Restrito ao Admin Técnico.
     * @param gestaoSLAId Id da GestaoSLA__c a excluir.
     **/
    public static void deleteGestaoSLA(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = buildPermissionInfo();
        ensureCanAccess(perms);
        ensureCanDelete(perms);
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

        Integer categoriasVinculadas = GestaoSLASelector.countCategoriasByGestaoSLA(gestaoSLAId);
        if (categoriasVinculadas > 0) {
            throw new FunctionalException('Não é possível excluir: existem Categorizações vinculadas a esta Gestão de SLA. Exclua ou reatribua as categorizações antes.');
        }

        delete rows[0];
    }

    private static GestaoSLA__c loadGestaoOrThrow(Id gestaoSLAId) {
        if (gestaoSLAId == null) {
            throw new FunctionalException('Gestão de SLA não informada.');
        }
        List<GestaoSLA__c> rows = GestaoSLASelector.selectUnidadeById(gestaoSLAId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Gestão de SLA não encontrada.');
        }
        return rows[0];
    }

    private static void validateRegraSLARequest(GestaoSLADTO.RegraSLARequest request, Boolean isUpdate) {
        if (request == null) throw new FunctionalException('Gestão de SLA não informada.');
        if (request.gestaoSLAId == null) throw new FunctionalException('Gestão de SLA não informada.');
        if (String.isBlank(request.escopoRegra)) throw new FunctionalException('Tipo de regra é obrigatório.');
        request.escopoRegra = normalizeEscopoRegra(request.escopoRegra);

        if (!hasPositiveTime(request)) {
            throw new FunctionalException('Informe pelo menos um tempo de SLA maior que zero.');
        }
        validatePositiveTime(request.tempoBaixa, 'Tempo Baixa');
        validatePositiveTime(request.tempoMedia, 'Tempo Média');
        validatePositiveTime(request.tempoAlta, 'Tempo Alta');

        if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO) {
            if (request.marcoSLAId == null) {
                throw new FunctionalException('Marco SLA é obrigatório para regra de Atendimento.');
            }
            if (request.categorizacaoId == null) {
                throw new FunctionalException('Categorização é obrigatória para regra de Atendimento.');
            }
        } else if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA) {
            if (request.categorizacaoId == null) {
                throw new FunctionalException('Categorização é obrigatória para regra de Área Interna.');
            }
            if (String.isBlank(request.areaAtendimento)) {
                throw new FunctionalException('Área interna é obrigatória para regra de Área Interna.');
            }
        }

        request.areaAtendimento = normalizeOptionalText(request.areaAtendimento);
        validatePicklistValue('Área interna', RegrasSLACategorizacao__c.AreaAtendimento__c, request.areaAtendimento);
    }

    private static void validateRegraReferences(GestaoSLADTO.RegraSLARequest request) {
        loadGestaoOrThrow(request.gestaoSLAId);

        if (request.marcoSLAId != null) {
            List<MarcoSLA__c> marcos = GestaoSLASelector.selectMarcoByIdAndGestaoSLA(request.marcoSLAId, request.gestaoSLAId);
            if (marcos.isEmpty()) {
                throw new FunctionalException('Marco SLA não pertence à Gestão de SLA informada.');
            }
        }

        if (request.categorizacaoId != null) {
            List<Categorizacao__c> categoriasRows = GestaoSLASelector.selectCategoriaByIdAndGestaoSLA(request.categorizacaoId, request.gestaoSLAId);
            if (categoriasRows.isEmpty()) {
                throw new FunctionalException('Categorização não pertence à Gestão de SLA informada.');
            }
        }
    }

    private static void validateRegraDuplicateActive(GestaoSLADTO.RegraSLARequest request, Id excludeId) {
        if (request.ativo == false) {
            return;
        }

        if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO) {
            for (RegrasSLACategorizacao__c row : GestaoSLASelector.selectActiveByGestaoMarcoEscopo(request.gestaoSLAId, request.marcoSLAId, request.escopoRegra)) {
                if (excludeId != null && row.Id == excludeId) continue;
                if (row.Categorizacao__c == request.categorizacaoId) {
                    throw new FunctionalException('Já existe uma regra de SLA ativa com esta combinação.');
                }
            }
        } else if (request.escopoRegra == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA) {
            String normalizedArea = normalizeOptionalText(request.areaAtendimento);
            for (RegrasSLACategorizacao__c row : GestaoSLASelector.selectActiveByGestaoCategorizacaoEscopo(request.gestaoSLAId, request.categorizacaoId, request.escopoRegra)) {
                if (excludeId != null && row.Id == excludeId) continue;
                if (normalizeOptionalText(row.AreaAtendimento__c) == normalizedArea) {
                    throw new FunctionalException('Já existe uma regra de SLA ativa com esta combinação.');
                }
            }
        }
    }

    private static GestaoSLADTO.RegraSLAResumo loadRegraResumoById(Id regraId) {
        List<RegrasSLACategorizacao__c> rows = GestaoSLASelector.selectRegraDetailById(regraId);
        if (rows.isEmpty()) {
            throw new FunctionalException('Regra de SLA não encontrada.');
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
        throw new FunctionalException('Tipo de regra inválido. Use "Atendimento" ou "Area Interna".');
    }

    private static Boolean hasPositiveTime(GestaoSLADTO.RegraSLARequest request) {
        return isPositive(request.tempoBaixa) || isPositive(request.tempoMedia) || isPositive(request.tempoAlta);
    }

    private static Boolean isPositive(Integer value) {
        return value != null && value > 0;
    }

    private static void validatePositiveTime(Integer value, String label) {
        if (value != null && value <= 0) {
            throw new FunctionalException(label + ' deve ser maior que zero.');
        }
    }

    private static String normalizeOptionalText(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    private static void validatePicklistValue(String label, Schema.SObjectField fieldRef, String value) {
        if (String.isBlank(value)) {
            return;
        }
        Schema.DescribeFieldResult describeResult = fieldRef.getDescribe();
        if (!describeResult.isRestrictedPicklist()) {
            return;
        }
        Set<String> allowedValues = new Set<String>();
        for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
            if (entry != null && entry.isActive()) {
                allowedValues.add(entry.getValue());
            }
        }
        if (!allowedValues.isEmpty() && !allowedValues.contains(value)) {
            throw new FunctionalException(label + ' inválida.');
        }
    }

    private static List<String> getActivePicklistValues(Schema.SObjectField fieldRef) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
            if (entry != null && entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    private static List<GestaoSLADTO.PicklistOptionDTO> getActivePicklistOptions(Schema.SObjectField fieldRef) {
        List<GestaoSLADTO.PicklistOptionDTO> options = new List<GestaoSLADTO.PicklistOptionDTO>();
        for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
            if (entry == null || !entry.isActive()) continue;
            GestaoSLADTO.PicklistOptionDTO opt = new GestaoSLADTO.PicklistOptionDTO();
            opt.label = entry.getLabel();
            opt.value = entry.getValue();
            options.add(opt);
        }
        return options;
    }

    private static void validateCategoriaRequest(GestaoSLADTO.CategoriaRequest request, Boolean isUpdate) {
        if (request == null) throw new FunctionalException('Gestão de SLA não informada.');
        if (request.gestaoSLAId == null) throw new FunctionalException('Gestão de SLA não informada.');
        if (String.isBlank(request.tipoCaso)) throw new FunctionalException('Tipo de Caso é obrigatório.');
        if (String.isBlank(request.categoria)) throw new FunctionalException('Categoria é obrigatória.');
        if (String.isBlank(request.assunto)) throw new FunctionalException('Assunto é obrigatório.');
        validatePicklistValue('Tipo de Caso', Categorizacao__c.TipoCaso__c, request.tipoCaso);
        validatePicklistValue('Categoria', Categorizacao__c.Categoria__c, request.categoria);
        validatePicklistValue('Assunto', Categorizacao__c.Assunto__c, request.assunto);
        validatePicklistValue('Subassunto', Categorizacao__c.Subassunto__c, request.subassunto);
    }

    private static String normalizePrioridadeOrThrow(String prioridadeInput) {
        String normalized = GestaoSLAHelper.normalizeText(prioridadeInput).replace('é', 'e');
        if (normalized == 'baixa' || normalized == 'low') return 'Low';
        if (normalized == 'media' || normalized == 'medium') return 'Medium';
        if (normalized == 'alta' || normalized == 'high') return 'High';
        throw new FunctionalException('Prioridade sugerida inválida.');
    }

    private static String normalizeUnidadeNegocioForCategorizacao(String unidadeInput) {
        if (String.isBlank(unidadeInput)) {
            return unidadeInput;
        }
        String trimmed = unidadeInput.trim();
        Set<String> allowed = new Set<String>();
        for (Schema.PicklistEntry pe : Categorizacao__c.UnidadeNegocios__c.getDescribe().getPicklistValues()) {
            if (pe != null && pe.isActive()) {
                allowed.add(pe.getValue());
            }
        }
        if (allowed.contains(trimmed)) {
            return trimmed;
        }
        if (trimmed.startsWith('Atendimento ')) {
            String semPrefixo = trimmed.replaceFirst('^Atendimento\\s+', '');
            if (allowed.contains(semPrefixo)) {
                return semPrefixo;
            }
        }
        return trimmed;
    }

    private static void validateCategoriaDuplicateActive(Id gestaoSLAId, String tipoCaso, String categoria, String assunto, String subassunto, Id excludeId) {
        List<Categorizacao__c> dupRows = GestaoSLASelector.selectDuplicateActiveCategoria(
            gestaoSLAId, tipoCaso, categoria, assunto, subassunto, excludeId
        );
        if (!dupRows.isEmpty()) {
            throw new FunctionalException('Já existe uma categorização ativa com esta combinação.');
        }
    }

    private static GestaoSLADTO.CategoriaResumo toCategoriaResumo(Categorizacao__c row, Integer totalRegrasAtivas) {
        GestaoSLADTO.CategoriaResumo dto = new GestaoSLADTO.CategoriaResumo();
        dto.id = row.Id;
        dto.name = row.Name;
        dto.unidadeNegocio = row.UnidadeNegocios__c;
        dto.tipoCaso = row.TipoCaso__c;
        dto.categoria = row.Categoria__c;
        dto.assunto = row.Assunto__c;
        dto.subassunto = row.Subassunto__c;
        dto.prioridadeSugerida = row.Prioridade__c;
        dto.ativo = row.Ativo__c;
        dto.totalRegrasAtivas = totalRegrasAtivas;
        dto.distribuirParaFila = CategorizacaoHelper.isTrueFlag(row.DistribuirParaFila__c);
        dto.porCampoCustomizado = CategorizacaoHelper.isTrueFlag(row.PorCampoCustomizado__c);
        dto.filaDeveloperName = row.FilaDeveloperName__c;
        dto.nomeFilaDistribuicao = row.NomeFilaDistribuicao__c;
        dto.campoDistribuicao = row.CampoDistribuicao__c;
        dto.valorDistribuicao = row.ValorDistribuicao__c;
        dto.labelCampoDistribuicao = row.LabelCampoDistribuicao__c;
        dto.labelValorDistribuicao = row.LabelValorDistribuicao__c;
        return dto;
    }

    private static GestaoSLADTO.RegraSLAResumo toRegraSLAResumo(RegrasSLACategorizacao__c row) {
        GestaoSLADTO.RegraSLAResumo dto = new GestaoSLADTO.RegraSLAResumo();
        dto.id = row.Id;
        dto.gestaoSLAId = row.GestaoSLA__c;
        dto.categorizacaoId = row.Categorizacao__c;
        dto.categorizacaoNome = buildCategorizacaoLabel(row.Categorizacao__r);
        dto.marcoSLAId = row.MarcoSLA__c;
        dto.marcoNome = row.MarcoSLA__r == null
            ? null
            : (String.isBlank(row.MarcoSLA__r.NomeMarco__c) ? row.MarcoSLA__r.Name : row.MarcoSLA__r.NomeMarco__c);
        dto.escopoRegra = row.EscopoRegra__c;
        dto.areaAtendimento = row.AreaAtendimento__c;
        dto.tempoBaixa = toInteger(row.TempoBaixa__c);
        dto.tempoMedia = toInteger(row.TempoMedia__c);
        dto.tempoAlta = toInteger(row.TempoAlta__c);
        dto.ativo = row.Ativo__c;
        return dto;
    }

    private static String buildCategorizacaoLabel(Categorizacao__c row) {
        if (row == null) {
            return null;
        }
        List<String> parts = new List<String>();
        if (!String.isBlank(row.Categoria__c)) parts.add(row.Categoria__c);
        if (!String.isBlank(row.Assunto__c)) parts.add(row.Assunto__c);
        if (!String.isBlank(row.Subassunto__c)) parts.add(row.Subassunto__c);
        return parts.isEmpty() ? row.Name : String.join(parts, ' / ');
    }

    private static Integer toInteger(Decimal value) {
        return value == null ? null : value.intValue();
    }

    private static String normalizeOptionalFilter(String value) {
        if (String.isBlank(value) || value == 'Todos' || value == 'Todas') {
            return null;
        }
        return GestaoSLAHelper.normalizeText(value);
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