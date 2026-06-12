@IsTest
private class WSWillConversationLinkTest {
    private static final Id FAKE_MESSAGING_ID = Id.valueOf('0Mw000000000001');
    private static final Id FAKE_LIVE_CHAT_ID = Id.valueOf('570000000000001');

    @IsTest
    static void shouldReturnConversationNotFoundWhenNoConversation() {
        Case cs = new Case(Subject = 'Teste Link', Status = 'Aberto');
        insert cs;

        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.caseId = cs.Id;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkInvocable.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual('CONVERSATION_NOT_FOUND', res[0].statusCode);
    }

    @IsTest
    static void shouldReturnEmptyForNullOrEmptyList() {
        List<WSWillConversationLinkDTO.Response> resNull = WSWillConversationLinkService.link(null);
        Assert.areEqual(0, resNull.size());

        List<WSWillConversationLinkDTO.Response> resEmpty = WSWillConversationLinkService.link(new List<WSWillConversationLinkDTO.Request>());
        Assert.areEqual(0, resEmpty.size());
    }

    @IsTest
    static void shouldReturnCaseNotFoundWhenCaseIdMissing() {
        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.conversationId = FAKE_MESSAGING_ID;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual('CASE_NOT_FOUND', res[0].statusCode);
    }

    @IsTest
    static void shouldReturnConversationNotFoundForMessagingSessionNotInDb() {
        Case cs = new Case(Subject = 'Teste Link MS', Status = 'Aberto');
        insert cs;

        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.caseId = cs.Id;
        req.conversationId = FAKE_MESSAGING_ID;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual('CONVERSATION_NOT_FOUND', res[0].statusCode);
    }

    @IsTest
    static void shouldReturnConversationNotFoundForLiveChatNotInDb() {
        Case cs = new Case(Subject = 'Teste Link LC', Status = 'Aberto');
        insert cs;

        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.caseId = cs.Id;
        req.conversationId = FAKE_LIVE_CHAT_ID;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual('CONVERSATION_NOT_FOUND', res[0].statusCode);
    }

    @IsTest
    static void shouldReturnUnsupportedWhenConversationIsNotMessagingOrLiveChat() {
        Case cs = new Case(Subject = 'Teste Link Unsupported', Status = 'Aberto');
        insert cs;

        Case fakeConvCase = new Case(Subject = 'Fake Conv', Status = 'Aberto');
        insert fakeConvCase;

        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.caseId = cs.Id;
        req.conversationId = fakeConvCase.Id;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual('UNSUPPORTED_CONVERSATION_OBJECT', res[0].statusCode);
    }

    @IsTest
    static void shouldHandleNullRequestInList() {
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ null }
        );
        Assert.areEqual(1, res.size());
        Assert.areEqual('CONVERSATION_NOT_FOUND', res[0].statusCode);
    }

    @IsTest
    static void shouldLinkMessagingSessionSuccess() {
        Case cs = new Case(Subject = 'Link MS Success');
        insert cs;

        MessagingSession ms = (MessagingSession) JSON.deserialize(
            '{"Id":"' + String.valueOf(FAKE_MESSAGING_ID) + '"}', MessagingSession.class
        );

        WSWillConversationLinkService.testCaseById = new Map<Id, Case>{ cs.Id => cs };
        WSWillConversationLinkService.testMessagingById = new Map<Id, MessagingSession>{ FAKE_MESSAGING_ID => ms };
        WSWillConversationLinkService.testLiveChatById = new Map<Id, LiveChatTranscript>();
        WSWillConversationLinkService.bypassDmlInTests = true;

        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.caseId = cs.Id;
        req.conversationId = FAKE_MESSAGING_ID;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        WSWillConversationLinkService.testCaseById = null;
        WSWillConversationLinkService.testMessagingById = null;
        WSWillConversationLinkService.testLiveChatById = null;
        WSWillConversationLinkService.bypassDmlInTests = false;

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual('SUCCESS', res[0].statusCode);
    }

    @IsTest
    static void shouldReturnUnexpectedErrorWhenServiceThrows() {
        WSWillConversationLinkService.throwExceptionForTest = true;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkInvocable.link(
            new List<WSWillConversationLinkDTO.Request>{ new WSWillConversationLinkDTO.Request() }
        );
        Test.stopTest();

        WSWillConversationLinkService.throwExceptionForTest = false;

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual('UNEXPECTED_ERROR', res[0].statusCode);
    }

    @IsTest
    static void shouldLinkLiveChatTranscriptSuccess() {
        Case cs = new Case(Subject = 'Link LC Success');
        insert cs;

        LiveChatTranscript lct = (LiveChatTranscript) JSON.deserialize(
            '{"Id":"' + String.valueOf(FAKE_LIVE_CHAT_ID) + '"}', LiveChatTranscript.class
        );

        WSWillConversationLinkService.testCaseById = new Map<Id, Case>{ cs.Id => cs };
        WSWillConversationLinkService.testMessagingById = new Map<Id, MessagingSession>();
        WSWillConversationLinkService.testLiveChatById = new Map<Id, LiveChatTranscript>{ FAKE_LIVE_CHAT_ID => lct };
        WSWillConversationLinkService.bypassDmlInTests = true;

        WSWillConversationLinkDTO.Request req = new WSWillConversationLinkDTO.Request();
        req.caseId = cs.Id;
        req.conversationId = FAKE_LIVE_CHAT_ID;

        Test.startTest();
        List<WSWillConversationLinkDTO.Response> res = WSWillConversationLinkService.link(
            new List<WSWillConversationLinkDTO.Request>{ req }
        );
        Test.stopTest();

        WSWillConversationLinkService.testCaseById = null;
        WSWillConversationLinkService.testMessagingById = null;
        WSWillConversationLinkService.testLiveChatById = null;
        WSWillConversationLinkService.bypassDmlInTests = false;

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual('SUCCESS', res[0].statusCode);
    }
}