/**
 * @description       : DTO tratado para configurações do domínio de Atendimento.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Marllon Nascimento
 **/
public inherited sharing class AtendimentoConfigDTO {
    @AuraEnabled public String businessUnit { get; set; }
    @AuraEnabled public Boolean isActive { get; set; }
    @AuraEnabled public String surveyMode { get; set; }
    @AuraEnabled public String surveyDeveloperName { get; set; }
    @AuraEnabled public String surveyVersionName { get; set; }
    @AuraEnabled public String surveyDeveloperNameEN { get; set; }
    @AuraEnabled public Boolean verifyDailySurvey { get; set; }
    @AuraEnabled public Boolean showDailySurveyIndicator { get; set; }
    @AuraEnabled public Boolean allowSameDaySurvey { get; set; }
    @AuraEnabled public String blockedInternalDomain { get; set; }
    @AuraEnabled public String defaultLanguage { get; set; }
    @AuraEnabled public String emailTemplateDeveloperName { get; set; }
    @AuraEnabled public String emailTemplateDeveloperNameEN { get; set; }
    @AuraEnabled public String caseClosureTemplateDeveloperName { get; set; }
    @AuraEnabled public String caseClosureTemplateDeveloperNameEN { get; set; }
    @AuraEnabled public Boolean sendCaseOpeningEmail { get; set; }
    @AuraEnabled public String caseOpeningTemplateDeveloperName { get; set; }
    @AuraEnabled public String caseOpeningTemplateDeveloperNameEN { get; set; }
    @AuraEnabled public String orgWideEmailAddress { get; set; }
    @AuraEnabled public String surveyCommunityUrlPathPrefix { get; set; }
    @AuraEnabled public String brandLogoResourceName { get; set; }
    @AuraEnabled public String brandPrimaryColor { get; set; }
    @AuraEnabled public String brandSecondaryColor { get; set; }
    @AuraEnabled public String brandAccentColor { get; set; }
    @AuraEnabled public String emailFooterText { get; set; }
    @AuraEnabled public String emailLanguage { get; set; }
    @AuraEnabled public String description { get; set; }
    @AuraEnabled public String developerName { get; set; }
    @AuraEnabled public String masterLabel { get; set; }
    @AuraEnabled public String caseRecordTypeDeveloperName { get; set; }
    @AuraEnabled public String defaultQueueDeveloperName { get; set; }
    @AuraEnabled public String queueDeveloperNamePrefix { get; set; }
    @AuraEnabled public String messagingChannelDeveloperName { get; set; }
    @AuraEnabled public String whatsAppChannelDeveloperName { get; set; }
    @AuraEnabled public String messagingChannelType { get; set; }
    @AuraEnabled public String messagingTargetQueueDeveloperName { get; set; }
    @AuraEnabled public String messagingFallbackQueueDeveloperName { get; set; }
}