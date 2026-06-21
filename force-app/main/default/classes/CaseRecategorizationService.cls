public inherited sharing class CaseRecategorizationService {
    public class FunctionalException extends Exception { public String code; }

    private static void throwFunctional(String code, String message) {
        FunctionalException ex = new FunctionalException(message);
        ex.code = code;
        throw ex;
    }

    /**
     * @description Retorna contexto atual do Case para iniciar recategorização.
     * @param caseId Id do Case.
     * @return Contexto serializável para LWC.
     */
    public static CaseRecategorizationDTO.CaseRecategorizationContextDTO getContext(Id caseId) {
        validateReadAccess();
        if (caseId == null) throwFunctional('REQUIRED_CASE_ID', 'Caso não informado.');

        Case c = CaseRecategorizationSelector.getCaseById(caseId);
        if (c == null) throwFunctional('CASE_NOT_FOUND', 'Caso não encontrado.');
        validateCaseBusinessContext(c);

        CaseRecategorizationDTO.CaseRecategorizationContextDTO out = new CaseRecategorizationDTO.CaseRecategorizationContextDTO();
        out.caseId = c.Id;
        out.caseNumber = c.CaseNumber;
        out.status = c.Status;
        out.recordTypeId = c.RecordTypeId;
        out.recordTypeDeveloperName = c.RecordType != null ? c.RecordType.DeveloperName : null;
        out.recordTypeLabel = c.RecordType != null ? c.RecordType.Name : null;
        out.unidadeNegocio = c.UnidadeNegocio__c;
        out.currentTipoCaso = c.TipoCaso__c;
        out.currentTipoCasoLabel = CaseRecategorizationHelper.resolveCasePicklistLabel('TipoCaso__c', c.TipoCaso__c);
        out.currentCategoria = c.Categoria__c;
        out.currentCategoriaLabel = CaseRecategorizationHelper.resolveCasePicklistLabel('Categoria__c', c.Categoria__c);
        out.currentAssunto = c.Assunto__c;
        out.currentAssuntoLabel = CaseRecategorizationHelper.resolveCasePicklistLabel('Assunto__c', c.Assunto__c);
        out.currentSubassunto = c.Subassunto__c;
        out.currentSubassuntoLabel = CaseRecategorizationHelper.resolveCasePicklistLabel('Subassunto__c', c.Subassunto__c);
        out.canRecategorize = !CaseRecategorizationHelper.isCaseBlocked(c);
        if (!out.canRecategorize) out.blockedReason = 'Não é possível recategorizar um Caso fechado ou cancelado.';
        return out;
    }

    /**
     * @description Retorna opções de árvore válidas de categorização para seleção parcial.
     * @param request dados de contexto e seleção atual.
     * @return Opções por nível da árvore.
     */
    public static CaseRecategorizationDTO.TreeOptionsDTO getTreeOptions(CaseRecategorizationDTO.TreeRequestDTO request) {
        validateTreeRequest(request);
        List<Categorizacao__c> rows = CaseRecategorizationSelector.getActiveCategorizacoes(request.recordTypeDeveloperName, request.unidadeNegocio);

        Set<String> tipos = new Set<String>();
        Set<String> categorias = new Set<String>();
        Set<String> assuntos = new Set<String>();
        Set<String> subassuntos = new Set<String>();
        Map<String, String> tipoLabels = new Map<String, String>();
        Map<String, String> categoriaLabels = new Map<String, String>();
        Map<String, String> assuntoLabels = new Map<String, String>();
        Map<String, String> subassuntoLabels = new Map<String, String>();

        for (Categorizacao__c row : rows) {
            tipos.add(row.TipoCaso__c);
            tipoLabels.put(row.TipoCaso__c, CaseRecategorizationHelper.safeAliasValue(row, 'TipoCasoLabel', row.TipoCaso__c));
            if (CaseRecategorizationHelper.sameNormalizedValue(request.selectedTipoCaso, row.TipoCaso__c)) {
                categorias.add(row.Categoria__c);
                categoriaLabels.put(row.Categoria__c, CaseRecategorizationHelper.safeAliasValue(row, 'CategoriaLabel', row.Categoria__c));
                if (CaseRecategorizationHelper.sameNormalizedValue(request.selectedCategoria, row.Categoria__c)) {
                    assuntos.add(row.Assunto__c);
                    assuntoLabels.put(row.Assunto__c, CaseRecategorizationHelper.safeAliasValue(row, 'AssuntoLabel', row.Assunto__c));
                    if (CaseRecategorizationHelper.sameNormalizedValue(request.selectedAssunto, row.Assunto__c)) {
                        subassuntos.add(row.Subassunto__c);
                        subassuntoLabels.put(row.Subassunto__c, CaseRecategorizationHelper.safeAliasValue(row, 'SubassuntoLabel', row.Subassunto__c));
                    }
                }
            }
        }

        CaseRecategorizationDTO.TreeOptionsDTO out = new CaseRecategorizationDTO.TreeOptionsDTO();
        out.tipoCasoOptions = CaseRecategorizationHelper.toSortedOptionsWithLabels(tipos, tipoLabels, 'TipoCaso__c');
        out.categoriaOptions = CaseRecategorizationHelper.toSortedOptionsWithLabels(categorias, categoriaLabels, 'Categoria__c');
        out.assuntoOptions = CaseRecategorizationHelper.toSortedOptionsWithLabels(assuntos, assuntoLabels, 'Assunto__c');
        out.subassuntoOptions = CaseRecategorizationHelper.toSortedOptionsWithLabels(subassuntos, subassuntoLabels, 'Subassunto__c');
        return out;
    }

    /**
     * @description Atualiza os campos de categorização do Case após validar árvore ativa.
     * @param request seleção final escolhida no modal.
     * @return Resultado amigável para UI.
     */
    public static CaseRecategorizationDTO.RecategorizationResponseDTO recategorize(CaseRecategorizationDTO.RecategorizationRequestDTO request) {
        validateUpdateAccess();
        if (request == null || request.caseId == null) throwFunctional('REQUIRED_CASE_ID', 'Caso não informado.');

        Case c = CaseRecategorizationSelector.getCaseById(request.caseId);
        if (c == null) throwFunctional('CASE_NOT_FOUND', 'Caso não encontrado.');
        validateCaseBusinessContext(c);
        if (CaseRecategorizationHelper.isCaseBlocked(c)) {
            throwFunctional('CASE_BLOCKED', 'Não é possível recategorizar um Caso fechado ou cancelado.');
        }

        validateRequiredCategorizationFields(request.tipoCaso, request.categoria);
        Boolean uncategorizedBefore = String.isBlank(c.TipoCaso__c) || String.isBlank(c.Categoria__c);
        Categorizacao__c matchedCategorization = validateCombinationExists(c, request);

        c.TipoCaso__c = request.tipoCaso;
        c.Categoria__c = request.categoria;
        c.Assunto__c = request.assunto;
        c.Subassunto__c = request.subassunto;
        if (Case.Categorizacao__c.getDescribe().isUpdateable()) {
            c.Categorizacao__c = matchedCategorization != null ? matchedCategorization.Id : null;
        }
        if (matchedCategorization != null
            && !String.isBlank(matchedCategorization.Prioridade__c)
            && Case.Priority.getDescribe().isUpdateable()) {
            c.Priority = matchedCategorization.Prioridade__c;
        }

        if (uncategorizedBefore) {
            applyDestination(c, request, matchedCategorization);
        }

        update c;

        CaseRecategorizationDTO.RecategorizationResponseDTO out = new CaseRecategorizationDTO.RecategorizationResponseDTO();
        out.success = true;
        out.caseId = c.Id;
        out.message = 'Caso recategorizado com sucesso.';
        out.warnings = new List<String>();
        return out;
    }

    private static void validateReadAccess() {
        if (!Schema.sObjectType.Case.isAccessible()) {
            throwFunctional('CRUD_DENIED', 'Você não possui permissão para recategorizar este Caso.');
        }
        if (!Schema.sObjectType.Categorizacao__c.isAccessible()) {
            throwFunctional('CRUD_DENIED', 'Você não possui permissão para recategorizar este Caso.');
        }
    }

    private static void validateUpdateAccess() {
        validateReadAccess();
        if (!Schema.sObjectType.Case.isUpdateable()) {
            throwFunctional('CRUD_DENIED', 'Você não possui permissão para recategorizar este Caso.');
        }
        if (!Case.TipoCaso__c.getDescribe().isUpdateable()
            || !Case.Categoria__c.getDescribe().isUpdateable()
            || !Case.Assunto__c.getDescribe().isUpdateable()
            || !Case.Subassunto__c.getDescribe().isUpdateable()) {
            throwFunctional('FLS_DENIED', 'Você não possui permissão para recategorizar este Caso.');
        }
    }

    private static void validateTreeRequest(CaseRecategorizationDTO.TreeRequestDTO request) {
        if (request == null) throwFunctional('INVALID_REQUEST', 'Requisição inválida.');
        if (String.isBlank(request.unidadeNegocio)) throwFunctional('REQUIRED_UNIDADE', 'Unidade de Negócio é obrigatória.');
        if (String.isBlank(request.recordTypeDeveloperName)) {
            throwFunctional('REQUIRED_RECORD_TYPE', 'Record Type é obrigatório.');
        }
    }

    private static void validateRequiredCategorizationFields(String tipoCaso, String categoria) {
        if (String.isBlank(tipoCaso)) throwFunctional('REQUIRED_TIPO_CASO', 'Tipo de Caso é obrigatório.');
        if (String.isBlank(categoria)) throwFunctional('REQUIRED_CATEGORIA', 'Categoria é obrigatória.');
    }

    private static void validateCaseBusinessContext(Case c) {
        Map<String, CaseCreationSelector.UnidadeConfig> allConfigs = CaseRecategorizationSelector.getUnidadeConfigs();
        CaseCreationSelector.UnidadeConfig cfg = CaseRecategorizationSelector.findConfigForCaseRecordType(
            c.RecordType != null ? c.RecordType.DeveloperName : null,
            c.RecordType != null ? c.RecordType.Name : null
        );
        if (!String.isBlank(c.UnidadeNegocio__c)) {
            c.UnidadeNegocio__c = CaseCreationSelector.resolveCanonicalBusinessUnit(c.UnidadeNegocio__c);
        }
        if (String.isBlank(c.UnidadeNegocio__c) && cfg != null && cfg.ativo == true) {
            c.UnidadeNegocio__c = cfg.unidadeNegocio;
        }
        if (String.isBlank(c.UnidadeNegocio__c)) {
            c.UnidadeNegocio__c = inferUnidadeFromAnyActiveConfig(
                c.RecordType != null ? c.RecordType.DeveloperName : null,
                c.RecordType != null ? c.RecordType.Name : null,
                allConfigs
            );
        }
        if (String.isBlank(c.UnidadeNegocio__c)) {
            c.UnidadeNegocio__c = inferUnidadeFromOwnerQueue(c.OwnerId, allConfigs);
        }
        if (String.isBlank(c.UnidadeNegocio__c)) {
            throwFunctional('REQUIRED_UNIDADE', 'Unidade de Negócio é obrigatória.');
        }
        if (cfg == null) {
            cfg = CaseRecategorizationSelector.findConfigForCaseRecordType(
                c.RecordType != null ? c.RecordType.DeveloperName : null,
                c.RecordType != null ? c.RecordType.Name : null
            );
        }
        if (cfg != null && cfg.ativo == true && !CaseRecategorizationHelper.sameNormalizedValue(cfg.unidadeNegocio, c.UnidadeNegocio__c)) {
            throwFunctional('INVALID_RECORD_TYPE_UNIDADE', 'Record Type incompatível com Unidade de Negócio.');
        }
    }

    private static String inferUnidadeFromOwnerQueue(Id ownerId, Map<String, CaseCreationSelector.UnidadeConfig> configsByRt) {
        if (ownerId == null || !String.valueOf(ownerId).startsWith('00G')) return null;
        Group ownerQueue = CaseRecategorizationSelector.getQueueById(ownerId);
        if (ownerQueue == null || String.isBlank(ownerQueue.DeveloperName)) return null;
        String ownerDev = ownerQueue.DeveloperName;
        if (configsByRt == null || configsByRt.isEmpty()) return null;
        for (CaseCreationSelector.UnidadeConfig cfg : configsByRt.values()) {
            if (cfg == null || cfg.ativo != true || String.isBlank(cfg.queueToken) || String.isBlank(cfg.unidadeNegocio)) continue;
            if (ownerDev.contains(cfg.queueToken)) return cfg.unidadeNegocio;
        }
        return null;
    }

    private static String inferUnidadeFromAnyActiveConfig(String rtDevName, String rtLabel, Map<String, CaseCreationSelector.UnidadeConfig> configsByRt) {
        if (configsByRt == null || configsByRt.isEmpty()) return null;
        for (CaseCreationSelector.UnidadeConfig cfg : configsByRt.values()) {
            if (cfg == null || cfg.ativo != true || String.isBlank(cfg.unidadeNegocio)) continue;
            if (CaseCreationHelper.keyMatches(rtDevName, cfg.recordTypeDeveloperName)) return cfg.unidadeNegocio;
            if (CaseCreationHelper.keyMatches(rtLabel, cfg.recordTypeDeveloperName)) return cfg.unidadeNegocio;
            if (CaseCreationHelper.keyMatches(rtDevName, cfg.unidadeNegocio)) return cfg.unidadeNegocio;
            if (CaseCreationHelper.keyMatches(rtLabel, cfg.unidadeNegocio)) return cfg.unidadeNegocio;
        }
        return null;
    }

    private static Categorizacao__c validateCombinationExists(Case c, CaseRecategorizationDTO.RecategorizationRequestDTO request) {
        List<Categorizacao__c> rows = CaseRecategorizationSelector.getActiveCategorizacoes(
            c.RecordType != null ? c.RecordType.DeveloperName : null,
            c.UnidadeNegocio__c
        );
        Categorizacao__c matched;
        for (Categorizacao__c row : rows) {
            if (CaseRecategorizationHelper.sameNormalizedValue(row.TipoCaso__c, request.tipoCaso)
                && CaseRecategorizationHelper.sameNormalizedValue(row.Categoria__c, request.categoria)
                && CaseRecategorizationHelper.sameNormalizedValue(row.Assunto__c, request.assunto)
                && CaseRecategorizationHelper.sameNormalizedValue(row.Subassunto__c, request.subassunto)) {
                matched = row;
                break;
            }
        }

        if (matched == null) {
            throwFunctional('INVALID_CATEGORIZATION', 'A combinação de categorização selecionada não está ativa ou não existe para esta Unidade de Negócio.');
        }
        return matched;
    }

    private static void applyDestination(Case c, CaseRecategorizationDTO.RecategorizationRequestDTO request, Categorizacao__c matchedCategorization) {
        String action = String.isBlank(request.destinationAction) ? 'ASSUMIR' : request.destinationAction;

        if (action == 'ASSUMIR') {
            c.OwnerId = UserInfo.getUserId();
            c.AcaoPosCategorizacao__c = 'Assumir';
            c.DistribuicaoSolicitada__c = false;
            c.OrigemDistribuicao__c = null;
            c.FilaDestinoDeveloperName__c = null;
            c.FilaDestinoId__c = null;
            c.Status = 'Aberto';
            c.EtapaAtendimento__c = 'Em Atendimento';
            return;
        }

        if (action == 'ENCERRAR') {
            c.OwnerId = UserInfo.getUserId();
            c.AcaoPosCategorizacao__c = 'Encerrar';
            c.DistribuicaoSolicitada__c = false;
            c.OrigemDistribuicao__c = null;
            c.FilaDestinoDeveloperName__c = null;
            c.FilaDestinoId__c = null;
            c.Status = 'Fechado';
            c.EtapaAtendimento__c = 'Concluído';
            return;
        }

        if (action != 'DISTRIBUIR') {
            throwFunctional('DESTINATION_REQUIRED', 'Selecione o destino do caso.');
        }

        String queueDevName;
        if (CategorizacaoHelper.isTrueFlag(matchedCategorization.DistribuirParaFila__c)
            && !String.isBlank(matchedCategorization.FilaDeveloperName__c)
            && (!CategorizacaoHelper.isTrueFlag(matchedCategorization.PorCampoCustomizado__c)
                || (String.isBlank(matchedCategorization.CampoDistribuicao__c) && String.isBlank(matchedCategorization.ValorDistribuicao__c)))) {
            queueDevName = matchedCategorization.FilaDeveloperName__c;
            c.OrigemDistribuicao__c = 'Categorização';
        } else {
            if (String.isBlank(request.selectedQueueDeveloperName)) {
                throwFunctional('QUEUE_REQUIRED', 'Selecione uma fila para distribuição.');
            }
            queueDevName = request.selectedQueueDeveloperName;
            c.OrigemDistribuicao__c = 'Seleção Manual';
        }

        Map<String, Group> queueByDev = CaseCreationSelector.getQueuesByDeveloperName(new Set<String>{ queueDevName });
        Group queue = queueByDev.get(queueDevName);
        if (queue == null) {
            throwFunctional('INVALID_QUEUE', 'Fila inválida para a Unidade de Negócio selecionada.');
        }

        c.OwnerId = queue.Id;
        c.AcaoPosCategorizacao__c = 'Distribuir';
        c.DistribuicaoSolicitada__c = true;
        c.FilaDestinoDeveloperName__c = queue.DeveloperName;
        c.FilaDestinoId__c = String.valueOf(queue.Id);
        c.Status = 'Aberto';
        c.EtapaAtendimento__c = 'Em Triagem';
    }
}