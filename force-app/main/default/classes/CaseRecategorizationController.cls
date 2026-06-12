public inherited sharing class CaseRecategorizationController {
    @TestVisible static Exception testException;

    @AuraEnabled(cacheable=true)
    public static CaseRecategorizationDTO.CaseRecategorizationContextDTO getContext(Id caseId) {
        return CaseRecategorizationService.getContext(caseId);
    }

    @AuraEnabled(cacheable=true)
    public static CaseRecategorizationDTO.TreeOptionsDTO getTreeOptions(CaseRecategorizationDTO.TreeRequestDTO request) {
        return CaseRecategorizationService.getTreeOptions(request);
    }

    @AuraEnabled
    public static CaseRecategorizationDTO.RecategorizationResponseDTO recategorize(CaseRecategorizationDTO.RecategorizationRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return CaseRecategorizationService.recategorize(request);
        } catch (CaseRecategorizationService.FunctionalException ex) {
            CaseRecategorizationDTO.RecategorizationResponseDTO out = new CaseRecategorizationDTO.RecategorizationResponseDTO();
            out.success = false;
            out.caseId = request != null ? request.caseId : null;
            out.message = ex.getMessage();
            out.warnings = new List<String>();
            out.error = new CaseRecategorizationDTO.ErrorInfo();
            out.error.code = String.isBlank(ex.code) ? 'VALIDATION_ERROR' : ex.code;
            out.error.message = ex.getMessage();
            return out;
        } catch (Exception ex) {
            CaseRecategorizationDTO.RecategorizationResponseDTO out = new CaseRecategorizationDTO.RecategorizationResponseDTO();
            out.success = false;
            out.caseId = request != null ? request.caseId : null;
            out.message = 'Erro inesperado ao recategorizar o Caso.';
            out.warnings = new List<String>();
            out.error = new CaseRecategorizationDTO.ErrorInfo();
            out.error.code = 'UNEXPECTED_ERROR';
            out.error.message = out.message;
            return out;
        }
    }
}