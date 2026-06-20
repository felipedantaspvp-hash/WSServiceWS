/**
 * Manages recurring Case schedule records from Account while reusing the Case creation categorization services.
 */
public with sharing class AccountCaseScheduleService {
    private static final String OWNER_TYPE_USER = 'USER';
    private static final String OWNER_TYPE_QUEUE = 'QUEUE';

    public class FunctionalException extends Exception {}

    /**
     * @param accountId Account Id shown by the component.
     * @return Initial component state with Account, schedules, Case categorization context, and picklist options.
     */
    public static AccountCaseScheduleDTO.InitialStateDTO getInitialState(Id accountId) {
        validateAccountId(accountId);
        assertReadAccess();

        Account account = AccountCaseScheduleHelper.getAccount(accountId);
        if (account == null) throw new FunctionalException(Label.AccountCaseSchedule_AccountNotFoundNoAccess);

        AccountCaseScheduleDTO.InitialStateDTO out = new AccountCaseScheduleDTO.InitialStateDTO();
        out.accountId = account.Id;
        out.accountName = account.Name;
        out.agendamentoObjectApiName = AccountCaseScheduleHelper.getAgendamentoObjectApiName();
        out.caseContext = CaseCreationService.getInitialContext();
        out.frequenciaOptions = AccountCaseScheduleHelper.toOptions(Agendamento__c.Frequencia__c.getDescribe());
        out.ownerTypeOptions = AccountCaseScheduleHelper.toOptions(Agendamento__c.OwnerType__c.getDescribe());
        out.schedules = toScheduleDTOs(AccountCaseScheduleHelper.getSchedulesByAccount(accountId));
        return out;
    }

    /**
     * @param accountId Account Id shown by the indicator component.
     * @return Compact schedule status summary for the Account.
     */
    public static AccountCaseScheduleDTO.IndicatorDTO getIndicator(Id accountId) {
        validateAccountId(accountId);
        assertReadAccess();

        Account account = AccountCaseScheduleHelper.getAccount(accountId);
        if (account == null) throw new FunctionalException(Label.AccountCaseSchedule_AccountNotFoundNoAccess);

        Integer totalSchedules = 0;
        Integer activeSchedules = 0;
        for (Agendamento__c schedule : AccountCaseScheduleHelper.getSchedulesByAccount(accountId)) {
            totalSchedules++;
            if (schedule.Ativo__c == true) {
                activeSchedules++;
            }
        }

        AccountCaseScheduleDTO.IndicatorDTO out = new AccountCaseScheduleDTO.IndicatorDTO();
        out.accountId = account.Id;
        out.totalSchedules = totalSchedules;
        out.activeSchedules = activeSchedules;
        out.inactiveSchedules = totalSchedules - activeSchedules;
        return out;
    }

    /**
     * @param request Dependent categorization request.
     * @return Case creation tree options from the existing Case creation service.
     */
    public static CaseCreationDTO.TreeOptionsDTO getTreeOptions(CaseCreationDTO.CategorizationRequestDTO request) {
        return CaseCreationService.getTreeOptions(request);
    }

    /**
     * @param request Categorization request.
     * @return Existing Case creation queue resolution response.
     */
    public static CaseCreationDTO.ResolveSelectionResponseDTO resolveCategorizationSelection(CaseCreationDTO.CategorizationRequestDTO request) {
        return CaseCreationService.resolveCategorizationSelection(request);
    }

    /**
     * @param recordTypeDeveloperName Case Record Type DeveloperName.
     * @param unidadeNegocio Business unit.
     * @return Case queues available according to the existing Case creation service.
     */
    public static List<CaseCreationDTO.QueueOptionDTO> getAvailableQueues(String recordTypeDeveloperName, String unidadeNegocio) {
        return CaseCreationService.getAvailableQueues(recordTypeDeveloperName, unidadeNegocio);
    }

    /**
     * @param searchTerm Active user search term.
     * @return Active user options for manual ownership.
     */
    public static List<AccountCaseScheduleDTO.OptionDTO> searchUsers(String searchTerm) {
        List<AccountCaseScheduleDTO.OptionDTO> out = new List<AccountCaseScheduleDTO.OptionDTO>();
        for (User userRow : AccountCaseScheduleHelper.searchActiveUsers(searchTerm)) {
            AccountCaseScheduleDTO.OptionDTO option = new AccountCaseScheduleDTO.OptionDTO();
            option.id = userRow.Id;
            option.value = String.valueOf(userRow.Id);
            option.label = userRow.Name;
            out.add(option);
        }
        return out;
    }

    /**
     * @param request Schedule values to create or update.
     * @return Saved schedule DTO.
     */
    public static AccountCaseScheduleDTO.ScheduleDTO saveSchedule(AccountCaseScheduleDTO.SaveRequestDTO request) {
        validateSaveRequest(request);
        assertWriteAccess(request.id == null);

        Agendamento__c existing = request.id == null ? null : AccountCaseScheduleHelper.getScheduleById(request.id);
        if (request.id != null && existing == null) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleNotFoundNoAccess);
        if (existing != null && existing.Conta__c != request.accountId) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleNotCurrentAccount);

        CaseCreationDTO.ResolveSelectionResponseDTO resolved = validateCategorization(request.categorization);
        Id ownerId = resolveOwnerId(request, resolved);
        Id scheduleRecordTypeId = AccountCaseScheduleHelper.getScheduleRecordTypeId(request.categorization.recordTypeDeveloperName);
        if (scheduleRecordTypeId == null) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleRecordTypeNotFound);

        Agendamento__c row = request.id == null ? new Agendamento__c() : new Agendamento__c(Id = request.id);
        row.Conta__c = request.accountId;
        row.RecordTypeId = scheduleRecordTypeId;
        row.Ativo__c = request.ativo == null ? false : request.ativo;
        row.UnidadeNegocio__c = AccountCaseScheduleHelper.normalizeScheduleBusinessUnit(request.categorization.unidadeNegocio);
        row.TipoCaso__c = request.categorization.tipoCaso;
        row.Categoria__c = request.categorization.categoria;
        row.Assunto__c = normalizeBlank(request.categorization.assunto);
        row.Subassunto__c = normalizeBlank(request.categorization.subassunto);
        row.DescricaoAtividade__c = request.descricaoAtividade.trim();
        row.Frequencia__c = request.frequencia;
        row.HorarioExecucao__c = parseTime(request.horarioExecucao);
        row.DataInicio__c = request.dataInicio;
        row.PularFimDeSemana__c = request.pularFimDeSemana == true;
        row.OwnerType__c = request.ownerType;
        row.OwnerId = ownerId;

        if (request.ownerType == OWNER_TYPE_USER) {
            row.OwnerUser__c = request.ownerUserId;
            row.OwnerQueueDeveloperName__c = null;
        } else {
            row.OwnerUser__c = null;
            row.OwnerQueueDeveloperName__c = request.ownerQueueDeveloperName;
        }

        try {
            if (request.id == null) {
                Database.insert(row, AccessLevel.USER_MODE);
            } else {
                Database.update(row, AccessLevel.USER_MODE);
            }
        } catch (DmlException ex) {
            throw new FunctionalException(cleanDmlMessage(ex));
        }

        List<Agendamento__c> savedRows = [
            SELECT Id, Name, Ativo__c, Conta__c, UnidadeNegocio__c, RecordTypeId,
                RecordType.DeveloperName, TipoCaso__c, Categoria__c, Assunto__c,
                Subassunto__c, Frequencia__c, HorarioExecucao__c, DataInicio__c,
                PularFimDeSemana__c, DescricaoAtividade__c, OwnerType__c,
                OwnerUser__c, OwnerUser__r.Name, OwnerQueueDeveloperName__c,
                OwnerId, Owner.Name, UltimoErroExecucao__c,
                toLabel(UnidadeNegocio__c) UnidadeNegocioLabel,
                toLabel(TipoCaso__c) TipoCasoLabel,
                toLabel(Categoria__c) CategoriaLabel,
                toLabel(Assunto__c) AssuntoLabel,
                toLabel(Subassunto__c) SubassuntoLabel,
                toLabel(Frequencia__c) FrequenciaLabel,
                toLabel(OwnerType__c) OwnerTypeLabel
            FROM Agendamento__c
            WHERE Id = :row.Id
            LIMIT 1
        ];
        return AccountCaseScheduleHelper.toScheduleDTO(savedRows[0]);
    }

    /**
     * @param accountId Account Id used to ensure ownership of the operation.
     * @param scheduleId Schedule Id.
     * @param active New active state.
     * @return Updated schedule DTO.
     */
    public static AccountCaseScheduleDTO.ScheduleDTO setActive(Id accountId, Id scheduleId, Boolean active) {
        validateAccountId(accountId);
        if (scheduleId == null) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleRequired);
        assertWriteAccess(false);

        Agendamento__c existing = AccountCaseScheduleHelper.getScheduleById(scheduleId);
        if (existing == null) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleNotFoundNoAccess);
        if (existing.Conta__c != accountId) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleNotCurrentAccount);

        AccountCaseScheduleDTO.SaveRequestDTO request = toSaveRequest(existing, accountId);
        request.ativo = active == true;
        return saveSchedule(request);
    }

    private static List<AccountCaseScheduleDTO.ScheduleDTO> toScheduleDTOs(List<Agendamento__c> rows) {
        List<AccountCaseScheduleDTO.ScheduleDTO> out = new List<AccountCaseScheduleDTO.ScheduleDTO>();
        for (Agendamento__c row : rows) out.add(AccountCaseScheduleHelper.toScheduleDTO(row));
        return out;
    }

    private static void validateSaveRequest(AccountCaseScheduleDTO.SaveRequestDTO request) {
        if (request == null) throw new FunctionalException(Label.AccountCaseSchedule_RequestRequired);
        validateAccountId(request.accountId);
        if (request.categorization == null) throw new FunctionalException(Label.AccountCaseSchedule_CategorizationRequired);
        if (String.isBlank(request.categorization.unidadeNegocio)) throw new FunctionalException(Label.AccountCaseSchedule_BusinessUnitRequired);
        if (String.isBlank(request.categorization.tipoCaso)) throw new FunctionalException(Label.AccountCaseSchedule_CaseTypeRequired);
        if (String.isBlank(request.categorization.categoria)) throw new FunctionalException(Label.AccountCaseSchedule_CategoryRequired);
        if (String.isBlank(request.descricaoAtividade)) throw new FunctionalException(Label.AccountCaseSchedule_DescriptionRequired);
        if (String.isBlank(request.frequencia)) throw new FunctionalException(Label.AccountCaseSchedule_FrequencyRequired);
        if (String.isBlank(request.horarioExecucao)) throw new FunctionalException(Label.AccountCaseSchedule_TimeRequired);
        if (request.dataInicio == null) throw new FunctionalException(Label.AccountCaseSchedule_StartDateRequired);
        if (String.isBlank(request.ownerType)) throw new FunctionalException(Label.AccountCaseSchedule_OwnerTypeRequired);

        if (request.ownerType == OWNER_TYPE_USER) {
            if (request.ownerUserId == null) throw new FunctionalException(Label.AccountCaseSchedule_OwnerUserRequired);
            if (!String.isBlank(request.ownerQueueDeveloperName)) throw new FunctionalException(Label.AccountCaseSchedule_QueueMustBeBlankForUser);
        } else if (request.ownerType == OWNER_TYPE_QUEUE) {
            if (String.isBlank(request.ownerQueueDeveloperName)) throw new FunctionalException(Label.AccountCaseSchedule_QueueRequired);
            if (request.ownerUserId != null) throw new FunctionalException(Label.AccountCaseSchedule_UserMustBeBlankForQueue);
        } else {
            throw new FunctionalException(Label.AccountCaseSchedule_OwnerTypeInvalid);
        }
    }

    private static CaseCreationDTO.ResolveSelectionResponseDTO validateCategorization(CaseCreationDTO.CategorizationRequestDTO categorization) {
        try {
            return CaseCreationService.resolveCategorizationSelection(categorization);
        } catch (CaseCreationService.FunctionalException ex) {
            throw new FunctionalException(ex.getMessage());
        }
    }

    private static Id resolveOwnerId(AccountCaseScheduleDTO.SaveRequestDTO request, CaseCreationDTO.ResolveSelectionResponseDTO resolved) {
        if (request.ownerType == OWNER_TYPE_USER) {
            User userRow = AccountCaseScheduleHelper.getActiveUser(request.ownerUserId);
            if (userRow == null) throw new FunctionalException(Label.AccountCaseSchedule_InactiveUser);
            return userRow.Id;
        }

        Group queue = AccountCaseScheduleHelper.getCaseQueueByDeveloperName(request.ownerQueueDeveloperName);
        if (queue == null) throw new FunctionalException(Label.AccountCaseSchedule_QueueNotFoundCase);
        if (!AccountCaseScheduleHelper.isScheduleQueueEnabled(queue.Id)) {
            throw new FunctionalException(Label.AccountCaseSchedule_QueueNotScheduleOwner);
        }

        Boolean parametrizedQueueMatches = resolved != null
            && resolved.hasParametrizedQueue == true
            && resolved.queue != null
            && resolved.queue.developerName == request.ownerQueueDeveloperName;
        if (!parametrizedQueueMatches && !isAvailableQueue(request.categorization, request.ownerQueueDeveloperName)) {
            throw new FunctionalException(Label.AccountCaseSchedule_QueueInvalidForBusinessUnit);
        }
        return queue.Id;
    }

    private static Boolean isAvailableQueue(CaseCreationDTO.CategorizationRequestDTO categorization, String queueDeveloperName) {
        for (CaseCreationDTO.QueueOptionDTO option : CaseCreationService.getAvailableQueues(categorization.recordTypeDeveloperName, categorization.unidadeNegocio)) {
            if (option.developerName == queueDeveloperName) return true;
        }
        return false;
    }

    private static AccountCaseScheduleDTO.SaveRequestDTO toSaveRequest(Agendamento__c existing, Id accountId) {
        List<Agendamento__c> rows = AccountCaseScheduleHelper.getSchedulesByAccount(accountId);
        Agendamento__c fullRow;
        for (Agendamento__c row : rows) {
            if (row.Id == existing.Id) {
                fullRow = row;
                break;
            }
        }
        if (fullRow == null) throw new FunctionalException(Label.AccountCaseSchedule_ScheduleNotFoundNoAccess);

        AccountCaseScheduleDTO.SaveRequestDTO request = new AccountCaseScheduleDTO.SaveRequestDTO();
        request.id = fullRow.Id;
        request.accountId = accountId;
        request.ativo = fullRow.Ativo__c;
        request.categorization = new CaseCreationDTO.CategorizationRequestDTO();
        request.categorization.recordTypeId = fullRow.RecordTypeId;
        request.categorization.recordTypeDeveloperName = fullRow.RecordType.DeveloperName;
        request.categorization.unidadeNegocio = fullRow.UnidadeNegocio__c;
        request.categorization.tipoCaso = fullRow.TipoCaso__c;
        request.categorization.categoria = fullRow.Categoria__c;
        request.categorization.assunto = fullRow.Assunto__c;
        request.categorization.subassunto = fullRow.Subassunto__c;
        request.frequencia = fullRow.Frequencia__c;
        request.horarioExecucao = AccountCaseScheduleHelper.toScheduleDTO(fullRow).horarioExecucao;
        request.dataInicio = fullRow.DataInicio__c;
        request.pularFimDeSemana = fullRow.PularFimDeSemana__c;
        request.descricaoAtividade = fullRow.DescricaoAtividade__c;
        request.ownerType = fullRow.OwnerType__c;
        request.ownerUserId = fullRow.OwnerUser__c;
        request.ownerQueueDeveloperName = fullRow.OwnerQueueDeveloperName__c;
        return request;
    }

    private static void validateAccountId(Id accountId) {
        if (accountId == null) throw new FunctionalException(Label.AccountCaseSchedule_AccountRequired);
        if (accountId.getSObjectType() != Account.SObjectType) throw new FunctionalException(Label.AccountCaseSchedule_AccountIdInvalid);
    }

    private static void assertReadAccess() {
        if (!Schema.sObjectType.Account.isAccessible() || !Schema.sObjectType.Agendamento__c.isAccessible()) {
            throw new FunctionalException(Label.AccountCaseSchedule_ReadPermissionDenied);
        }
    }

    private static void assertWriteAccess(Boolean isCreate) {
        if (isCreate && !Schema.sObjectType.Agendamento__c.isCreateable()) {
            throw new FunctionalException(Label.AccountCaseSchedule_CreatePermissionDenied);
        }
        if (!isCreate && !Schema.sObjectType.Agendamento__c.isUpdateable()) {
            throw new FunctionalException(Label.AccountCaseSchedule_EditPermissionDenied);
        }
    }

    private static Time parseTime(String value) {
        if (String.isBlank(value)) return null;
        List<String> parts = value.split(':');
        if (parts.size() < 2) throw new FunctionalException(Label.AccountCaseSchedule_InvalidTime);
        try {
            return Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0);
        } catch (Exception ex) {
            throw new FunctionalException(Label.AccountCaseSchedule_InvalidTime);
        }
    }

    private static String normalizeBlank(String value) {
        return String.isBlank(value) ? null : value;
    }

    private static String cleanDmlMessage(DmlException ex) {
        String message = ex.getNumDml() > 0 ? ex.getDmlMessage(0) : ex.getMessage();
        return String.isBlank(message) ? Label.AccountCaseSchedule_SaveFailed : message;
    }
}