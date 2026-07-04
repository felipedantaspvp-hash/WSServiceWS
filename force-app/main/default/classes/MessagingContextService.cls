public inherited sharing class MessagingContextService {
    public interface ConversationGateway {
        Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead);
    }

    private inherited sharing class DefaultConversationGateway implements ConversationGateway {
        public Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead) {
            Map<Id, SObject> out = new Map<Id, SObject>();
            if (String.isBlank(objectApiName) || ids == null || ids.isEmpty() || !MessagingContextHelper.canQueryObject(objectApiName)) return out;

            Set<String> readableFields = new Set<String>();
            if (fieldsToRead != null) {
                Map<String, Schema.SObjectField> mapFields = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
                for (String f : fieldsToRead) if (mapFields.containsKey(f)) readableFields.add(f);
            }
            readableFields.add('Id');
            // objectApiName validated via canQueryObject() and readableFields via schema field map above
            String soql = 'SELECT ' + String.join(new List<String>(readableFields), ',') + ' FROM ' + objectApiName + ' WHERE Id IN :ids';
            for (SObject row : Database.queryWithBinds(soql, new Map<String, Object>{ 'ids' => ids }, AccessLevel.USER_MODE)) out.put((Id) row.get('Id'), row);
            return out;
        }
    }

    public class ChannelConfig {
        public String channelDeveloperName;
        public String businessUnit;
        public String channelType;
        public String targetQueueDeveloperName;
        public String fallbackQueueDeveloperName;
        public Boolean isActive;
    }

    @TestVisible private static ConversationGateway gateway = new DefaultConversationGateway();
    @TestVisible private static List<ChannelConfig> testConfigs;

    @TestVisible
    private static void resetGateway() {
        gateway = new DefaultConversationGateway();
    }

    public static List<MessagingContextDTO.Response> resolve(List<MessagingContextDTO.Request> requests) {
        List<MessagingContextDTO.Response> out = new List<MessagingContextDTO.Response>();
        if (requests == null || requests.isEmpty()) return out;

        List<MessagingContextDTO.Request> normalized = new List<MessagingContextDTO.Request>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> endUserIds = new Set<Id>();
        Set<Id> msgSessionIds = new Set<Id>();
        Set<Id> liveChatIds = new Set<Id>();
        Set<String> channelDevNames = new Set<String>();

        for (MessagingContextDTO.Request req : requests) {
            MessagingContextDTO.Request r = req == null ? new MessagingContextDTO.Request() : req;
            if (r.messagingSessionId == null && r.routableId != null && MessagingContextHelper.inferSObjectApiName(r.routableId) == 'MessagingSession') {
                r.messagingSessionId = r.routableId;
            }
            if (r.liveChatTranscriptId == null && r.routableId != null && MessagingContextHelper.inferSObjectApiName(r.routableId) == 'LiveChatTranscript') {
                r.liveChatTranscriptId = r.routableId;
            }
            normalized.add(r);

            if (r.contactId != null) contactIds.add(r.contactId);
            if (r.endUserId != null) endUserIds.add(r.endUserId);
            if (r.messagingSessionId != null) msgSessionIds.add(r.messagingSessionId);
            if (r.liveChatTranscriptId != null) liveChatIds.add(r.liveChatTranscriptId);
            if (!String.isBlank(r.channelDeveloperName)) channelDevNames.add(r.channelDeveloperName);
        }

        Map<Id, SObject> msgById = gateway.fetchByIds('MessagingSession', msgSessionIds, new Set<String>{'ContactId','EndUserContactId','MessagingEndUserId','ChannelKey','ChannelType'});
        Map<Id, SObject> lctById = gateway.fetchByIds('LiveChatTranscript', liveChatIds, new Set<String>{'ContactId','LiveChatDeploymentId'});

        for (SObject row : msgById.values()) {
            Id c1 = (Id) row.get('ContactId');
            Id c2 = (Id) row.get('EndUserContactId');
            Id e1 = (Id) row.get('MessagingEndUserId');
            if (c1 != null) contactIds.add(c1);
            if (c2 != null) contactIds.add(c2);
            if (e1 != null) endUserIds.add(e1);
        }
        for (SObject row : lctById.values()) {
            Id c1 = (Id) row.get('ContactId');
            if (c1 != null) contactIds.add(c1);
        }

        Map<Id, Id> endUserToContactId = fetchEndUserContactMap(endUserIds);
        contactIds.addAll(endUserToContactId.values());

        Map<Id, Contact> contactsById = fetchContacts(contactIds);
        Map<Id, Account> accountsById = fetchAccounts(contactsById.values());
        Map<String, ChannelConfig> configByDevName = fetchConfigByDeveloperName(channelDevNames);

        for (MessagingContextDTO.Request r : normalized) {
            MessagingContextDTO.Response resp = new MessagingContextDTO.Response();
            try {
                fillResponse(r, resp, msgById, lctById, endUserToContactId, contactsById, accountsById, configByDevName);
            } catch (Exception ex) {
                resp.success = false;
                resp.requiresCustomerIdentification = true;
                resp.fallbackReason = 'Erro inesperado ao resolver contexto de messaging.';
            }
            out.add(resp);
        }
        return out;
    }

    private static void fillResponse(
        MessagingContextDTO.Request r,
        MessagingContextDTO.Response resp,
        Map<Id, SObject> msgById,
        Map<Id, SObject> lctById,
        Map<Id, Id> endUserToContactId,
        Map<Id, Contact> contactsById,
        Map<Id, Account> accountsById,
        Map<String, ChannelConfig> configByDevName
    ) {
        Id resolvedContactId = r.contactId;
        Id resolvedConversationId;
        Id resolvedConversationContactId;

        resp.channelType = MessagingContextHelper.normalizeChannelType(r.channelType);
        resp.channelDeveloperName = r.channelDeveloperName;
        resp.messagingSessionId = r.messagingSessionId;
        resp.liveChatTranscriptId = r.liveChatTranscriptId;

        if (r.messagingSessionId != null && msgById.containsKey(r.messagingSessionId)) {
            SObject ms = msgById.get(r.messagingSessionId);
            resolvedConversationId = r.messagingSessionId;
            Id fromContact = (Id) ms.get('ContactId');
            Id fromEndContact = (Id) ms.get('EndUserContactId');
            resp.messagingEndUserId = r.endUserId != null ? r.endUserId : (Id) ms.get('MessagingEndUserId');
            if (resolvedContactId == null) resolvedContactId = fromContact != null ? fromContact : fromEndContact;
            resolvedConversationContactId = fromContact != null ? fromContact : fromEndContact;
            if (String.isBlank(resp.channelType) || resp.channelType == 'Unknown') {
                resp.channelType = MessagingContextHelper.normalizeChannelType(String.valueOf(ms.get('ChannelType')));
            }
            if (String.isBlank(resp.channelDeveloperName)) {
                resp.channelDeveloperName = String.valueOf(ms.get('ChannelKey'));
            }
        }

        if (r.liveChatTranscriptId != null && lctById.containsKey(r.liveChatTranscriptId)) {
            SObject lct = lctById.get(r.liveChatTranscriptId);
            resolvedConversationId = r.liveChatTranscriptId;
            Id fromContact = (Id) lct.get('ContactId');
            if (resolvedContactId == null) resolvedContactId = fromContact;
            resolvedConversationContactId = fromContact;
            if (String.isBlank(resp.channelType) || resp.channelType == 'Unknown') resp.channelType = 'WebChat';
            if (String.isBlank(resp.channelDeveloperName)) {
                resp.channelDeveloperName = String.valueOf(lct.get('LiveChatDeploymentId'));
            }
        }

        if (resolvedContactId == null && r.endUserId != null && endUserToContactId.containsKey(r.endUserId)) {
            resolvedContactId = endUserToContactId.get(r.endUserId);
        }

        if (resolvedContactId != null && contactsById.containsKey(resolvedContactId)) {
            Contact c = contactsById.get(resolvedContactId);
            resp.contactId = c.Id;
            resp.contactName = c.Name;
            if (c.AccountId != null && accountsById.containsKey(c.AccountId)) {
                resp.accountId = c.AccountId;
                resp.accountName = accountsById.get(c.AccountId).Name;
            }
        }

        resp.conversationId = resolvedConversationId;
        resp.conversationContactId = resolvedConversationContactId;

        if (!String.isBlank(resp.channelDeveloperName)) {
            ChannelConfig cfg = configByDevName.get(MessagingContextHelper.normalizeKey(resp.channelDeveloperName));
            if (cfg != null && cfg.isActive == true) {
                resp.businessUnitName = cfg.businessUnit;
                if (String.isBlank(resp.channelType) || resp.channelType == 'Unknown') resp.channelType = cfg.channelType;
                resp.targetQueueDeveloperName = cfg.targetQueueDeveloperName;
                resp.fallbackQueueDeveloperName = cfg.fallbackQueueDeveloperName;
            }
        }

        Boolean hasChannelConfig = !String.isBlank(resp.businessUnitName);
        Boolean hasAnyContext = resolvedConversationId != null || !String.isBlank(resp.channelDeveloperName) || !String.isBlank(resp.channelType);

        if (!hasChannelConfig) {
            resp.fallbackReason = 'Configuração ativa de canal não encontrada para o channelDeveloperName informado.';
        }
        if (resp.contactId == null) {
            resp.requiresCustomerIdentification = true;
            if (String.isBlank(resp.fallbackReason)) resp.fallbackReason = 'Contato não identificado no contexto inicial.';
        } else {
            resp.requiresCustomerIdentification = false;
        }

        if (!hasAnyContext) {
            resp.success = false;
            if (String.isBlank(resp.fallbackReason)) resp.fallbackReason = 'Contexto insuficiente para resolver o atendimento.';
            return;
        }

        resp.success = true;
    }

    private static Map<Id, Contact> fetchContacts(Set<Id> ids) {
        Map<Id, Contact> out = new Map<Id, Contact>();
        if (ids == null || ids.isEmpty()) return out;
        for (Contact c : [SELECT Id, Name, AccountId FROM Contact WHERE Id IN :ids]) out.put(c.Id, c);
        return out;
    }

    private static Map<Id, Account> fetchAccounts(List<Contact> contacts) {
        Set<Id> ids = new Set<Id>();
        for (Contact c : contacts) if (c.AccountId != null) ids.add(c.AccountId);
        Map<Id, Account> out = new Map<Id, Account>();
        if (ids.isEmpty()) return out;
        for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :ids]) out.put(a.Id, a);
        return out;
    }

    private static Map<Id, Id> fetchEndUserContactMap(Set<Id> endUserIds) {
        Map<Id, Id> out = new Map<Id, Id>();
        if (endUserIds == null || endUserIds.isEmpty()) return out;
        if (!MessagingContextHelper.canQueryObject('MessagingEndUser')) return out;
        for (SObject m : Database.query('SELECT Id, ContactId FROM MessagingEndUser WHERE Id IN :endUserIds')) {
            Id contactId = (Id) m.get('ContactId');
            if (contactId != null) out.put((Id) m.get('Id'), contactId);
        }
        return out;
    }

    private static Map<String, ChannelConfig> fetchConfigByDeveloperName(Set<String> channelDevNames) {
        Map<String, ChannelConfig> out = new Map<String, ChannelConfig>();

        if (testConfigs != null) {
            for (ChannelConfig c : testConfigs) {
                out.put(MessagingContextHelper.normalizeKey(c.channelDeveloperName), c);
            }
            return out;
        }

        for (AtendimentoConfigDTO row : AtendimentoConfigService.getActiveConfigs()) {
            putConfig(out, row, String.isBlank(row.messagingChannelDeveloperName) ? row.developerName : row.messagingChannelDeveloperName, row.messagingChannelType);
            putConfig(out, row, row.whatsAppChannelDeveloperName, 'WhatsApp');
        }
        return out;
    }

    private static void putConfig(Map<String, ChannelConfig> configsByDeveloperName, AtendimentoConfigDTO row, String channelDeveloperName, String channelType) {
        if (configsByDeveloperName == null || row == null || String.isBlank(channelDeveloperName)) return;
        ChannelConfig cfg = new ChannelConfig();
        cfg.channelDeveloperName = channelDeveloperName;
        cfg.businessUnit = row.businessUnit;
        cfg.channelType = channelType;
        cfg.targetQueueDeveloperName = row.messagingTargetQueueDeveloperName;
        cfg.fallbackQueueDeveloperName = row.messagingFallbackQueueDeveloperName;
        cfg.isActive = row.isActive;
        configsByDeveloperName.put(MessagingContextHelper.normalizeKey(cfg.channelDeveloperName), cfg);
    }
}