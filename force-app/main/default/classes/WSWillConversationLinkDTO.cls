/**
 * @description       : DTOs de transferência de dados para o módulo WSWillConversationLink. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillConversationLinkDTO {
    public class Request {
        @InvocableVariable(label='Conversation Id')
        public Id conversationId;

        @InvocableVariable(label='Case Id')
        public Id caseId;

        @InvocableVariable(label='Channel Name')
        public String channelName;

        @InvocableVariable(label='Routable Id')
        public Id routableId;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Status Code')
        public String statusCode;

        @InvocableVariable(label='Message')
        public String message;
    }
}