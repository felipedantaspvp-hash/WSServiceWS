/**
 * @description       : DTOs de transferência de dados para o módulo WSWillContextResolver. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillContextResolverDTO {
    public class Request {
        @InvocableVariable(label='Routable Id')
        public String routableId;

        @InvocableVariable(label='Channel Type')
        public String channelType;

        @InvocableVariable(label='End User Id')
        public String endUserId;
    }

    public class Response {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Código de Status')
        public String statusCode;

        @InvocableVariable(label='Mensagem')
        public String message;

        @InvocableVariable(label='Nome do Contato')
        public String contactName;

        @InvocableVariable(label='Id do Contato')
        public Id contactId;

        @InvocableVariable(label='Nome da Conta')
        public String accountName;

        @InvocableVariable(label='Id da Conta')
        public Id accountId;

        @InvocableVariable(label='Unidade de Negócio')
        public String businessUnitName;

        @InvocableVariable(label='Fonte da Unidade')
        public String businessUnitSource;

        @InvocableVariable(label='Canal')
        public String channelName;

        @InvocableVariable(label='Id da Conversa')
        public Id conversationId;

        @InvocableVariable(label='Id do Contato da Conversa')
        public Id conversationContactId;

        @InvocableVariable(label='Idioma Preferido')
        public String preferredLanguage;

        @InvocableVariable(label='Deve Perguntar Idioma')
        public Boolean shouldAskLanguage;
    }
}