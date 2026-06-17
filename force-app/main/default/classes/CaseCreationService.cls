/**
 * @description       : Serviço de negócio para o módulo CaseCreation. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : Case Creation
 * @last modified on  : 06-15-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseCreationService {
    public class FunctionalException extends Exception { public String code; }

    /**
     * @description Lança FunctionalException com código de erro para tratamento pelo Controller.
     * @param code Código de erro (ex: 'CRUD_DENIED', 'NO_RECORD_TYPE').
     * @param message Mensagem legível pelo usuário.
     **/
    public static void throwFunctional(String code, String message) {
        FunctionalException ex = new FunctionalException(message);
        ex.code = code;
        throw ex;
    }

    /**
     * @description Carrega contexto inicial para criação de Case: verifica permissões, retorna record types
     *              disponíveis para o usuário e unidade de negócio padrão.
     * @return InitialContextDTO com userId, record types e unidade de negócio padrão.
     **/
    public static CaseCreationDTO.InitialContextDTO getInitialContext() {
        if (!Schema.sObjectType.Case.isCreateable()) throwFunctional('CRUD_DENIED', 'Usuário sem permissão para criar Case.');

        User u = CaseCreationSelector.getCurrentUser();
        Map<String, CaseCreationSelector.UnidadeConfig> cfg = CaseCreationSelector.getUnidadeConfigByRtDevName();
        Map<Id, Schema.RecordTypeInfo> infos = Case.SObjectType.getDescribe().getRecordTypeInfosById();

        CaseCreationDTO.InitialContextDTO out = new CaseCreationDTO.InitialContextDTO();
        out.userId = u.Id;
        out.userName = u.Name;
        out.recordTypes = new List<CaseCreationDTO.RecordTypeOptionDTO>();

        for (RecordType rt : CaseCreationSelector.getCaseRecordTypes()) {
            Schema.RecordTypeInfo info = infos.get(rt.Id);
            if (info == null || !info.isAvailable()) continue;

            CaseCreationDTO.RecordTypeOptionDTO dto = new CaseCreationDTO.RecordTypeOptionDTO();
            dto.recordTypeId = rt.Id;
            dto.developerName = rt.DeveloperName;
            dto.label = rt.Name;
            dto.isDefault = info.isDefaultRecordTypeMapping();
            CaseCreationSelector.UnidadeConfig c = CaseCreationSelector.findConfigForCaseRecordType(rt.DeveloperName, rt.Name);
            if (c != null && c.ativo == true) dto.unidadeNegocio = c.unidadeNegocio;
            out.recordTypes.add(dto);

            if (dto.isDefault == true) {
                out.defaultRecordTypeId = dto.recordTypeId;
                out.unidadeNegocioDefault = dto.unidadeNegocio;
            }
        }

        if (out.recordTypes.isEmpty()) throwFunctional('NO_RECORD_TYPE', 'Nenhum Record Type de Case disponível para o usuário.');
        if (out.defaultRecordTypeId == null && out.recordTypes.size() == 1) {
            out.defaultRecordTypeId = out.recordTypes[0].recordTypeId;
            out.unidadeNegocioDefault = out.recordTypes[0].unidadeNegocio;
        }
        return out;
    }

    /**
     * @description Retorna opções da árvore de categorização filtradas pela seleção atual do usuário.
     *              Percorre categorizações ativas e retorna próximo nível de opções baseado em TipoCaso/Categoria/Assunto já selecionados.
     * @param request CategorizationRequestDTO com recordType, unidadeNegocio e valores selecionados até o momento.
     * @return TreeOptionsDTO com listas de opções para TipoCaso, Categoria, Assunto e Subassunto.
     **/
    public static CaseCreationDTO.TreeOptionsDTO getTreeOptions(CaseCreationDTO.CategorizationRequestDTO request) {
        validateCategorizationBase(request);
        List<Categorizacao__c> rows = CaseCreationSelector.getActiveCategorizacoes(request.recordTypeDeveloperName, request.unidadeNegocio);

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
            tipoLabels.put(row.TipoCaso__c, getLabelOrFieldValue(row, 'TipoCasoLabel', 'TipoCaso__c'));
            if (CaseCreationHelper.sameNormalizedValue(request.tipoCaso, row.TipoCaso__c)) {
                categorias.add(row.Categoria__c);
                categoriaLabels.put(row.Categoria__c, getLabelOrFieldValue(row, 'CategoriaLabel', 'Categoria__c'));
                if (CaseCreationHelper.sameNormalizedValue(request.categoria, row.Categoria__c)) {
                    assuntos.add(row.Assunto__c);
                    assuntoLabels.put(row.Assunto__c, getLabelOrFieldValue(row, 'AssuntoLabel', 'Assunto__c'));
                    if (CaseCreationHelper.sameNormalizedValue(request.assunto, row.Assunto__c)) {
                        subassuntos.add(row.Subassunto__c);
                        subassuntoLabels.put(row.Subassunto__c, getLabelOrFieldValue(row, 'SubassuntoLabel', 'Subassunto__c'));
                    }
                }
            }
        }

        CaseCreationDTO.TreeOptionsDTO out = new CaseCreationDTO.TreeOptionsDTO();
        out.tipoCasoOptions = CaseCreationHelper.toSortedOptionsWithLabels(tipos, tipoLabels, 'TipoCaso__c');
        out.categoriaOptions = CaseCreationHelper.toSortedOptionsWithLabels(categorias, categoriaLabels, 'Categoria__c');
        out.assuntoOptions = CaseCreationHelper.toSortedOptionsWithLabels(assuntos, assuntoLabels, 'Assunto__c');
        out.subassuntoOptions = CaseCreationHelper.toSortedOptionsWithLabels(subassuntos, subassuntoLabels, 'Subassunto__c');
        return out;
    }

    /**
     * @description Resolve seleção completa de categorização e retorna fila parametrizada se houver,
     *              indicando se a fila é read-only por configuração da categorização.
     * @param request CategorizationRequestDTO com seleção completa (tipoCaso + categoria + assunto + subassunto).
     * @return ResolveSelectionResponseDTO com fila sugerida e flag de leitura apenas.
     **/
    public static CaseCreationDTO.ResolveSelectionResponseDTO resolveCategorizationSelection(CaseCreationDTO.CategorizationRequestDTO request) {
        validateCategorizationBase(request);
        validateCategorizationPath(request);

        List<Categorizacao__c> rows = CaseCreationSelector.getActiveCategorizacoes(request.recordTypeDeveloperName, request.unidadeNegocio);
        Categorizacao__c chosen;
        for (Categorizacao__c row : rows) {
            if (CaseCreationHelper.sameNormalizedValue(row.TipoCaso__c, request.tipoCaso)
                && CaseCreationHelper.sameNormalizedValue(row.Categoria__c, request.categoria)
                && CaseCreationHelper.sameNormalizedValue(row.Assunto__c, request.assunto)
                && CaseCreationHelper.sameNormalizedValue(row.Subassunto__c, request.subassunto)) {
                Boolean distributeToQueue = CaseCreationHelper.isTrueFlag(row.DistribuirParaFila__c);
                Boolean queueIsDefined = !String.isBlank(row.FilaDeveloperName__c);
                Boolean noFieldDistribution = String.isBlank(row.CampoDistribuicao__c) && String.isBlank(row.ValorDistribuicao__c);
                Boolean isCategorizationMode = CaseCreationHelper.isTrueFlag(row.PorCategorizacao__c);
                if (distributeToQueue && queueIsDefined && (isCategorizationMode || noFieldDistribution)) {
                    chosen = row;
                    break;
                }
            }
        }

        CaseCreationDTO.ResolveSelectionResponseDTO out = new CaseCreationDTO.ResolveSelectionResponseDTO();
        out.hasParametrizedQueue = chosen != null;
        out.queueReadOnly = chosen != null;
        if (chosen != null) {
            Map<String, Group> gByDev = CaseCreationSelector.getQueuesByDeveloperName(new Set<String>{ chosen.FilaDeveloperName__c });
            Group g = gByDev.get(chosen.FilaDeveloperName__c);
            if (g != null) {
                CaseCreationDTO.QueueOptionDTO q = new CaseCreationDTO.QueueOptionDTO();
                q.id = g.Id; q.name = g.Name; q.developerName = g.DeveloperName; q.readonlyReason = 'Fila definida pela parametrização da categorização.';
                out.queue = q;
                out.message = q.readonlyReason;
            }
        }
        return out;
    }

    /**
     * @description Retorna filas de Case habilitadas para o record type e unidade de negócio, filtradas por token de configuração.
     * @param recordTypeDeveloperName DeveloperName do RecordType selecionado.
     * @param unidadeNegocio Unidade de negócio para filtrar a configuração.
     * @return Lista de QueueOptionDTO com id, name e developerName das filas elegíveis.
     **/
    public static List<CaseCreationDTO.QueueOptionDTO> getAvailableQueues(String recordTypeDeveloperName, String unidadeNegocio) {
        CaseCreationSelector.UnidadeConfig c = CaseCreationSelector.findConfigForCaseRecordType(recordTypeDeveloperName, unidadeNegocio);
        if (c == null || c.ativo != true || !CaseCreationHelper.sameNormalizedValue(c.unidadeNegocio, unidadeNegocio)) {
            return new List<CaseCreationDTO.QueueOptionDTO>();
        }

        List<Group> groups = CaseCreationSelector.getCaseQueuesByToken(c.queueToken);
        Set<Id> queueIds = new Set<Id>();
        for (Group g : groups) queueIds.add(g.Id);
        Set<Id> enabled = CaseCreationSelector.getCaseEnabledQueueIds(queueIds);

        List<CaseCreationDTO.QueueOptionDTO> out = new List<CaseCreationDTO.QueueOptionDTO>();
        for (Group g : groups) {
            if (!enabled.contains(g.Id)) continue;
            CaseCreationDTO.QueueOptionDTO q = new CaseCreationDTO.QueueOptionDTO();
            q.id = g.Id; q.name = g.Name; q.developerName = g.DeveloperName;
            out.add(q);
        }
        return out;
    }

    /**
     * @description Constrói valores padrão para o formulário de criação de Case com base na categorização e destino selecionados.
     *              Consulta regra de SLA ativa, resolve entitlement process, business hours e fila sugerida.
     * @param request BuildDefaultValuesRequestDTO com seleção de categorização e informações de destino.
     * @return BuildDefaultValuesResponseDTO com mapa de valores padrão, fila, SLA e warnings.
     **/
    public static CaseCreationDTO.BuildDefaultValuesResponseDTO buildDefaultValues(CaseCreationDTO.BuildDefaultValuesRequestDTO request) {
        if (!Schema.sObjectType.Case.isCreateable()) throwFunctional('CRUD_DENIED', 'Usuário sem permissão para criar Case.');
        if (request == null || request.categorization == null || request.destination == null) throwFunctional('INVALID_REQUEST', 'Dados de categorização/destino são obrigatórios.');

        validateCategorizationBase(request.categorization);
        validateCategorizationPath(request.categorization);

        Categorizacao__c matchedCategorization = findMatchingCategorization(request.categorization);
        CaseCreationDTO.ResolveSelectionResponseDTO resolved = resolveCategorizationSelection(request.categorization);

        Map<String, String> values = new Map<String, String>();
        values.put('RecordTypeId', String.valueOf(request.categorization.recordTypeId));
        values.put('UnidadeNegocio__c', CaseCreationSelector.resolveCanonicalBusinessUnit(request.categorization.unidadeNegocio));
        if (matchedCategorization != null) {
            values.put('Categorizacao__c', String.valueOf(matchedCategorization.Id));
        }
        values.put('TipoCaso__c', request.categorization.tipoCaso);
        values.put('Categoria__c', request.categorization.categoria);
        CaseCreationHelper.putIfNotBlank(values, 'Assunto__c', request.categorization.assunto);
        CaseCreationHelper.putIfNotBlank(values, 'Subassunto__c', request.categorization.subassunto);
        if (matchedCategorization != null && !String.isBlank(matchedCategorization.Prioridade__c)) {
            values.put('Priority', matchedCategorization.Prioridade__c);
        }
        values.put('Origin', 'Manual');

        String action = request.destination.action;
        Id currentUserId = UserInfo.getUserId();

        if (action == 'ASSUMIR') {
            values.put('OwnerId', String.valueOf(currentUserId));
            values.put('AcaoPosCategorizacao__c', 'Assumir');
            values.put('DistribuicaoSolicitada__c', 'false');
            values.put('Status', 'Aberto');
            CaseCreationHelper.putIfNotBlank(values, 'EtapaAtendimento__c', 'Em Atendimento');
        } else if (action == 'ENCERRAR') {
            values.put('OwnerId', String.valueOf(currentUserId));
            values.put('AcaoPosCategorizacao__c', 'Encerrar');
            values.put('DistribuicaoSolicitada__c', 'false');
            values.put('Status', 'Fechado');
            CaseCreationHelper.putIfNotBlank(values, 'EtapaAtendimento__c', 'Concluído');
        } else if (action == 'DISTRIBUIR') {
            CaseCreationDTO.QueueOptionDTO queue;
            if (resolved.hasParametrizedQueue == true && resolved.queue != null) {
                queue = resolved.queue;
                values.put('OrigemDistribuicao__c', 'Categorização');
            } else {
                if (String.isBlank(request.destination.selectedQueueDeveloperName)) throwFunctional('QUEUE_REQUIRED', 'Selecione uma fila para distribuição.');
                List<CaseCreationDTO.QueueOptionDTO> allowed = getAvailableQueues(request.categorization.recordTypeDeveloperName, request.categorization.unidadeNegocio);
                for (CaseCreationDTO.QueueOptionDTO item : allowed) {
                    if (item.developerName == request.destination.selectedQueueDeveloperName) queue = item;
                }
                if (queue == null) throwFunctional('INVALID_QUEUE', 'Fila inválida para a Unidade de Negócio selecionada.');
                values.put('OrigemDistribuicao__c', 'Seleção Manual');
            }

            values.put('OwnerId', String.valueOf(queue.id));
            values.put('AcaoPosCategorizacao__c', 'Distribuir');
            values.put('DistribuicaoSolicitada__c', 'true');
            values.put('FilaDestinoDeveloperName__c', queue.developerName);
            values.put('FilaDestinoId__c', String.valueOf(queue.id));
            values.put('Status', 'Aberto');
            CaseCreationHelper.putIfNotBlank(values, 'EtapaAtendimento__c', 'Em Triagem');
        } else {
            throwFunctional('DESTINATION_REQUIRED', 'Selecione o destino do caso.');
        }

        if (request.originalDefaults != null) {
            for (String k : new List<String>{ 'AccountId', 'ContactId', 'ParentId' }) {
                if (!values.containsKey(k) && !String.isBlank(request.originalDefaults.get(k))) values.put(k, request.originalDefaults.get(k));
            }
        }

        CaseCreationDTO.BuildDefaultValuesResponseDTO out = new CaseCreationDTO.BuildDefaultValuesResponseDTO();
        out.defaultValues = values;
        out.warnings = new List<String>();
        out.errors = new List<String>();
        out.success = true;
        return out;
    }

    private static void validateCategorizationBase(CaseCreationDTO.CategorizationRequestDTO request) {
        if (request == null) throwFunctional('REQUIRED_CATEGORIZATION', 'Categorização é obrigatória.');
        if (request.recordTypeId == null) throwFunctional('REQUIRED_RECORD_TYPE', 'Record Type é obrigatório.');
        if (String.isBlank(request.unidadeNegocio) && !String.isBlank(request.recordTypeDeveloperName)) {
            CaseCreationSelector.UnidadeConfig c = CaseCreationSelector.findConfigForCaseRecordType(request.recordTypeDeveloperName, null);
            if (c != null) request.unidadeNegocio = c.unidadeNegocio;
        }
        if (String.isBlank(request.unidadeNegocio)) throwFunctional('REQUIRED_UNIDADE', 'Unidade de Negócio é obrigatória.');
    }

    private static void validateCategorizationPath(CaseCreationDTO.CategorizationRequestDTO request) {
        if (String.isBlank(request.tipoCaso)) throwFunctional('REQUIRED_TIPO', 'Tipo de Caso é obrigatório.');
        if (String.isBlank(request.categoria)) throwFunctional('REQUIRED_CATEGORIA', 'Categoria é obrigatória.');

        List<Categorizacao__c> rows = CaseCreationSelector.getActiveCategorizacoes(request.recordTypeDeveloperName, request.unidadeNegocio);
        Boolean match = false;
        for (Categorizacao__c row : rows) {
            if (CaseCreationHelper.sameNormalizedValue(row.TipoCaso__c, request.tipoCaso)
                && CaseCreationHelper.sameNormalizedValue(row.Categoria__c, request.categoria)
                && CaseCreationHelper.sameNormalizedValue(row.Assunto__c, request.assunto)
                && CaseCreationHelper.sameNormalizedValue(row.Subassunto__c, request.subassunto)) {
                match = true;
                break;
            }
        }
        if (!match) throwFunctional('INVALID_CATEGORIZATION', 'A combinação de categorização não está ativa ou não existe.');
    }

    private static Categorizacao__c findMatchingCategorization(CaseCreationDTO.CategorizationRequestDTO request) {
        List<Categorizacao__c> rows = CaseCreationSelector.getActiveCategorizacoes(request.recordTypeDeveloperName, request.unidadeNegocio);
        for (Categorizacao__c row : rows) {
            if (CaseCreationHelper.sameNormalizedValue(row.TipoCaso__c, request.tipoCaso)
                && CaseCreationHelper.sameNormalizedValue(row.Categoria__c, request.categoria)
                && CaseCreationHelper.sameNormalizedValue(row.Assunto__c, request.assunto)
                && CaseCreationHelper.sameNormalizedValue(row.Subassunto__c, request.subassunto)) {
                return row;
            }
        }
        return null;
    }

    private static String getLabelOrFieldValue(Categorizacao__c row, String labelAlias, String fieldApiName) {
        Map<String, Object> populated = row.getPopulatedFieldsAsMap();
        if (populated.containsKey(labelAlias) && populated.get(labelAlias) != null) return (String) populated.get(labelAlias);
        return (String) row.get(fieldApiName);
    }
}