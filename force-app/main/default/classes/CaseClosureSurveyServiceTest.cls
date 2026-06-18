@IsTest
private class CaseClosureSurveyServiceTest {
    private static Map<String, Id> categorizationIdByBusinessUnit = new Map<String, Id>();

    @IsTest
    static void alwaysModeDoesNotShowQuestionAndMarksSurvey() {
        Case c = createCase('Centro Logístico', 'cliente.always@example.com');
        setupConfig('Centro Logístico', 'ALWAYS', false, false, true, null);

        CaseClosureSurveyDTO context = CaseClosureSurveyService.getClosureContext(c.Id);
        Assert.areEqual('ALWAYS', context.surveyMode);
        Assert.areEqual(false, context.showSurveyQuestion);
        Assert.areEqual(true, context.defaultSendSurvey);

        CaseClosureSurveyDTO request = buildRequest(c.Id, true);
        CaseClosureSurveyDTO result = CaseClosureSurveyService.closeCase(request);
        Case updatedCase = [SELECT Status, EnviarPesquisaSatisfacao__c FROM Case WHERE Id = :c.Id];

        Assert.areEqual('Caso encerrado com sucesso.', result.successMessage);
        Assert.areEqual('Fechado', updatedCase.Status);
        Assert.areEqual(true, updatedCase.EnviarPesquisaSatisfacao__c);
    }

    @IsTest
    static void optionalModeShowsQuestionAndHonorsUserDecision() {
        Case c = createCase('Centro Logístico', 'cliente.optional@example.com');
        setupConfig('Centro Logístico', 'OPTIONAL', true, true, true, null);
        CaseClosureSurveyHelper.setTestCustomerSurveyTodayByEmail(new Map<String, Boolean>{
            'cliente.optional@example.com' => false
        });

        CaseClosureSurveyDTO context = CaseClosureSurveyService.getClosureContext(c.Id);
        Assert.areEqual(true, context.showSurveyQuestion);
        Assert.areEqual(true, context.showDailySurveyIndicator);
        Assert.areEqual(false, context.customerAlreadyReceivedSurveyToday);

        CaseClosureSurveyDTO request = buildRequest(c.Id, true);
        CaseClosureSurveyService.closeCase(request);
        Case updatedCase = [SELECT EnviarPesquisaSatisfacao__c FROM Case WHERE Id = :c.Id];

        Assert.areEqual(true, updatedCase.EnviarPesquisaSatisfacao__c);

        Case caseWithoutSurvey = createCase('Centro Logístico', 'cliente.optional.no@example.com');
        CaseClosureSurveyDTO noSurveyRequest = buildRequest(caseWithoutSurvey.Id, false);
        CaseClosureSurveyService.closeCase(noSurveyRequest);
        Case updatedCaseWithoutSurvey = [SELECT EnviarPesquisaSatisfacao__c FROM Case WHERE Id = :caseWithoutSurvey.Id];

        Assert.areEqual(false, updatedCaseWithoutSurvey.EnviarPesquisaSatisfacao__c);
        CaseClosureSurveyHelper.clearTestCustomerSurveyTodayByEmail();
    }

    @IsTest
    static void optionalModeBlocksSameDayWhenConfigured() {
        Case c = createCase('Centro Logístico', 'cliente.block@example.com');
        setupConfig('Centro Logístico', 'OPTIONAL', true, true, false, null);
        CaseClosureSurveyHelper.setTestCustomerSurveyTodayByEmail(new Map<String, Boolean>{
            'cliente.block@example.com' => true
        });

        CaseClosureSurveyDTO request = buildRequest(c.Id, true);

        try {
            CaseClosureSurveyService.closeCase(request);
            Assert.areEqual(true, false, 'Deveria bloquear envio no mesmo dia.');
        } catch (CaseClosureSurveyService.FunctionalException ex) {
            Assert.areEqual('Este cliente já recebeu pesquisa hoje.', ex.getMessage());
        }

        CaseClosureSurveyHelper.clearTestCustomerSurveyTodayByEmail();
    }

