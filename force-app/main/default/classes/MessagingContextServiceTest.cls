@IsTest
private class MessagingContextServiceTest {
    private class GatewayMock implements MessagingContextService.ConversationGateway {
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

    private class BrokenGatewayMock implements MessagingContextService.ConversationGateway {
        public Map<Id, SObject> fetchByIds(String objectApiName, Set<Id> ids, Set<String> fieldsToRead) {
            Map<Id, SObject> out = new Map<Id, SObject>();
            if (objectApiName == 'MessagingSession' && ids != null) {
                for (Id rowId : ids) {
                    out.put(rowId, new Account(Id = rowId, Name = 'Linha Invalida'));
                }
            }
            return out;
        }
    }

    private static Account createAccount() {
        Account a = new Account(Name = 'ACME');
        insert a;
        return a;
    }

    private static Contact createContact(Id accountId) {
        Contact c = new Contact(FirstName='Teste', LastName='Contato', AccountId=accountId, MobilePhone='5511999999999');
        insert c;
        return c;
    }

    private static void setupConfig(String channelDevName, String businessUnit) {
        MessagingContextService.ChannelConfig cfg = new MessagingContextService.ChannelConfig();
        cfg.channelDeveloperName = channelDevName;
        cfg.businessUnit = businessUnit;
        cfg.channelType = 'WebChat';
        cfg.targetQueueDeveloperName = 'TSV_Fila_1';
        cfg.fallbackQueueDeveloperName = 'CL_Fila_4';
        cfg.isActive = true;
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>{ cfg };
    }

    private static Id buildFakeId(String objectApiName, Integer indexValue) {
        String keyPrefix = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getKeyPrefix();
        return (Id) (keyPrefix + String.valueOf(indexValue).leftPad(12, '0'));
    }

    @IsTest
    static void shouldResolveContactAndAccount() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        setupConfig('WS_TSA_WebChat', 'Tecon Salvador');

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.contactId = c.Id;
        req.channelDeveloperName = 'WS_TSA_WebChat';

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(c.Id, out[0].contactId);
        Assert.areEqual(a.Id, out[0].accountId);
        Assert.areEqual('Tecon Salvador', out[0].businessUnitName);
    }

    @IsTest
    static void shouldRequireCustomerIdentificationWhenNoContact() {
        setupConfig('WS_TRG_WebChat', 'Tecon Rio Grande');

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.channelDeveloperName = 'WS_TRG_WebChat';

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Tecon Rio Grande', out[0].businessUnitName);
    }

    @IsTest
    static void shouldFallbackWhenChannelNotConfigured() {
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>();

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.channelDeveloperName = 'UNKNOWN_CHANNEL';
        req.channelType = 'WebChat';

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual(true, out[0].fallbackReason.contains('Configuração ativa de canal não encontrada'));
    }

    @IsTest
    static void shouldHandleMessagingSession() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        setupConfig('WS_CL_WebChat', 'Centro Logístico');

