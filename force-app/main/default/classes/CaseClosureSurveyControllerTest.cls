@IsTest
private class CaseClosureSurveyControllerTest {
    @IsTest
    static void controllerDelegatesContextAndClose() {
        Contact contact = new Contact(
            LastName = 'Cliente Controller',
            Email = 'cliente.controller@example.com',
            Phone = '11999990000'
        );
        insert contact;

        Categorizacao__c categorizacao = createCentroLogisticoCategorization();

        Case c = new Case(
            Subject = 'Atendimento controller',
            Status = 'Aberto',
            Origin = 'Telefone',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email
        );
        insert c;
        update new Case(Id = c.Id, Categorizacao__c = categorizacao.Id, IsStopped = false);

        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = 'Centro Logístico';
        config.isActive = true;
        config.surveyMode = 'OPTIONAL';
        config.verifyDailySurvey = false;
        config.showDailySurveyIndicator = false;
        config.allowSameDaySurvey = true;
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ config });

        CaseClosureSurveyDTO context = CaseClosureSurveyController.getClosureContext(c.Id);
        Assert.areEqual('Centro Logístico', context.businessUnit);
        Assert.areEqual(true, context.showSurveyQuestion);

        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();
        request.caseId = c.Id;
        request.selectedSendSurvey = false;
        request.closureReason = 'Resolvido';
        request.closureSolution = 'Resolvido pelo atendimento.';
        request.closureComment = 'Sem envio de pesquisa por decisão do usuário.';

        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);
        Assert.areEqual(null, response.errorMessage, 'Erro inesperado no encerramento: ' + response.errorMessage);
        Assert.areEqual(Label.CaseClosureSurvey_SuccessMessage, response.successMessage);

        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void controllerReturnsFunctionalErrorDTO() {
        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();

        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);

        Assert.areEqual(Label.CaseClosureSurvey_CaseRequired, response.errorMessage);
    }

    @IsTest
    static void controllerBlocksCloseWhenCaseIsOnHold() {
        Contact contact = new Contact(
            LastName = 'Cliente Em Espera',
            Email = 'cliente.espera@example.com',
            Phone = '11999990000'
        );
        insert contact;

        Categorizacao__c categorizacao = createCentroLogisticoCategorization();

        Case c = new Case(
            Subject = 'Atendimento em espera',
            Status = 'Aberto',
            Origin = 'Telefone',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email
        );
        insert c;
        update new Case(Id = c.Id, Categorizacao__c = categorizacao.Id, IsStopped = true);

        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();
        request.caseId = c.Id;
        request.selectedSendSurvey = false;
        request.closureReason = 'Resolvido';
        request.closureSolution = 'Resolvido pelo atendimento.';
        request.closureComment = 'Tentativa bloqueada por espera.';

        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);

        Assert.areEqual(Label.CaseClosureSurvey_CaseOnHoldBlocked, response.errorMessage);
    }

    @IsTest
    static void controllerReturnsUnexpectedErrorDTO() {
        Contact contact = new Contact(
            LastName = 'Cliente Erro Controller',
            Email = 'cliente.erro.controller@example.com',
            Phone = '11999990000'
        );
        insert contact;

        Categorizacao__c categorizacao = createCentroLogisticoCategorization();

        Case c = new Case(
            Subject = 'Atendimento erro controller',
            Status = 'Aberto',
            Origin = 'Email',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email
        );
        insert c;
        update new Case(Id = c.Id, Categorizacao__c = categorizacao.Id);

        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();
        request.caseId = c.Id;
        request.closureReason = 'Resolvido';
        request.closureSolution = 'Forçar erro de DML.';

        ApexTestSeam.set('CaseClosureSurveyController.forceUnexpectedError', true);
        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);
        ApexTestSeam.clear('CaseClosureSurveyController.forceUnexpectedError');

        Assert.areEqual(Label.CaseClosureSurvey_UnexpectedControllerError, response.errorMessage);
    }

    private static Categorizacao__c createCentroLogisticoCategorization() {
        Categorizacao__c categorizacao = CategorizacaoTestDataFactory.base(false, false);
        categorizacao.RecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Categorizacao__c'
              AND DeveloperName = 'AtendimentoCentroLogistico'
            LIMIT 1
        ].Id;
        categorizacao.UnidadeNegocios__c = 'Centro Logístico';
        insert categorizacao;
        return categorizacao;
    }
}