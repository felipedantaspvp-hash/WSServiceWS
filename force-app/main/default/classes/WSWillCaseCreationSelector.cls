/**
 * @description       : Selector de queries SOQL para o módulo WSWillCaseCreation.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseCreationSelector {

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