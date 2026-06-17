/**
 * @description       : Funções utilitárias e helpers para o módulo WSWillContextResolver.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillContextResolverHelper {
    public static String normalizePreferredLanguage(String rawValue) {
        if (String.isBlank(rawValue)) return null;
        String norm = rawValue.trim().toLowerCase();
        if (norm == 'pt_br' || norm == 'pt-br' || norm == 'pt' || norm == 'portugues' || norm == 'português') {
            return 'pt_BR';
        }
        if (norm == 'en_us' || norm == 'en-us' || norm == 'en' || norm == 'ingles' || norm == 'inglês' || norm == 'english') {
            return 'en_US';
        }
        return null;
    }

    public static String inferBusinessUnitSource(Boolean hasBusinessUnit, Id conversationId) {
        return inferBusinessUnitSource(hasBusinessUnit, conversationId, null);
    }

    public static String inferBusinessUnitSource(Boolean hasBusinessUnit, Id conversationId, String explicitSource) {
        if (!hasBusinessUnit) return 'UNRESOLVED';
        if (!String.isBlank(explicitSource)) return explicitSource;
        if (conversationId != null) return 'CHANNEL_ROUTING_METADATA';
        return 'CONTACT_OR_CHANNEL';
    }

    public static String computeSuccessStatus(String baseStatusCode, Id contactId, String businessUnitName) {
        if (String.isBlank(baseStatusCode)) {
            if (contactId == null && String.isBlank(businessUnitName)) return 'SUCCESS_WITH_LIMITED_CONTEXT';
            if (contactId == null) return 'SUCCESS_WITHOUT_CONTACT';
            if (String.isBlank(businessUnitName)) return 'SUCCESS_WITHOUT_BUSINESS_UNIT';
            return 'SUCCESS';
        }
        return baseStatusCode;
    }
}