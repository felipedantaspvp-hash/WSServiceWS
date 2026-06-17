/**
 * @description       : Service responsável pela lógica de negócio de AreaParticipante__c:
 *                      adição (unitária e bulk), encerramento, pausa, retomada e leitura de painel.
 *                      Coordena cálculo de SLA, validação de regras, atualização de campos do Case
 *                      e integridade de ciclos abertos.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteService {
    public class FunctionalException extends Exception {
        public String code;
    }
    private static final String AREA_FIELD = 'AreaAtendimento__c';
    private static Map<String, String> caseAreaLabelByValue;
    private static Map<String, String> statusLabelByValue;

    private static void throwFunctional(String code, String message) {
        FunctionalException ex = new FunctionalException(message);
        ex.code = code;
        throw ex;
    }

    private static Boolean isEnglish() {
        String lang = UserInfo.getLanguage();
        return !String.isBlank(lang) && lang.toLowerCase().startsWith('en');
    }

    private static String msg(String pt, String en) {
        return isEnglish() ? en : pt;
    }

    public static AreaParticipanteDTO.PanelDTO getPanelData(Id caseId) {
        validateReadPermissions();
        if (caseId == null) throwFunctional('REQUIRED_CASE_ID', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));

        Case caseRow = AreaParticipanteSelector.getCaseById(caseId);
        if (caseRow == null) throwFunctional('CASE_NOT_FOUND', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));

        List<AreaParticipante__c> areas = AreaParticipanteSelector.getAreasByCase(caseId);
        Datetime nowRef = System.now();

        AreaParticipanteDTO.PanelDTO out = new AreaParticipanteDTO.PanelDTO();
        out.caseId = caseRow.Id;
        out.caseNumber = caseRow.CaseNumber;
        out.etapaAtendimento = caseRow.EtapaAtendimento__c;
        out.areasAtivasMultipicklist = caseRow.AreasParticipantesSLA__c;
        out.totalAbertas = 0;
        out.totalVencidas = 0;
        out.totalConcluidas = 0;
        out.items = new List<AreaParticipanteDTO.AreaItemDTO>();
        out.areaOptions = new List<AreaParticipanteDTO.PicklistOptionDTO>();
        out.warnings = new List<String>();
        out.canManage = Schema.sObjectType.AreaParticipante__c.isUpdateable() && AreaParticipante__c.StatusAtuacao__c.getDescribe().isUpdateable();
        Set<String> occupiedAreas = new Set<String>();
        Set<String> eligibleAreas = AreaParticipanteSelector.getEligibleAreaValuesForCase(caseRow);

        Datetime nextDeadline;
        for (AreaParticipante__c row : areas) {
            AreaParticipanteDTO.AreaItemDTO item = toItem(row, nowRef, out.canManage);
            out.items.add(item);
            if (item.isConcluida) out.totalConcluidas++;
            if (item.isAberta || item.isVencida) out.totalAbertas++;
            if (item.isVencida) out.totalVencidas++;
            if (item.isAberta || item.isVencida) occupiedAreas.add(AreaParticipanteHelper.normalizeText(item.area));

            if ((item.isAberta || item.isVencida) && item.dataHoraPrazo != null) {
                if (nextDeadline == null || item.dataHoraPrazo.getTime() < nextDeadline.getTime()) {
                    nextDeadline = item.dataHoraPrazo;
                }
            }
        }
        for (Schema.PicklistEntry pe : Case.AreasParticipantesSLA__c.getDescribe().getPicklistValues()) {
            if (!pe.isActive()) continue;
            if (!eligibleAreas.contains(pe.getValue())) continue;
            if (occupiedAreas.contains(AreaParticipanteHelper.normalizeText(pe.getValue()))) continue;
            AreaParticipanteDTO.PicklistOptionDTO o = new AreaParticipanteDTO.PicklistOptionDTO();
            o.value = pe.getValue();
            o.label = pe.getLabel();
            out.areaOptions.add(o);
        }
        out.proximoPrazo = nextDeadline;
        return out;
    }

    public static AreaParticipanteDTO.AddResponseDTO addParticipation(AreaParticipanteDTO.AddRequestDTO request) {
        validateAddPermissions();
        if (request == null || request.caseId == null) throwFunctional('REQUIRED_CASE_ID', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));
        if (String.isBlank(request.area)) throwFunctional('REQUIRED_AREA', msg('Informe a área participante.', 'Provide the participant area.'));

        Case caseRow = AreaParticipanteSelector.getCaseById(request.caseId);
        if (caseRow == null) throwFunctional('CASE_NOT_FOUND', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));

        Set<String> allowedAreas = new Set<String>();
        for (Schema.PicklistEntry pe : Case.AreasParticipantesSLA__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) allowedAreas.add(pe.getValue());
        }
        String selectedArea = request.area;
        Boolean allowed = false;
        for (String value : allowedAreas) {
            if (AreaParticipanteHelper.normalizeText(value) == AreaParticipanteHelper.normalizeText(selectedArea)) {
                selectedArea = value;
                allowed = true;
                break;
            }
        }
        if (!allowed) throwFunctional('INVALID_AREA', msg('Área participante inválida.', 'Invalid participant area.'));
        if (!AreaParticipanteSelector.hasEligibleAreaRule(caseRow, selectedArea)) {
            throwFunctional(
                'SLA_RULE_NOT_FOUND',
                msg(
                    'Não existe regra de SLA ativa para a categorização, área participante e prioridade informadas.',
                    'There is no active SLA rule for this categorization, participant area, and priority.'
                )
            );
        }

        List<AreaParticipante__c> areas = AreaParticipanteSelector.getAreasByCase(request.caseId);
        for (AreaParticipante__c existing : areas) {
            if ((AreaParticipanteHelper.isAbertaOuAndamento(existing.StatusAtuacao__c) || AreaParticipanteHelper.isOverdue(existing.DataHoraPrazo__c, System.now(), existing.StatusAtuacao__c))
                && AreaParticipanteHelper.normalizeText((String) existing.get(AREA_FIELD)) == AreaParticipanteHelper.normalizeText(selectedArea)) {
                throwFunctional('DUPLICATE_OPEN_AREA', msg('Já existe participação ativa para esta área.', 'An active participation already exists for this area.'));
            }
        }

        if (String.isBlank(request.comentarioSolicitacao)) {
            throwFunctional('REQUIRED_REQUEST_COMMENT', msg('Informe o comentário de solicitação.', 'Provide the request comment.'));
        }

        AreaParticipante__c row = new AreaParticipante__c();
        row.Caso__c = request.caseId;
        row.put(AREA_FIELD, selectedArea);
        row.TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA;
        row.OrigemAtuacao__c = 'Manual';
        row.StatusAtuacao__c = AreaParticipanteHelper.resolveOpenStatusValue();
        row.DataHoraInicio__c = System.now();
        row.ComentarioSolicitacao__c = request.comentarioSolicitacao;
        if (AreaParticipante__c.Solicitante__c.getDescribe().isCreateable()) row.Solicitante__c = UserInfo.getUserId();

        String updatedAreas = AreaParticipanteHelper.addValue(caseRow.AreasParticipantesSLA__c, selectedArea);
        caseRow.AreasParticipantesSLA__c = updatedAreas;
        caseRow.AreasParticipantes__c = AreaParticipanteHelper.addValue(caseRow.AreasParticipantes__c, selectedArea);

        if (Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
            String etapaNorm = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
            String statusNorm = AreaParticipanteHelper.normalizeText(caseRow.Status);
            Boolean addIsTerminal = statusNorm.contains('fechad') || etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
            if (!addIsTerminal) {
                caseRow.EtapaAtendimento__c = 'Aguardando Área Interna';
            }
        }

        try {
            insert row;
            update caseRow;
        } catch (DmlException ex) {
            String message = ex.getNumDml() > 0 ? ex.getDmlMessage(0) : ex.getMessage();
            throwFunctional('DML_ERROR', String.isBlank(message) ? msg('Não foi possível adicionar a participação.', 'Could not add participation.') : message);
        }

        AreaParticipanteDTO.AddResponseDTO out = new AreaParticipanteDTO.AddResponseDTO();
        out.success = true;
        out.message = msg('Área participante adicionada com sucesso.', 'Participant area added successfully.');
        out.caseId = caseRow.Id;
        out.areaParticipanteId = row.Id;
        out.updatedAreas = updatedAreas;
        return out;
    }

    /**
     * @description Adiciona múltiplas áreas participantes a um Case em uma única operação DML.
     *              Valida permissões, unicidade de área, existência de regra de SLA ativa e comentário obrigatório
     *              por área antes de inserir. Atualiza campos multipicklist e EtapaAtendimento__c do Case ao final.
     * @param request AddBulkRequestDTO contendo caseId e lista de AddBulkItemDTO (área + comentário).
     * @return AddBulkResponseDTO com sucesso, contagem de registros inseridos e mensagem localizada.
     **/
    public static AreaParticipanteDTO.AddBulkResponseDTO addParticipationBulk(AreaParticipanteDTO.AddBulkRequestDTO request) {
        validateAddPermissions();
        if (request == null || request.caseId == null) throwFunctional('REQUIRED_CASE_ID', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));
        if (request.items == null || request.items.isEmpty()) throwFunctional('REQUIRED_ITEMS', msg('Informe ao menos uma área participante.', 'Provide at least one participant area.'));

        Case caseRow = AreaParticipanteSelector.getCaseById(request.caseId);
        if (caseRow == null) throwFunctional('CASE_NOT_FOUND', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));

        Map<String, String> normalizedToCanonical = new Map<String, String>();
        for (Schema.PicklistEntry pe : Case.AreasParticipantesSLA__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) normalizedToCanonical.put(AreaParticipanteHelper.normalizeText(pe.getValue()), pe.getValue());
        }

        Set<String> eligibleAreas = AreaParticipanteSelector.getEligibleAreaValuesForCase(caseRow);

        List<AreaParticipante__c> existingAreas = AreaParticipanteSelector.getAreasByCase(request.caseId);
        Set<String> occupiedNormalized = new Set<String>();
        Datetime nowRef = System.now();
        for (AreaParticipante__c ea : existingAreas) {
            if (AreaParticipanteHelper.isAbertaOuAndamento(ea.StatusAtuacao__c) || AreaParticipanteHelper.isOverdue(ea.DataHoraPrazo__c, nowRef, ea.StatusAtuacao__c)) {
                occupiedNormalized.add(AreaParticipanteHelper.normalizeText((String) ea.get(AREA_FIELD)));
            }
        }

        List<AreaParticipante__c> toInsert = new List<AreaParticipante__c>();
        Set<String> addedNormalized = new Set<String>();

        for (AreaParticipanteDTO.AddBulkItemDTO item : request.items) {
            if (String.isBlank(item.area)) throwFunctional('REQUIRED_AREA', msg('Informe a área participante.', 'Provide the participant area.'));
            if (String.isBlank(item.comentarioSolicitacao)) throwFunctional('REQUIRED_REQUEST_COMMENT', msg('Informe o comentário de solicitação.', 'Provide the request comment.'));

            String normalizedItem = AreaParticipanteHelper.normalizeText(item.area);
            String selectedArea = normalizedToCanonical.get(normalizedItem);
            if (selectedArea == null) throwFunctional('INVALID_AREA', msg('Área participante inválida: ' + item.area, 'Invalid participant area: ' + item.area));
            if (!eligibleAreas.contains(selectedArea)) {
                throwFunctional('SLA_RULE_NOT_FOUND', msg(
                    'Não existe regra de SLA ativa para a área: ' + selectedArea,
                    'No active SLA rule for area: ' + selectedArea
                ));
            }
            String normalizedSelected = AreaParticipanteHelper.normalizeText(selectedArea);
            if (occupiedNormalized.contains(normalizedSelected)) {
                throwFunctional('DUPLICATE_OPEN_AREA', msg('Já existe participação ativa para a área: ' + selectedArea, 'An active participation already exists for area: ' + selectedArea));
            }
            if (addedNormalized.contains(normalizedSelected)) {
                throwFunctional('DUPLICATE_IN_REQUEST', msg('Área duplicada na solicitação: ' + selectedArea, 'Duplicate area in request: ' + selectedArea));
            }
            addedNormalized.add(normalizedSelected);

            AreaParticipante__c row = new AreaParticipante__c();
            row.Caso__c = request.caseId;
            row.put(AREA_FIELD, selectedArea);
            row.TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA;
            row.OrigemAtuacao__c = 'Manual';
            row.StatusAtuacao__c = AreaParticipanteHelper.resolveOpenStatusValue();
            row.DataHoraInicio__c = nowRef;
            row.ComentarioSolicitacao__c = item.comentarioSolicitacao;
            if (AreaParticipante__c.Solicitante__c.getDescribe().isCreateable()) row.Solicitante__c = UserInfo.getUserId();
            toInsert.add(row);

            caseRow.AreasParticipantesSLA__c = AreaParticipanteHelper.addValue(caseRow.AreasParticipantesSLA__c, selectedArea);
            caseRow.AreasParticipantes__c = AreaParticipanteHelper.addValue(caseRow.AreasParticipantes__c, selectedArea);
        }

        if (Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
            String etapaNorm = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
            String statusNorm = AreaParticipanteHelper.normalizeText(caseRow.Status);
            Boolean isTerminal = statusNorm.contains('fechad') || etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
            if (!isTerminal) caseRow.EtapaAtendimento__c = 'Aguardando Área Interna';
        }

        try {
            insert toInsert;
            update caseRow;
        } catch (DmlException ex) {
            String message = ex.getNumDml() > 0 ? ex.getDmlMessage(0) : ex.getMessage();
            throwFunctional('DML_ERROR', String.isBlank(message) ? msg('Não foi possível adicionar as participações.', 'Could not add participations.') : message);
        }

        AreaParticipanteDTO.AddBulkResponseDTO out = new AreaParticipanteDTO.AddBulkResponseDTO();
        out.success = true;
        out.count = toInsert.size();
        out.message = msg(toInsert.size() + ' área(s) participante(s) adicionada(s) com sucesso.', toInsert.size() + ' participant area(s) added successfully.');
        return out;
    }

    public static AreaParticipanteDTO.CloseResponseDTO closeParticipation(AreaParticipanteDTO.CloseRequestDTO request) {
        validateUpdatePermissions();
        if (request == null || request.areaParticipanteId == null) throwFunctional('REQUIRED_AREA_ID', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));

        AreaParticipante__c row = AreaParticipanteSelector.getAreaById(request.areaParticipanteId);
        if (row == null) throwFunctional('AREA_NOT_FOUND', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));
        if (row.Caso__c == null) throwFunctional('CASE_NOT_FOUND', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));

        if (AreaParticipanteHelper.isConcluida(row.StatusAtuacao__c)) {
            throwFunctional('ALREADY_CLOSED', msg('Esta participação já foi concluída.', 'This participation is already closed.'));
        }
        if (AreaParticipanteHelper.isCancelada(row.StatusAtuacao__c)) {
            throwFunctional('ALREADY_CANCELED', msg('Esta participação já foi cancelada.', 'This participation is already canceled.'));
        }
        if (!AreaParticipanteHelper.isAbertaOuAndamento(row.StatusAtuacao__c) && !AreaParticipanteHelper.isOverdue(row.DataHoraPrazo__c, System.now(), row.StatusAtuacao__c)) {
            throwFunctional('INVALID_STATUS', msg('Esta participação não pode ser encerrada.', 'This participation cannot be closed.'));
        }

        if (String.isBlank(request.comentarioRetorno)) throwFunctional('REQUIRED_COMMENT', msg('Informe o comentário de retorno.', 'Provide the return comment.'));
        if (String.isBlank(request.solucaoRetorno)) throwFunctional('REQUIRED_SOLUTION', msg('Informe a solução ou retorno da área.', 'Provide the area solution/return.'));

        Case caseRow = AreaParticipanteSelector.getCaseById(row.Caso__c);
        if (caseRow == null) throwFunctional('CASE_NOT_FOUND', msg('Caso não encontrado ou sem acesso.', 'Case not found or no access.'));

        Datetime nowRef = System.now();
        row.StatusAtuacao__c = AreaParticipanteHelper.resolveConcluidaStatusValue();
        row.DataHoraFim__c = nowRef;
        row.ComentarioRetorno__c = request.comentarioRetorno;
        row.SolucaoTomada__c = request.solucaoRetorno;
        if (AreaParticipante__c.FinalizadoPor__c.getDescribe().isUpdateable()) {
            row.FinalizadoPor__c = UserInfo.getUserId();
        }
        if (AreaParticipante__c.ViolouSLA__c.getDescribe().isUpdateable()) {
            row.ViolouSLA__c = row.DataHoraPrazo__c != null && nowRef.getTime() > row.DataHoraPrazo__c.getTime();
        }
        if (AreaParticipante__c.PercentualDecorrido__c.getDescribe().isUpdateable() && row.DataHoraInicio__c != null && row.DataHoraPrazo__c != null) {
            row.PercentualDecorrido__c = AreaParticipanteHelper.calculatePercent(row.DataHoraInicio__c, row.DataHoraPrazo__c, nowRef);
        }

        String beforeAreas = caseRow.AreasParticipantesSLA__c;
        String removedArea = (String) row.get(AREA_FIELD);
        caseRow.AreasParticipantesSLA__c = AreaParticipanteHelper.removeValue(caseRow.AreasParticipantesSLA__c, removedArea);

        Boolean rowIsCustomInterna = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(row.TipoAreaParticipante__c)
            && AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(row.OrigemSLA__c);

        List<AreaParticipante__c> remainingRows = AreaParticipanteSelector.getAreasByCase(caseRow.Id);
        Integer openCustomInterna = 0;
        for (AreaParticipante__c other : remainingRows) {
            if (other.Id == row.Id) continue;
            if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(other.TipoAreaParticipante__c)) continue;
            if (!AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(other.OrigemSLA__c)) continue;
            if (AreaParticipanteHelper.isAbertaOuAndamento(other.StatusAtuacao__c) || AreaParticipanteHelper.isOverdue(other.DataHoraPrazo__c, nowRef, other.StatusAtuacao__c)) {
                openCustomInterna++;
            }
        }

        Boolean etapaUpdated = false;
        String novaEtapa;
        List<String> warnings = new List<String>();

        String etapaNormClose = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
        String statusNormClose = AreaParticipanteHelper.normalizeText(caseRow.Status);
        Boolean caseIsTerminal = statusNormClose.contains('fechad') || etapaNormClose.contains('conclu') || etapaNormClose.contains('cancel');

        if (rowIsCustomInterna && !caseIsTerminal && Case.EtapaAtendimento__c.getDescribe().isUpdateable() && openCustomInterna == 0) {
            caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
            etapaUpdated = true;
            novaEtapa = caseRow.EtapaAtendimento__c;
        }

        try {
            update row;
            update caseRow;
        } catch (DmlException ex) {
            if (beforeAreas != caseRow.AreasParticipantesSLA__c) {
                throwFunctional('CASE_SYNC_ERROR', msg('Não foi possível atualizar as áreas participantes do Caso.', 'Could not update Case participant areas.'));
            }
            throw ex;
        }

        AreaParticipanteDTO.CloseResponseDTO out = new AreaParticipanteDTO.CloseResponseDTO();
        out.success = true;
        out.message = msg('Participação encerrada com sucesso.', 'Participation closed successfully.');
        out.caseId = caseRow.Id;
        out.removedArea = removedArea;
        out.remainingAreas = caseRow.AreasParticipantesSLA__c;
        out.etapaAtualizada = etapaUpdated;
        out.novaEtapa = novaEtapa;
        out.warnings = warnings;
        return out;
    }

    public static AreaParticipanteDTO.PauseResumeResponseDTO pauseParticipation(AreaParticipanteDTO.PauseResumeRequestDTO request) {
        validatePauseResumePermissions();
        if (request == null || request.areaParticipanteId == null) {
            throwFunctional('REQUIRED_AREA_ID', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));
        }

        Map<Id, AreaParticipante__c> rowsById = new Map<Id, AreaParticipante__c>(
            AreaParticipanteSelector.getAreasByIds(new Set<Id>{ request.areaParticipanteId })
        );
        AreaParticipante__c row = rowsById.get(request.areaParticipanteId);
        if (row == null) throwFunctional('AREA_NOT_FOUND', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));

        pauseRows(new List<AreaParticipante__c>{ row }, System.now());
        return toPauseResumeResponse(row, msg('Participação pausada com sucesso.', 'Participation paused successfully.'));
    }

    public static AreaParticipanteDTO.PauseResumeResponseDTO resumeParticipation(AreaParticipanteDTO.PauseResumeRequestDTO request) {
        validatePauseResumePermissions();
        if (request == null || request.areaParticipanteId == null) {
            throwFunctional('REQUIRED_AREA_ID', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));
        }

        Map<Id, AreaParticipante__c> rowsById = new Map<Id, AreaParticipante__c>(
            AreaParticipanteSelector.getAreasByIds(new Set<Id>{ request.areaParticipanteId })
        );
        AreaParticipante__c row = rowsById.get(request.areaParticipanteId);
        if (row == null) throwFunctional('AREA_NOT_FOUND', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));

        resumeRows(new List<AreaParticipante__c>{ row }, System.now());
        return toPauseResumeResponse(row, msg('Participação retomada com sucesso.', 'Participation resumed successfully.'));
    }

    @TestVisible
    private static void pauseRows(List<AreaParticipante__c> rows, Datetime nowRef) {
        if (rows == null || rows.isEmpty()) return;
        for (AreaParticipante__c row : rows) {
            validateManualPauseResumeTarget(row);
            if (row.DataHoraInicioPausa__c != null || row.StatusSLA__c == AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO) {
                throwFunctional('ALREADY_PAUSED', msg('Esta participação já está pausada.', 'This participation is already paused.'));
            }
            if (!AreaParticipanteSLAHelper.isOpenStatus(row.StatusAtuacao__c)) {
                throwFunctional('INVALID_STATUS', msg('Esta participação não pode ser pausada.', 'This participation cannot be paused.'));
            }
        }

        for (AreaParticipante__c row : rows) {
            row.StatusAtuacaoAnteriorPausa__c = row.StatusAtuacao__c;
            row.DataHoraInicioPausa__c = nowRef;
            row.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
        }
        update rows;
    }

    @TestVisible
    private static void resumeRows(List<AreaParticipante__c> rows, Datetime nowRef) {
        if (rows == null || rows.isEmpty()) return;
        Map<String, Id> bhByName = new Map<String, Id>();
        for (AreaParticipante__c row : rows) {
            validateManualPauseResumeTarget(row);
            if (row.DataHoraInicioPausa__c == null) {
                throwFunctional('NOT_PAUSED', msg('Esta participação não está pausada.', 'This participation is not paused.'));
            }
            String bhName = row.RegraSLACategorizacao__r == null ? null : row.RegraSLACategorizacao__r.BusinessHoursName__c;
            if (String.isBlank(bhName)) {
                throwFunctional('BUSINESS_HOURS_NOT_FOUND', msg('Regra de SLA sem horário comercial para retomada.', 'SLA rule has no business hours for resume.'));
            }
            if (!bhByName.containsKey(bhName)) {
                bhByName.put(bhName, BusinessHoursResolverService.resolveActiveByName(bhName));
            }
        }

        for (AreaParticipante__c row : rows) {
            String bhName = row.RegraSLACategorizacao__r.BusinessHoursName__c;
            Id bhId = bhByName.get(bhName);
            Long pausedMs = useBypassBusinessHoursInTests()
                ? nowRef.getTime() - row.DataHoraInicioPausa__c.getTime()
                : BusinessHours.diff(bhId, row.DataHoraInicioPausa__c, nowRef);
            pausedMs = Math.max(0, pausedMs);
            Long pausedMin = pausedMs / (60L * 1000L);
            row.TempoPausadoMinutos__c = (row.TempoPausadoMinutos__c == null ? 0 : row.TempoPausadoMinutos__c) + pausedMin;
            if (row.DataHoraPrazo__c != null) {
                row.DataHoraPrazo__c = useBypassBusinessHoursInTests()
                    ? row.DataHoraPrazo__c.addSeconds(Integer.valueOf(String.valueOf(pausedMs / 1000L)))
                    : BusinessHours.add(bhId, row.DataHoraPrazo__c, pausedMs);
            }
            row.DataHoraInicioPausa__c = null;
            row.StatusAtuacaoAnteriorPausa__c = null;
            row.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO;
        }
        AreaParticipanteSLAService.calculateCacheBulk(rows, nowRef);
        update rows;
    }

    private static void validateManualPauseResumeTarget(AreaParticipante__c row) {
        if (row == null) throwFunctional('AREA_NOT_FOUND', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));
        if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(row.TipoAreaParticipante__c)
            || !AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(row.OrigemSLA__c)) {
            throwFunctional('NOT_CUSTOM_INTERNAL_AREA', msg('Somente Área Interna Custom pode ser pausada ou retomada.', 'Only Custom Internal Area can be paused or resumed.'));
        }
        if (AreaParticipanteHelper.isConcluida(row.StatusAtuacao__c) || row.DataHoraFim__c != null) {
            throwFunctional('ALREADY_CLOSED', msg('Esta participação já foi concluída.', 'This participation is already closed.'));
        }
        if (AreaParticipanteHelper.isCancelada(row.StatusAtuacao__c)) {
            throwFunctional('ALREADY_CANCELED', msg('Esta participação já foi cancelada.', 'This participation is already canceled.'));
        }
    }

    private static AreaParticipanteDTO.PauseResumeResponseDTO toPauseResumeResponse(AreaParticipante__c row, String message) {
        AreaParticipanteDTO.PauseResumeResponseDTO out = new AreaParticipanteDTO.PauseResumeResponseDTO();
        out.success = true;
        out.message = message;
        out.caseId = row.Caso__c;
        out.areaParticipanteId = row.Id;
        out.statusAtuacao = row.StatusAtuacao__c;
        out.statusSLA = row.StatusSLA__c;
        out.dataHoraInicioPausa = row.DataHoraInicioPausa__c;
        out.tempoPausadoMinutos = row.TempoPausadoMinutos__c;
        return out;
    }

    public static AreaParticipanteDTO.DetailDTO getParticipationDetails(Id areaParticipanteId) {
        validateReadPermissions();
        if (areaParticipanteId == null) throwFunctional('REQUIRED_AREA_ID', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));
        AreaParticipante__c row = AreaParticipanteSelector.getAreaById(areaParticipanteId);
        if (row == null) throwFunctional('AREA_NOT_FOUND', msg('Área participante não encontrada ou sem acesso.', 'Participant area not found or no access.'));

        AreaParticipanteDTO.DetailDTO out = new AreaParticipanteDTO.DetailDTO();
        out.item = toItem(row, System.now(), false);
        out.warnings = new List<String>();
        return out;
    }

    private static void validateReadPermissions() {
        if (!Schema.sObjectType.Case.isAccessible() || !Schema.sObjectType.AreaParticipante__c.isAccessible()) {
            throwFunctional('CRUD_DENIED', msg('Você não possui permissão para encerrar esta participação.', 'You do not have permission to close this participation.'));
        }
    }

    private static void validateUpdatePermissions() {
        validateReadPermissions();
        if (!Schema.sObjectType.Case.isUpdateable() || !Schema.sObjectType.AreaParticipante__c.isUpdateable()) {
            throwFunctional('CRUD_DENIED', msg('Você não possui permissão para encerrar esta participação.', 'You do not have permission to close this participation.'));
        }
        if (!AreaParticipante__c.StatusAtuacao__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.ComentarioRetorno__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.SolucaoTomada__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.DataHoraFim__c.getDescribe().isUpdateable()) {
            throwFunctional('FLS_DENIED', msg('Você não possui permissão para encerrar esta participação.', 'You do not have permission to close this participation.'));
        }
        if (!Case.AreasParticipantesSLA__c.getDescribe().isUpdateable()) {
            throwFunctional('FLS_DENIED', msg('Você não possui permissão para encerrar esta participação.', 'You do not have permission to close this participation.'));
        }
    }

    private static void validatePauseResumePermissions() {
        validateReadPermissions();
        if (!Schema.sObjectType.AreaParticipante__c.isUpdateable()) {
            throwFunctional('CRUD_DENIED', msg('Você não possui permissão para pausar ou retomar esta participação.', 'You do not have permission to pause or resume this participation.'));
        }
        if (!AreaParticipante__c.DataHoraInicioPausa__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.StatusAtuacaoAnteriorPausa__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.StatusSLA__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.TempoPausadoMinutos__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.DataHoraPrazo__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.TempoConsumidoMinutos__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.TempoRestanteMinutos__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.PercentualDecorrido__c.getDescribe().isUpdateable()
            || !AreaParticipante__c.ViolouSLA__c.getDescribe().isUpdateable()) {
            throwFunctional('FLS_DENIED', msg('Você não possui permissão para pausar ou retomar esta participação.', 'You do not have permission to pause or resume this participation.'));
        }
    }

    private static void validateAddPermissions() {
        validateReadPermissions();
        if (!Schema.sObjectType.Case.isUpdateable() || !Schema.sObjectType.AreaParticipante__c.isCreateable()) {
            throwFunctional('CRUD_DENIED', msg('Você não possui permissão para adicionar participação.', 'You do not have permission to add participation.'));
        }
        if (!AreaParticipante__c.Caso__c.getDescribe().isCreateable()
            || !Schema.sObjectType.AreaParticipante__c.fields.getMap().get(AREA_FIELD).getDescribe().isCreateable()
            || !AreaParticipante__c.StatusAtuacao__c.getDescribe().isCreateable()
            || !AreaParticipante__c.DataHoraInicio__c.getDescribe().isCreateable()
            || !AreaParticipante__c.ComentarioSolicitacao__c.getDescribe().isCreateable()) {
            throwFunctional('FLS_DENIED', msg('Você não possui permissão para adicionar participação.', 'You do not have permission to add participation.'));
        }
        if (!Case.AreasParticipantesSLA__c.getDescribe().isUpdateable()
            || !Case.AreasParticipantes__c.getDescribe().isUpdateable()) {
            throwFunctional('FLS_DENIED', msg('Você não possui permissão para adicionar participação.', 'You do not have permission to add participation.'));
        }
    }

    private static Boolean useBypassBusinessHoursInTests() {
        return Test.isRunningTest() && AreaParticipanteSLAService.bypassBusinessHoursMathForTests == true;
    }

    private static Map<String, String> getCaseAreaLabelByValue() {
        if (caseAreaLabelByValue == null) {
            caseAreaLabelByValue = new Map<String, String>();
            for (Schema.PicklistEntry pe : Case.AreasParticipantesSLA__c.getDescribe().getPicklistValues()) {
                caseAreaLabelByValue.put(pe.getValue(), pe.getLabel());
            }
        }
        return caseAreaLabelByValue;
    }

    private static Map<String, String> getStatusLabelByValue() {
        if (statusLabelByValue == null) {
            statusLabelByValue = new Map<String, String>();
            for (Schema.PicklistEntry pe : AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues()) {
                statusLabelByValue.put(pe.getValue(), pe.getLabel());
            }
        }
        return statusLabelByValue;
    }

    private static String resolvePicklistLabel(Map<String, String> labelsByValue, String value) {
        if (String.isBlank(value) || labelsByValue == null) {
            return value;
        }
        String label = labelsByValue.get(value);
        if (!String.isBlank(label)) {
            return label;
        }
        String normalizedValue = AreaParticipanteHelper.normalizeText(value);
        for (String key : labelsByValue.keySet()) {
            if (AreaParticipanteHelper.normalizeText(key) == normalizedValue) {
                String normalizedLabel = labelsByValue.get(key);
                return String.isBlank(normalizedLabel) ? value : normalizedLabel;
            }
        }
        return value;
    }

    private static String resolveStatusVisualLabel(AreaParticipante__c row, Datetime nowRef) {
        Boolean isDone = AreaParticipanteHelper.isConcluida(row.StatusAtuacao__c);
        Boolean isCanceled = AreaParticipanteHelper.isCancelada(row.StatusAtuacao__c);
        Boolean isOverdue = AreaParticipanteHelper.isOverdue(row.DataHoraPrazo__c, nowRef, row.StatusAtuacao__c);
        if (isCanceled) {
            return msg('Cancelada', 'Canceled');
        }
        if (isDone) {
            return msg('Concluída', 'Completed');
        }
        if (isOverdue) {
            return msg('Vencida', 'Overdue');
        }
        return msg('Aberta', 'Open');
    }

    private static Boolean canPause(AreaParticipante__c row, Boolean canManage) {
        if (!canManage || row == null) return false;
        if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(row.TipoAreaParticipante__c)) return false;
        if (!AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(row.OrigemSLA__c)) return false;
        if (AreaParticipanteHelper.isConcluida(row.StatusAtuacao__c) || row.DataHoraFim__c != null) return false;
        if (AreaParticipanteHelper.isCancelada(row.StatusAtuacao__c)) return false;
        if (row.DataHoraInicioPausa__c != null || row.StatusSLA__c == AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO) return false;
        return AreaParticipanteSLAHelper.isOpenStatus(row.StatusAtuacao__c);
    }

    private static Boolean canResume(AreaParticipante__c row, Boolean canManage) {
        if (!canManage || row == null) return false;
        if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(row.TipoAreaParticipante__c)) return false;
        if (!AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(row.OrigemSLA__c)) return false;
        if (AreaParticipanteHelper.isConcluida(row.StatusAtuacao__c) || row.DataHoraFim__c != null) return false;
        if (AreaParticipanteHelper.isCancelada(row.StatusAtuacao__c)) return false;
        return row.DataHoraInicioPausa__c != null || row.StatusSLA__c == AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
    }

    private static AreaParticipanteDTO.AreaItemDTO toItem(AreaParticipante__c row, Datetime nowRef, Boolean canManage) {
        AreaParticipanteDTO.AreaItemDTO item = new AreaParticipanteDTO.AreaItemDTO();
        item.id = row.Id;
        item.area = (String) row.get(AREA_FIELD);
        item.areaLabel = resolvePicklistLabel(getCaseAreaLabelByValue(), (String) row.get(AREA_FIELD));
        item.status = row.StatusAtuacao__c;
        item.statusLabel = resolveStatusVisualLabel(row, nowRef);
        item.dataHoraInicio = row.DataHoraInicio__c;
        item.dataHoraPrazo = row.DataHoraPrazo__c;
        item.dataHoraFim = row.DataHoraFim__c;
        item.percentualDecorrido = AreaParticipanteHelper.calculatePercent(row.DataHoraInicio__c, row.DataHoraPrazo__c, nowRef);
        item.tempoTexto = AreaParticipanteHelper.buildTempoTexto(nowRef, row.DataHoraPrazo__c, row.DataHoraFim__c);
        item.prazoTexto = row.DataHoraPrazo__c == null ? msg('Prazo não informado', 'No deadline informed') : msg('Prazo definido', 'Deadline defined');
        item.isConcluida = AreaParticipanteHelper.isConcluida(row.StatusAtuacao__c);
        item.isCancelada = AreaParticipanteHelper.isCancelada(row.StatusAtuacao__c);
        item.isVencida = AreaParticipanteHelper.isOverdue(row.DataHoraPrazo__c, nowRef, row.StatusAtuacao__c);
        item.isAberta = !item.isConcluida && !item.isCancelada && !item.isVencida;
        item.violouSLA = row.ViolouSLA__c == true || item.isVencida;
        item.statusSLA = row.StatusSLA__c;
        item.tempoSLAMinutos = row.TempoSLAMinutos__c;
        item.tempoPausadoMinutos = row.TempoPausadoMinutos__c;
        item.tempoConsumidoMinutos = row.TempoConsumidoMinutos__c;
        item.tempoRestanteMinutos = row.TempoRestanteMinutos__c;
        item.sequenciaAcionamento = row.SequenciaAcionamento__c;
        item.responsavelNome = row.Responsavel__c;
        item.comentarioSolicitacao = row.ComentarioSolicitacao__c;
        item.comentarioRetorno = row.ComentarioRetorno__c;
        item.solucaoRetorno = row.SolucaoTomada__c;
        item.nomeMarco = row.NomeMarco__c;
        item.caseMilestoneId = row.CaseMilestoneId__c;
        item.canClose = canManage && (item.isAberta || item.isVencida);
        item.canPause = canPause(row, canManage);
        item.canResume = canResume(row, canManage);
        item.canCancel = false;
        item.cssClass = item.isVencida ? 'item overdue' : (item.isConcluida ? 'item done' : 'item open');
        item.progressClass = item.isVencida ? 'progress-overdue' : ((item.percentualDecorrido != null && item.percentualDecorrido >= 80) ? 'progress-warning' : 'progress-ok');
        return item;
    }
}