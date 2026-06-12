/**
 * @description       : DTO da FlowAction de disparo de Survey após fechamento do Case.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Codex
 **/
public inherited sharing class CaseSurveyDispatchDTO {
    public class Request {
        @InvocableVariable(required=true label='Case Id')
        public Id caseId;
    }

    public class Response {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem')
        public String message;

        @InvocableVariable(label='Case Id')
        public Id caseId;

        @InvocableVariable(label='Survey Invitation Id')
        public Id surveyInvitationId;
    }
}