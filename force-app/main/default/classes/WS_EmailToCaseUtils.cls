/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseUtils {
    public static String normalize(String input) {
        return String.isBlank(input) ? null : input.trim().toLowerCase();
    }

    public static String normalizeMessageId(String rawMessageId) {
        String normalized = normalize(rawMessageId);
        if (String.isBlank(normalized)) {
            return null;
        }
        normalized = normalized.replace('<', '').replace('>', '');
        return normalized;
    }

    public static String joinAddresses(String[] addresses) {
        if (addresses == null || addresses.isEmpty()) {
            return null;
        }
        return String.join(addresses, ';');
    }

    public static Set<String> normalizeAddressSet(String[] addresses) {
        Set<String> normalized = new Set<String>();
        if (addresses == null) {
            return normalized;
        }
        for (String addr : addresses) {
            String value = normalize(addr);
            if (!String.isBlank(value)) {
                normalized.add(value);
            }
        }
        return normalized;
    }

    public static String computeSha256(String input) {
        Blob payload = Blob.valueOf(input == null ? '' : input);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', payload));
    }

    public static String safeLeft(String value, Integer maxLen) {
        if (value == null) {
            return null;
        }
        if (value.length() <= maxLen) {
            return value;
        }
        return value.substring(0, maxLen);
    }

    public static String htmlToText(String html) {
        if (String.isBlank(html)) {
            return null;
        }
        String noTags = html.replaceAll('<[^>]+>', ' ');
        return noTags.replaceAll('\\s+', ' ').trim();
    }

    public static String getHeaderValue(Messaging.InboundEmail email, String headerName) {
        if (email == null || email.headers == null || String.isBlank(headerName)) {
            return null;
        }
        for (Messaging.InboundEmail.Header header : email.headers) {
            if (header != null && header.name != null && header.name.equalsIgnoreCase(headerName)) {
                return header.value;
            }
        }
        return null;
    }

    public static void ensureCaseCreateAccess() {
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new WS_EmailToCaseConfigException('Sem permissÃ£o para criar Case.');
        }
    }

    public static void ensureCaseUpdateAccess() {
        if (!Schema.sObjectType.Case.isUpdateable()) {
            throw new WS_EmailToCaseConfigException('Sem permissÃ£o para atualizar Case.');
        }
    }

    public static Boolean canWriteCaseField(String fieldApiName) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Case.fields.getMap();
        if (!fields.containsKey(fieldApiName)) {
            return false;
        }
        return fields.get(fieldApiName).getDescribe().isUpdateable();
    }
}