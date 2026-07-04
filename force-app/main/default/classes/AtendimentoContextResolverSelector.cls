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
}