/**
 * @description       : Selector de queries SOQL estáticas para o módulo AtendimentoContextResolver.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AtendimentoContextResolverSelector {

    /**
     * @description Retorna Contacts pelos Ids informados com campos de identificação e contato.
     * @param ids Conjunto de Ids a consultar.
     * @return Lista de Contact.
     **/
    public static List<Contact> selectContactsByIds(Set<Id> ids) {
        return [
            SELECT Id, Name, AccountId, Email, Phone, MobilePhone
            FROM Contact
            WHERE Id IN :ids
        ];
    }

    /**
     * @description Retorna Accounts pelos Ids informados com Id e Name.
     * @param accountIds Conjunto de Ids a consultar.
     * @return Lista de Account.
     **/
    public static List<Account> selectAccountsByIds(Set<Id> accountIds) {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    /**
     * @description Retorna todos os registros ativos de TCO_ChannelRouting__mdt para roteamento de canal.
     * @return Lista de TCO_ChannelRouting__mdt.
     **/
    public static List<TCO_ChannelRouting__mdt> selectActiveChannelRoutes() {
        return [
            SELECT TCF_ChannelType__c, TCF_ChannelIdentifier__c, TCF_BusinessUnit__c, TCF_IsActive__c
            FROM TCO_ChannelRouting__mdt
            WHERE TCF_IsActive__c = true
        ];
    }
}