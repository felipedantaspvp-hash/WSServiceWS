/**
 * @description       : Funções utilitárias e helpers para o módulo MessagingContext.
 * @author            : Triscal
 * @group             : Mensageria
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class MessagingContextHelper {
    public static String normalizeKey(String value) {
        if (String.isBlank(value)) return '';
        return value.trim().toLowerCase().replaceAll('[^a-z0-9]', '');
    }

    public static String inferSObjectApiName(Id recordId) {
        if (recordId == null) return null;
        String idStr = String.valueOf(recordId);
        if (idStr.length() < 3) return null;
        String prefix = idStr.substring(0, 3);

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String apiName : globalDescribe.keySet()) {
            String keyPrefix = globalDescribe.get(apiName).getDescribe().getKeyPrefix();
            if (keyPrefix == prefix) return apiName;
        }
        return null;
    }

    public static Boolean canQueryObject(String objectApiName) {
        if (String.isBlank(objectApiName)) return false;
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (!globalDescribe.containsKey(objectApiName)) return false;
        return globalDescribe.get(objectApiName).getDescribe().isQueryable();
    }

    public static String normalizeChannelType(String value) {
        String normalized = normalizeKey(value);
        if (normalized.contains('webchat') || normalized == 'chat' || normalized.contains('livechat')) return 'WebChat';
        if (normalized.contains('whatsapp')) return 'WhatsApp';
        if (normalized.contains('messaging')) return 'Messaging';
        return String.isBlank(value) ? 'Unknown' : value;
    }
}