/**
 * @description       : Helper de apoio ao disparo de Survey de Atendimento.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Marllon Nascimento
 **/
public inherited sharing class CaseSurveyDispatchHelper {
    public static final String STATUS_SKIPPED = 'SKIPPED';
    public static final String STATUS_SENT = 'SENT';
    public static final String STATUS_CASE_CLOSURE_SENT = 'CASE_CLOSURE_SENT';
    public static final String STATUS_ERROR = 'ERROR';

    public static Set<Id> extractCaseIds(List<CaseSurveyDispatchDTO.Request> requests) {
        Set<Id> caseIds = new Set<Id>();
        if (requests == null) return caseIds;
        for (CaseSurveyDispatchDTO.Request request : requests) {
            if (request != null && request.caseId != null) caseIds.add(request.caseId);
        }
        return caseIds;
    }

    public static CaseSurveyDispatchDTO.Response response(Id caseId, Boolean success, String message, Id invitationId) {
        CaseSurveyDispatchDTO.Response out = new CaseSurveyDispatchDTO.Response();
        out.caseId = caseId;
        out.success = success;
        out.message = message;
        out.surveyInvitationId = invitationId;
        return out;
    }

    public static String chooseSurveyDeveloperName(AtendimentoConfigDTO config, String language) {
        if (config == null) return null;
        if (isEnglish(language) && !String.isBlank(config.surveyDeveloperNameEN)) {
            return config.surveyDeveloperNameEN;
        }
        return config.surveyDeveloperName;
    }

    public static String chooseTemplateDeveloperName(AtendimentoConfigDTO config, String language) {
        if (config == null) return null;
        if (isEnglish(language) && !String.isBlank(config.emailTemplateDeveloperNameEN)) {
            return config.emailTemplateDeveloperNameEN;
        }
        return config.emailTemplateDeveloperName;
    }

    public static String chooseCaseClosureTemplateDeveloperName(AtendimentoConfigDTO config, String language) {
        if (config == null) return null;
        if (isEnglish(language) && !String.isBlank(config.caseClosureTemplateDeveloperNameEN)) {
            return config.caseClosureTemplateDeveloperNameEN;
        }
        return config.caseClosureTemplateDeveloperName;
    }

    public static String resolveLanguage(Case c, AtendimentoConfigDTO config) {
        Object rawContactLanguage = c == null || c.Contact == null ? null : c.Contact.get('Idioma__c');
        String contactLanguage = rawContactLanguage == null ? null : String.valueOf(rawContactLanguage);
        String normalizedContactLanguage = normalizeLanguage(contactLanguage);
        if (!String.isBlank(normalizedContactLanguage)) {
            return normalizedContactLanguage;
        }
        String normalizedDefaultLanguage = normalizeLanguage(config == null ? null : config.defaultLanguage);
        return normalizedDefaultLanguage == null ? 'pt_BR' : normalizedDefaultLanguage;
    }

    public static Boolean isEnglish(String language) {
        return normalizeLanguage(language) == 'en_US';
    }

    public static String normalizeLanguage(String language) {
        if (String.isBlank(language)) return null;
        String value = language.trim().toLowerCase();
        if (value == 'en' || value == 'en_us' || value == 'en-us' || value == 'english' || value == 'inglês' || value == 'ingles') {
            return 'en_US';
        }
        if (value == 'pt' || value == 'pt_br' || value == 'pt-br' || value == 'português' || value == 'portugues') {
            return 'pt_BR';
        }
        return null;
    }
}