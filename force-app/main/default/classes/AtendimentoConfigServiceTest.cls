/**
 * @description       : Testes unitários de AtendimentoConfigService.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-12-2026
 * @last modified by  : Marllon Nascimento
 **/
@IsTest
private class AtendimentoConfigServiceTest {
    @IsTest
    static void returnsInjectedSurveyConfigByBusinessUnit() {
        AtendimentoConfigDTO config = buildConfig('Tecon Rio Grande', 'OPTIONAL');
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ config });

        AtendimentoConfigDTO result = AtendimentoConfigService.getSurveyConfigByBusinessUnit('tecon rio grande');

        Assert.areEqual('Tecon Rio Grande', result.businessUnit);
        Assert.areEqual(true, result.isActive);
        Assert.areEqual('OPTIONAL', result.surveyMode);
        Assert.areEqual(true, result.verifyDailySurvey);
        Assert.areEqual('Atend_Close_Test', result.caseClosureTemplateDeveloperName);
        Assert.areEqual('Atend_Close_Test_EN', result.caseClosureTemplateDeveloperNameEN);

        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void matchesOperationalAtendimentoPrefixInBusinessUnit() {
        AtendimentoConfigDTO config = buildConfig('Atendimento Tecon Rio Grande', 'ALWAYS');
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ config });

        AtendimentoConfigDTO result = AtendimentoConfigService.getSurveyConfigByBusinessUnit('Tecon Rio Grande');

        Assert.areEqual(true, result.isActive);
        Assert.areEqual('ALWAYS', result.surveyMode);

        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void returnsNeverWhenBusinessUnitHasNoActiveConfig() {
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>());

        AtendimentoConfigDTO result = AtendimentoConfigService.getSurveyConfigByBusinessUnit('Sem Configuração');

        Assert.areEqual(false, result.isActive);
        Assert.areEqual('NEVER', result.surveyMode);

        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void readsSurveyConfigFromCustomMetadataWhenNoInjectionExists() {
        AtendimentoConfigService.clearTestSurveyConfigs();

        AtendimentoConfigDTO result = AtendimentoConfigService.getSurveyConfigByBusinessUnit('Centro Logístico');

        Assert.areEqual('Centro Logístico', result.businessUnit);
        Assert.areEqual(true, result.isActive);
        Assert.areEqual('OPTIONAL', result.surveyMode);
        Assert.areEqual('Atendimento_Survey_CentroLogistico', result.surveyDeveloperName);
        Assert.areEqual('Atendimento_Survey_CentroLogistico_v1', result.surveyVersionName);
        Assert.areEqual('Atend_Survey_Email_CentroLogistico', result.emailTemplateDeveloperName);
        Assert.areEqual('Atend_Close_CL_PT', result.caseClosureTemplateDeveloperName);
        Assert.areEqual('Atend_Close_CL_EN', result.caseClosureTemplateDeveloperNameEN);
        Assert.areEqual('logoWSemail', result.brandLogoResourceName);
    }

    private static AtendimentoConfigDTO buildConfig(String businessUnit, String mode) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = businessUnit;
        config.isActive = true;
        config.surveyMode = mode;
        config.surveyDeveloperName = 'Atendimento_Survey_Teste';
        config.surveyVersionName = 'Atendimento_Survey_Teste_v1';
        config.surveyDeveloperNameEN = 'Atendimento_Survey_Teste_EN';
        config.verifyDailySurvey = true;
        config.showDailySurveyIndicator = true;
        config.allowSameDaySurvey = false;
        config.blockedInternalDomain = 'wilsonsons.com.br';
        config.defaultLanguage = 'pt_BR';
        config.emailTemplateDeveloperName = 'Atend_Survey_Email_Teste';
        config.emailTemplateDeveloperNameEN = 'Atend_Survey_Email_Teste_EN';
        config.caseClosureTemplateDeveloperName = 'Atend_Close_Test';
        config.caseClosureTemplateDeveloperNameEN = 'Atend_Close_Test_EN';
        config.brandLogoResourceName = 'WILSON_SONS_LOGO_RESOURCE_NAME';
        config.brandPrimaryColor = 'WILSON_SONS_PRIMARY_COLOR';
        config.brandSecondaryColor = 'WILSON_SONS_SECONDARY_COLOR';
        config.brandAccentColor = 'WILSON_SONS_ACCENT_COLOR';
        config.emailFooterText = 'Wilson Sons | Atendimento ao Cliente';
        config.emailLanguage = 'pt_BR';
        config.description = 'Teste';
        return config;
    }
}