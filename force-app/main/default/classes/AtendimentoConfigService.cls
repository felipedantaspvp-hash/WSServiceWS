/**
 * @description       : Centraliza leitura de Custom Metadata do domínio de Atendimento.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-12-2026
 * @last modified by  : Marllon Nascimento
 **/
public inherited sharing class AtendimentoConfigService {
    @TestVisible private static Map<String, AtendimentoConfigDTO> testSurveyConfigsByKey;
    private static Map<String, AtendimentoConfigDTO> surveyConfigsByKey;

    /**
     * @description Injeta configurações em testes sem depender de registros reais de Custom Metadata.
     * @param configs Configurações tratadas.
     */
    @TestVisible
    static void setTestSurveyConfigs(List<AtendimentoConfigDTO> configs) {
        testSurveyConfigsByKey = new Map<String, AtendimentoConfigDTO>();
        for (AtendimentoConfigDTO config : configs) {
            if (config == null) continue;
            testSurveyConfigsByKey.put(AtendimentoConfigHelper.normalizeBusinessUnitKey(config.businessUnit), cloneConfig(config));
        }
    }

    @TestVisible
    static void clearTestSurveyConfigs() {
        testSurveyConfigsByKey = null;
        surveyConfigsByKey = null;
    }

    /**
     * @description Busca configuração tratada de Survey por unidade de negócio.
     * @param businessUnit Unidade funcional do Case.
     * @return Configuração tratada, ou configuração segura NEVER quando não encontrada.
     */
    public static AtendimentoConfigDTO getSurveyConfigByBusinessUnit(String businessUnit) {
        String key = AtendimentoConfigHelper.normalizeBusinessUnitKey(businessUnit);
        Map<String, AtendimentoConfigDTO> source = getSurveyConfigsByKey();
        if (source.containsKey(key)) {
            return cloneConfig(source.get(key));
        }
        AtendimentoConfigDTO fallback = new AtendimentoConfigDTO();
        fallback.businessUnit = businessUnit;
        fallback.isActive = false;
        fallback.surveyMode = AtendimentoConfigHelper.SURVEY_MODE_NEVER;
        fallback.verifyDailySurvey = false;
        fallback.showDailySurveyIndicator = false;
        fallback.allowSameDaySurvey = false;
        return fallback;
    }

    /**
     * @description Lista parâmetros ativos de Atendimento para regras de roteamento e categorização.
     * @return Configurações ativas clonadas.
     */
    public static List<AtendimentoConfigDTO> getActiveConfigs() {
        List<AtendimentoConfigDTO> out = new List<AtendimentoConfigDTO>();
        for (AtendimentoConfigDTO config : getSurveyConfigsByKey().values()) {
            if (config != null && config.isActive == true) {
                out.add(cloneConfig(config));
            }
        }
        return out;
    }

    private static Map<String, AtendimentoConfigDTO> getSurveyConfigsByKey() {
        if (Test.isRunningTest() && testSurveyConfigsByKey != null) {
            return testSurveyConfigsByKey;
        }
        if (surveyConfigsByKey != null) {
            return surveyConfigsByKey;
        }

        surveyConfigsByKey = new Map<String, AtendimentoConfigDTO>();
        for (ParametrosAtendimento__mdt row : ParametrosAtendimento__mdt.getAll().values()) {
            AtendimentoConfigDTO config = toDTO(row);
            surveyConfigsByKey.put(AtendimentoConfigHelper.normalizeBusinessUnitKey(config.businessUnit), config);
        }
        return surveyConfigsByKey;
    }

    private static AtendimentoConfigDTO toDTO(ParametrosAtendimento__mdt row) {
        AtendimentoConfigDTO dto = new AtendimentoConfigDTO();
        dto.developerName = row.DeveloperName;
        dto.masterLabel = row.MasterLabel;
        dto.businessUnit = row.UnidadeNegocio__c;
        dto.isActive = row.Ativo__c;
        dto.surveyMode = AtendimentoConfigHelper.normalizeSurveyMode(row.SurveyMode__c);
        dto.surveyDeveloperName = row.SurveyDeveloperName__c;
        dto.surveyVersionName = row.SurveyVersionName__c;
        dto.surveyDeveloperNameEN = row.SurveyDeveloperNameEN__c;
        dto.verifyDailySurvey = row.VerifyDailySurvey__c;
        dto.showDailySurveyIndicator = row.ShowDailySurveyIndicator__c;
        dto.allowSameDaySurvey = row.AllowSameDaySurvey__c;
        dto.blockedInternalDomain = row.BlockedInternalDomain__c;
        dto.defaultLanguage = row.DefaultLanguage__c;
        dto.emailTemplateDeveloperName = row.EmailTemplateDeveloperName__c;
        dto.emailTemplateDeveloperNameEN = row.EmailTemplateDeveloperNameEN__c;
        dto.caseClosureTemplateDeveloperName = row.CaseClosureTemplateDeveloperName__c;
        dto.caseClosureTemplateDeveloperNameEN = row.CaseClosureTemplateDeveloperNameEN__c;
        dto.sendCaseOpeningEmail = row.SendCaseOpeningEmail__c;
        dto.caseOpeningTemplateDeveloperName = row.CaseOpeningTemplateDeveloperName__c;
        dto.caseOpeningTemplateDeveloperNameEN = row.CaseOpeningTemplateDeveloperNameEN__c;
        dto.orgWideEmailAddress = row.OrgWideEmailAddress__c;
        dto.surveyCommunityUrlPathPrefix = row.SurveyCommunityUrlPathPrefix__c;
        dto.brandLogoResourceName = row.BrandLogoResourceName__c;
        dto.brandPrimaryColor = row.BrandPrimaryColor__c;
        dto.brandSecondaryColor = row.BrandSecondaryColor__c;
        dto.brandAccentColor = row.BrandAccentColor__c;
        dto.emailFooterText = row.EmailFooterText__c;
        dto.emailLanguage = row.EmailLanguage__c;
        dto.description = row.Descricao__c;
        dto.caseRecordTypeDeveloperName = row.CaseRecordTypeDeveloperName__c;
        dto.defaultQueueDeveloperName = row.DefaultQueueDeveloperName__c;
        dto.queueDeveloperNamePrefix = row.QueueDeveloperNamePrefix__c;
        dto.messagingChannelDeveloperName = row.MessagingChannelDeveloperName__c;
        dto.whatsAppChannelDeveloperName = row.WhatsAppChannelDeveloperName__c;
        dto.messagingChannelType = row.MessagingChannelType__c;
        dto.messagingTargetQueueDeveloperName = row.MessagingTargetQueueDeveloperName__c;
        dto.messagingFallbackQueueDeveloperName = row.MessagingFallbackQueueDeveloperName__c;
        return dto;
    }

    private static AtendimentoConfigDTO cloneConfig(AtendimentoConfigDTO source) {
        AtendimentoConfigDTO dto = new AtendimentoConfigDTO();
        dto.developerName = source.developerName;
        dto.masterLabel = source.masterLabel;
        dto.businessUnit = source.businessUnit;
        dto.isActive = source.isActive;
        dto.surveyMode = AtendimentoConfigHelper.normalizeSurveyMode(source.surveyMode);
        dto.surveyDeveloperName = source.surveyDeveloperName;
        dto.surveyVersionName = source.surveyVersionName;
        dto.surveyDeveloperNameEN = source.surveyDeveloperNameEN;
        dto.verifyDailySurvey = source.verifyDailySurvey == true;
        dto.showDailySurveyIndicator = source.showDailySurveyIndicator == true;
        dto.allowSameDaySurvey = source.allowSameDaySurvey == true;
        dto.blockedInternalDomain = source.blockedInternalDomain;
        dto.defaultLanguage = source.defaultLanguage;
        dto.emailTemplateDeveloperName = source.emailTemplateDeveloperName;
        dto.emailTemplateDeveloperNameEN = source.emailTemplateDeveloperNameEN;
        dto.caseClosureTemplateDeveloperName = source.caseClosureTemplateDeveloperName;
        dto.caseClosureTemplateDeveloperNameEN = source.caseClosureTemplateDeveloperNameEN;
        dto.sendCaseOpeningEmail = source.sendCaseOpeningEmail == true;
        dto.caseOpeningTemplateDeveloperName = source.caseOpeningTemplateDeveloperName;
        dto.caseOpeningTemplateDeveloperNameEN = source.caseOpeningTemplateDeveloperNameEN;
        dto.orgWideEmailAddress = source.orgWideEmailAddress;
        dto.surveyCommunityUrlPathPrefix = source.surveyCommunityUrlPathPrefix;
        dto.brandLogoResourceName = source.brandLogoResourceName;
        dto.brandPrimaryColor = source.brandPrimaryColor;
        dto.brandSecondaryColor = source.brandSecondaryColor;
        dto.brandAccentColor = source.brandAccentColor;
        dto.emailFooterText = source.emailFooterText;
        dto.emailLanguage = source.emailLanguage;
        dto.description = source.description;
        dto.caseRecordTypeDeveloperName = source.caseRecordTypeDeveloperName;
        dto.defaultQueueDeveloperName = source.defaultQueueDeveloperName;
        dto.queueDeveloperNamePrefix = source.queueDeveloperNamePrefix;
        dto.messagingChannelDeveloperName = source.messagingChannelDeveloperName;
        dto.whatsAppChannelDeveloperName = source.whatsAppChannelDeveloperName;
        dto.messagingChannelType = source.messagingChannelType;
        dto.messagingTargetQueueDeveloperName = source.messagingTargetQueueDeveloperName;
        dto.messagingFallbackQueueDeveloperName = source.messagingFallbackQueueDeveloperName;
        return dto;
    }
}