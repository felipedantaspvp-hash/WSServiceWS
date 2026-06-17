/**
 * @description       : Classe de suporte para o módulo WSWill.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-12-2026
 * @last modified by  : Marllon Nascimento
 **/
public inherited sharing class WSWillContactLanguageInvocable {
    @TestVisible private static Map<Id, SObject> testSessionById;
    @TestVisible private static Map<Id, SObject> testEndUserById;

    public class Request {
        @InvocableVariable(label='Routable Id')
        public String routableId;

        @InvocableVariable(label='End User Id')
        public String endUserId;

        @InvocableVariable(label='Language')
        public String language;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Status Code')
        public String statusCode;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Resolved Contact Id')
        public Id resolvedContactId;
    }

    @InvocableMethod(label='WS Will - Atualizar Idioma do Contato')
    public static List<Response> updateLanguage(List<Request> requests) {
        List<Response> out = new List<Response>();
        if (requests == null || requests.isEmpty()) return out;

        Set<Id> requestedEndUserIds = new Set<Id>();
        Set<Id> messagingSessionIds = new Set<Id>();

        for (Request req : requests) {
            if (req == null) continue;

            Id endUserId = parseId(req.endUserId);
            if (endUserId != null) requestedEndUserIds.add(endUserId);

            Id routableId = parseId(req.routableId);
            if (routableId != null && AtendimentoContextResolverHelper.inferSObjectApiName(routableId) == 'MessagingSession') {
                messagingSessionIds.add(routableId);
            }
        }

        Map<Id, SObject> sessionById = Test.isRunningTest() && testSessionById != null ? testSessionById : fetchByIds(
            'MessagingSession',
            messagingSessionIds,
            new Set<String>{ 'Id', 'MessagingEndUserId', 'EndUserContactId', 'ContactId' }
        );

        Set<Id> allEndUserIds = new Set<Id>();
        allEndUserIds.addAll(requestedEndUserIds);
        for (SObject sessionRow : sessionById.values()) {
            Id sessionEndUserId = getIdSafe(sessionRow, 'MessagingEndUserId');
            if (sessionEndUserId != null) allEndUserIds.add(sessionEndUserId);
        }

        Map<Id, SObject> endUserById = Test.isRunningTest() && testEndUserById != null ? testEndUserById : fetchByIds(
            'MessagingEndUser',
            allEndUserIds,
            new Set<String>{ 'Id', 'ContactId' }
        );

        Set<Id> contactIds = new Set<Id>();
        for (SObject sessionRow : sessionById.values()) {
            Id contactId = getIdSafe(sessionRow, 'EndUserContactId');
            if (contactId == null) contactId = getIdSafe(sessionRow, 'ContactId');
            if (contactId != null) contactIds.add(contactId);
        }
        for (SObject endUserRow : endUserById.values()) {
            Id contactId = getIdSafe(endUserRow, 'ContactId');
            if (contactId != null) contactIds.add(contactId);
        }

        Map<Id, Contact> contactById = contactIds.isEmpty() ? new Map<Id, Contact>() : new Map<Id, Contact>([
            SELECT Id, Idioma__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        Map<Id, Contact> contactsToUpdateById = new Map<Id, Contact>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            Response res = defaultResponse('INVALID_INPUT', 'Dados insuficientes para atualizar idioma.');

            if (req == null) {
                out.add(res);
                continue;
            }

            String normalizedLanguage = WSWillContextResolverHelper.normalizePreferredLanguage(req.language);
            if (String.isBlank(normalizedLanguage)) {
                out.add(defaultResponse('INVALID_LANGUAGE', 'Idioma invalido.'));
                continue;
            }

            Id resolvedContactId = resolveContactId(req, sessionById, endUserById);
            if (resolvedContactId == null || !contactById.containsKey(resolvedContactId)) {
                out.add(defaultResponse('CONTACT_NOT_FOUND', 'Contato relacionado ao Messaging User nao encontrado.'));
                continue;
            }

            Contact currentContact = contactById.get(resolvedContactId);
            if (WSWillContextResolverHelper.normalizePreferredLanguage(currentContact.Idioma__c) != normalizedLanguage) {
                contactsToUpdateById.put(resolvedContactId, new Contact(Id = resolvedContactId, Idioma__c = normalizedLanguage));
            }

            res.success = true;
            res.statusCode = 'SUCCESS';
            res.message = 'Idioma atualizado com sucesso no Contact.';
            res.resolvedContactId = resolvedContactId;
            out.add(res);
        }

        if (!contactsToUpdateById.isEmpty()) {
            update contactsToUpdateById.values();
        }

        return out;
    }

    private static Id resolveContactId(Request req, Map<Id, SObject> sessionById, Map<Id, SObject> endUserById) {
        Id routableId = parseId(req.routableId);
        SObject sessionRow = sessionById.get(routableId);
        if (sessionRow != null) {
            Id contactId = getIdSafe(sessionRow, 'EndUserContactId');
            if (contactId == null) contactId = getIdSafe(sessionRow, 'ContactId');
            if (contactId != null) return contactId;

            Id sessionEndUserId = getIdSafe(sessionRow, 'MessagingEndUserId');
            SObject sessionEndUser = endUserById.get(sessionEndUserId);
            contactId = getIdSafe(sessionEndUser, 'ContactId');
            if (contactId != null) return contactId;
        }

        Id endUserId = parseId(req.endUserId);
        SObject endUser = endUserById.get(endUserId);
        return getIdSafe(endUser, 'ContactId');
    }

    private static Response defaultResponse(String statusCode, String message) {
        Response res = new Response();
        res.success = false;
        res.statusCode = statusCode;
        res.message = message;
        return res;
    }

    @TestVisible
    private static Id parseId(String rawValue) {
        if (String.isBlank(rawValue)) return null;
        String candidate = rawValue.trim();
        if (candidate.length() != 15 && candidate.length() != 18) return null;
        try {
            return Id.valueOf(candidate);
        } catch (Exception ex) {
            return null;
        }
    }

    @TestVisible
    private static Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> candidateFields) {
        Map<Id, SObject> out = new Map<Id, SObject>();
        if (String.isBlank(objectApiName) || ids == null || ids.isEmpty() || !AtendimentoContextResolverHelper.canQueryObject(objectApiName)) {
            return out;
        }

        Set<String> readableFields = AtendimentoContextResolverHelper.existingFields(objectApiName, candidateFields);
        readableFields.add('Id');
        String soql = 'SELECT ' + String.join(new List<String>(readableFields), ',') + ' FROM ' + objectApiName + ' WHERE Id IN :ids';
        for (SObject row : Database.query(soql)) {
            out.put((Id) row.get('Id'), row);
        }
        return out;
    }

    private static Id getIdSafe(SObject row, String fieldName) {
        if (row == null || String.isBlank(fieldName)) return null;
        try {
            Object raw = row.get(fieldName);
            return raw == null ? null : (Id) raw;
        } catch (Exception ex) {
            return null;
        }
    }
}