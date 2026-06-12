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
        return value.trim().toLowerCase().replaceAll('[^a-z0-9]', '');
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
}