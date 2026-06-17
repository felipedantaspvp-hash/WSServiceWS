/**
 * @description       : DTOs de transferência de dados para o módulo AtendimentoContextResolver. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AtendimentoContextResolverDTO {
    public class Request {
        @InvocableVariable(label='Routable Id')
        public Id routableId;

        @InvocableVariable(label='Channel Type')
        public String channelType;

        @InvocableVariable(label='End User Id')
        public Id endUserId;

        @InvocableVariable(label='Contact Id')
        public Id contactId;
    }

    public class Response {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Código de Status')
        public String statusCode;

        @InvocableVariable(label='Mensagem')
        public String message;

        @InvocableVariable(label='Precisa Perguntar ao Cliente')
        public Boolean needsCustomerInput;

        @InvocableVariable(label='Próxima Ação Recomendada')
        public String nextAction;

        @InvocableVariable(label='Informações Pendentes')
        public String missingInformation;

        @InvocableVariable(label='Nome do Contato')
        public String contactName;

        @InvocableVariable(label='Id do Contato')
        public Id contactId;

        @InvocableVariable(label='Nome da Conta')
        public String accountName;

        @InvocableVariable(label='Id da Conta')
        public Id accountId;

        @InvocableVariable(label='Nome da Unidade de Negócio')
        public String businessUnitName;

        @InvocableVariable(label='Canal')
        public String channelName;

        @InvocableVariable(label='Id da Conversa')
        public Id conversationId;

        @InvocableVariable(label='Id do Contato da Conversa')
        public Id conversationContactId;
    }
}