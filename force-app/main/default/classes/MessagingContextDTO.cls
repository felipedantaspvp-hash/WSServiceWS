/**
 * @description       : DTOs de transferência de dados para o módulo MessagingContext. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : Mensageria
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class MessagingContextDTO {
    public class Request {
        @InvocableVariable(label='Routable Id')
        public Id routableId;

        @InvocableVariable(label='Channel Type')
        public String channelType;

        @InvocableVariable(label='End User Id')
        public Id endUserId;

        @InvocableVariable(label='Contact Id')
        public Id contactId;

        @InvocableVariable(label='Messaging Session Id')
        public Id messagingSessionId;

        @InvocableVariable(label='Live Chat Transcript Id')
        public Id liveChatTranscriptId;

        @InvocableVariable(label='Channel Developer Name')
        public String channelDeveloperName;
    }

    public class Response {
        @InvocableVariable(label='Contact Id') public Id contactId;
        @InvocableVariable(label='Contact Name') public String contactName;
        @InvocableVariable(label='Account Id') public Id accountId;
        @InvocableVariable(label='Account Name') public String accountName;
        @InvocableVariable(label='Business Unit Name') public String businessUnitName;
        @InvocableVariable(label='Channel Type') public String channelType;
        @InvocableVariable(label='Channel Developer Name') public String channelDeveloperName;
        @InvocableVariable(label='Conversation Id') public Id conversationId;
        @InvocableVariable(label='Conversation Contact Id') public Id conversationContactId;
        @InvocableVariable(label='Messaging Session Id') public Id messagingSessionId;
        @InvocableVariable(label='Messaging End User Id') public Id messagingEndUserId;
        @InvocableVariable(label='Live Chat Transcript Id') public Id liveChatTranscriptId;
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Requires Customer Identification') public Boolean requiresCustomerIdentification;
        @InvocableVariable(label='Fallback Reason') public String fallbackReason;
        @InvocableVariable(label='Target Queue Developer Name') public String targetQueueDeveloperName;
        @InvocableVariable(label='Fallback Queue Developer Name') public String fallbackQueueDeveloperName;
    }
}