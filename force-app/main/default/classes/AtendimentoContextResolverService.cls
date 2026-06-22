public inherited sharing class AtendimentoContextResolverService {
    public class FunctionalException extends Exception { public String code; }

    public interface ConversationGateway {
        Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead);
    }

    private class DefaultConversationGateway implements ConversationGateway {
        public Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead) {
            Map<Id, SObject> out = new Map<Id, SObject>();
            if (String.isBlank(objectApiName) || ids == null || ids.isEmpty() || !AtendimentoContextResolverHelper.canQueryObject(objectApiName)) {
                return out;
            }

            Set<String> readableFields = AtendimentoContextResolverHelper.existingFields(objectApiName, fieldsToRead);
            readableFields.add('Id');
            String soql = 'SELECT ' + String.join(new List<String>(readableFields), ',') + ' FROM ' + objectApiName + ' WHERE Id IN :ids';
            for (SObject row : Database.query(soql)) {
                out.put((Id) row.get('Id'), row);
            }
            return out;
        }
    }

    @TestVisible private static ConversationGateway gateway = new DefaultConversationGateway();
    @TestVisible private static List<TCO_ChannelRouting__mdt> activeChannelRoutesOverride;

    @TestVisible
    private static void restoreDefaultGateway() {
        gateway = new DefaultConversationGateway();
    }

    private class WorkingResult {
        public AtendimentoContextResolverDTO.Response response;
        public String normalizedChannelType;
        public String channelIdentifier;
        public Id conversationCandidateId;
        public String conversationObjectApiName;
        public Id directContactId;
        public Id endUserId;
        public Id conversationContactCandidateId;
        public Boolean hasAnyInput = false;

        public WorkingResult(AtendimentoContextResolverDTO.Response response) {
            this.response = response;
        }
    }

    public static List<AtendimentoContextResolverDTO.Response> resolve(List<AtendimentoContextResolverDTO.Request> requests) {
        List<AtendimentoContextResolverDTO.Response> output = new List<AtendimentoContextResolverDTO.Response>();
        if (requests == null || requests.isEmpty()) return output;

        List<WorkingResult> works = new List<WorkingResult>();
        Set<Id> allContactIds = new Set<Id>();
        Set<Id> allMessagingSessionIds = new Set<Id>();
        Set<Id> allLiveChatTranscriptIds = new Set<Id>();
        Set<Id> allEndUserIds = new Set<Id>();

        for (AtendimentoContextResolverDTO.Request req : requests) {
            WorkingResult wr = initWorking(req);
            works.add(wr);

            if (wr.directContactId != null) allContactIds.add(wr.directContactId);
            if (wr.endUserId != null) allEndUserIds.add(wr.endUserId);
            if (wr.conversationCandidateId != null) {
                if (wr.conversationObjectApiName == 'MessagingSession') allMessagingSessionIds.add(wr.conversationCandidateId);
                if (wr.conversationObjectApiName == 'LiveChatTranscript') allLiveChatTranscriptIds.add(wr.conversationCandidateId);
            }
        }

        Map<Id, Contact> contactById = fetchContactsById(allContactIds);

        Map<Id, SObject> messagingById = gateway.fetchByIds(
            'MessagingSession',
            allMessagingSessionIds,
            new Set<String>{ 'ContactId', 'EndUserContactId', 'MessagingEndUserId', 'MessagingChannelId', 'ChannelType', 'ChannelName', 'ChannelKey' }
        );

        Map<Id, SObject> liveChatById = gateway.fetchByIds(
            'LiveChatTranscript',
            allLiveChatTranscriptIds,
            new Set<String>{ 'ContactId', 'LiveChatVisitorId', 'LiveChatDeploymentId' }
        );

        Map<Id, Contact> endUserMappedContacts = fetchContactsByEndUser(allEndUserIds);
        for (Contact c : endUserMappedContacts.values()) {
            allContactIds.add(c.Id);
        }
        contactById.putAll(fetchContactsById(allContactIds));
        Map<Id, Account> accountById = fetchAccountsFromContacts(contactById.values());
        List<TCO_ChannelRouting__mdt> activeChannelRoutes = fetchActiveChannelRoutes();

        for (WorkingResult wr : works) {
            try {
                resolveOne(wr, contactById, accountById, messagingById, liveChatById, endUserMappedContacts, activeChannelRoutes);
            } catch (Exception ex) {
                applyUnexpectedError(wr.response);
            }
            output.add(wr.response);
        }
        return output;
    }

    private static WorkingResult initWorking(AtendimentoContextResolverDTO.Request req) {
        AtendimentoContextResolverDTO.Response response = new AtendimentoContextResolverDTO.Response();
        response.success = false;
        response.statusCode = 'INVALID_INPUT';
        response.message = 'Dados de entrada insuficientes para resolver o contexto.';
        response.channelName = 'Unknown';
        response.needsCustomerInput = true;
        response.nextAction = 'CONTINUE_WITH_LIMITED_CONTEXT';

        WorkingResult wr = new WorkingResult(response);
        if (req == null) {
            response.missingInformation = 'Contact,BusinessUnit';
            return wr;
        }
        wr.hasAnyInput = req.routableId != null || !String.isBlank(req.channelType) || req.endUserId != null || req.contactId != null;

        wr.normalizedChannelType = AtendimentoContextResolverHelper.normalizeChannelType(req.channelType);
        wr.directContactId = req.contactId;
        wr.endUserId = req.endUserId;
        wr.conversationCandidateId = req.routableId;
        wr.conversationObjectApiName = AtendimentoContextResolverHelper.inferSObjectApiName(req.routableId);

        response.channelName = AtendimentoContextResolverHelper.channelDisplayName(wr.normalizedChannelType);
        return wr;
    }

    private static void resolveOne(
        WorkingResult wr,
        Map<Id, Contact> contactById,
        Map<Id, Account> accountById,
        Map<Id, SObject> messagingById,
        Map<Id, SObject> liveChatById,
        Map<Id, Contact> endUserMappedContacts,
        List<TCO_ChannelRouting__mdt> activeChannelRoutes
    ) {
        Id resolvedContactId;
        Id resolvedConversationContactId;
        Set<Id> contactCandidates = new Set<Id>();

        if (wr.directContactId != null && contactById.containsKey(wr.directContactId)) {
            resolvedContactId = wr.directContactId;
            contactCandidates.add(resolvedContactId);
        }

        if (wr.conversationCandidateId != null) {
            wr.response.conversationId = wr.conversationCandidateId;
            if (wr.conversationObjectApiName == 'MessagingSession') {
                SObject messaging = messagingById.get(wr.conversationCandidateId);
                if (messaging != null) {
                    resolvedConversationContactId = (Id) messaging.get('ContactId');
                    if (resolvedConversationContactId == null) {
                        resolvedConversationContactId = (Id) messaging.get('EndUserContactId');
                    }
                    if (resolvedConversationContactId != null) contactCandidates.add(resolvedConversationContactId);
                    wr.channelIdentifier = String.valueOf(messaging.get('ChannelKey'));
                    if (String.isBlank(wr.channelIdentifier)) {
                        wr.channelIdentifier = String.valueOf(messaging.get('MessagingChannelId'));
                    }
                    String sessionChannelType = String.valueOf(messaging.get('ChannelType'));
                    if (wr.normalizedChannelType == AtendimentoContextResolverHelper.CHANNEL_UNKNOWN && !String.isBlank(sessionChannelType)) {
                        wr.normalizedChannelType = AtendimentoContextResolverHelper.normalizeChannelType(sessionChannelType);
                    }
                    if (wr.normalizedChannelType == AtendimentoContextResolverHelper.CHANNEL_UNKNOWN) {
                        wr.normalizedChannelType = AtendimentoContextResolverHelper.CHANNEL_WHATSAPP;
                    }
                } else {
                    wr.response.statusCode = 'CONVERSATION_NOT_FOUND';
                    wr.response.message = 'Conversa informada não foi encontrada.';
                }
            } else if (wr.conversationObjectApiName == 'LiveChatTranscript') {
                SObject liveChat = liveChatById.get(wr.conversationCandidateId);
                if (liveChat != null) {
                    resolvedConversationContactId = (Id) liveChat.get('ContactId');
                    if (resolvedConversationContactId != null) contactCandidates.add(resolvedConversationContactId);
                    wr.channelIdentifier = String.valueOf(liveChat.get('LiveChatDeploymentId'));
                    if (wr.normalizedChannelType == AtendimentoContextResolverHelper.CHANNEL_UNKNOWN) {
                        wr.normalizedChannelType = AtendimentoContextResolverHelper.CHANNEL_CHAT;
                    }
                } else {
                    wr.response.statusCode = 'CONVERSATION_NOT_FOUND';
                    wr.response.message = 'Conversa informada não foi encontrada.';
                }
            }
        }

        if (resolvedContactId == null && wr.endUserId != null) {
            Contact mapped = endUserMappedContacts.get(wr.endUserId);
            if (mapped != null) contactCandidates.add(mapped.Id);
        }

        if (contactCandidates.size() > 1) {
            wr.response.success = false;
            wr.response.statusCode = 'MULTIPLE_CONTACTS_FOUND';
            wr.response.message = 'Mais de um contato possível foi identificado para o atendimento.';
            wr.response.needsCustomerInput = true;
            wr.response.nextAction = 'ASK_CONTACT_DISAMBIGUATION';
            wr.response.missingInformation = 'Contact';
            wr.response.conversationContactId = resolvedConversationContactId;
            wr.response.channelName = AtendimentoContextResolverHelper.channelDisplayName(wr.normalizedChannelType);
            wr.response.businessUnitName = resolveBusinessUnit(
                wr.normalizedChannelType,
                wr.channelIdentifier,
                wr.response.conversationId,
                activeChannelRoutes
            );
            return;
        }

        if (!contactCandidates.isEmpty()) {
            resolvedContactId = new List<Id>(contactCandidates)[0];
        }

        wr.response.conversationContactId = resolvedConversationContactId;
        wr.response.channelName = AtendimentoContextResolverHelper.channelDisplayName(wr.normalizedChannelType);

        if (resolvedContactId != null && contactById.containsKey(resolvedContactId)) {
            Contact c = contactById.get(resolvedContactId);
            wr.response.contactId = c.Id;
            wr.response.contactName = c.Name;
            if (c.AccountId != null && accountById.containsKey(c.AccountId)) {
                Account a = accountById.get(c.AccountId);
                wr.response.accountId = a.Id;
                wr.response.accountName = a.Name;
            }
        }

        wr.response.businessUnitName = resolveBusinessUnit(
            wr.normalizedChannelType,
            wr.channelIdentifier,
            wr.response.conversationId,
            activeChannelRoutes
        );

        if (wr.normalizedChannelType == AtendimentoContextResolverHelper.CHANNEL_UNKNOWN && wr.hasAnyInput) {
            wr.response.statusCode = 'CHANNEL_NOT_IDENTIFIED';
            wr.response.message = 'Canal de entrada não identificado.';
        }
        if (wr.response.statusCode == 'INVALID_INPUT' && wr.hasAnyInput) {
            wr.response.statusCode = null;
            wr.response.message = null;
        }

        finalizeStatus(wr.response);
    }

    private static void finalizeStatus(AtendimentoContextResolverDTO.Response response) {
        if (response.statusCode == 'INVALID_INPUT') {
            response.success = false;
            response.needsCustomerInput = true;
            response.nextAction = 'CONTINUE_WITH_LIMITED_CONTEXT';
            response.missingInformation = 'Contact,BusinessUnit';
            return;
        }

        if (response.contactId == null) {
            response.success = false;
            response.statusCode = 'CONTACT_NOT_FOUND';
            response.message = 'Contato não identificado para o atendimento.';
            response.needsCustomerInput = true;
            response.nextAction = 'ASK_CONTACT_IDENTIFICATION';
            response.missingInformation = 'Contact';
            return;
        }

        if (response.accountId == null) {
            response.success = false;
            response.statusCode = 'CONTACT_WITHOUT_ACCOUNT';
            response.message = 'Contato identificado sem conta vinculada.';
            response.needsCustomerInput = true;
            response.nextAction = 'ASK_ACCOUNT_IDENTIFICATION';
            response.missingInformation = 'Account';
            return;
        }

        if (String.isBlank(response.businessUnitName)) {
            response.success = false;
            response.statusCode = 'BUSINESS_UNIT_NOT_FOUND';
            response.message = 'Unidade de negócio não identificada para o canal.';
            response.needsCustomerInput = true;
            response.nextAction = 'ASK_BUSINESS_UNIT_CONFIRMATION';
            response.missingInformation = 'BusinessUnit';
            return;
        }

        response.success = true;
        response.needsCustomerInput = false;
        response.nextAction = 'CONTINUE_TO_MAIN_MENU';
        response.missingInformation = null;

        if (response.conversationId == null) {
            response.statusCode = 'SUCCESS_WITHOUT_CONVERSATION';
            response.message = 'Contexto resolvido sem conversa vinculada.';
            return;
        }

        response.statusCode = 'SUCCESS';
        response.message = 'Contexto inicial resolvido com sucesso.';
    }

    private static Map<Id, Contact> fetchContactsById(Set<Id> ids) {
        Map<Id, Contact> out = new Map<Id, Contact>();
        if (ids == null || ids.isEmpty()) return out;
        for (Contact row : AtendimentoContextResolverSelector.selectContactsByIds(ids)) {
            out.put(row.Id, row);
        }
        return out;
    }

    private static Map<Id, Account> fetchAccountsFromContacts(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : contacts) {
            if (c.AccountId != null) accountIds.add(c.AccountId);
        }

        Map<Id, Account> out = new Map<Id, Account>();
        if (accountIds.isEmpty()) return out;

        for (Account row : AtendimentoContextResolverSelector.selectAccountsByIds(accountIds)) {
            out.put(row.Id, row);
        }
        return out;
    }

    private static Map<Id, Contact> fetchContactsByEndUser(Set<Id> endUserIds) {
        Map<Id, Contact> out = new Map<Id, Contact>();
        if (endUserIds == null || endUserIds.isEmpty()) return out;

        String endUserObject = 'MessagingEndUser';
        if (!AtendimentoContextResolverHelper.canQueryObject(endUserObject)) return out;

        Set<String> candidateFields = new Set<String>{ 'Id', 'ContactId' };
        Set<String> existing = AtendimentoContextResolverHelper.existingFields(endUserObject, candidateFields);
        if (!existing.contains('ContactId')) return out;

        String soql = 'SELECT Id, ContactId FROM ' + endUserObject + ' WHERE Id IN :endUserIds';
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Id> endUserToContact = new Map<Id, Id>();
        for (SObject row : Database.query(soql)) {
            Id contactId = (Id) row.get('ContactId');
            if (contactId == null) continue;
            endUserToContact.put((Id) row.get('Id'), contactId);
            contactIds.add(contactId);
        }

        Map<Id, Contact> byId = fetchContactsById(contactIds);
        for (Id endUserId : endUserToContact.keySet()) {
            Id contactId = endUserToContact.get(endUserId);
            if (byId.containsKey(contactId)) out.put(endUserId, byId.get(contactId));
        }
        return out;
    }

    private static String resolveBusinessUnit(String normalizedChannelType, String channelIdentifier, Id conversationId, List<TCO_ChannelRouting__mdt> rows) {
        if (rows == null || rows.isEmpty()) return null;
        String normalizedType = AtendimentoContextResolverHelper.normalizeKey(normalizedChannelType);
        String normalizedIdentifier = AtendimentoContextResolverHelper.normalizeKey(channelIdentifier);
        String normalizedConversation = AtendimentoContextResolverHelper.normalizeKey(String.valueOf(conversationId));

        for (TCO_ChannelRouting__mdt row : rows) {
            String rowType = AtendimentoContextResolverHelper.normalizeKey(row.TCF_ChannelType__c);
            String rowIdentifier = AtendimentoContextResolverHelper.normalizeKey(row.TCF_ChannelIdentifier__c);

            if (rowType != normalizedType) continue;
            if (!String.isBlank(normalizedIdentifier) && rowIdentifier == normalizedIdentifier) return row.TCF_BusinessUnit__c;
            if (!String.isBlank(normalizedConversation) && rowIdentifier == normalizedConversation) return row.TCF_BusinessUnit__c;
        }

        for (TCO_ChannelRouting__mdt row : rows) {
            String rowType = AtendimentoContextResolverHelper.normalizeKey(row.TCF_ChannelType__c);
            String rowIdentifier = AtendimentoContextResolverHelper.normalizeKey(row.TCF_ChannelIdentifier__c);
            if (rowType == normalizedType && String.isBlank(rowIdentifier)) return row.TCF_BusinessUnit__c;
        }
        return null;
    }

    private static List<TCO_ChannelRouting__mdt> fetchActiveChannelRoutes() {
        if (Test.isRunningTest() && activeChannelRoutesOverride != null) {
            return activeChannelRoutesOverride;
        }
        if (!AtendimentoContextResolverHelper.canQueryObject('TCO_ChannelRouting__mdt')) return new List<TCO_ChannelRouting__mdt>();
        return AtendimentoContextResolverSelector.selectActiveChannelRoutes();
    }

    private static void applyUnexpectedError(AtendimentoContextResolverDTO.Response response) {
        response.success = false;
        response.statusCode = 'UNEXPECTED_ERROR';
        response.message = 'Erro inesperado ao resolver o contexto inicial.';
        response.needsCustomerInput = true;
        response.nextAction = 'TRANSFER_TO_SPECIALIST';
        if (String.isBlank(response.missingInformation)) response.missingInformation = 'Contact,BusinessUnit';
    }
}