/**
 * Aura-enabled controller for the Account Case Schedule manager LWC.
 */
public with sharing class AccountCaseScheduleController {
    /**
     * @param accountId Current Account Id.
     * @return Initial component state.
     */
    @AuraEnabled(cacheable=true)
    public static AccountCaseScheduleDTO.InitialStateDTO getInitialState(Id accountId) {
        try {
            throwTestException();
            return AccountCaseScheduleService.getInitialState(accountId);
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorInitialLoadUnexpected);
        }
    }

    /**
     * @param accountId Current Account Id.
     * @return Compact schedule indicator state.
     */
    @AuraEnabled(cacheable=true)
    public static AccountCaseScheduleDTO.IndicatorDTO getIndicator(Id accountId) {
        try {
            throwTestException();
            return AccountCaseScheduleService.getIndicator(accountId);
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorInitialLoadUnexpected);
        }
    }

    /**
     * @param request Categorization request.
     * @return Dependent options from Case creation service.
     */
    @AuraEnabled(cacheable=true)
    public static CaseCreationDTO.TreeOptionsDTO getTreeOptions(CaseCreationDTO.CategorizationRequestDTO request) {
        try {
            throwTestException();
            return AccountCaseScheduleService.getTreeOptions(request);
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorTreeLoad);
        }
    }

    /**
     * @param request Categorization request.
     * @return Queue resolution from Case creation service.
     */
    @AuraEnabled
    public static CaseCreationDTO.ResolveSelectionResponseDTO resolveCategorizationSelection(CaseCreationDTO.CategorizationRequestDTO request) {
        try {
            throwTestException();
            return AccountCaseScheduleService.resolveCategorizationSelection(request);
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorQueueResolve);
        }
    }

    /**
     * @param recordTypeDeveloperName Case Record Type DeveloperName.
     * @param unidadeNegocio Business unit.
     * @return Queue options from Case creation service.
     */
    @AuraEnabled(cacheable=true)
    public static List<CaseCreationDTO.QueueOptionDTO> getAvailableQueues(String recordTypeDeveloperName, String unidadeNegocio) {
        try {
            throwTestException();
            return AccountCaseScheduleService.getAvailableQueues(recordTypeDeveloperName, unidadeNegocio);
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorQueuesLoad);
        }
    }

    /**
     * @param searchTerm Active user search term.
     * @return Active user options.
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountCaseScheduleDTO.OptionDTO> searchUsers(String searchTerm) {
        try {
            throwTestException();
            return AccountCaseScheduleService.searchUsers(searchTerm);
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorUsersSearch);
        }
    }

    /**
     * @param request Schedule payload.
     * @return Saved schedule.
     */
    @AuraEnabled
    public static AccountCaseScheduleDTO.ScheduleDTO saveSchedule(AccountCaseScheduleDTO.SaveRequestDTO request) {
        try {
            throwTestException();
            return AccountCaseScheduleService.saveSchedule(request);
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorSaveUnexpected);
        }
    }

    /**
     * @param accountId Current Account Id.
     * @param scheduleId Schedule Id.
     * @param active New active state.
     * @return Updated schedule.
     */
    @AuraEnabled
    public static AccountCaseScheduleDTO.ScheduleDTO setActive(Id accountId, Id scheduleId, Boolean active) {
        try {
            throwTestException();
            return AccountCaseScheduleService.setActive(accountId, scheduleId, active);
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.AccountCaseSchedule_ErrorStatusUnexpected);
        }
    }

    private static void throwTestException() {
        Exception forcedException = ApexTestSeam.getException('AccountCaseScheduleController.testException');
        if (forcedException != null) {
            throw forcedException;
        }
    }
}