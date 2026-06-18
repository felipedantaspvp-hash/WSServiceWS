@IsTest
private class AtendimentoContextResolverTest {
    private class GatewayMock implements AtendimentoContextResolverService.ConversationGateway {
        public Map<Id, SObject> messaging = new Map<Id, SObject>();
        public Map<Id, SObject> liveChat = new Map<Id, SObject>();

        public Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead) {
            Map<Id, SObject> out = new Map<Id, SObject>();
            if (objectApiName == 'MessagingSession') {
                for (Id rowId : ids) if (messaging.containsKey(rowId)) out.put(rowId, messaging.get(rowId));
            }
            if (objectApiName == 'LiveChatTranscript') {
                for (Id rowId : ids) if (liveChat.containsKey(rowId)) out.put(rowId, liveChat.get(rowId));
            }
            return out;
        }
    }

    private class EmptyGatewayMock implements AtendimentoContextResolverService.ConversationGateway {
        public Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead) {
            return new Map<Id, SObject>();
        }
    }

    private class ThrowingGatewayMock implements AtendimentoContextResolverService.ConversationGateway {
        public Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead) {
            throw new GatewayTestException('boom');
        }
    }

    private class GatewayTestException extends Exception {}

    private static Account createAccount(String name) {
        Account row = new Account(Name = name);
        insert row;
        return row;
    }

    private static Contact createContact(String firstName, String lastName, Id accountId) {
        Contact row = new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = accountId,
            Email = firstName + '.' + lastName + '@example.com',
            MobilePhone = '5511999999999'
        );
        insert row;
        return row;
    }

    private static AtendimentoContextResolverDTO.Request baseRequest() {
        AtendimentoContextResolverDTO.Request req = new AtendimentoContextResolverDTO.Request();
        req.channelType = 'WHATSAPP';
        return req;
    }

    private static void resetResolverTestState() {
        AtendimentoContextResolverService.gateway = new EmptyGatewayMock();
        AtendimentoContextResolverService.activeChannelRoutesOverride = null;
        AtendimentoContextResolverHelper.globalDescribeCache = null;
        AtendimentoContextResolverHelper.fieldMapCacheByObject.clear();
    }

    private static TCO_ChannelRouting__mdt buildRoute(String type, String identifier, String businessUnit) {
        TCO_ChannelRouting__mdt row = new TCO_ChannelRouting__mdt();
        row.TCF_ChannelType__c = type;
        row.TCF_ChannelIdentifier__c = identifier;
        row.TCF_BusinessUnit__c = businessUnit;
        row.TCF_IsActive__c = true;
        return row;
    }

    @IsTest
    static void shouldResolveFromContactWithAccount() {
        resetResolverTestState();
        Account acc = createAccount('WS Account');
        Contact con = createContact('Ana', 'Cliente', acc.Id);

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.contactId = con.Id;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, out.size());
        Assert.areEqual(true, out[0].needsCustomerInput);
        Assert.areEqual('BUSINESS_UNIT_NOT_FOUND', out[0].statusCode);
        Assert.areEqual(con.Id, out[0].contactId);
        Assert.areEqual(acc.Id, out[0].accountId);
    }

    @IsTest
    static void shouldReturnContactWithoutAccount() {
        resetResolverTestState();
        Contact con = createContact('Bruno', 'SemConta', null);

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.contactId = con.Id;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual('CONTACT_WITHOUT_ACCOUNT', out[0].statusCode);
        Assert.areEqual('ASK_ACCOUNT_IDENTIFICATION', out[0].nextAction);
    }

    @IsTest
    static void shouldHandleMessagingRoutableId() {
        resetResolverTestState();
        Account acc = createAccount('WS Account 2');
        Contact con = createContact('Carla', 'Messaging', acc.Id);

        GatewayMock mock = new GatewayMock();
        Id messagingId = (Id) '0Mw000000000001AAA';
        SObject row = Schema.getGlobalDescribe().containsKey('MessagingSession')
            ? Schema.getGlobalDescribe().get('MessagingSession').newSObject(messagingId)
            : null;
        if (row != null) {
            row.put('Id', messagingId);
            if (row.getSObjectType().getDescribe().fields.getMap().containsKey('ContactId')) {
                row.put('ContactId', con.Id);
            }
            mock.messaging.put(messagingId, row);
        }

        AtendimentoContextResolverService.gateway = mock;

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.routableId = messagingId;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(messagingId, out[0].conversationId);
    }

    @IsTest
    static void shouldHandleLiveChatRoutableId() {
        resetResolverTestState();
        Account acc = createAccount('WS Account 3');
        Contact con = createContact('Diego', 'LiveChat', acc.Id);

        GatewayMock mock = new GatewayMock();
        Id chatId = (Id) '570000000000001AAA';
        SObject row = Schema.getGlobalDescribe().containsKey('LiveChatTranscript')
            ? Schema.getGlobalDescribe().get('LiveChatTranscript').newSObject(chatId)
            : null;
        if (row != null) {
            row.put('Id', chatId);
            if (row.getSObjectType().getDescribe().fields.getMap().containsKey('ContactId')) {
                row.put('ContactId', con.Id);
            }
            mock.liveChat.put(chatId, row);
        }

        AtendimentoContextResolverService.gateway = mock;

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.channelType = 'CHAT';
        req.routableId = chatId;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(chatId, out[0].conversationId);
    }

    @IsTest
    static void shouldReturnInvalidInputWhenNoData() {
        resetResolverTestState();
        AtendimentoContextResolverDTO.Request req = new AtendimentoContextResolverDTO.Request();

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual('INVALID_INPUT', out[0].statusCode);
        Assert.areEqual('CONTINUE_WITH_LIMITED_CONTEXT', out[0].nextAction);
    }

    @IsTest
    static void shouldBeBulkSafe() {
        resetResolverTestState();
        Account acc = createAccount('WS Bulk');
        Contact c1 = createContact('Elisa', 'Bulk1', acc.Id);
        Contact c2 = createContact('Fabio', 'Bulk2', acc.Id);

        AtendimentoContextResolverDTO.Request r1 = baseRequest();
        r1.contactId = c1.Id;

        AtendimentoContextResolverDTO.Request r2 = baseRequest();
        r2.contactId = c2.Id;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ r1, r2 });
        Test.stopTest();

        Assert.areEqual(2, out.size());
        Assert.areEqual(c1.Id, out[0].contactId);
        Assert.areEqual(c2.Id, out[1].contactId);
    }

    @IsTest
    static void shouldResolveSuccessWithoutConversationWhenRouteExists() {
        resetResolverTestState();
        Account acc = createAccount('WS Success');
        Contact con = createContact('Gabi', 'Sucesso', acc.Id);

        AtendimentoContextResolverService.activeChannelRoutesOverride = new List<TCO_ChannelRouting__mdt>{
            buildRoute('WHATSAPP', null, 'Atendimento Salvador')
        };

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.contactId = con.Id;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual('SUCCESS_WITHOUT_CONVERSATION', out[0].statusCode);
        Assert.areEqual('Atendimento Salvador', out[0].businessUnitName);
        Assert.areEqual('CONTINUE_TO_MAIN_MENU', out[0].nextAction);
    }

    @IsTest
    static void shouldReturnConversationNotFoundWhenGatewayHasNoRow() {
        resetResolverTestState();
        AtendimentoContextResolverService.gateway = new EmptyGatewayMock();

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.routableId = (Id) '0Mw000000000004AAA';

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual('CONTACT_NOT_FOUND', out[0].statusCode);
        Assert.areEqual('ASK_CONTACT_IDENTIFICATION', out[0].nextAction);
        Assert.areEqual(req.routableId, out[0].conversationId);
    }

    @IsTest
    static void shouldApplyUnexpectedErrorWhenGatewayThrows() {
        resetResolverTestState();
        AtendimentoContextResolverService.gateway = new ThrowingGatewayMock();

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.routableId = (Id) '0Mw000000000005AAA';

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(false, out[0].success);
        Assert.areEqual('UNEXPECTED_ERROR', out[0].statusCode);
        Assert.areEqual('TRANSFER_TO_SPECIALIST', out[0].nextAction);
        Assert.areEqual('Contact,BusinessUnit', out[0].missingInformation);
    }

    @IsTest
    static void shouldHandleNullRequestInsideList() {
        resetResolverTestState();

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(
            new List<AtendimentoContextResolverDTO.Request>{ null }
        );
        Test.stopTest();

        Assert.areEqual(1, out.size());
        Assert.areEqual('INVALID_INPUT', out[0].statusCode);
        Assert.areEqual('Contact,BusinessUnit', out[0].missingInformation);
    }

    @IsTest
    static void shouldReturnMultipleContactsFoundWhenDirectAndLiveChatDiffer() {
        resetResolverTestState();
        Account acc = createAccount('WS Multiple');
        Contact directContact = createContact('Igor', 'Direct', acc.Id);
        Contact conversationContact = createContact('Julia', 'Conversation', acc.Id);

        GatewayMock mock = new GatewayMock();
        Id chatId = (Id) '570000000000007AAA';
        SObject row = Schema.getGlobalDescribe().containsKey('LiveChatTranscript')
            ? Schema.getGlobalDescribe().get('LiveChatTranscript').newSObject(chatId)
            : null;
        if (row != null) {
            row.put('Id', chatId);
            if (row.getSObjectType().getDescribe().fields.getMap().containsKey('ContactId')) {
                row.put('ContactId', conversationContact.Id);
            }
            mock.liveChat.put(chatId, row);
        }

        AtendimentoContextResolverService.gateway = mock;
        AtendimentoContextResolverService.activeChannelRoutesOverride = new List<TCO_ChannelRouting__mdt>{
            buildRoute('CHAT', String.valueOf(chatId), 'Atendimento Salvador')
        };

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.channelType = 'CHAT';
        req.contactId = directContact.Id;
        req.routableId = chatId;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(false, out[0].success);
        Assert.areEqual('MULTIPLE_CONTACTS_FOUND', out[0].statusCode);
        Assert.areEqual('ASK_CONTACT_DISAMBIGUATION', out[0].nextAction);
        Assert.areEqual(conversationContact.Id, out[0].conversationContactId);
        Assert.areEqual('Atendimento Salvador', out[0].businessUnitName);
    }

    @IsTest
    static void shouldUseDefaultGatewayWhenConversationDoesNotExist() {
        resetResolverTestState();
        AtendimentoContextResolverService.restoreDefaultGateway();

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.routableId = (Id) '0Mw000000000008AAA';

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(new List<AtendimentoContextResolverDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(false, out[0].success);
        Assert.areEqual('CONTACT_NOT_FOUND', out[0].statusCode);
        Assert.areEqual(req.routableId, out[0].conversationId);
    }

    @IsTest
    static void shouldCoverHelperIsIdOfType() {
        Id caseId = [SELECT Id FROM Case LIMIT 1]?.Id;
        if (caseId == null) {
            Case c = new Case(Subject = 'helper test');
            insert c;
            caseId = c.Id;
        }

        Assert.areEqual(true, AtendimentoContextResolverHelper.isIdOfType(caseId, 'Case'));
        Assert.areEqual(false, AtendimentoContextResolverHelper.isIdOfType(caseId, 'Contact'));
        Assert.areEqual(false, AtendimentoContextResolverHelper.isIdOfType(null, 'Case'));
        Assert.areEqual(false, AtendimentoContextResolverHelper.isIdOfType(caseId, null));
    }

    @IsTest
    static void shouldCoverHelperFirstExistingField() {
        String found = AtendimentoContextResolverHelper.firstExistingField('Case', new List<String>{ 'Subject', 'Status' });
        Assert.isNotNull(found);

        String notFound = AtendimentoContextResolverHelper.firstExistingField('Case', new List<String>{ 'FieldThatDoesNotExist12345' });
        Assert.isNull(notFound);

        Assert.isNull(AtendimentoContextResolverHelper.firstExistingField(null, new List<String>{ 'Subject' }));
        Assert.isNull(AtendimentoContextResolverHelper.firstExistingField('NonExistentObject99', new List<String>{ 'Subject' }));
    }

    @IsTest
    static void shouldCoverHelperChannelDisplayName() {
        Assert.areEqual('WhatsApp', AtendimentoContextResolverHelper.channelDisplayName(AtendimentoContextResolverHelper.CHANNEL_WHATSAPP));
        Assert.areEqual('Chat', AtendimentoContextResolverHelper.channelDisplayName(AtendimentoContextResolverHelper.CHANNEL_CHAT));
        Assert.areEqual('Messaging', AtendimentoContextResolverHelper.channelDisplayName(AtendimentoContextResolverHelper.CHANNEL_MESSAGING));
        Assert.areEqual('Unknown', AtendimentoContextResolverHelper.channelDisplayName('anything_else'));
    }

    @IsTest
    static void shouldHandleRequestWithEndUserId() {
        resetResolverTestState();
        Account acc = createAccount('EndUser Coverage');
        Contact con = createContact('EU', 'Coverage', acc.Id);

        AtendimentoContextResolverDTO.Request req = new AtendimentoContextResolverDTO.Request();
        req.channelType = 'WHATSAPP';
        req.endUserId = con.Id;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(
            new List<AtendimentoContextResolverDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, out.size());
        Assert.areEqual(true, out[0] != null);
    }

    @IsTest
    static void shouldReturnNullBusinessUnitWhenNoRouteMatches() {
        resetResolverTestState();
        Account acc = createAccount('No Match Route');
        Contact con = createContact('NR', 'Test', acc.Id);

        AtendimentoContextResolverService.activeChannelRoutesOverride = new List<TCO_ChannelRouting__mdt>{
            buildRoute('CHAT', null, 'Atendimento Salvador')
        };

        AtendimentoContextResolverDTO.Request req = baseRequest();
        req.contactId = con.Id;

        Test.startTest();
        List<AtendimentoContextResolverDTO.Response> out = AtendimentoContextResolverInvocable.resolve(
            new List<AtendimentoContextResolverDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(true, out[0] != null);
        Assert.isNull(out[0].businessUnitName);
    }
}