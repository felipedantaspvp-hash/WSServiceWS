/**
 * @description       : Selector de queries SOQL para o módulo WSWillCaseCreation.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseCreationSelector {

    /**
     * @description Retorna Contacts pelos Ids informados com campos de identificação e preferência de idioma.
     * @param contactIds Conjunto de Ids a consultar.
     * @return Mapa de Id → Contact.
     **/
    public static Map<Id, Contact> selectContactsByIds(Set<Id> contactIds) {
        return new Map<Id, Contact>([
            SELECT Id, AccountId, Name, Email, Phone, Idioma__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);
    }

    /**
     * @description Retorna Contacts pelos endereços de e-mail informados.
     * @param emails Conjunto de e-mails (em minúsculas) a consultar.
     * @return Lista de Contact.
     **/
    public static List<Contact> selectContactsByEmails(Set<String> emails) {
        return [
            SELECT Id, AccountId, Name, Email, Phone, Idioma__c
            FROM Contact
            WHERE Email IN :emails
        ];
    }

    /**
     * @description Retorna MessagingSessions pelos Ids informados.
     * @param sessionIds Conjunto de Ids a consultar.
     * @return Mapa de Id → MessagingSession.
     **/
    public static Map<Id, MessagingSession> selectMessagingSessionsByIds(Set<Id> sessionIds) {
        return new Map<Id, MessagingSession>([
            SELECT Id, EndUserContactId, MessagingEndUserId, CaseId
            FROM MessagingSession
            WHERE Id IN :sessionIds
        ]);
    }

    /**
     * @description Retorna MessagingEndUsers pelos Ids informados.
     * @param endUserIds Conjunto de Ids a consultar.
     * @return Mapa de Id → MessagingEndUser.
     **/
    public static Map<Id, MessagingEndUser> selectMessagingEndUsersByIds(Set<Id> endUserIds) {
        return new Map<Id, MessagingEndUser>([
            SELECT Id, ContactId, AccountId, Name, Language
            FROM MessagingEndUser
            WHERE Id IN :endUserIds
        ]);
    }

    /**
     * @description Retorna Cases pelos Ids informados com Id e CaseNumber.
     * @param caseIds Conjunto de Ids a consultar.
     * @return Mapa de Id → Case.
     **/
    public static Map<Id, Case> selectCasesById(Set<Id> caseIds) {
        return new Map<Id, Case>([
            SELECT Id, CaseNumber
            FROM Case
            WHERE Id IN :caseIds
        ]);
    }

    /**
     * @description Retorna todos os QueueSobjects do SObjectType Case com QueueId e DeveloperName da fila.
     * @return Lista de QueueSobject ordenada por DeveloperName da fila.
     **/
    public static List<QueueSobject> selectCaseQueuesBySobjectType() {
        return [
            SELECT QueueId, Queue.DeveloperName
            FROM QueueSobject
            WHERE SobjectType = 'Case'
            ORDER BY Queue.DeveloperName
        ];
    }
}
