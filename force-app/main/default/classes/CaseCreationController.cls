public inherited sharing class CaseCreationController {
    @TestVisible static Exception testException;

    @AuraEnabled(cacheable=true)
    public static CaseCreationDTO.InitialContextDTO getInitialContext() {
        return CaseCreationService.getInitialContext();
    }

    @AuraEnabled(cacheable=true)
    public static CaseCreationDTO.TreeOptionsDTO getTreeOptions(CaseCreationDTO.CategorizationRequestDTO request) {
        return CaseCreationService.getTreeOptions(request);
    }

    @AuraEnabled
    public static CaseCreationDTO.ResolveSelectionResponseDTO resolveCategorizationSelection(CaseCreationDTO.CategorizationRequestDTO request) {
        return CaseCreationService.resolveCategorizationSelection(request);
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseCreationDTO.QueueOptionDTO> getAvailableQueues(String recordTypeDeveloperName, String unidadeNegocio) {
        return CaseCreationService.getAvailableQueues(recordTypeDeveloperName, unidadeNegocio);
    }

    @AuraEnabled
    public static CaseCreationDTO.BuildDefaultValuesResponseDTO buildDefaultValues(CaseCreationDTO.BuildDefaultValuesRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return CaseCreationService.buildDefaultValues(request);
        } catch (CaseCreationService.FunctionalException ex) {
            CaseCreationDTO.BuildDefaultValuesResponseDTO out = new CaseCreationDTO.BuildDefaultValuesResponseDTO();
            out.success = false;
            out.defaultValues = new Map<String, String>();
            out.warnings = new List<String>();
            out.errors = new List<String>{ ex.getMessage() };
            out.error = new CaseCreationDTO.ErrorInfo();
            out.error.code = String.isBlank(ex.code) ? 'VALIDATION_ERROR' : ex.code;
            out.error.message = ex.getMessage();
            return out;
        } catch (Exception ex) {
            CaseCreationDTO.BuildDefaultValuesResponseDTO out = new CaseCreationDTO.BuildDefaultValuesResponseDTO();
            out.success = false;
            out.defaultValues = new Map<String, String>();
            out.warnings = new List<String>();
            out.errors = new List<String>{ 'Erro inesperado ao preparar o formulário de criação do Case.' };
            out.error = new CaseCreationDTO.ErrorInfo();
            out.error.code = 'UNEXPECTED_ERROR';
            out.error.message = out.errors[0];
            return out;
        }
    }
}