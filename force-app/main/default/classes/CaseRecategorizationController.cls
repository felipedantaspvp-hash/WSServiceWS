/**
 * @description       : Controller Apex expondo endpoints @AuraEnabled para o módulo CaseRecategorization. Delega toda lógica ao CaseRecategorizationService.
 * @author            : Triscal
 * @group             : Case Recategorização
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseRecategorizationController {
    @TestVisible static Exception testException;

    /**
     * @description Retorna contexto de recategorização: categorização atual do Case e opções disponíveis.
     * @param caseId Id do Case a ser recategorizado.
     * @return CaseRecategorizationContextDTO com dados atuais e árvore de categorização disponível.
     **/
    @AuraEnabled(cacheable=true)
    public static CaseRecategorizationDTO.CaseRecategorizationContextDTO getContext(Id caseId) {
        return CaseRecategorizationService.getContext(caseId);
    }

    /**
     * @description Retorna opções da árvore de categorização para o fluxo de recategorização.
     * @param request TreeRequestDTO com nível e valores selecionados até o momento.
     * @return TreeOptionsDTO com opções disponíveis para o próximo nível.
     **/
    @AuraEnabled(cacheable=true)
    public static CaseRecategorizationDTO.TreeOptionsDTO getTreeOptions(CaseRecategorizationDTO.TreeRequestDTO request) {
        return CaseRecategorizationService.getTreeOptions(request);
    }

    /**
     * @description Executa a recategorização do Case, aplicando novas opções de categorização,
     *              redistribuindo para fila e atualizando campos relevantes.
     * @param request RecategorizationRequestDTO com caseId e nova seleção de categorização.
     * @return RecategorizationResponseDTO com sucesso, caseId atualizado e warnings.
     **/
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