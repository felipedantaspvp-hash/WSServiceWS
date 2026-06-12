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

        Case c = new Case(
            Subject = 'Atendimento controller',
            Status = 'Aberto',
            Origin = 'Telefone',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email
        );
        insert c;

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
        request.closureReason = 'A definir';
        request.closureSolution = 'Resolvido pelo atendimento.';
        request.closureComment = 'Sem envio de pesquisa por decisão do usuário.';

        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);
        Assert.areEqual('Caso encerrado com sucesso.', response.successMessage);
        Assert.areEqual(null, response.errorMessage);

        AtendimentoConfigService.clearTestSurveyConfigs();
    }

    @IsTest
    static void controllerReturnsFunctionalErrorDTO() {
        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();

        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);

        Assert.areEqual('Caso não informado.', response.errorMessage);
    }

    @IsTest
    static void controllerReturnsUnexpectedErrorDTO() {
        Contact contact = new Contact(
            LastName = 'Cliente Erro Controller',
            Email = 'cliente.erro.controller@example.com',
            Phone = '11999990000'
        );
        insert contact;

        Case c = new Case(
            Subject = 'Atendimento erro controller',
            Status = 'Aberto',
            Origin = 'Email',
            UnidadeNegocio__c = 'Centro Logístico',
            ContactId = contact.Id,
            SuppliedEmail = contact.Email
        );
        insert c;

        CaseClosureSurveyDTO request = new CaseClosureSurveyDTO();
        request.caseId = c.Id;
        request.closureReason = 'A definir';
        request.closureSolution = 'Forçar erro de DML.';

        CaseClosureSurveyController.forceUnexpectedErrorForTest = true;
        CaseClosureSurveyDTO response = CaseClosureSurveyController.closeCase(request);
        CaseClosureSurveyController.forceUnexpectedErrorForTest = false;

        Assert.areEqual('Erro inesperado ao encerrar o Caso.', response.errorMessage);
    }
}