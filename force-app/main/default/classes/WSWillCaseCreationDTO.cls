/**
 * @description       : DTOs de transferência de dados para o módulo WSWillCaseCreation. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseCreationDTO {
    public class Request {
        @InvocableVariable(label='Business Unit Name')
        public String businessUnitName;

        @InvocableVariable(label='Language')
        public String language;

        @InvocableVariable(label='Channel Name')
        public String channelName;

        @InvocableVariable(label='Origin')
        public String origin;

        @InvocableVariable(label='Conversation Id')
        public Id conversationId;

        @InvocableVariable(label='End User Id')
        public Id endUserId;

        @InvocableVariable(label='Contact Id')
        public Id contactId;

        @InvocableVariable(label='Account Id')
        public Id accountId;

        @InvocableVariable(label='Customer Full Name')
        public String customerFullName;

        @InvocableVariable(label='Customer Email')
        public String customerEmail;

        @InvocableVariable(label='Customer Phone')
        public String customerPhone;

        @InvocableVariable(label='Case Type')
        public String caseType;




        @InvocableVariable(label='Description')
        public String description;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Status Code')
        public String statusCode;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Contact Id')
        public Id contactId;

        @InvocableVariable(label='Account Id')
        public Id accountId;

        @InvocableVariable(label='Case Id')
        public Id caseId;

        @InvocableVariable(label='Case Number')
        public String caseNumber;
    }
}