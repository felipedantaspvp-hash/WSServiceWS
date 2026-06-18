/**
 * @description       : Service de envio de e-mail transacional na abertura do Case.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-17-2026
 * @last modified by  : Marllon Nascimento
 **/
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class CaseOpeningNotificationService {
    @TestVisible private static Map<String, Id> testTemplateIdsByDeveloperName;
    @TestVisible private static Map<String, Id> testOrgWideEmailIdsByAddress;

    private class OpeningPlan {
        Case caseRecord;
        AtendimentoConfigDTO config;
        String templateName;
    }

    /**
     * @description Envia e-mail de abertura para Cases recém-criados com contato preenchido.
     * @param caseIds Identificadores dos Cases criados.
     */
    public static void notifyOpenedCases(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        if (Test.isRunningTest() && testTemplateIdsByDeveloperName == null) {
            return;
        }

        // Trigger-owned system notification: read-only lookups are intentionally system-mode.
        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT Id, CaseNumber, UnidadeNegocio__c, ContactId, Contact.Email, Contact.Idioma__c
            FROM Case
            WHERE Id IN :caseIds
            AND ContactId != null
        ]);
        if (casesById.isEmpty()) {
            return;
        }

        Set<String> templateNames = new Set<String>();
        Set<String> orgWideEmailAddresses = new Set<String>();
        List<OpeningPlan> plans = new List<OpeningPlan>();
        for (Case c : casesById.values()) {
            AtendimentoConfigDTO config = AtendimentoConfigService.getSurveyConfigByBusinessUnit(c.UnidadeNegocio__c);
            if (!isEligible(c, config)) {
                continue;
            }

            String language = CaseSurveyDispatchHelper.resolveLanguage(c, config);
            String templateName = CaseSurveyDispatchHelper.chooseCaseOpeningTemplateDeveloperName(config, language);
            if (String.isBlank(templateName)) {
                continue;
            }

            OpeningPlan plan = new OpeningPlan();
            plan.caseRecord = c;
            plan.config = config;
            plan.templateName = templateName;
            plans.add(plan);
            templateNames.add(templateName);
            if (!String.isBlank(config.orgWideEmailAddress)) {
                orgWideEmailAddresses.add(config.orgWideEmailAddress.trim().toLowerCase());
            }
        }
        if (plans.isEmpty()) {
            return;
        }

        Map<String, Id> templateIdsByName = getTemplateIdsByDeveloperName(templateNames);
        Map<String, Id> orgWideEmailIdsByAddress = getOrgWideEmailIdsByAddress(orgWideEmailAddresses);
        List<CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope> envelopes =
            new List<CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope>();

        for (OpeningPlan plan : plans) {
            Id templateId = templateIdsByName.get(plan.templateName);
            if (templateId == null) {
                continue;
            }

            CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope envelope =
                new CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope();
            envelope.caseRecord = plan.caseRecord;
            envelope.emailTemplateId = templateId;
            envelope.orgWideEmailAddressId = String.isBlank(plan.config.orgWideEmailAddress)
                ? null
                : orgWideEmailIdsByAddress.get(plan.config.orgWideEmailAddress.trim().toLowerCase());
            envelopes.add(envelope);
        }

        CaseOpeningNotificationServiceAgent.sendCaseOpeningEmails(envelopes);
    }

    private static Boolean isEligible(Case c, AtendimentoConfigDTO config) {
        if (c == null || c.ContactId == null || c.Contact == null || String.isBlank(c.Contact.Email)) {
            return false;
        }
        if (config == null || config.isActive != true) {
            return false;
        }
        return config.sendCaseOpeningEmail == true;
    }

    private static Map<String, Id> getTemplateIdsByDeveloperName(Set<String> developerNames) {
        if (Test.isRunningTest() && testTemplateIdsByDeveloperName != null) {
            return new Map<String, Id>(testTemplateIdsByDeveloperName);
        }
        Map<String, Id> result = new Map<String, Id>();
        if (developerNames.isEmpty()) {
            return result;
        }
        for (EmailTemplate template : [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName IN :developerNames
        ]) {
            result.put(template.DeveloperName, template.Id);
        }
        return result;
    }

    private static Map<String, Id> getOrgWideEmailIdsByAddress(Set<String> addresses) {
        if (Test.isRunningTest() && testOrgWideEmailIdsByAddress != null) {
            return new Map<String, Id>(testOrgWideEmailIdsByAddress);
        }
        Map<String, Id> result = new Map<String, Id>();
        if (addresses.isEmpty()) {
            return result;
        }
        for (OrgWideEmailAddress sender : [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address IN :addresses
        ]) {
            result.put(sender.Address.toLowerCase(), sender.Id);
        }
        return result;
    }
}