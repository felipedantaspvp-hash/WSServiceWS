/**
 * @description Controller LWC para colocar Case em acompanhamento com pausa de SLA.
 * @author Triscal
 * @group Atendimento
 * @last modified on 06-17-2026
 * @last modified by Marllon Nascimento
 */
public inherited sharing class CaseAcompanhamentoController {
    @TestVisible private static Boolean forceUnexpectedErrorForTest = false;

    /**
     * Busca os dados de acompanhamento do Case para exibição em banner.
     *
     * @param caseId Id do Case.
     * @return Dados de acompanhamento e ação ativa, quando houver.
     */
    @AuraEnabled(cacheable=true)
    public static CaseAcompanhamentoDTO getAcompanhamentoData(Id caseId) {
        try {
            if (Test.isRunningTest() && forceUnexpectedErrorForTest == true) {
                throw new UnexpectedControllerException('Erro forçado para cobertura do catch genérico.');
            }
            return CaseAcompanhamentoService.getAcompanhamentoData(caseId);
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.Acao_Acompanhamento_ErroInesperado);
        }
    }

    /**
     * Coloca o Case em acompanhamento e cria o histórico operacional de pausa.
     *
     * @param caseId Id do Case.
     * @param motivo Motivo do acompanhamento.
     * @param comentarioEntrada Comentário de entrada no acompanhamento.
     * @return Resultado serializável para o LWC.
     */
    @AuraEnabled
    public static CaseAcompanhamentoDTO entrarEmAcompanhamento(Id caseId, String motivo, String comentarioEntrada) {
        try {
            if (Test.isRunningTest() && forceUnexpectedErrorForTest == true) {
                throw new UnexpectedControllerException('Erro forçado para cobertura do catch genérico.');
            }
            return CaseAcompanhamentoService.entrarEmAcompanhamento(caseId, motivo, comentarioEntrada);
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.Acao_Acompanhamento_ErroInesperado);
        }
    }

    /**
     * Retoma o atendimento do Case, reativa o SLA e encerra a ação de pausa ativa.
     *
     * @param caseId Id do Case.
     * @param comentarioSaida Comentário obrigatório de retomada.
     * @return Dados atualizados da operação.
     */
    @AuraEnabled
    public static CaseAcompanhamentoDTO retomarAtendimento(Id caseId, String comentarioSaida) {
        try {
            if (Test.isRunningTest() && forceUnexpectedErrorForTest == true) {
                throw new UnexpectedControllerException('Erro forçado para cobertura do catch genérico.');
            }
            return CaseAcompanhamentoService.retomarAtendimento(caseId, comentarioSaida);
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(Label.Acao_Acompanhamento_ErroInesperado);
        }
    }

    private class UnexpectedControllerException extends Exception {}
}