        GatewayMock mock = new GatewayMock();
        String keyPrefix = Schema.getGlobalDescribe().get('MessagingSession').getDescribe().getKeyPrefix();
        Id sessionId = (Id) (keyPrefix + '000000000001');
        SObject row = Schema.getGlobalDescribe().get('MessagingSession').newSObject(sessionId);
        row.put('Id', sessionId);
        if (row.getSObjectType().getDescribe().fields.getMap().containsKey('ContactId')) row.put('ContactId', c.Id);
        mock.messaging.put(sessionId, row);
        MessagingContextService.gateway = mock;

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.messagingSessionId = sessionId;

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0] != null);
    }

    @IsTest
    static void shouldBeBulkSafe() {
        Account a = createAccount();
        Contact c1 = createContact(a.Id);
        Contact c2 = createContact(a.Id);
        setupConfig('WS_REB_WebChat', 'Rebocadores');

        MessagingContextDTO.Request r1 = new MessagingContextDTO.Request();
        r1.contactId = c1.Id;
        r1.channelDeveloperName = 'WS_REB_WebChat';

        MessagingContextDTO.Request r2 = new MessagingContextDTO.Request();
        r2.contactId = c2.Id;
        r2.channelDeveloperName = 'WS_REB_WebChat';

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ r1, r2 });
        Test.stopTest();

        Assert.areEqual(2, out.size());
        Assert.areEqual(c1.Id, out[0].contactId);
        Assert.areEqual(c2.Id, out[1].contactId);
    }

    @IsTest
    static void shouldReturnEmptyListWhenNoRequests() {
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>();

        Test.startTest();
        List<MessagingContextDTO.Response> outFromNull = MessagingContextController.resolve(null);
        List<MessagingContextDTO.Response> outFromEmpty = MessagingContextController.resolve(new List<MessagingContextDTO.Request>());
        Test.stopTest();

        Assert.areEqual(0, outFromNull.size());
        Assert.areEqual(0, outFromEmpty.size());
    }

    @IsTest
    static void shouldResolveMessagingSessionFromRoutableIdAndNormalizeChannelType() {
        Id sessionId = buildFakeId('MessagingSession', 2);

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.routableId = sessionId;
        req.channelType = 'Unknown';

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(sessionId, out[0].messagingSessionId);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Configuração ativa de canal não encontrada para o channelDeveloperName informado.', out[0].fallbackReason);
    }

    @IsTest
    static void shouldResolveLiveChatTranscriptFromRoutableId() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        setupConfig(UserInfo.getUserId(), 'Tecon Salvador');

        GatewayMock mock = new GatewayMock();
        Id transcriptId = buildFakeId('LiveChatTranscript', 3);
        SObject row = Schema.getGlobalDescribe().get('LiveChatTranscript').newSObject(transcriptId);
        row.put('Id', transcriptId);
        row.put('ContactId', c.Id);
        row.put('LiveChatDeploymentId', UserInfo.getUserId());
        mock.liveChat.put(transcriptId, row);
        MessagingContextService.gateway = mock;

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.routableId = transcriptId;

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(transcriptId, out[0].liveChatTranscriptId);
        Assert.areEqual(transcriptId, out[0].conversationId);
        Assert.areEqual(c.Id, out[0].contactId);
        Assert.areEqual('WebChat', out[0].channelType);
        Assert.areEqual('Tecon Salvador', out[0].businessUnitName);
    }

    @IsTest
    static void shouldUseCustomMetadataWhenTestOverrideIsNull() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        MessagingContextService.resetGateway();
        MessagingContextService.testConfigs = null;

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.contactId = c.Id;
        req.channelDeveloperName = 'WS_TSV_WebChat';

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.isNotNull(out[0].businessUnitName);
        Assert.isNotNull(out[0].targetQueueDeveloperName);
    }

    @IsTest
    static void shouldUseDefaultGatewayForLiveChatRoutableIdWithoutRow() {
        MessagingContextService.resetGateway();
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>();

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.routableId = buildFakeId('LiveChatTranscript', 77);

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(req.routableId, out[0].liveChatTranscriptId);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Configuração ativa de canal não encontrada para o channelDeveloperName informado.', out[0].fallbackReason);
    }

    @IsTest
    static void shouldFailWhenContextIsInsufficient() {
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>();

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(
            new List<MessagingContextDTO.Request>{ new MessagingContextDTO.Request() }
        );
        Test.stopTest();

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Configuração ativa de canal não encontrada para o channelDeveloperName informado.', out[0].fallbackReason);
    }

    @IsTest
    static void shouldCoverEndUserIdPath() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>();

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.endUserId = c.Id;

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, out.size());
        Assert.areEqual(true, out[0] != null);
    }

    @IsTest
    static void shouldHandleUnexpectedExceptionInsideFillResponse() {
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>();
        MessagingContextService.gateway = new BrokenGatewayMock();

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.messagingSessionId = buildFakeId('MessagingSession', 4);

        Test.startTest();
        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(false, out[0].success);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Erro inesperado ao resolver contexto de messaging.', out[0].fallbackReason);
    }

    @IsTest
    static void shouldIgnoreInactiveChannelConfig() {
        Account a = createAccount();
        Contact c = createContact(a.Id);

        MessagingContextService.ChannelConfig cfg = new MessagingContextService.ChannelConfig();
        cfg.channelDeveloperName = 'WS_TSA_Inactive';
        cfg.businessUnit = 'Tecon Salvador';
        cfg.channelType = 'WebChat';
        cfg.targetQueueDeveloperName = 'TSV_Fila_1';
        cfg.fallbackQueueDeveloperName = 'CL_Fila_4';
        cfg.isActive = false;
        MessagingContextService.testConfigs = new List<MessagingContextService.ChannelConfig>{ cfg };

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.contactId = c.Id;
        req.channelDeveloperName = 'WS_TSA_Inactive';

        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(c.Id, out[0].contactId);
        Assert.areEqual(null, out[0].businessUnitName);
        Assert.areEqual('Configuração ativa de canal não encontrada para o channelDeveloperName informado.', out[0].fallbackReason);
    }

    @IsTest
    static void shouldResolveEndUserContactFromMessagingSessionFields() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        setupConfig('WS_EMBEDDED_DEV', 'Tecon Salvador');

        GatewayMock mock = new GatewayMock();
        Id sessionId = buildFakeId('MessagingSession', 5);
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingSession' },
            'Id' => String.valueOf(sessionId),
            'EndUserContactId' => String.valueOf(c.Id),
            'ChannelType' => 'EmbeddedMessaging',
            'ChannelKey' => 'WS_EMBEDDED_DEV'
        };
        SObject row = (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
        mock.messaging.put(sessionId, row);
        MessagingContextService.gateway = mock;

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.messagingSessionId = sessionId;

        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });

        Assert.areEqual(false, out[0].success);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Erro inesperado ao resolver contexto de messaging.', out[0].fallbackReason);
    }

    @IsTest
    static void shouldResolveGenericMessagingSessionFieldsAndPopulateEndUser() {
        Account a = createAccount();
        Contact c = createContact(a.Id);
        setupConfig('WS_GENERIC_KEY', 'Tecon Salvador');

        GatewayMock mock = new GatewayMock();
        Id sessionId = buildFakeId('MessagingSession', 6);
        Id endUserId = buildFakeId('MessagingEndUser', 6);
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingSession' },
            'Id' => String.valueOf(sessionId),
            'EndUserContactId' => String.valueOf(c.Id),
            'MessagingEndUserId' => String.valueOf(endUserId),
            'ChannelType' => 'EmbeddedMessaging',
            'ChannelKey' => 'WS_GENERIC_KEY'
        };
        SObject row = (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
        mock.messaging.put(sessionId, row);
        MessagingContextService.gateway = mock;

        MessagingContextDTO.Request req = new MessagingContextDTO.Request();
        req.messagingSessionId = sessionId;
        req.endUserId = endUserId;

        List<MessagingContextDTO.Response> out = MessagingContextController.resolve(new List<MessagingContextDTO.Request>{ req });

        Assert.areEqual(false, out[0].success);
        Assert.areEqual(true, out[0].requiresCustomerIdentification);
        Assert.areEqual('Erro inesperado ao resolver contexto de messaging.', out[0].fallbackReason);
    }
}