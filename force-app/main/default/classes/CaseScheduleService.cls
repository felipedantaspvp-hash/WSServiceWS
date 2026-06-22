/**
 * Service that evaluates active Agendamento__c records and creates recurring Cases.
 */
public with sharing class CaseScheduleService {
    private static final String OWNER_TYPE_USER = 'USER';
    private static final String OWNER_TYPE_QUEUE = 'QUEUE';
    private static final String ORIGIN_RECORRENTE = 'Recorrente';
    private static final String ORIGIN_AGENDAMENTO = 'Agendamento';
    private static final String STATUS_OPEN = 'Aberto';
    private static final String STEP_IN_SERVICE = 'Em Atendimento';
    private static final String STEP_IN_TRIAGE = 'Em Triagem';
    private static final String ACTION_ASSUME = 'Assumir';
    private static final String ACTION_DISTRIBUTE = 'Distribuir';
    private static final String DISTRIBUTION_SCHEDULE = 'Agendamento';
    private static final String DISTRIBUTION_CATEGORIZATION = 'Categorização';

    @TestVisible private static Datetime testNow;

    /**
     * @param schedules Active Agendamento__c records loaded by the batch.
     * @return Processing result per supplied schedule.
     */
    public static List<CaseScheduleResultDTO> processSchedules(List<Agendamento__c> schedules) {
        List<CaseScheduleResultDTO> results = new List<CaseScheduleResultDTO>();
        if (schedules == null || schedules.isEmpty()) {
            return results;
        }

        Datetime nowValue = testNow == null ? System.now() : testNow;
        ProcessingContext context = prepareContext(schedules, nowValue);
        List<Case> casesToInsert = new List<Case>();
        List<Id> scheduleIdsByCaseIndex = new List<Id>();
        Map<Id, Agendamento__c> schedulesToUpdateById = new Map<Id, Agendamento__c>();
        List<SObject> logsToInsert = new List<SObject>();
        Map<Id, Agendamento__c> scheduleById = new Map<Id, Agendamento__c>();
        for (Agendamento__c schedule : schedules) {
            if (schedule != null && schedule.Id != null) {
                scheduleById.put(schedule.Id, schedule);
            }
        }

        for (Agendamento__c schedule : schedules) {
            CaseScheduleResultDTO result;
            try {
                result = processSingleSchedule(schedule, context, nowValue, casesToInsert, scheduleIdsByCaseIndex);
                if (result != null && schedule != null && schedule.Id != null) {
                    if (result.success == false) {
                        schedulesToUpdateById.put(schedule.Id, buildErrorUpdate(schedule, result.errorMessage, nowValue));
                        SObject logRow = CaseScheduleHelper.buildErrorLog(schedule, result.errorMessage);
                        if (logRow != null) {
                            logsToInsert.add(logRow);
                        }
                    } else if (result.skipped == true && schedule.ProximaExecucao__c == null) {
                        schedulesToUpdateById.put(schedule.Id, buildNextExecutionUpdate(schedule, nowValue));
                    }
                }
            } catch (Exception ex) {
                String message = sanitizeError(ex);
                result = CaseScheduleResultDTO.error(schedule == null ? null : schedule.Id, message);
                if (schedule != null && schedule.Id != null) {
                    schedulesToUpdateById.put(schedule.Id, buildErrorUpdate(schedule, message, nowValue));
                }
                SObject logRow = CaseScheduleHelper.buildErrorLog(schedule, ex.getMessage());
                if (logRow != null) {
                    logsToInsert.add(logRow);
                }
            }
            if (result != null) {
                results.add(result);
            }
        }

        persistCases(casesToInsert, scheduleIdsByCaseIndex, scheduleById, schedulesToUpdateById, results, logsToInsert, nowValue);
        if (!schedulesToUpdateById.isEmpty()) {
            Database.update(schedulesToUpdateById.values(), false);
        }
        CaseScheduleHelper.insertIntegrationLogs(logsToInsert);
        return results;
    }

    /**
     * @param schedule Schedule to evaluate.
     * @param nowValue Reference date and time.
     * @return True when the schedule should run now.
     */
    public static Boolean isEligibleToRun(Agendamento__c schedule, Datetime nowValue) {
        if (schedule == null || nowValue == null) {
            return false;
        }
        if (schedule.Ativo__c != true || schedule.DataInicio__c == null || schedule.HorarioExecucao__c == null || String.isBlank(schedule.Frequencia__c)) {
            return false;
        }

        Date today = nowValue.date();
        if (today < schedule.DataInicio__c) {
            return false;
        }
        if (today == schedule.DataInicio__c && nowValue.time() < schedule.HorarioExecucao__c) {
            return false;
        }
        if (schedule.PularFimDeSemana__c == true && isWeekend(today)) {
            return false;
        }
        if (normalizeFrequency(schedule.Frequencia__c) == 'SPECIFIC_WEEKDAYS' && String.isBlank(schedule.DiasDaSemana__c)) {
            return false;
        }
        return matchesFrequency(schedule, today);
    }

    /**
     * @param schedule Schedule to evaluate.
     * @param nowValue Reference date and time.
     * @return Idempotency execution window for the supplied date.
     */
    public static CaseScheduleExecutionWindowDTO buildExecutionWindow(Agendamento__c schedule, Datetime nowValue) {
        if (schedule == null || nowValue == null) {
            return null;
        }
        String normalizedFrequency = normalizeFrequency(schedule.Frequencia__c);
        Date today = nowValue.date();

        CaseScheduleExecutionWindowDTO out = new CaseScheduleExecutionWindowDTO();
        out.scheduleId = schedule.Id;
        out.frequency = schedule.Frequencia__c;

        if (normalizedFrequency == 'WEEKLY') {
            out.windowStartDate = today.addDays(1 - dayOfWeek(today));
            out.windowEndDate = out.windowStartDate.addDays(6);
        } else if (normalizedFrequency == 'MONTHLY') {
            out.windowStartDate = Date.newInstance(today.year(), today.month(), 1);
            out.windowEndDate = Date.newInstance(today.year(), today.month(), Date.daysInMonth(today.year(), today.month()));
        } else if (normalizedFrequency == 'QUARTERLY') {
            Integer startMonth = quarterStartMonth(today.month());
            out.windowStartDate = Date.newInstance(today.year(), startMonth, 1);
            Integer endMonth = startMonth + 2;
            out.windowEndDate = Date.newInstance(today.year(), endMonth, Date.daysInMonth(today.year(), endMonth));
        } else if (normalizedFrequency == 'ANNUAL') {
            out.windowStartDate = Date.newInstance(today.year(), 1, 1);
            out.windowEndDate = Date.newInstance(today.year(), 12, 31);
        } else {
            out.windowStartDate = today;
            out.windowEndDate = today;
        }

        out.executionKey = String.valueOf(schedule.Id) + ':' + normalizedFrequency + ':' + String.valueOf(out.windowStartDate);
        return out;
    }

    private static CaseScheduleResultDTO processSingleSchedule(
        Agendamento__c schedule,
        ProcessingContext context,
        Datetime nowValue,
        List<Case> casesToInsert,
        List<Id> scheduleIdsByCaseIndex
    ) {
        if (schedule == null) {
            return CaseScheduleResultDTO.error(null, 'Agendamento inválido / Invalid schedule.');
        }

        String validationError = validateSchedule(schedule, context);
        if (!String.isBlank(validationError)) {
            return CaseScheduleResultDTO.error(schedule.Id, validationError);
        }
        if (!isEligibleToRun(schedule, nowValue)) {
            return CaseScheduleResultDTO.skipped(schedule.Id, 'Agendamento fora da janela de execução / Schedule outside execution window.');
        }
        if (context.createdScheduleIds.contains(schedule.Id)) {
            return CaseScheduleResultDTO.skipped(schedule.Id, 'Case já criado para a janela atual / Case already created for the current window.');
        }

        OwnerResolution owner = resolveOwner(schedule, context);
        if (!owner.success) {
            return CaseScheduleResultDTO.error(schedule.Id, owner.message);
        }

        Case caseRow = buildCaseFromSchedule(schedule, owner, context);
        casesToInsert.add(caseRow);
        scheduleIdsByCaseIndex.add(schedule.Id);

        CaseScheduleResultDTO out = new CaseScheduleResultDTO();
        out.scheduleId = schedule.Id;
        out.success = true;
        out.skipped = false;
        out.message = 'Case preparado para criação / Case prepared for creation.';
        return out;
    }

    private static ProcessingContext prepareContext(List<Agendamento__c> schedules, Datetime nowValue) {
        ProcessingContext context = new ProcessingContext();
        Set<Id> userIds = new Set<Id>();
        Set<String> queueDeveloperNames = new Set<String>();
        Set<String> caseRecordTypeDeveloperNames = new Set<String>();
        Set<Id> scheduleIds = new Set<Id>();
        List<CaseScheduleExecutionWindowDTO> windows = new List<CaseScheduleExecutionWindowDTO>();

        for (Agendamento__c schedule : schedules) {
            if (schedule == null || schedule.Id == null) {
                continue;
            }
            scheduleIds.add(schedule.Id);
            if (schedule.OwnerType__c == OWNER_TYPE_USER && schedule.OwnerUser__c != null) {
                userIds.add(schedule.OwnerUser__c);
            }
            if (schedule.OwnerType__c == OWNER_TYPE_QUEUE && !String.isBlank(schedule.OwnerQueueDeveloperName__c)) {
                queueDeveloperNames.add(schedule.OwnerQueueDeveloperName__c);
            }
            if (schedule.RecordType != null && !String.isBlank(schedule.RecordType.DeveloperName)) {
                caseRecordTypeDeveloperNames.add(schedule.RecordType.DeveloperName);
            }
            CaseScheduleExecutionWindowDTO window = buildExecutionWindow(schedule, nowValue);
            if (window != null && window.windowStartDate != null && window.windowEndDate != null) {
                windows.add(window);
                context.windowByScheduleId.put(schedule.Id, window);
            }
        }

        context.activeUserById = CaseScheduleHelper.getActiveUsersById(userIds);
        context.queueByDeveloperName = CaseScheduleHelper.getQueuesByDeveloperName(queueDeveloperNames);
        context.caseRecordTypeByDeveloperName = CaseScheduleHelper.getCaseRecordTypesByDeveloperName(caseRecordTypeDeveloperNames);
        Set<Id> queueIds = new Set<Id>();
        for (Group queue : context.queueByDeveloperName.values()) {
            queueIds.add(queue.Id);
        }
        context.caseEnabledQueueIds = CaseScheduleHelper.getCaseEnabledQueueIds(queueIds);
        markAlreadyCreated(context, scheduleIds, windows);
        return context;
    }

    private static void markAlreadyCreated(ProcessingContext context, Set<Id> scheduleIds, List<CaseScheduleExecutionWindowDTO> windows) {
        if (scheduleIds.isEmpty() || windows.isEmpty()) {
            return;
        }
        Datetime minStart = windows[0].startDateTime();
        Datetime maxEnd = windows[0].endDateTime();
        for (CaseScheduleExecutionWindowDTO window : windows) {
            if (window.startDateTime() < minStart) {
                minStart = window.startDateTime();
            }
            if (window.endDateTime() > maxEnd) {
                maxEnd = window.endDateTime();
            }
        }
        for (Case caseRow : CaseScheduleHelper.getCasesCreatedForSchedules(scheduleIds, minStart, maxEnd)) {
            CaseScheduleExecutionWindowDTO window = context.windowByScheduleId.get(caseRow.Agendamento__c);
            if (window == null) {
                continue;
            }
            Date createdDate = caseRow.CreatedDate.date();
            if (createdDate >= window.windowStartDate && createdDate <= window.windowEndDate) {
                context.createdScheduleIds.add(caseRow.Agendamento__c);
            }
        }
    }

    private static String validateSchedule(Agendamento__c schedule, ProcessingContext context) {
        if (schedule.Conta__c == null) {
            return 'Conta obrigatória / Account is required.';
        }
        if (String.isBlank(schedule.UnidadeNegocio__c)) {
            return 'Unidade de Negócio obrigatória / Business Unit is required.';
        }
        if (String.isBlank(schedule.TipoCaso__c)) {
            return 'Tipo de Caso obrigatório / Case Type is required.';
        }
        if (String.isBlank(schedule.Categoria__c)) {
            return 'Categoria obrigatória / Category is required.';
        }
        if (String.isBlank(schedule.DescricaoAtividade__c)) {
            return 'Descrição da atividade obrigatória / Activity description is required.';
        }
        if (schedule.DataInicio__c == null) {
            return 'Data de início obrigatória / Start date is required.';
        }
        if (schedule.HorarioExecucao__c == null) {
            return 'Horário de execução obrigatório / Execution time is required.';
        }
        if (String.isBlank(schedule.Frequencia__c)) {
            return 'Frequência obrigatória / Frequency is required.';
        }
        if (normalizeFrequency(schedule.Frequencia__c) == 'SPECIFIC_WEEKDAYS' && String.isBlank(schedule.DiasDaSemana__c)) {
            return 'Dias da semana obrigatórios para frequência "Dias específicos da semana" / Weekdays are required for the "specific weekdays" frequency.';
        }
        if (String.isBlank(schedule.OwnerType__c)) {
            return 'Tipo de proprietário obrigatório / Owner type is required.';
        }
        if (schedule.OwnerType__c == OWNER_TYPE_USER && schedule.OwnerUser__c == null) {
            return 'Usuário proprietário obrigatório / Owner user is required.';
        }
        if (schedule.OwnerType__c == OWNER_TYPE_QUEUE && String.isBlank(schedule.OwnerQueueDeveloperName__c)) {
            return 'Fila proprietária obrigatória / Owner queue is required.';
        }
        if (schedule.OwnerType__c != OWNER_TYPE_USER && schedule.OwnerType__c != OWNER_TYPE_QUEUE) {
            return 'Tipo de proprietário inválido / Invalid owner type.';
        }
        if (schedule.RecordType == null
            || String.isBlank(schedule.RecordType.DeveloperName)
            || !context.caseRecordTypeByDeveloperName.containsKey(schedule.RecordType.DeveloperName)) {
            return 'Record Type de Case não encontrado para o Agendamento / Case Record Type was not found for the schedule.';
        }

        try {
            resolveCategorization(schedule, context);
        } catch (CaseCreationService.FunctionalException ex) {
            return ex.getMessage();
        }
        return null;
    }

    private static OwnerResolution resolveOwner(Agendamento__c schedule, ProcessingContext context) {
        OwnerResolution out = new OwnerResolution();
        if (schedule.OwnerType__c == OWNER_TYPE_USER) {
            User activeUser = context.activeUserById.get(schedule.OwnerUser__c);
            if (activeUser == null) {
                out.success = false;
                out.message = 'Usuário proprietário inexistente ou inativo / Owner user does not exist or is inactive.';
                return out;
            }
            out.success = true;
            out.ownerId = activeUser.Id;
            out.ownerType = OWNER_TYPE_USER;
            return out;
        }

        Group queue = context.queueByDeveloperName.get(schedule.OwnerQueueDeveloperName__c);
        if (queue == null) {
            out.success = false;
            out.message = 'Fila proprietária não encontrada / Owner queue was not found.';
            return out;
        }
        if (!context.caseEnabledQueueIds.contains(queue.Id)) {
            out.success = false;
            out.message = 'Fila proprietária não habilitada para Case / Owner queue is not enabled for Case.';
            return out;
        }
        out.success = true;
        out.ownerId = queue.Id;
        out.ownerType = OWNER_TYPE_QUEUE;
        out.queueDeveloperName = queue.DeveloperName;
        return out;
    }

    private static Case buildCaseFromSchedule(Agendamento__c schedule, OwnerResolution owner, ProcessingContext context) {
        CaseCreationDTO.BuildDefaultValuesResponseDTO defaults = buildDefaultValues(schedule, context);
        Case caseRow = new Case();
        applyDefaultValues(caseRow, defaults == null ? null : defaults.defaultValues);

        caseRow.AccountId = schedule.Conta__c;
        caseRow.Agendamento__c = schedule.Id;
        caseRow.RecordTypeId = context.caseRecordTypeByDeveloperName.get(schedule.RecordType.DeveloperName).Id;
        caseRow.OwnerId = owner.ownerId;
        caseRow.Origin = resolveCaseOrigin();
        caseRow.Subject = buildSubject(schedule);
        caseRow.Description = schedule.DescricaoAtividade__c;
        caseRow.Status = STATUS_OPEN;

        putCaseString(caseRow, 'UnidadeNegocio__c', CaseCreationHelper.normalizeBusinessUnitForCase(schedule.UnidadeNegocio__c));
        putCaseString(caseRow, 'TipoCaso__c', schedule.TipoCaso__c);
        putCaseString(caseRow, 'Categoria__c', schedule.Categoria__c);
        putCaseString(caseRow, 'Assunto__c', schedule.Assunto__c);
        putCaseString(caseRow, 'Subassunto__c', schedule.Subassunto__c);
        putCaseString(caseRow, 'OrigemDistribuicao__c', DISTRIBUTION_SCHEDULE);

        if (owner.ownerType == OWNER_TYPE_QUEUE) {
            putCaseString(caseRow, 'AcaoPosCategorizacao__c', ACTION_DISTRIBUTE);
            putCaseBoolean(caseRow, 'DistribuicaoSolicitada__c', true);
            putCaseString(caseRow, 'FilaDestinoDeveloperName__c', owner.queueDeveloperName);
            putCaseString(caseRow, 'FilaDestinoId__c', String.valueOf(owner.ownerId));
            putCaseString(caseRow, 'EtapaAtendimento__c', STEP_IN_TRIAGE);
        } else {
            putCaseString(caseRow, 'AcaoPosCategorizacao__c', ACTION_ASSUME);
            putCaseBoolean(caseRow, 'DistribuicaoSolicitada__c', false);
            putCaseString(caseRow, 'EtapaAtendimento__c', STEP_IN_SERVICE);
        }
        return caseRow;
    }

    private static CaseCreationDTO.BuildDefaultValuesResponseDTO buildDefaultValues(Agendamento__c schedule, ProcessingContext context) {
        CaseCreationDTO.BuildDefaultValuesRequestDTO request = new CaseCreationDTO.BuildDefaultValuesRequestDTO();
        request.categorization = buildCategorizationRequest(schedule, context);
        request.destination = new CaseCreationDTO.DestinationRequestDTO();
        request.destination.action = 'ASSUMIR';
        request.originalDefaults = new Map<String, String>{ 'AccountId' => String.valueOf(schedule.Conta__c) };
        return CaseCreationService.buildDefaultValues(request);
    }

    private static CaseCreationDTO.ResolveSelectionResponseDTO resolveCategorization(Agendamento__c schedule, ProcessingContext context) {
        return CaseCreationService.resolveCategorizationSelection(buildCategorizationRequest(schedule, context));
    }

    private static CaseCreationDTO.CategorizationRequestDTO buildCategorizationRequest(Agendamento__c schedule, ProcessingContext context) {
        RecordType caseRecordType = schedule.RecordType == null ? null : context.caseRecordTypeByDeveloperName.get(schedule.RecordType.DeveloperName);
        CaseCreationDTO.CategorizationRequestDTO out = new CaseCreationDTO.CategorizationRequestDTO();
        out.recordTypeId = caseRecordType == null ? null : caseRecordType.Id;
        out.recordTypeDeveloperName = schedule.RecordType == null ? null : schedule.RecordType.DeveloperName;
        out.unidadeNegocio = schedule.UnidadeNegocio__c;
        out.tipoCaso = schedule.TipoCaso__c;
        out.categoria = schedule.Categoria__c;
        out.assunto = schedule.Assunto__c;
        out.subassunto = schedule.Subassunto__c;
        return out;
    }

    private static void persistCases(
        List<Case> casesToInsert,
        List<Id> scheduleIdsByCaseIndex,
        Map<Id, Agendamento__c> scheduleById,
        Map<Id, Agendamento__c> schedulesToUpdateById,
        List<CaseScheduleResultDTO> results,
        List<SObject> logsToInsert,
        Datetime nowValue
    ) {
        if (casesToInsert.isEmpty()) {
            return;
        }
        Database.SaveResult[] saveResults = Database.insert(casesToInsert, false);
        Map<Id, CaseScheduleResultDTO> resultByScheduleId = new Map<Id, CaseScheduleResultDTO>();
        for (CaseScheduleResultDTO result : results) {
            resultByScheduleId.put(result.scheduleId, result);
        }
        for (Integer index = 0; index < saveResults.size(); index++) {
            Id scheduleId = scheduleIdsByCaseIndex[index];
            CaseScheduleResultDTO result = resultByScheduleId.get(scheduleId);
            Agendamento__c schedule = scheduleById.get(scheduleId);
            if (saveResults[index].isSuccess()) {
                schedulesToUpdateById.put(scheduleId, buildSuccessUpdate(schedule, nowValue));
                if (result != null) {
                    result.caseId = saveResults[index].getId();
                    result.message = 'Case criado com sucesso / Case created successfully.';
                }
            } else {
                String message = saveResults[index].getErrors()[0].getMessage();
                schedulesToUpdateById.put(scheduleId, buildErrorUpdate(schedule, sanitizeError(message), nowValue));
                if (result != null) {
                    result.success = false;
                    result.errorMessage = sanitizeError(message);
                }
                SObject logRow = CaseScheduleHelper.buildErrorLog(new Agendamento__c(Id = scheduleId), message);
                if (logRow != null) {
                    logsToInsert.add(logRow);
                }
            }
        }
    }

    private static Agendamento__c buildSuccessUpdate(Agendamento__c schedule, Datetime nowValue) {
        Id scheduleId = schedule == null ? null : schedule.Id;
        Datetime nextExecution = schedule == null
            ? null
            : computeNextExecution(schedule, nextSearchStartAfterSuccess(schedule, nowValue));
        return new Agendamento__c(Id = scheduleId, UltimoErroExecucao__c = null, UltimaExecucao__c = nowValue, ProximaExecucao__c = nextExecution);
    }

    private static Agendamento__c buildErrorUpdate(Agendamento__c schedule, String errorMessage, Datetime nowValue) {
        Datetime nextExecution = schedule == null || String.isBlank(schedule.Frequencia__c)
            ? null
            : computeNextExecution(schedule, nowValue.date());
        return new Agendamento__c(
            Id = schedule == null ? null : schedule.Id,
            UltimoErroExecucao__c = CaseScheduleHelper.safeLeft(errorMessage, 32000),
            ProximaExecucao__c = nextExecution
        );
    }

    private static Agendamento__c buildNextExecutionUpdate(Agendamento__c schedule, Datetime nowValue) {
        Datetime nextExecution = String.isBlank(schedule.Frequencia__c) ? null : computeNextExecution(schedule, nowValue.date());
        return new Agendamento__c(Id = schedule.Id, ProximaExecucao__c = nextExecution);
    }

    private static Date nextSearchStartAfterSuccess(Agendamento__c schedule, Datetime nowValue) {
        CaseScheduleExecutionWindowDTO window = buildExecutionWindow(schedule, nowValue);
        Date windowEnd = window == null || window.windowEndDate == null ? nowValue.date() : window.windowEndDate;
        return windowEnd.addDays(1);
    }

    /**
     * @param schedule Schedule to evaluate.
     * @param searchStartDate Earliest candidate date to consider.
     * @return Next datetime (date + HorarioExecucao__c) at which the schedule will be eligible, bounded to ~2 years ahead.
     */
    private static Datetime computeNextExecution(Agendamento__c schedule, Date searchStartDate) {
        if (schedule == null || String.isBlank(schedule.Frequencia__c) || schedule.HorarioExecucao__c == null) {
            return null;
        }
        Date candidate = schedule.DataInicio__c != null && searchStartDate < schedule.DataInicio__c
            ? schedule.DataInicio__c
            : searchStartDate;
        for (Integer i = 0; i < 740; i++) {
            if (!(schedule.PularFimDeSemana__c == true && isWeekend(candidate)) && matchesFrequency(schedule, candidate)) {
                return Datetime.newInstance(candidate, schedule.HorarioExecucao__c);
            }
            candidate = candidate.addDays(1);
        }
        return null;
    }

    private static void applyDefaultValues(Case caseRow, Map<String, String> values) {
        if (values == null || values.isEmpty()) {
            return;
        }
        Map<String, Schema.SObjectField> fields = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        for (String fieldApiName : values.keySet()) {
            if (String.isBlank(fieldApiName) || !fields.containsKey(fieldApiName) || !fields.get(fieldApiName).getDescribe().isCreateable()) {
                continue;
            }
            Schema.DescribeFieldResult describe = fields.get(fieldApiName).getDescribe();
            String value = values.get(fieldApiName);
            if (String.isBlank(value)) {
                continue;
            }
            if (describe.getType() == Schema.DisplayType.Boolean) {
                caseRow.put(fieldApiName, value == 'true');
            } else {
                caseRow.put(fieldApiName, value);
            }
        }
    }

    private static void putCaseString(Case caseRow, String fieldApiName, String value) {
        if (String.isBlank(value)) {
            return;
        }
        Map<String, Schema.SObjectField> fields = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        if (fields.containsKey(fieldApiName) && fields.get(fieldApiName).getDescribe().isCreateable()) {
            caseRow.put(fieldApiName, value);
        }
    }

    private static void putCaseBoolean(Case caseRow, String fieldApiName, Boolean value) {
        Map<String, Schema.SObjectField> fields = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        if (fields.containsKey(fieldApiName) && fields.get(fieldApiName).getDescribe().isCreateable()) {
            caseRow.put(fieldApiName, value);
        }
    }

    private static String buildSubject(Agendamento__c schedule) {
        List<String> parts = new List<String>();
        if (!String.isBlank(schedule.Categoria__c)) {
            parts.add(schedule.Categoria__c);
        }
        if (!String.isBlank(schedule.Assunto__c)) {
            parts.add(schedule.Assunto__c);
        }
        String detail = parts.isEmpty() ? schedule.Name : String.join(parts, ' - ');
        return CaseScheduleHelper.safeLeft('Atendimento recorrente - ' + detail, 255);
    }

    private static String resolveCaseOrigin() {
        for (Schema.PicklistEntry entry : Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == ORIGIN_RECORRENTE) {
                return ORIGIN_RECORRENTE;
            }
        }
        for (Schema.PicklistEntry entry : Case.Origin.getDescribe().getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == ORIGIN_AGENDAMENTO) {
                return ORIGIN_AGENDAMENTO;
            }
        }
        return 'Manual';
    }

    private static Boolean matchesFrequency(Agendamento__c schedule, Date today) {
        String normalized = normalizeFrequency(schedule.Frequencia__c);
        Date startDate = schedule.DataInicio__c;
        if (normalized == 'DAILY') {
            return true;
        }
        if (normalized == 'SPECIFIC_WEEKDAYS') {
            return matchesSpecificWeekday(schedule.DiasDaSemana__c, today);
        }
        if (normalized == 'WEEKLY') {
            return dayOfWeek(startDate) == dayOfWeek(today);
        }
        if (normalized == 'MONTHLY') {
            return today.day() == dueDayForMonth(startDate, today.year(), today.month());
        }
        if (normalized == 'QUARTERLY') {
            Integer monthDelta = ((today.year() - startDate.year()) * 12) + (today.month() - startDate.month());
            return monthDelta >= 0 && Math.mod(monthDelta, 3) == 0 && today.day() == dueDayForMonth(startDate, today.year(), today.month());
        }
        if (normalized == 'ANNUAL') {
            Integer dueDay = dueDayForMonth(startDate, today.year(), startDate.month());
            return today.month() == startDate.month() && today.day() == dueDay;
        }
        return false;
    }

    private static String normalizeFrequency(String frequency) {
        String normalized = CaseCreationHelper.normalizeText(frequency);
        if (normalized == 'diaria' || normalized == 'diario' || normalized == 'daily') {
            return 'DAILY';
        }
        if (normalized == 'semanal' || normalized == 'weekly') {
            return 'WEEKLY';
        }
        if (normalized == 'diasespecificosdasemana' || normalized == 'specificweekdays') {
            return 'SPECIFIC_WEEKDAYS';
        }
        if (normalized == 'mensal' || normalized == 'monthly') {
            return 'MONTHLY';
        }
        if (normalized == 'trimestral' || normalized == 'quarterly') {
            return 'QUARTERLY';
        }
        if (normalized == 'anual' || normalized == 'annual') {
            return 'ANNUAL';
        }
        return normalized.toUpperCase();
    }

    private static Integer dueDayForMonth(Date startDate, Integer yearValue, Integer monthValue) {
        Integer lastDay = Date.daysInMonth(yearValue, monthValue);
        return startDate.day() < lastDay ? startDate.day() : lastDay;
    }

    private static Integer quarterStartMonth(Integer monthValue) {
        if (monthValue <= 3) {
            return 1;
        }
        if (monthValue <= 6) {
            return 4;
        }
        if (monthValue <= 9) {
            return 7;
        }
        return 10;
    }

    private static final List<String> WEEKDAY_LABELS_BY_ISO_NUMBER = new List<String>{
        'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    };

    private static Boolean matchesSpecificWeekday(String diasDaSemana, Date today) {
        if (String.isBlank(diasDaSemana)) {
            return false;
        }
        String todayLabel = WEEKDAY_LABELS_BY_ISO_NUMBER[dayOfWeek(today) - 1];
        for (String selectedDay : diasDaSemana.split(';')) {
            if (selectedDay == todayLabel) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isWeekend(Date value) {
        Integer weekday = dayOfWeek(value);
        return weekday == 6 || weekday == 7;
    }

    private static Integer dayOfWeek(Date value) {
        Integer diff = Date.newInstance(1900, 1, 1).daysBetween(value);
        Integer zeroBased = Math.mod(diff, 7);
        if (zeroBased < 0) {
            zeroBased += 7;
        }
        return zeroBased + 1;
    }

    private static String sanitizeError(Exception ex) {
        return sanitizeError(ex == null ? null : ex.getMessage());
    }

    private static String sanitizeError(String message) {
        if (String.isBlank(message)) {
            return 'Falha ao criar Case recorrente / Failed to create recurring Case.';
        }
        return CaseScheduleHelper.safeLeft(message.replace('\n', ' '), 32000);
    }

    private class ProcessingContext {
        Map<Id, User> activeUserById = new Map<Id, User>();
        Map<String, Group> queueByDeveloperName = new Map<String, Group>();
        Map<String, RecordType> caseRecordTypeByDeveloperName = new Map<String, RecordType>();
        Set<Id> caseEnabledQueueIds = new Set<Id>();
        Map<Id, CaseScheduleExecutionWindowDTO> windowByScheduleId = new Map<Id, CaseScheduleExecutionWindowDTO>();
        Set<Id> createdScheduleIds = new Set<Id>();
    }

    private class OwnerResolution {
        Boolean success = false;
        String message;
        Id ownerId;
        String ownerType;
        String queueDeveloperName;
    }
}