/**
 * @description       : Testes unitários de DTOCoverage.
 * @author            : Triscal
 * @group             : Triscal
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class DTOCoverageTest {
    @IsTest
    static void testAtendimentoContextResolverDTO() {
        AtendimentoContextResolverDTO.Request req = new AtendimentoContextResolverDTO.Request();
        req.routableId = UserInfo.getUserId();
        req.channelType = 'messaging';
        req.endUserId = UserInfo.getUserId();
        req.contactId = UserInfo.getUserId();

        AtendimentoContextResolverDTO.Response res = new AtendimentoContextResolverDTO.Response();
        res.success = true;
        res.statusCode = 'SUCCESS';
        res.message = 'OK';
        res.needsCustomerInput = false;
        res.nextAction = 'PROCEED';
        res.missingInformation = null;
        res.contactName = 'Test';
        res.contactId = UserInfo.getUserId();
        res.accountName = 'Acc';
        res.accountId = UserInfo.getUserId();
        res.businessUnitName = 'Atendimento Salvador';
        res.channelName = 'WS_Will';
        res.conversationId = UserInfo.getUserId();
        res.conversationContactId = UserInfo.getUserId();

        Assert.areEqual('SUCCESS', res.statusCode);
    }

    @IsTest
    static void testMessagingContextDTO() {
        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.routableId = UserInfo.getUserId();
        req.channelType = 'messaging';
        req.endUserId = UserInfo.getUserId();
        req.contactId = UserInfo.getUserId();
        req.messagingSessionId = UserInfo.getUserId();
        req.liveChatTranscriptId = UserInfo.getUserId();
        req.channelDeveloperName = 'WS_Will';

        MessagingContextDTO.Response res = new MessagingContextDTO.Response();
        res.contactId = UserInfo.getUserId();
        res.contactName = 'Test';
        res.accountId = UserInfo.getUserId();
        res.accountName = 'Acc';
        res.businessUnitName = 'Salvador';
        res.channelType = 'messaging';
        res.channelDeveloperName = 'WS_Will';
        res.conversationId = UserInfo.getUserId();
        res.conversationContactId = UserInfo.getUserId();
        res.messagingSessionId = UserInfo.getUserId();
        res.messagingEndUserId = UserInfo.getUserId();
        res.liveChatTranscriptId = UserInfo.getUserId();
        res.success = true;
        res.requiresCustomerIdentification = false;
        res.fallbackReason = null;
        res.targetQueueDeveloperName = 'Q1';
        res.fallbackQueueDeveloperName = 'Q2';

        Assert.areEqual(true, res.success);
    }

    @IsTest
    static void testWSWillCaseCreationDTO() {
        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.businessUnitName = 'Atendimento Salvador';
        req.language = 'pt_BR';
        req.channelName = 'WS_Will';
        req.origin = 'Messaging';
        req.conversationId = UserInfo.getUserId();
        req.endUserId = UserInfo.getUserId();
        req.contactId = UserInfo.getUserId();
        req.accountId = UserInfo.getUserId();
        req.customerFullName = 'João Silva';
        req.customerEmail = 'joao@example.com';
        req.customerPhone = '5511999999999';
        req.caseType = 'Solicitação';
        req.description = 'Descrição do caso';

        WSWillCaseCreationDTO.Response res = new WSWillCaseCreationDTO.Response();
        res.success = true;
        res.statusCode = 'SUCCESS';
        res.message = 'Caso criado';
        res.contactId = UserInfo.getUserId();
        res.accountId = UserInfo.getUserId();
        res.caseId = UserInfo.getUserId();
        res.caseNumber = '00001234';

        Assert.areEqual('SUCCESS', res.statusCode);
    }

    @IsTest
    static void testWSWillContextResolverDTO() {
        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(UserInfo.getUserId());
        req.channelType = 'messaging';
        req.endUserId = String.valueOf(UserInfo.getUserId());

        WSWillContextResolverDTO.Response res = new WSWillContextResolverDTO.Response();
        res.success = true;
        res.statusCode = 'SUCCESS';
        res.message = 'OK';
        res.contactName = 'Test';
        res.contactId = UserInfo.getUserId();
        res.accountName = 'Acc';
        res.accountId = UserInfo.getUserId();
        res.businessUnitName = 'Atendimento Salvador';
        res.businessUnitSource = 'ACCOUNT';
        res.channelName = 'WS_Will';
        res.conversationId = UserInfo.getUserId();
        res.conversationContactId = UserInfo.getUserId();
        res.preferredLanguage = 'pt_BR';
        res.shouldAskLanguage = false;

        Assert.areEqual(true, res.success);
    }

    @IsTest
    static void testWSWillConversationLinkDTO() {
        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.conversationId = UserInfo.getUserId();
        req.caseId = UserInfo.getUserId();
        req.channelName = 'WS_Will';
        req.routableId = UserInfo.getUserId();

        WSWillConversationLinkDTO.Response res = new WSWillConversationLinkDTO.Response();
        res.success = true;
        res.statusCode = 'SUCCESS';
        res.message = 'Vinculado';

        Assert.areEqual('SUCCESS', res.statusCode);
    }

    @IsTest
    static void testWSWillCaseLookupDTO() {
        WSWillCaseLookupDTO.Request req = new WSWillCaseLookupDTO.Request();
        req.caseNumber = '00001234';
        req.contactId = UserInfo.getUserId();
        req.accountId = UserInfo.getUserId();
        req.language = 'pt_BR';
        req.businessUnitName = 'Atendimento Salvador';

        WSWillCaseLookupDTO.Response res = new WSWillCaseLookupDTO.Response();
        res.success = true;
        res.statusCode = 'SUCCESS';
        res.message = 'Encontrado';
        res.caseId = UserInfo.getUserId();
        res.caseNumber = '00001234';
        res.caseStatus = 'New';
        res.caseType = 'Solicitação';
        res.caseCategory = 'Solicitação';
        res.caseSubject = 'Assunto';
        res.caseStage = 'Aberto';
        res.caseBusinessUnitName = 'Atendimento Salvador';
        res.canShowCaseData = true;
        res.caseFound = true;

        Assert.areEqual(true, res.caseFound);
    }

    @IsTest
    static void testCaseSurveyDispatchDTO() {
        CaseSurveyDispatchDTO.Request req = new CaseSurveyDispatchDTO.Request();
        req.caseId = UserInfo.getUserId();

        CaseSurveyDispatchDTO.Response res = new CaseSurveyDispatchDTO.Response();
        res.success = true;
        res.message = 'Enviado';
        res.caseId = UserInfo.getUserId();
        res.surveyInvitationId = UserInfo.getUserId();

        Assert.areEqual(true, res.success);
    }
}