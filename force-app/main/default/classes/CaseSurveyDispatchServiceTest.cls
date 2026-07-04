@IsTest
private class CaseSurveyDispatchServiceTest {
    @IsTest
    static void dispatchSendsSurveyAndMarksCase() {
        Case c = createClosedEligibleCase('Centro Logístico', 'cliente.survey@example.com');
        setupConfig('Centro Logístico', 'Atendimento_Survey_Teste', 'Atend_Survey_Email_Teste', null);
        CaseSurveyDispatchService.testSurveyIdsByDeveloperName = new Map<String, Id>{ 'Atendimento_Survey_Teste' => '0Kd000000000001AAA' };
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Survey_Email_Teste' => '00X000000000001AAA' };
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseSurveyDispatchService.testNetworkIdsByUrlPathPrefix = new Map<String, Id>{ 'pesquisaws' => '0DB000000000001AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();
        ApexTestSeam.set('CaseSurveyDispatchServiceAgent.skipDmlAndEmail', true);
        CaseSurveyDispatchServiceAgent.testInvitationId = '0Ki000000000001AAA';

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Case updatedCase = [SELECT PesquisaEnviada__c, DataHoraEnvioPesquisa__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(1, responses.size());
        Assert.areEqual(true, responses[0].success);
        Assert.areEqual('SENT', responses[0].message);
        Assert.areEqual(true, updatedCase.PesquisaEnviada__c);
        Assert.areNotEqual(null, updatedCase.DataHoraEnvioPesquisa__c);
        clearInjections();
    }

    @IsTest
    static void dispatchSkipsWhenCaseIsNotEligible() {
        Case c = createClosedEligibleCase('Centro Logístico', 'cliente.skip@example.com');
        setupConfig('Centro Logístico', 'Atendimento_Survey_Teste', 'Atend_Survey_Email_Teste', null);
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Close_Test_PT' => '00X000000000002AAA' };
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();
        ApexTestSeam.set('CaseSurveyDispatchServiceAgent.skipDmlAndEmail', true);
        update new Case(Id = c.Id, EnviarPesquisaSatisfacao__c = false);

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchFlowAction.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Assert.areEqual(1, responses.size());
        Assert.areEqual(true, responses[0].success);
        Assert.areEqual('CASE_CLOSURE_SENT', responses[0].message);
        Assert.areEqual(false, [SELECT PesquisaEnviada__c FROM Case WHERE Id = :c.Id].PesquisaEnviada__c);
        clearInjections();
    }

    @IsTest
    static void dispatchSkipsWhenCaseAlreadyHasSurveySubject() {
        Case c = createClosedEligibleCase('Centro Logístico', 'cliente.duplicate@example.com');
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>{ c.Id };

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Assert.areEqual(1, responses.size());
        Assert.areEqual(true, responses[0].success);
        Assert.areEqual(true, responses[0].message.contains('já possui Survey vinculada'));
        clearInjections();
    }

    @IsTest
    static void dispatchReturnsErrorWhenSurveyMetadataIsMissing() {
        Case c = createClosedEligibleCase('Centro Logístico', 'cliente.missing@example.com');
        setupConfig('Centro Logístico', 'Survey_Inexistente', 'Template_Inexistente', null);
        CaseSurveyDispatchService.testSurveyIdsByDeveloperName = new Map<String, Id>();
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Template_Inexistente' => '00X000000000003AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Assert.areEqual(1, responses.size());
        Assert.areEqual(false, responses[0].success);
        Assert.areEqual('Survey não encontrada para a unidade de negócio e idioma do contato.', responses[0].message);
        clearInjections();
    }

    @IsTest
    static void dispatchDoesNotMarkCaseWhenEmailFails() {
        Case c = createClosedEligibleCase('Centro Logístico', 'cliente.emailfail@example.com');
        setupConfig('Centro Logístico', 'Atendimento_Survey_Teste', 'Atend_Survey_Email_Teste', null);
        CaseSurveyDispatchService.testSurveyIdsByDeveloperName = new Map<String, Id>{ 'Atendimento_Survey_Teste' => '0Kd000000000001AAA' };
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Survey_Email_Teste' => '00X000000000001AAA' };
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseSurveyDispatchService.testNetworkIdsByUrlPathPrefix = new Map<String, Id>{ 'pesquisaws' => '0DB000000000001AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();
        ApexTestSeam.set('CaseSurveyDispatchServiceAgent.skipDmlAndEmail', true);
        CaseSurveyDispatchServiceAgent.testInvitationId = '0Ki000000000001AAA';
        CaseSurveyDispatchServiceAgent.testEmailErrorsByIndex = new Map<Integer, String>{ 0 => 'INVALID_ID_FIELD: SaveAsActivity is not allowed.' };

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Case updatedCase = [SELECT PesquisaEnviada__c, DataHoraEnvioPesquisa__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(1, responses.size());
        Assert.areEqual(false, responses[0].success);
        Assert.areEqual(true, responses[0].message.contains('INVALID_ID_FIELD'));
        Assert.areEqual(false, updatedCase.PesquisaEnviada__c);
        Assert.areEqual(null, updatedCase.DataHoraEnvioPesquisa__c);
        clearInjections();
    }

    @IsTest
    static void dispatchCreatesGuestInvitationWithoutParticipant() {
        Case c = createClosedEligibleCase('Centro Logístico', 'cliente.guest@example.com');
        setupConfig('Centro Logístico', 'Atendimento_Survey_Teste', 'Atend_Survey_Email_Teste', null);
        CaseSurveyDispatchService.testSurveyIdsByDeveloperName = new Map<String, Id>{ 'Atendimento_Survey_Teste' => '0Kd000000000001AAA' };
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Survey_Email_Teste' => '00X000000000001AAA' };
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseSurveyDispatchService.testNetworkIdsByUrlPathPrefix = new Map<String, Id>{ 'pesquisaws' => '0DB000000000001AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();
        ApexTestSeam.set('CaseSurveyDispatchServiceAgent.skipDmlAndEmail', true);
        CaseSurveyDispatchServiceAgent.testInvitationId = '0Ki000000000001AAA';

        Test.startTest();
        CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Assert.areEqual(1, CaseSurveyDispatchServiceAgent.preparedInvitationsForTest.size());
        Assert.areEqual(null, CaseSurveyDispatchServiceAgent.preparedInvitationsForTest[0].ParticipantId);
        Assert.areEqual(true, CaseSurveyDispatchServiceAgent.preparedInvitationsForTest[0].OptionsAllowGuestUserResponse);
        Assert.areEqual((Id) '0DB000000000001AAA', CaseSurveyDispatchServiceAgent.preparedInvitationsForTest[0].CommunityId);
        clearInjections();
    }

    @IsTest
    static void dispatchUsesEnglishSurveyForEnglishContactWhenConfigured() {
        Case c = createClosedEligibleCase('Rebocadores', 'cliente.en.survey@example.com', 'en_US');
        setupConfig('Rebocadores', 'Atendimento_Survey_Teste_PT', 'Atend_Survey_Email_Teste_PT', null);
        CaseSurveyDispatchService.testSurveyIdsByDeveloperName = new Map<String, Id>{ 'Atendimento_Survey_Teste_EN' => '0Kd000000000002AAA' };
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Survey_Email_Teste_EN' => '00X000000000004AAA' };
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseSurveyDispatchService.testNetworkIdsByUrlPathPrefix = new Map<String, Id>{ 'pesquisaws' => '0DB000000000001AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();
        ApexTestSeam.set('CaseSurveyDispatchServiceAgent.skipDmlAndEmail', true);
        CaseSurveyDispatchServiceAgent.testInvitationId = '0Ki000000000001AAA';

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Assert.areEqual(1, responses.size());
        Assert.areEqual(true, responses[0].success);
        Assert.areEqual('SENT', responses[0].message);
        clearInjections();
    }

    @IsTest
    static void dispatchUsesEnglishClosureTemplateWhenSurveyIsNotSent() {
        Case c = createClosedEligibleCase('Rebocadores', 'cliente.en.closure@example.com', 'en_US');
        setupConfig('Rebocadores', 'Atendimento_Survey_Teste_PT', 'Atend_Survey_Email_Teste_PT', null);
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = new Map<String, Id>{ 'Atend_Close_Test_EN' => '00X000000000005AAA' };
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = new Map<String, Id>{ 'eu@marl2on.com' => '0D2000000000001AAA' };
        CaseSurveyDispatchService.testCasesWithSurveySubject = new Set<Id>();
        ApexTestSeam.set('CaseSurveyDispatchServiceAgent.skipDmlAndEmail', true);
        update new Case(Id = c.Id, EnviarPesquisaSatisfacao__c = false);

        Test.startTest();
        List<CaseSurveyDispatchDTO.Response> responses = CaseSurveyDispatchService.dispatch(new List<CaseSurveyDispatchDTO.Request>{ request(c.Id) });
        Test.stopTest();

        Assert.areEqual(1, responses.size());
        Assert.areEqual(true, responses[0].success);
        Assert.areEqual('CASE_CLOSURE_SENT', responses[0].message);
        clearInjections();
    }

    private static Case createClosedEligibleCase(String businessUnit, String email) {
        return createClosedEligibleCase(businessUnit, email, 'pt_BR');
    }

    private static Case createClosedEligibleCase(String businessUnit, String email, String language) {
        Contact contact = TestDataFactory.createAccountAndContact(
            new Map<String, Object>{ 'Name' => 'Conta Survey' },
            new Map<String, Object>{ 'LastName' => 'Cliente Survey', 'Email' => email, 'Phone' => '11999990000', 'Idioma__c' => language }
        );
        return TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => getCaseRecordTypeId('AtendimentoCentroLogistico'),
            'Subject' => 'Caso Survey',
            'Status' => 'Fechado',
            'Origin' => 'Email',
            'UnidadeNegocio__c' => businessUnit,
            'ContactId' => contact.Id,
            'EnviarPesquisaSatisfacao__c' => true,
            'PesquisaEnviada__c' => false,
            // 'A definir' não é um valor habilitado da lista restrita para o RecordType
            // AtendimentoCentroLogistico (confirmado no Setup) — usa 'Resolvido', que é.
            'MotivoEncerramento__c' => 'Resolvido',
            'SolucaoCaso__c' => 'Atendimento concluído.'
        });
    }

    private static Id getCaseRecordTypeId(String developerName) {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND DeveloperName = :developerName
            LIMIT 1
        ].Id;
    }

    private static CaseSurveyDispatchDTO.Request request(Id caseId) {
        CaseSurveyDispatchDTO.Request request = new CaseSurveyDispatchDTO.Request();
        request.caseId = caseId;
        return request;
    }

    private static void setupConfig(String businessUnit, String surveyDeveloperName, String templateDeveloperName, String blockedDomains) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = businessUnit;
        config.isActive = true;
        config.surveyMode = AtendimentoConfigHelper.SURVEY_MODE_OPTIONAL;
        config.surveyDeveloperName = surveyDeveloperName;
        config.surveyDeveloperNameEN = 'Atendimento_Survey_Teste_EN';
        config.emailTemplateDeveloperName = templateDeveloperName;
        config.emailTemplateDeveloperNameEN = 'Atend_Survey_Email_Teste_EN';
        config.caseClosureTemplateDeveloperName = 'Atend_Close_Test_PT';
        config.caseClosureTemplateDeveloperNameEN = 'Atend_Close_Test_EN';
        config.orgWideEmailAddress = 'eu@marl2on.com';
        config.surveyCommunityUrlPathPrefix = 'PesquisaWS';
        config.blockedInternalDomain = blockedDomains;
        config.defaultLanguage = 'pt_BR';
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ config });
    }

    private static void clearInjections() {
        AtendimentoConfigService.clearTestSurveyConfigs();
        CaseSurveyDispatchService.testSurveyIdsByDeveloperName = null;
        CaseSurveyDispatchService.testTemplateIdsByDeveloperName = null;
        CaseSurveyDispatchService.testOrgWideEmailIdsByAddress = null;
        CaseSurveyDispatchService.testNetworkIdsByUrlPathPrefix = null;
        CaseSurveyDispatchService.testCasesWithSurveySubject = null;
        ApexTestSeam.clear('CaseSurveyDispatchServiceAgent.skipDmlAndEmail');
        CaseSurveyDispatchServiceAgent.testInvitationId = null;
        CaseSurveyDispatchServiceAgent.testEmailErrorsByIndex = null;
        CaseSurveyDispatchServiceAgent.preparedInvitationsForTest = null;
    }
}