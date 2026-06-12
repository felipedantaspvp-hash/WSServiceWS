/**
 * @description       : Controller LWC para encerramento de Case com Survey.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Codex
 **/
public inherited sharing class CaseClosureSurveyController {
    @TestVisible private static Boolean forceUnexpectedErrorForTest = false;

    /**
     * @description Carrega contexto de encerramento para o Case.
     * @param caseId Id do Case.
     * @return Contexto serializável para o LWC.
     */
    @AuraEnabled(cacheable=true)
    public static CaseClosureSurveyDTO getClosureContext(Id caseId) {
        return CaseClosureSurveyService.getClosureContext(caseId);
    }

    /**
     * @description Fecha o Case e marca elegibilidade de Survey.
     * @param request Dados do encerramento.
     * @return Resultado serializável para o LWC.
     */
    @AuraEnabled
    public static CaseClosureSurveyDTO closeCase(CaseClosureSurveyDTO request) {
        try {
            if (Test.isRunningTest() && forceUnexpectedErrorForTest == true) {
                throw new UnexpectedControllerException('Erro forçado para cobertura do catch genérico.');
            }
            return CaseClosureSurveyService.closeCase(request);
        } catch (CaseClosureSurveyService.FunctionalException ex) {
            CaseClosureSurveyDTO out = new CaseClosureSurveyDTO();
            out.caseId = request != null ? request.caseId : null;
            out.errorMessage = ex.getMessage();
            return out;
        } catch (Exception ex) {
            CaseClosureSurveyDTO out = new CaseClosureSurveyDTO();
            out.caseId = request != null ? request.caseId : null;
            out.errorMessage = 'Erro inesperado ao encerrar o Caso.';
            return out;
        }
    }

    private class UnexpectedControllerException extends Exception {}
}