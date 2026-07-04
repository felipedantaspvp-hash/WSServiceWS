public inherited sharing class AtendimentoContextResolverHelper {
    public static final String CHANNEL_WHATSAPP = 'WHATSAPP';
    public static final String CHANNEL_CHAT = 'CHAT';
    public static final String CHANNEL_MESSAGING = 'MESSAGING';
    public static final String CHANNEL_UNKNOWN = 'UNKNOWN';

    public static final Set<String> ROUTABLE_OBJECTS = new Set<String>{ 'MessagingSession', 'LiveChatTranscript' };
    @TestVisible private static Map<String, Schema.SObjectType> globalDescribeCache;
    @TestVisible private static Map<String, Map<String, Schema.SObjectField>> fieldMapCacheByObject = new Map<String, Map<String, Schema.SObjectField>>();

    public static String normalizeChannelType(String value) {
        String normalized = normalizeKey(value);
        if (normalized.contains('whatsapp')) return CHANNEL_WHATSAPP;
        if (normalized.contains('livechat') || normalized == 'chat') return CHANNEL_CHAT;
        if (normalized.contains('messaging') || normalized.contains('sms')) return CHANNEL_MESSAGING;
        return CHANNEL_UNKNOWN;
    }

    public static String channelDisplayName(String normalizedType) {
        if (normalizedType == CHANNEL_WHATSAPP) return 'WhatsApp';
        if (normalizedType == CHANNEL_CHAT) return 'Chat';
        if (normalizedType == CHANNEL_MESSAGING) return 'Messaging';
        return 'Unknown';
    }

    public static String normalizeKey(String value) {
        if (String.isBlank(value)) return '';
        return TextNormalizationUtil.stripAccents(value.trim().toLowerCase()).replaceAll('[^a-z0-9]', '');
    }

    public static String inferSObjectApiName(Id recordId) {
        if (recordId == null) return null;
        Schema.SObjectType t = recordId.getSObjectType();
        if (t == null) return null;
        return t.getDescribe().getName();
    }

    public static Boolean isIdOfType(Id recordId, String objectApiName) {
        if (recordId == null || String.isBlank(objectApiName)) return false;
        String actual = inferSObjectApiName(recordId);
        return normalizeKey(actual) == normalizeKey(objectApiName);
    }

    public static Set<String> existingFields(String objectApiName, Set<String> candidates) {
        Set<String> out = new Set<String>();
        if (String.isBlank(objectApiName) || candidates == null || candidates.isEmpty()) return out;
        Map<String, Schema.SObjectType> globalDescribe = getGlobalDescribe();
        if (!globalDescribe.containsKey(objectApiName)) return out;

        Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
        for (String candidate : candidates) {
            if (fieldMap.containsKey(candidate)) out.add(candidate);
        }
        return out;
    }

    public static String firstExistingField(String objectApiName, List<String> orderedCandidates) {
        if (String.isBlank(objectApiName) || orderedCandidates == null) return null;
        Map<String, Schema.SObjectType> globalDescribe = getGlobalDescribe();
        if (!globalDescribe.containsKey(objectApiName)) return null;

        Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
        for (String candidate : orderedCandidates) {
            if (fieldMap.containsKey(candidate)) return candidate;
        }
        return null;
    }

    public static Boolean canQueryObject(String objectApiName) {
        if (String.isBlank(objectApiName)) return false;
        Map<String, Schema.SObjectType> globalDescribe = getGlobalDescribe();
        if (!globalDescribe.containsKey(objectApiName)) return false;
        return globalDescribe.get(objectApiName).getDescribe().isQueryable();
    }

    private static Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribeCache == null) {
            globalDescribeCache = Schema.getGlobalDescribe();
        }
        return globalDescribeCache;
    }

    private static Map<String, Schema.SObjectField> getFieldMap(String objectApiName) {
        if (String.isBlank(objectApiName)) return new Map<String, Schema.SObjectField>();
        if (!fieldMapCacheByObject.containsKey(objectApiName)) {
            Map<String, Schema.SObjectType> globalDescribe = getGlobalDescribe();
            if (!globalDescribe.containsKey(objectApiName)) return new Map<String, Schema.SObjectField>();
            fieldMapCacheByObject.put(objectApiName, globalDescribe.get(objectApiName).getDescribe().fields.getMap());
        }
        return fieldMapCacheByObject.get(objectApiName);
    }

    /**
     * @description Resolve a Unidade de Negócio a partir das configurações ativas de `AtendimentoConfigService`,
     * casando pelo canal/identificador informado. Fonte única usada por `WSWillContextResolverService` e
     * `AtendimentoContextResolverService` (ver CR-023 do CodeReview.md — antes cada classe tinha sua própria
     * cópia, e `AtendimentoContextResolverService` dependia só de `TCO_ChannelRouting__mdt`, que nunca teve
     * registros cadastrados, então sempre retornava null).
     * @param normalizedChannelType Tipo de canal já normalizado (ex.: CHANNEL_WHATSAPP).
     * @param channelIdentifier Identificador do canal (ex.: nome do canal de Messaging).
     * @param rows Configurações ativas de Atendimento.
     * @return Unidade de Negócio resolvida, ou null se nenhuma config casar.
     */
    public static String resolveBusinessUnitFromConfigs(String normalizedChannelType, String channelIdentifier, List<AtendimentoConfigDTO> rows) {
        if (rows == null || rows.isEmpty()) return null;
        String normalizedType = normalizeKey(normalizedChannelType);
        String normalizedIdentifier = normalizeKey(channelIdentifier);

        AtendimentoConfigDTO fallbackConfig;
        for (AtendimentoConfigDTO row : rows) {
            if (row == null || row.isActive != true || String.isBlank(row.businessUnit)) continue;
            if (fallbackConfig == null) fallbackConfig = row;

            String rowDeveloperName = normalizeKey(primaryChannelDeveloperName(normalizedType, row));
            String rowConfigName = normalizeKey(row.developerName);
            String rowBusinessUnit = normalizeKey(row.businessUnit);
            String rowMasterLabel = normalizeKey(row.masterLabel);

            if (matchesChannelIdentifier(normalizedIdentifier, rowDeveloperName)
                || matchesChannelIdentifier(normalizedIdentifier, rowConfigName)
                || matchesChannelIdentifier(normalizedIdentifier, rowBusinessUnit)
                || matchesChannelIdentifier(normalizedIdentifier, rowMasterLabel)) {
                return row.businessUnit;
            }
        }

        for (AtendimentoConfigDTO row : rows) {
            if (row == null || row.isActive != true || String.isBlank(row.businessUnit)) continue;

            String rowType = normalizeKey(row.messagingChannelType);
            if (!String.isBlank(normalizedType) && !String.isBlank(rowType) && (rowType == normalizedType || rowType.contains(normalizedType) || normalizedType.contains(rowType))) {
                return row.businessUnit;
            }
        }

        if (normalizedType == normalizeKey(CHANNEL_WHATSAPP)) {
            return null;
        }
        return fallbackConfig == null ? null : fallbackConfig.businessUnit;
    }

    private static String primaryChannelDeveloperName(String normalizedType, AtendimentoConfigDTO row) {
        if (row == null) return null;
        String normalizedWhatsAppType = normalizeKey(CHANNEL_WHATSAPP);
        return normalizedType == normalizedWhatsAppType ? row.whatsAppChannelDeveloperName : row.messagingChannelDeveloperName;
    }

    private static Boolean matchesChannelIdentifier(String normalizedIdentifier, String normalizedCandidate) {
        if (String.isBlank(normalizedIdentifier) || String.isBlank(normalizedCandidate)) return false;
        return normalizedIdentifier == normalizedCandidate
            || normalizedIdentifier.contains(normalizedCandidate)
            || normalizedCandidate.contains(normalizedIdentifier);
    }
}