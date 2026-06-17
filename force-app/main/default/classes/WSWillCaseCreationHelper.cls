/**
 * @description       : Funções utilitárias e helpers para o módulo WSWillCaseCreation.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseCreationHelper {
    public static String normalizeLanguageForCase(String lang) {
        String normalized = WSWillContextResolverHelper.normalizePreferredLanguage(lang);
        if (normalized == 'en_US') return 'Inglês';
        return 'Português';
    }

    public static String normalizeOrigin(String origin, String channelName) {
        if (!String.isBlank(origin)) {
            String normalizedOrigin = origin.trim();
            if (normalizedOrigin.equalsIgnoreCase('bot')) return 'Bot';
            if (normalizedOrigin.equalsIgnoreCase('whatsapp')) return 'Whatsapp';
            if (normalizedOrigin.equalsIgnoreCase('chat')) return 'Chat';
            return normalizedOrigin;
        }
        if (String.isBlank(channelName)) return 'Chat';
        String n = channelName.trim().toLowerCase();
        if (n.contains('whatsapp')) return 'Whatsapp';
        if (n.contains('chat') || n.contains('messaging')) return 'Chat';
        return 'Chat';
    }

    public static String normalizeBusinessUnitForCase(String businessUnitName) {
        return CaseCreationHelper.normalizeBusinessUnitForCase(businessUnitName);
    }

    public static String normalizeDistributionOrigin() {
        return 'Bot';
    }

    public static String[] splitFullName(String fullName) {
        if (String.isBlank(fullName)) return new String[]{ null, 'Cliente' };
        List<String> parts = fullName.trim().split(' ');
        if (parts.isEmpty()) return new String[]{ null, 'Cliente' };

        String firstName = parts.size() > 1 ? parts[0] : null;
        String lastName;
        if (parts.size() > 1) {
            List<String> remainder = new List<String>();
            for (Integer i = 1; i < parts.size(); i++) {
                remainder.add(parts[i]);
            }
            lastName = String.join(remainder, ' ');
        } else {
            lastName = parts[0];
        }
        return new String[]{ firstName, lastName };
    }
}