    @IsTest
    static void neverModeDoesNotMarkSurvey() {
        Case c = createCase('Rebocadores', 'cliente.never@example.com');
        setupConfig('Rebocadores', 'NEVER', false, false, false, null);

        CaseClosureSurveyDTO context = CaseClosureSurveyService.getClosureContext(c.Id);
        Assert.areEqual('NEVER', context.surveyMode);
        Assert.areEqual(false, context.showSurveyQuestion);

        CaseClosureSurveyService.closeCase(buildRequest(c.Id, true));
        Case updatedCase = [SELECT EnviarPesquisaSatisfacao__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(false, updatedCase.EnviarPesquisaSatisfacao__c);
    }

    @IsTest
    static void missingConfigFallsBackToNever() {
        Case c = createCase('Centro Logístico', 'cliente.none@example.com');
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>());

        CaseClosureSurveyDTO context = CaseClosureSurveyService.getClosureContext(c.Id);

        Assert.areEqual('NEVER', context.surveyMode);
        Assert.areEqual(false, context.showSurveyQuestion);
        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void closeCaseBlocksUncategorizedCase() {
        Case c = createUncategorizedCase('Centro Logístico', 'cliente.sem.categoria@example.com');
        setupConfig('Centro Logístico', 'NEVER', false, false, false, null);

        CaseClosureSurveyDTO context = CaseClosureSurveyService.getClosureContext(c.Id);
        Assert.areEqual(false, context.isCategorized);
        Assert.areEqual('Categorize o caso antes de encerrá-lo.', context.categorizationBlockMessage);

        try {
            CaseClosureSurveyService.closeCase(buildRequest(c.Id, false));
            Assert.fail('Deveria bloquear encerramento de caso sem categorização.');
        } catch (CaseClosureSurveyService.FunctionalException ex) {
            Assert.areEqual('Categorize o caso antes de encerrá-lo.', ex.getMessage());
        }

        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void internalDomainBlocksSurveyEligibility() {
        Case c = createCase('Centro Logístico', 'usuario@wilsonsons.com.br');
        setupConfig('Centro Logístico', 'ALWAYS', false, false, true, 'wilsonsons.com.br');

        CaseClosureSurveyService.closeCase(buildRequest(c.Id, true));
        Case updatedCase = [SELECT EnviarPesquisaSatisfacao__c FROM Case WHERE Id = :c.Id];

        Assert.areEqual(false, updatedCase.EnviarPesquisaSatisfacao__c);
    }

    @IsTest
    static void validationRequiresClosureFields() {
        Case c = createCase('Centro Logístico', 'cliente.validation@example.com');
        setupConfig('Centro Logístico', 'ALWAYS', false, false, true, null);
        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();
        request.caseId = c.Id;
        request.selectedSendSurvey = true;

        try {
            CaseClosureSurveyService.closeCase(request);
            Assert.areEqual(true, false, 'Deveria exigir motivo de encerramento.');
        } catch (CaseClosureSurveyService.FunctionalException ex) {
            Assert.areEqual('Motivo de encerramento é obrigatório.', ex.getMessage());
        }
    }

    @IsTest
    static void helperResolvesRecipientDomainAndDailyIndicator() {
        Case c = createCase('Centro Logístico', 'cliente.helper@example.com');
        c = [
            SELECT Id, ContactId, Contact.Email, ContactEmail, SuppliedEmail
            FROM Case
            WHERE Id = :c.Id
        ];

        Assert.areEqual('cliente.helper@example.com', CaseClosureSurveyHelper.resolveRecipientEmail(c));
        Assert.areEqual(true, CaseClosureSurveyHelper.isBlockedInternalDomain('user@wilsonsons.com.br', 'wilsonsons.com.br;example.com'));
        Assert.areEqual(false, CaseClosureSurveyHelper.isBlockedInternalDomain('user@cliente.com', 'wilsonsons.com.br;example.com'));
        Assert.areEqual('Este cliente já recebeu pesquisa hoje. A configuração permite novo envio.', CaseClosureSurveyHelper.buildDailySurveyMessage(true, true));

        CaseClosureSurveyHelper.setTestCustomerSurveyTodayByEmail(new Map<String, Boolean>{
            'cliente.helper@example.com' => true
        });
        Assert.areEqual(true, CaseClosureSurveyHelper.customerReceivedSurveyToday(c));
        CaseClosureSurveyHelper.clearTestCustomerSurveyTodayByEmail();
    }

    @IsTest
    static void helperUsesCaseFallbackForDailySurveyCheck() {
        Contact contact = new Contact(LastName = 'Cliente Fallback', Email = 'cliente.fallback@example.com', Phone = '11999990000');
        insert contact;

        Case previousCase = new Case(
            Subject = 'Pesquisa anterior',
            Status = 'Fechado',
            Origin = 'Email',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email,
            DataHoraEnvioPesquisa__c = System.now()
        );
        insert previousCase;

        Case currentCase = new Case(
            Subject = 'Pesquisa atual',
            Status = 'Aberto',
            Origin = 'Email',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email
        );
        insert currentCase;

        currentCase = [
            SELECT Id, ContactId, Contact.Email, ContactEmail, SuppliedEmail
            FROM Case
            WHERE Id = :currentCase.Id
        ];

        Assert.areEqual(true, CaseClosureSurveyHelper.customerReceivedSurveyToday(currentCase));
        Assert.areEqual(false, CaseClosureSurveyHelper.isBlockedInternalDomain(null, null));
    }

    private static Case createCase(String businessUnit, String email) {
        Case c = createUncategorizedCase(businessUnit, email);
        c.Categorizacao__c = getOrCreateCategorizationId(businessUnit);
        update c;
        return c;
    }

    private static Id getOrCreateCategorizationId(String businessUnit) {
        if (categorizationIdByBusinessUnit.containsKey(businessUnit)) {
            return categorizationIdByBusinessUnit.get(businessUnit);
        }

        Categorizacao__c categorizacao = CategorizacaoTestDataFactory.base(false, false);
        categorizacao.RecordTypeId = getCategorizationRecordTypeId(businessUnit);
        categorizacao.UnidadeNegocios__c = businessUnit;
        insert categorizacao;
        categorizationIdByBusinessUnit.put(businessUnit, categorizacao.Id);
        return categorizacao.Id;
    }

    private static Id getCategorizationRecordTypeId(String businessUnit) {
        String developerName = businessUnit == 'Rebocadores'
            ? 'AtendimentoRebocadores'
            : 'AtendimentoCentroLogistico';
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Categorizacao__c'
              AND DeveloperName = :developerName
            LIMIT 1
        ].Id;
    }

    private static Case createUncategorizedCase(String businessUnit, String email) {
        Contact contact = new Contact(LastName = 'Cliente Pesquisa', Email = email, Phone = '11999990000');
        insert contact;

        Case c = new Case(
            Subject = 'Atendimento pesquisa',
            Status = 'Aberto',
            Origin = 'Email',
            UnidadeNegocio__c = businessUnit,
            ContactId = contact.Id,
            SuppliedEmail = email
        );
        insert c;
        return c;
    }

    private static CaseClosureSurveyDTO buildRequest(Id caseId, Boolean sendSurvey) {
        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();
        request.caseId = caseId;
        request.selectedSendSurvey = sendSurvey;
        request.closureReason = 'A definir';
        request.closureSolution = 'Atendimento concluído.';
        request.closureComment = 'Encerramento registrado pela action.';
        return request;
    }

    private static void setupConfig(
        String businessUnit,
        String mode,
        Boolean verifyDaily,
        Boolean showDaily,
        Boolean allowSameDay,
        String blockedDomains
    ) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = businessUnit;
        config.isActive = true;
        config.surveyMode = mode;
        config.verifyDailySurvey = verifyDaily;
        config.showDailySurveyIndicator = showDaily;
        config.allowSameDaySurvey = allowSameDay;
        config.blockedInternalDomain = blockedDomains;
        config.emailTemplateDeveloperName = 'Atend_Survey_Email_Teste';
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ config });
    }
}