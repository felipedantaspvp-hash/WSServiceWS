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

    /**
     * @description Retorna Contacts pelos Ids informados, com fallback defensivo caso o campo dinâmico
     * de conta representada (ex.: `ContaRepresentadaAtual__c`) não exista na org.
     * @param contactIds Conjunto de Ids a consultar.
     * @param representedAccountField API name do campo dinâmico de conta representada, ou null/blank.
     * @return Mapa de Id → Contact.
     **/
    public static Map<Id, Contact> selectContactsByIds(Set<Id> contactIds, String representedAccountField) {
        Map<Id, Contact> out = new Map<Id, Contact>();
        if (contactIds == null || contactIds.isEmpty()) return out;
        for (Contact row : queryContactsWithFallback(
            'WHERE Id IN :contactIds',
            new Map<String, Object>{ 'contactIds' => contactIds },
            representedAccountField
        )) {
            out.put(row.Id, row);
        }
        return out;
    }

    /**
     * @description Retorna Contacts pelos e-mails informados, com o mesmo fallback defensivo de
     * `selectContactsByIds` para o campo dinâmico de conta representada.
     * @param emails Conjunto de e-mails a consultar.
     * @param representedAccountField API name do campo dinâmico de conta representada, ou null/blank.
     * @return Lista de Contact.
     **/
    public static List<Contact> selectContactsByEmails(Set<String> emails, String representedAccountField) {
        List<Contact> out = new List<Contact>();
        if (emails == null || emails.isEmpty()) return out;
        out.addAll(queryContactsWithFallback(
            'WHERE Email IN :emails',
            new Map<String, Object>{ 'emails' => emails },
            representedAccountField
        ));
        return out;
    }

    /**
     * @description Monta e executa a query de Contact com o campo dinâmico de conta representada quando
     * existente, aplicando o fallback defensivo (removendo o campo do SELECT) se a org não o tiver.
     * @param whereClause Cláusula WHERE completa (ex.: "WHERE Id IN :contactIds").
     * @param binds Bind variables referenciadas na cláusula WHERE.
     * @param representedAccountField API name do campo dinâmico de conta representada, ou null/blank.
     * @return Lista de Contact.
     **/
    private static List<Contact> queryContactsWithFallback(String whereClause, Map<String, Object> binds, String representedAccountField) {
        List<String> selectFields = new List<String>{ 'Id', 'AccountId', 'Name', 'Email', 'Phone', 'Idioma__c' };
        if (!String.isBlank(representedAccountField) &&
            Schema.SObjectType.Contact.fields.getMap().containsKey(representedAccountField.toLowerCase())) {
            selectFields.add(representedAccountField);
        }

        try {
            return (List<Contact>) Database.queryWithBinds(
                'SELECT ' + String.join(selectFields, ',') + ' FROM Contact ' + whereClause,
                binds,
                AccessLevel.SYSTEM_MODE
            );
        } catch (QueryException ex) {
            if (!ex.getMessage().contains('ContaRepresentadaAtual__c')) {
                throw ex;
            }
            List<String> fallbackFields = new List<String>();
            for (String fieldName : selectFields) {
                if (fieldName != 'ContaRepresentadaAtual__c') {
                    fallbackFields.add(fieldName);
                }
            }
            return (List<Contact>) Database.queryWithBinds(
                'SELECT ' + String.join(fallbackFields, ',') + ' FROM Contact ' + whereClause,
                binds,
                AccessLevel.SYSTEM_MODE
            );
        }
    }
}