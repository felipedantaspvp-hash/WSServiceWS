/**
 * @description Resolvedor de contexto inicial do Will para conversa, contato, idioma e unidade de negócio.
 * @author Triscal
 * @group Bot Will
 * @last modified on 06-03-2026
 * @last modified by Codex
 **/
public inherited sharing class WSWillContextResolverService {
    @TestVisible private static Map<Id, SObject> testMessagingById;
    @TestVisible private static Map<Id, SObject> testEndUserById;
    @TestVisible private static Map<Id, SObject> testLiveChatById;
    @TestVisible private static Map<Id, SObject> testMessagingChannelById;
    @TestVisible private static List<TCO_ChannelRouting__mdt> testRoutes;
    @TestVisible private static List<AtendimentoConfigDTO> testAtendimentoParams;
    @TestVisible static Boolean throwExceptionForTest = false;

    public static List<WSWillContextResolverDTO.Response> resolve(List<WSWillContextResolverDTO.Request> requests) {
        if (Test.isRunningTest() && throwExceptionForTest) {
            throw new IllegalArgumentException('Simulated exception for coverage');
        }
        List<WSWillContextResolverDTO.Response> out = new List<WSWillContextResolverDTO.Response>();
        if (requests == null || requests.isEmpty()) return out;
        Set<Id> endUserIds = new Set<Id>();
        Set<Id> messagingSessionIds = new Set<Id>();
        Set<Id> liveChatIds = new Set<Id>();

        for (WSWillContextResolverDTO.Request req : requests) {
            Id endUserId = parseId(req == null ? null : req.endUserId);
            Id routableId = parseId(req == null ? null : req.routableId);
            if (endUserId != null) endUserIds.add(endUserId);
            if (routableId != null) {
                String api = AtendimentoContextResolverHelper.inferSObjectApiName(routableId);
                if (api == 'MessagingSession') messagingSessionIds.add(routableId);
                if (api == 'LiveChatTranscript') liveChatIds.add(routableId);
            }
        }

        Map<Id, SObject> messagingById = Test.isRunningTest() && testMessagingById != null ? testMessagingById : fetchByIds(
            'MessagingSession',
            messagingSessionIds,
            new Set<String>{ 'Id', 'ContactId', 'EndUserContactId', 'MessagingEndUserId', 'MessagingChannelId', 'ChannelType', 'ChannelKey' }
        );
        Set<Id> messagingChannelIds = new Set<Id>();
        for (SObject row : messagingById.values()) {
            Id channelId = getIdSafe(row, 'MessagingChannelId');
            if (channelId != null) messagingChannelIds.add(channelId);
        }
        Map<Id, SObject> messagingChannelById = Test.isRunningTest() && testMessagingChannelById != null
            ? testMessagingChannelById
            : fetchByIds('MessagingChannel', messagingChannelIds, new Set<String>{ 'Id', 'DeveloperName', 'MasterLabel' });
        Map<Id, SObject> liveChatById = Test.isRunningTest() && testLiveChatById != null ? testLiveChatById : fetchByIds(
            'LiveChatTranscript',
            liveChatIds,
            new Set<String>{ 'Id', 'ContactId', 'LiveChatDeploymentId' }
        );

        for (SObject row : messagingById.values()) {
            Id sessionEndUserId = getIdSafe(row, 'MessagingEndUserId');
            if (sessionEndUserId != null) endUserIds.add(sessionEndUserId);
        }

        Map<Id, SObject> endUserById = Test.isRunningTest() && testEndUserById != null ? testEndUserById : fetchByIds(
            'MessagingEndUser',
            endUserIds,
            new Set<String>{ 'Id', 'ContactId', 'AccountId' }
        );

        Set<Id> allContactIds = new Set<Id>();
        for (SObject row : messagingById.values()) {
            Id c1 = getIdSafe(row, 'ContactId');
            Id c2 = getIdSafe(row, 'EndUserContactId');
            if (c1 != null) allContactIds.add(c1);
            if (c2 != null) allContactIds.add(c2);
        }
        for (SObject row : liveChatById.values()) {
            Id c = getIdSafe(row, 'ContactId');
            if (c != null) allContactIds.add(c);
        }
        for (SObject row : endUserById.values()) {
            Id c = getIdSafe(row, 'ContactId');
            if (c != null) allContactIds.add(c);
        }

        Map<Id, Contact> contactById = fetchContacts(allContactIds);
        Map<Id, Account> accountById = fetchAccounts(contactById.values());
        List<TCO_ChannelRouting__mdt> routes = Test.isRunningTest() && testRoutes != null ? testRoutes : fetchActiveChannelRoutes();
        List<AtendimentoConfigDTO> atendimentoParams = Test.isRunningTest() && testAtendimentoParams != null
            ? testAtendimentoParams
            : fetchActiveAtendimentoParams();

        for (WSWillContextResolverDTO.Request req : requests) {
            WSWillContextResolverDTO.Response res = new WSWillContextResolverDTO.Response();
            res.success = true;
            res.statusCode = 'SUCCESS';
            res.message = 'Contexto inicial resolvido com sucesso.';

            Id routableId = parseId(req == null ? null : req.routableId);
            Id endUserId = parseId(req == null ? null : req.endUserId);
            String normalizedChannelType = AtendimentoContextResolverHelper.normalizeChannelType(req == null ? null : req.channelType);

            res.conversationId = routableId;
            res.channelName = AtendimentoContextResolverHelper.channelDisplayName(normalizedChannelType);

            SObject messaging = messagingById.get(routableId);
            SObject liveChat = liveChatById.get(routableId);
            if (messaging != null) {
                Id sessionEndUserId = getIdSafe(messaging, 'MessagingEndUserId');
                if (endUserId == null) endUserId = sessionEndUserId;
                res.conversationContactId = getIdSafe(messaging, 'ContactId');
                if (res.conversationContactId == null) res.conversationContactId = getIdSafe(messaging, 'EndUserContactId');
            } else if (liveChat != null) {
                res.conversationContactId = getIdSafe(liveChat, 'ContactId');
            }

            SObject endUser = endUserById.get(endUserId);
            Id resolvedContactId = null;
            if (resolvedContactId == null && res.conversationContactId != null) resolvedContactId = res.conversationContactId;
            if (resolvedContactId == null && endUser != null) resolvedContactId = getIdSafe(endUser, 'ContactId');
            if (res.conversationContactId == null && resolvedContactId != null) res.conversationContactId = resolvedContactId;

            if (resolvedContactId != null && contactById.containsKey(resolvedContactId)) {
                Contact c = contactById.get(resolvedContactId);
                res.contactId = c.Id;
                res.contactName = c.Name;
                res.accountId = c.AccountId;
                if (c.AccountId != null && accountById.containsKey(c.AccountId)) {
                    res.accountName = accountById.get(c.AccountId).Name;
                }
            }

            String language = res.contactId == null
                ? null
                : WSWillContextResolverHelper.normalizePreferredLanguage(contactById.get(res.contactId).Idioma__c);
            res.preferredLanguage = language;
            res.shouldAskLanguage = String.isBlank(language);

            String channelIdentifier;
            if (messaging != null) {
                Id messagingChannelId = getIdSafe(messaging, 'MessagingChannelId');
                if (messagingChannelId != null && messagingChannelById.containsKey(messagingChannelId)) {
                    channelIdentifier = getStringSafe(messagingChannelById.get(messagingChannelId), 'DeveloperName');
                    if (String.isBlank(channelIdentifier)) channelIdentifier = getStringSafe(messagingChannelById.get(messagingChannelId), 'MasterLabel');
                }
                if (String.isBlank(channelIdentifier)) channelIdentifier = String.valueOf(messaging.get('ChannelKey'));
                if (String.isBlank(channelIdentifier)) channelIdentifier = String.valueOf(messaging.get('MessagingChannelId'));
                if (normalizedChannelType == AtendimentoContextResolverHelper.CHANNEL_UNKNOWN) {
                    normalizedChannelType = AtendimentoContextResolverHelper.normalizeChannelType(String.valueOf(messaging.get('ChannelType')));
                    res.channelName = AtendimentoContextResolverHelper.channelDisplayName(normalizedChannelType);
                }
            } else if (liveChat != null) {
                channelIdentifier = String.valueOf(liveChat.get('LiveChatDeploymentId'));
            }

            BusinessUnitResolution businessUnitResolution = resolveBusinessUnit(normalizedChannelType, channelIdentifier, res.conversationId, routes, atendimentoParams);
            res.businessUnitName = businessUnitResolution.businessUnitName;
            res.businessUnitSource = WSWillContextResolverHelper.inferBusinessUnitSource(
                !String.isBlank(res.businessUnitName),
                res.conversationId,
                businessUnitResolution.source
            );
            out.add(res);
        }

        return out;
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
        if (String.isBlank(objectApiName) || ids == null || ids.isEmpty() || !AtendimentoContextResolverHelper.canQueryObject(objectApiName)) return out;

        Set<String> readableFields = AtendimentoContextResolverHelper.existingFields(objectApiName, candidateFields);
        readableFields.add('Id');
        String soql = 'SELECT ' + String.join(new List<String>(readableFields), ',') + ' FROM ' + objectApiName + ' WHERE Id IN :ids';
        for (SObject row : Database.query(soql)) {
            out.put((Id) row.get('Id'), row);
        }
        return out;
    }

    private static Map<Id, Contact> fetchContacts(Set<Id> contactIds) {
        Map<Id, Contact> out = new Map<Id, Contact>();
        if (contactIds == null || contactIds.isEmpty()) return out;
        for (Contact row : [
            SELECT Id, Name, AccountId, Idioma__c
            FROM Contact
            WHERE Id IN :contactIds
        ]) {
            out.put(row.Id, row);
        }
        return out;
    }

    private static Map<Id, Account> fetchAccounts(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact contactRow : contacts) {
            if (contactRow.AccountId != null) accountIds.add(contactRow.AccountId);
        }
        if (accountIds.isEmpty()) return new Map<Id, Account>();
        return new Map<Id, Account>([
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accountIds
        ]);
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

    @TestVisible
    private static String getStringSafe(SObject row, String fieldName) {
        if (row == null || String.isBlank(fieldName)) return null;
        try {
            Object raw = row.get(fieldName);
            return raw == null ? null : String.valueOf(raw);
        } catch (Exception ex) {
            return null;
        }
    }

    private static List<TCO_ChannelRouting__mdt> fetchActiveChannelRoutes() {
        if (!AtendimentoContextResolverHelper.canQueryObject('TCO_ChannelRouting__mdt')) return new List<TCO_ChannelRouting__mdt>();
        return [
            SELECT TCF_ChannelType__c, TCF_ChannelIdentifier__c, TCF_BusinessUnit__c, TCF_IsActive__c
            FROM TCO_ChannelRouting__mdt
            WHERE TCF_IsActive__c = true
        ];
    }

    private class BusinessUnitResolution {
        public String businessUnitName;
        public String source;
    }

    @TestVisible
    private static String resolveBusinessUnit(String normalizedChannelType, String channelIdentifier, Id conversationId, List<TCO_ChannelRouting__mdt> rows) {
        return resolveBusinessUnit(normalizedChannelType, channelIdentifier, conversationId, rows, null).businessUnitName;
    }

    private static BusinessUnitResolution resolveBusinessUnit(
        String normalizedChannelType,
        String channelIdentifier,
        Id conversationId,
        List<TCO_ChannelRouting__mdt> rows,
        List<AtendimentoConfigDTO> atendimentoParams
    ) {
        BusinessUnitResolution out = new BusinessUnitResolution();
        String resolved = resolveFromChannelRouting(normalizedChannelType, channelIdentifier, conversationId, rows);
        if (!String.isBlank(resolved)) {
            out.businessUnitName = resolved;
            out.source = 'CHANNEL_ROUTING_METADATA';
            return out;
        }

        resolved = resolveFromAtendimentoParams(normalizedChannelType, channelIdentifier, atendimentoParams);
        if (!String.isBlank(resolved)) {
            out.businessUnitName = resolved;
            out.source = 'PARAMETROS_ATENDIMENTO';
        }
        return out;
    }

    private static String resolveFromChannelRouting(String normalizedChannelType, String channelIdentifier, Id conversationId, List<TCO_ChannelRouting__mdt> rows) {
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

    private static String resolveFromAtendimentoParams(String normalizedChannelType, String channelIdentifier, List<AtendimentoConfigDTO> rows) {
        if (rows == null || rows.isEmpty()) return null;
        String normalizedType = AtendimentoContextResolverHelper.normalizeKey(normalizedChannelType);
        String normalizedIdentifier = AtendimentoContextResolverHelper.normalizeKey(channelIdentifier);

        AtendimentoConfigDTO fallbackConfig;
        for (AtendimentoConfigDTO row : rows) {
            if (row == null || row.isActive != true || String.isBlank(row.businessUnit)) continue;
            if (fallbackConfig == null) fallbackConfig = row;

            String rowDeveloperName = AtendimentoContextResolverHelper.normalizeKey(row.messagingChannelDeveloperName);
            String rowType = AtendimentoContextResolverHelper.normalizeKey(row.messagingChannelType);

            if (!String.isBlank(normalizedIdentifier) && (rowDeveloperName == normalizedIdentifier || AtendimentoContextResolverHelper.normalizeKey(row.developerName) == normalizedIdentifier)) {
                return row.businessUnit;
            }
            if (!String.isBlank(normalizedType) && !String.isBlank(rowType) && (rowType == normalizedType || rowType.contains(normalizedType) || normalizedType.contains(rowType))) {
                return row.businessUnit;
            }
        }

        return fallbackConfig == null ? null : fallbackConfig.businessUnit;
    }

    private static List<AtendimentoConfigDTO> fetchActiveAtendimentoParams() {
        return AtendimentoConfigService.getActiveConfigs();
    }
}