@IsTest
private class CaseOpeningNotificationServiceTest {
    @IsTest
    static void sendsOpeningEmailWhenCaseHasContactAndConfigEnabled() {
        Case c = createOpenCase('Centro Logístico', 'cliente.open@example.com', 'pt_BR');
        setupConfig(true);
        CaseOpeningNotificationService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Open_Test_PT' => '00X000000000101AAA' };
        CaseOpeningNotificationService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseOpeningNotificationServiceAgent.skipEmailForTest = true;

        Test.startTest();
        CaseOpeningNotificationService.notifyOpenedCases(new Set<Id>{ c.Id });
        Test.stopTest();

        Assert.areEqual(1, CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest.size(), 'Deve preparar um e-mail de abertura.');
        Assert.areEqual(c.Id, CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest[0].caseRecord.Id, 'O Case deve ser usado como relatedTo.');
        clearInjections();
    }

    @IsTest
    static void skipsOpeningEmailWhenConfigDisabled() {
        Case c = createOpenCase('Centro Logístico', 'cliente.disabled@example.com', 'pt_BR');
        setupConfig(false);
        CaseOpeningNotificationService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Open_Test_PT' => '00X000000000101AAA' };
        CaseOpeningNotificationServiceAgent.skipEmailForTest = true;

        Test.startTest();
        CaseOpeningNotificationService.notifyOpenedCases(new Set<Id>{ c.Id });
        Test.stopTest();

        Assert.areEqual(null, CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest, 'Não deve preparar e-mail quando a configuração estiver desligada.');
        clearInjections();
    }

    @IsTest
    static void usesEnglishOpeningTemplateWhenContactLanguageIsEnglish() {
        Case c = createOpenCase('Rebocadores', 'cliente.open.en@example.com', 'en_US');
        setupConfig(true);
        CaseOpeningNotificationService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Open_Test_EN' => '00X000000000102AAA' };
        CaseOpeningNotificationServiceAgent.skipEmailForTest = true;

        Test.startTest();
        CaseOpeningNotificationService.notifyOpenedCases(new Set<Id>{ c.Id });
        Test.stopTest();

        Assert.areEqual((Id) '00X000000000102AAA', CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest[0].emailTemplateId, 'Deve escolher template EN.');
        clearInjections();
    }

    @IsTest
    static void skipsOpeningEmailWhenCaseHasNoContact() {
        Case c = new Case(Subject = 'Caso sem contato', Status = 'Aberto', Origin = 'Email', UnidadeNegocio__c = 'Centro Logístico');
        insert c;
        setupConfig(true);
        CaseOpeningNotificationService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Open_Test_PT' => '00X000000000101AAA' };
        CaseOpeningNotificationServiceAgent.skipEmailForTest = true;

        Test.startTest();
        CaseOpeningNotificationService.notifyOpenedCases(new Set<Id>{ c.Id });
        Test.stopTest();

        Assert.areEqual(null, CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest, 'Case sem contato não deve enviar e-mail.');
        clearInjections();
    }

    @IsTest
    static void skipsOpeningEmailWhenTemplateIsMissing() {
        Case c = createOpenCase('Centro Logístico', 'cliente.template@example.com', 'pt_BR');
        setupConfig(true);
        CaseOpeningNotificationService.testTemplateIdsByDeveloperName = new Map<String, Id>();
        CaseOpeningNotificationServiceAgent.skipEmailForTest = true;

        Test.startTest();
        CaseOpeningNotificationService.notifyOpenedCases(new Set<Id>{ c.Id });
        Test.stopTest();

        Assert.areEqual(null, CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest, 'Template ausente não deve preparar envio.');
        clearInjections();
    }

    @IsTest
    static void agentReturnsErrorWhenEmailFails() {
        Case c = createOpenCase('Centro Logístico', 'cliente.agentfail@example.com', 'pt_BR');
        CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope envelope =
            new CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope();
        envelope.caseRecord = c;
        envelope.emailTemplateId = '00X000000000101AAA';
        CaseOpeningNotificationServiceAgent.skipEmailForTest = true;
        CaseOpeningNotificationServiceAgent.testEmailErrorsByIndex =
            new Map<Integer, String>{ 0 => 'INVALID_ID_FIELD: Template inválido.' };

        Test.startTest();
        List<CaseOpeningNotificationServiceAgent.DispatchResult> results =
            CaseOpeningNotificationServiceAgent.sendCaseOpeningEmails(
                new List<CaseOpeningNotificationServiceAgent.CaseOpeningEnvelope>{ envelope });
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Deve retornar resultado do envio.');
        Assert.areEqual(false, results[0].success, 'Falha simulada deve retornar success=false.');
        Assert.isTrue(results[0].message.contains('INVALID_ID_FIELD'), 'Mensagem deve expor erro simulado.');
        clearInjections();
    }

    private static Case createOpenCase(String businessUnit, String email, String language) {
        Contact contact = TestDataFactory.createAccountAndContact(
            new Map<String, Object>{ 'Name' => 'Conta Abertura' },
            new Map<String, Object>{ 'LastName' => 'Cliente Abertura', 'Email' => email, 'Phone' => '11999990000', 'Idioma__c' => language }
        );
        // RecordTypeId propositalmente null: replica o comportamento original de deixar o
        // RecordType default da org resolver, sem depender de qual RT ativo a factory sortear.
        return TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => null,
            'Subject' => 'Caso Abertura',
            'Status' => 'Aberto',
            'Origin' => 'Email',
            'UnidadeNegocio__c' => businessUnit,
            'ContactId' => contact.Id
        });
    }

    private static void setupConfig(Boolean sendOpeningEmail) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = 'Centro Logístico';
        config.isActive = true;
        config.sendCaseOpeningEmail = sendOpeningEmail;
        config.caseOpeningTemplateDeveloperName = 'Atend_Open_Test_PT';
        config.caseOpeningTemplateDeveloperNameEN = 'Atend_Open_Test_EN';
        config.orgWideEmailAddress = 'eu@marl2on.com';
        config.defaultLanguage = 'pt_BR';

        AtendimentoConfigDTO englishConfig = new AtendimentoConfigDTO();
        englishConfig.businessUnit = 'Rebocadores';
        englishConfig.isActive = true;
        englishConfig.sendCaseOpeningEmail = sendOpeningEmail;
        englishConfig.caseOpeningTemplateDeveloperName = 'Atend_Open_Test_PT';
        englishConfig.caseOpeningTemplateDeveloperNameEN = 'Atend_Open_Test_EN';
        englishConfig.defaultLanguage = 'pt_BR';

        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ config, englishConfig });
    }

    private static void clearInjections() {
        AtendimentoConfigService.clearTestSurveyConfigs();
        CaseOpeningNotificationService.testTemplateIdsByDeveloperName = null;
        CaseOpeningNotificationService.testOrgWideEmailIdsByAddress = null;
        CaseOpeningNotificationServiceAgent.skipEmailForTest = false;
        CaseOpeningNotificationServiceAgent.testEmailErrorsByIndex = null;
        CaseOpeningNotificationServiceAgent.preparedEnvelopesForTest = null;
    }
}