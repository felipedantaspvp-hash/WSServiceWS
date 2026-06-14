/**
 * @description       : FlowAction fina para disparo governado de Survey após fechamento do Case.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseSurveyDispatchFlowAction {
    /**
     * @description Recebe Cases elegíveis do Flow e delega a regra de envio para a Service.
     * @param requests Lista de requisições com CaseId.
     * @return Resultado individual do processamento.
     */
    @InvocableMethod(label='Atendimento - Enviar Survey do Case' description='Cria Survey Invitation e envia template institucional quando o Case fechado está elegível.')
    public static List<CaseSurveyDispatchDTO.Response> dispatch(List<CaseSurveyDispatchDTO.Request> requests) {
        return CaseSurveyDispatchService.dispatch(requests);
    }
}