/**
 * @description CRUD administrativo de Categorizacao__c para a tela de Gestão de SLA, extraído de
 * GestaoSLAService.cls (Pacote 44 — divisão do God Object em serviços por domínio). Lança
 * GestaoSLAService.FunctionalException (tipo mantido na fachada original para não alterar o
 * catch já existente em GestaoSLAController.cls).
 */
public inherited sharing class GestaoSLACategoriaService {

    public static GestaoSLADTO.CategoriasResponse getCategorias(
        Id gestaoSLAId,
        String searchTerm,
        String tipoCaso,
        String categoria,
        String assunto,
        Boolean ativo
    ) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        if (gestaoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestaoCtx = GestaoSLAHelper.loadGestaoOrThrow(gestaoSLAId);
        GestaoSLAHelper.ensureUnidadeAllowed(gestaoCtx.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));

        List<Categorizacao__c> categoriasRows = GestaoSLACategoriaSelector.selectCategoriasByGestaoSLA(gestaoSLAId);

        Map<Id, Integer> regrasAtivasByCateg = new Map<Id, Integer>();
        for (AggregateResult ar : GestaoSLARegraSelector.countActiveByCategorizacao(gestaoSLAId)) {
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

    public static GestaoSLADTO.CategoriaResumo createCategoria(GestaoSLADTO.CategoriaRequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageCategories(perms);
        validateCategoriaRequest(request, false);

        GestaoSLA__c gestao = GestaoSLAHelper.loadGestaoOrThrow(request.gestaoSLAId);
        GestaoSLAHelper.ensureUnidadeAllowed(gestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
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
            throw new GestaoSLAService.FunctionalException(dmx.getDmlMessage(0));
        }
        return toCategoriaResumo(queryCategoriaById(row.Id), 0);
    }

    public static GestaoSLADTO.CategoriaResumo updateCategoria(GestaoSLADTO.CategoriaRequest request) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageCategories(perms);
        if (request == null || request.id == null) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }
        validateCategoriaRequest(request, true);

        List<Categorizacao__c> rows = GestaoSLACategoriaSelector.selectCategoriaById(request.id);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }

        Categorizacao__c existing = rows[0];
        if (request.gestaoSLAId == null || request.gestaoSLAId != existing.GestaoSLA__c) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestao = GestaoSLAHelper.loadGestaoOrThrow(existing.GestaoSLA__c);
        GestaoSLAHelper.ensureUnidadeAllowed(gestao.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
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
            throw new GestaoSLAService.FunctionalException(dmx.getDmlMessage(0));
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
        row.PermiteAssumirComFilaParametrizada__c = (request != null && request.permiteAssumirComFilaParametrizada == false) ? 'Não' : 'Sim';
        if (!distribuir) {
            row.PorCampoCustomizado__c = 'Não';
            row.FilaDeveloperName__c = null;
            row.CampoDistribuicao__c = null;
            row.ValorDistribuicao__c = null;
            row.FilaDeveloperNameFallback__c = null;
            row.EtapaAtendimentoDistribuicao__c = null;
            return;
        }
        Boolean porCampoCustomizado = request.porCampoCustomizado == true;
        row.PorCampoCustomizado__c = porCampoCustomizado ? 'Sim' : 'Não';
        row.FilaDeveloperName__c = String.isBlank(request.filaDeveloperName) ? null : request.filaDeveloperName.trim();
        row.EtapaAtendimentoDistribuicao__c = String.isBlank(request.etapaAtendimentoDistribuicao) ? null : request.etapaAtendimentoDistribuicao.trim();
        if (!porCampoCustomizado) {
            row.CampoDistribuicao__c = null;
            row.ValorDistribuicao__c = null;
            row.FilaDeveloperNameFallback__c = null;
        } else {
            row.CampoDistribuicao__c = String.isBlank(request.campoDistribuicao) ? null : request.campoDistribuicao.trim();
            row.ValorDistribuicao__c = String.isBlank(request.valorDistribuicao) ? null : request.valorDistribuicao.trim();
            row.FilaDeveloperNameFallback__c = String.isBlank(request.filaDeveloperNameFallback) ? null : request.filaDeveloperNameFallback.trim();
        }
    }

    private static Categorizacao__c queryCategoriaById(Id categoriaId) {
        List<Categorizacao__c> rows = GestaoSLACategoriaSelector.selectCategoriaById(categoriaId);
        return rows.isEmpty() ? null : rows[0];
    }

    public static GestaoSLADTO.CategoriaResumo deactivateCategoria(Id categoriaId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageCategories(perms);
        if (categoriaId == null) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }

        List<Categorizacao__c> rows = GestaoSLACategoriaSelector.selectCategoriaById(categoriaId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }

        Categorizacao__c row = rows[0];
        GestaoSLA__c gestaoCtxDeactivate = GestaoSLAHelper.loadGestaoOrThrow(row.GestaoSLA__c);
        GestaoSLAHelper.ensureUnidadeAllowed(gestaoCtxDeactivate.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
        row.Ativo__c = false;
        row.MotivoInativacao__c = 'Inativação via Gestão de SLA';
        update row;
        return toCategoriaResumo(row, 0);
    }

    public static GestaoSLADTO.InactiveCategoriasResponse getInactiveCategorias(Id gestaoSLAId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageCategories(perms);
        if (gestaoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }
        GestaoSLA__c gestaoCtxInactive = GestaoSLAHelper.loadGestaoOrThrow(gestaoSLAId);
        GestaoSLAHelper.ensureUnidadeAllowed(gestaoCtxInactive.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));

        GestaoSLADTO.InactiveCategoriasResponse response = new GestaoSLADTO.InactiveCategoriasResponse();
        response.permissions = perms;
        response.categoriasInativas = new List<GestaoSLADTO.CategoriaResumo>();

        for (Categorizacao__c row : GestaoSLACategoriaSelector.selectInactiveCategoriasByGestaoSLA(gestaoSLAId)) {
            response.categoriasInativas.add(toCategoriaResumo(row, 0));
        }

        return response;
    }

    public static GestaoSLADTO.CategoriaResumo reactivateCategoria(Id categoriaId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanManageCategories(perms);
        if (categoriaId == null) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }

        List<Categorizacao__c> rows = GestaoSLACategoriaSelector.selectCategoriaById(categoriaId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }

        Categorizacao__c row = rows[0];
        GestaoSLA__c gestaoCtxReactivate = GestaoSLAHelper.loadGestaoOrThrow(row.GestaoSLA__c);
        GestaoSLAHelper.ensureUnidadeAllowed(gestaoCtxReactivate.UnidadeNegocio__c, GestaoSLAHelper.resolveAllowedUnidades(perms));
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

    /**
     * @description Exclui definitivamente uma Categorização e, por master-detail, suas Regras de SLA filhas.
     *              Restrito ao Admin Técnico.
     * @param categoriaId Id da Categorizacao__c a excluir.
     **/
    public static void deleteCategoria(Id categoriaId) {
        GestaoSLADTO.PermissionInfo perms = GestaoSLAHelper.buildPermissionInfo();
        GestaoSLAHelper.ensureCanAccess(perms);
        GestaoSLAHelper.ensureCanDelete(perms);
        if (categoriaId == null) {
            throw new GestaoSLAService.FunctionalException('Categorização não informada.');
        }
        if (!Schema.sObjectType.Categorizacao__c.isDeletable()) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão (FLS/CRUD) para excluir Categorizações.');
        }

        List<Categorizacao__c> rows = GestaoSLACategoriaSelector.selectCategoriaIdById(categoriaId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Categorização não encontrada.');
        }
        delete rows[0];
    }

    private static void validateCategoriaRequest(GestaoSLADTO.CategoriaRequest request, Boolean isUpdate) {
        if (request == null) throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        if (request.gestaoSLAId == null) throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        if (String.isBlank(request.tipoCaso)) throw new GestaoSLAService.FunctionalException('Tipo de Caso é obrigatório.');
        if (String.isBlank(request.categoria)) throw new GestaoSLAService.FunctionalException('Categoria é obrigatória.');
        if (String.isBlank(request.assunto)) throw new GestaoSLAService.FunctionalException('Assunto é obrigatório.');
        GestaoSLAHelper.validatePicklistValue('Tipo de Caso', Categorizacao__c.TipoCaso__c, request.tipoCaso);
        GestaoSLAHelper.validatePicklistValue('Categoria', Categorizacao__c.Categoria__c, request.categoria);
        GestaoSLAHelper.validatePicklistValue('Assunto', Categorizacao__c.Assunto__c, request.assunto);
        GestaoSLAHelper.validatePicklistValue('Subassunto', Categorizacao__c.Subassunto__c, request.subassunto);
    }

    private static String normalizePrioridadeOrThrow(String prioridadeInput) {
        String normalized = GestaoSLAHelper.normalizeText(prioridadeInput).replace('é', 'e');
        if (normalized == 'baixa' || normalized == 'low') return 'Low';
        if (normalized == 'media' || normalized == 'medium') return 'Medium';
        if (normalized == 'alta' || normalized == 'high') return 'High';
        throw new GestaoSLAService.FunctionalException('Prioridade sugerida inválida.');
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
        List<Categorizacao__c> dupRows = GestaoSLACategoriaSelector.selectDuplicateActiveCategoria(
            gestaoSLAId, tipoCaso, categoria, assunto, subassunto, excludeId
        );
        if (!dupRows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Já existe uma categorização ativa com esta combinação.');
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
        dto.filaDeveloperNameFallback = row.FilaDeveloperNameFallback__c;
        dto.nomeFilaFallbackDistribuicao = row.NomeFilaFallbackDistribuicao__c;
        dto.permiteAssumirComFilaParametrizada = CategorizacaoHelper.isTrueFlag(row.PermiteAssumirComFilaParametrizada__c);
        dto.etapaAtendimentoDistribuicao = row.EtapaAtendimentoDistribuicao__c;
        return dto;
    }

    /**
     * @description Monta o label de exibição de uma Categorização (Categoria / Assunto / Subassunto),
     * usado também pelo mapeamento de DTO de Regras de SLA (GestaoSLARegraService.toRegraSLAResumo),
     * já que uma Regra sempre referencia uma Categorização.
     * @param row Categorizacao__c (ou o relacionamento Categorizacao__r de uma RegrasSLACategorizacao__c).
     * @return Label combinado, ou o Name do registro se nenhuma parte estiver preenchida.
     */
    public static String buildCategorizacaoLabel(Categorizacao__c row) {
        if (row == null) {
            return null;
        }
        List<String> parts = new List<String>();
        if (!String.isBlank(row.Categoria__c)) parts.add(row.Categoria__c);
        if (!String.isBlank(row.Assunto__c)) parts.add(row.Assunto__c);
        if (!String.isBlank(row.Subassunto__c)) parts.add(row.Subassunto__c);
        return parts.isEmpty() ? row.Name : String.join(parts, ' / ');
    }
}
