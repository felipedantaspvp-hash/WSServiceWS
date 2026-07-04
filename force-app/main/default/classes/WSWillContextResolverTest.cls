@IsTest
private class WSWillContextResolverTest {
    private static final Id SESSION_ID = Id.valueOf('0Mw000000000001');
    private static final Id END_USER_ID = Id.valueOf('0PA000000000001');
    private static final Id LIVE_CHAT_ID = Id.valueOf('570000000000001');

    @IsTest
    static void shouldResolveContactLanguageAndAccountFromMessagingSession() {
        Account accountRow = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Contexto' });
        Contact contactRow = TestDataFactory.createContact(accountRow.Id, new Map<String, Object>{
            'LastName' => 'Cliente Contexto',
            'Idioma__c' => 'pt_BR',
            'Email' => 'contexto@test.com',
            'Phone' => '11999990001'
        });

        Id messagingChannelId = Id.valueOf('0Mj000000000001');
        SObject sessionRow = fakeSession(
            SESSION_ID,
            END_USER_ID,
            contactRow.Id,
            'EmbeddedMessaging',
            'cf914b48-3307-4e00-8326-28d47105fb0c',
            messagingChannelId
        );
        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>{
            SESSION_ID => sessionRow
        };
        WSWillContextResolverService.testMessagingChannelById = new Map<Id, SObject>{
            messagingChannelId => fakeChannel(messagingChannelId, 'WS_TSV_WebChat', 'WS_TSV_WebChat')
        };
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, contactRow.Id)
        };
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>();
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>{
            buildConfig('Tecon Salvador', null, null, 'WS_TSV_WebChat', 'WebChat')
        };

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(SESSION_ID);

        Test.startTest();
        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverInvocable.resolve(
            new List<WSWillContextResolverDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual(contactRow.Id, res[0].contactId);
        Assert.areEqual(contactRow.Id, res[0].conversationContactId);
        Assert.areEqual(accountRow.Id, res[0].accountId);
        Assert.areEqual('Conta Contexto', res[0].accountName);
        Assert.areEqual('pt_BR', res[0].preferredLanguage);
        Assert.areEqual(false, res[0].shouldAskLanguage);
        Assert.areEqual('Messaging', res[0].channelName);
        Assert.areEqual('Tecon Salvador', res[0].businessUnitName);
        Assert.areEqual('PARAMETROS_ATENDIMENTO', res[0].businessUnitSource);

        WSWillContextResolverService.testAtendimentoParams = null;
        WSWillContextResolverService.testMessagingChannelById = null;
    }

    @IsTest
    static void shouldResolveContactFromEndUserWhenSessionDoesNotExposeContact() {
        Contact contactRow = TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'Cliente EndUser',
            'Idioma__c' => 'en_US',
            'Phone' => '11999990002'
        });

        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>{
            SESSION_ID => fakeSession(SESSION_ID, END_USER_ID, null, 'Chat', null)
        };
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, contactRow.Id)
        };
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>();
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>();

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(SESSION_ID);

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ req }
        );

        Assert.areEqual(contactRow.Id, res[0].contactId);
        Assert.areEqual(contactRow.Id, res[0].conversationContactId);
        Assert.areEqual('en_US', res[0].preferredLanguage);
        Assert.areEqual('Chat', res[0].channelName);
        WSWillContextResolverService.testAtendimentoParams = null;
    }

    @IsTest
    static void shouldResolveWhatsappContactAndLanguageFromMessagingPlatformKey() {
        Account accountRow = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta WhatsApp' });
        Contact contactRow = TestDataFactory.createContact(accountRow.Id, new Map<String, Object>{
            'LastName' => 'Cliente WhatsApp',
            'MobilePhone' => '21980792973',
            'Idioma__c' => 'pt_BR'
        });

        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>{
            SESSION_ID => fakeSession(SESSION_ID, END_USER_ID, null, 'WhatsApp', 'WhatsAppTeconSalvador')
        };
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, null, '5521980792973')
        };
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>();
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>{
            buildConfig('Centro Logístico', null, null, 'WS_CL_WebChat', 'WebChat', 'WhatsAppCentroLogistico'),
            buildConfig('Tecon Salvador', null, null, 'WS_TSV_WebChat', 'WebChat', 'WhatsAppTeconSalvador')
        };

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(SESSION_ID);

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ req }
        );

        Assert.areEqual(contactRow.Id, res[0].contactId, 'WhatsApp should resolve contact by DDI+DDD+number platform key.');
        Assert.areEqual(contactRow.Id, res[0].conversationContactId, 'Resolved contact should be returned as conversation contact.');
        Assert.areEqual(accountRow.Id, res[0].accountId, 'Resolved contact account should be returned.');
        Assert.areEqual('pt_BR', res[0].preferredLanguage, 'Resolved WhatsApp contact language should be reused.');
        Assert.areEqual(false, res[0].shouldAskLanguage, 'Bot should not ask language when contact already has one.');
        Assert.areEqual('WhatsApp', res[0].channelName, 'WhatsApp channel name should be preserved.');
        Assert.areEqual('Tecon Salvador', res[0].businessUnitName, 'WhatsApp channel config should resolve business unit.');

        WSWillContextResolverService.testAtendimentoParams = null;
    }

    @IsTest
    static void shouldNotFallbackToFirstBusinessUnitWhenWhatsappChannelIsUnmapped() {
        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>{
            SESSION_ID => fakeSession(SESSION_ID, END_USER_ID, null, 'WhatsApp', 'WhatsAppCanalNovo')
        };
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, null, '5521980792973')
        };
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>();
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>{
            buildConfig('Centro Logístico', null, null, 'WS_CL_WebChat', 'WebChat'),
            buildConfig('Tecon Salvador', null, null, 'WS_TSV_WebChat', 'WebChat')
        };

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(SESSION_ID);

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ req }
        );

        Assert.areEqual(null, res[0].businessUnitName, 'Unmapped WhatsApp channels must not fallback to the first active config.');
        Assert.areEqual('UNRESOLVED', res[0].businessUnitSource);

        WSWillContextResolverService.testAtendimentoParams = null;
    }

    @IsTest
    static void shouldReuseEndUserLanguageWhenContactIsNotVisible() {
        Id contactId = Id.valueOf('003000000000001');
        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>();
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, contactId, null, 'pt_BR')
        };
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>();
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>();

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.endUserId = String.valueOf(END_USER_ID);
        req.channelType = 'WhatsApp';

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ req }
        );

        Assert.areEqual('pt_BR', res[0].preferredLanguage, 'MessagingEndUser language should be reused when contact is not returned.');
        Assert.areEqual(false, res[0].shouldAskLanguage, 'Bot should not ask language when MessagingEndUser already has one.');

        WSWillContextResolverService.testAtendimentoParams = null;
    }

    @IsTest
    static void shouldExerciseRealFetchFallbacksWhenNoTestSeamIsProvided() {
        WSWillContextResolverService.testMessagingById = null;
        WSWillContextResolverService.testEndUserById = null;
        WSWillContextResolverService.testLiveChatById = null;
        WSWillContextResolverService.testAtendimentoParams = null;

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(SESSION_ID);
        req.endUserId = String.valueOf(END_USER_ID);
        req.channelType = 'EmbeddedMessaging';

        WSWillContextResolverDTO.Request invalidIdReq = new WSWillContextResolverDTO.Request();
        invalidIdReq.routableId = '!!!!!!!!!!!!!!!';

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ req, invalidIdReq }
        );

        Assert.areEqual(2, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual('Messaging', res[0].channelName);
        Assert.areEqual(true, res[0].shouldAskLanguage);
        Assert.areEqual(true, res[1].success);
    }

    @IsTest
    static void shouldCoverUtilityBranches() {
        Account accountRow = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Fetch' });

        Map<Id, SObject> fetched = WSWillContextResolverService.fetchByIds(
            'Account',
            new Set<Id>{ accountRow.Id },
            new Set<String>{ 'Id', 'Name', 'CampoInexistente__c' }
        );

        Assert.areEqual(accountRow.Id, fetched.get(accountRow.Id).get('Id'));
        Assert.areEqual('Conta Fetch', WSWillContextResolverService.getStringSafe(fetched.get(accountRow.Id), 'Name'));
        Assert.areEqual(null, WSWillContextResolverService.getStringSafe(fetched.get(accountRow.Id), 'CampoInexistente__c'));
        Assert.areEqual(null, WSWillContextResolverService.parseId('!!!!!!!!!!!!!!!'));
    }

    @IsTest
    static void shouldHandleLiveChatAndLimitedContext() {
        Contact contactRow = TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'Cliente Live',
            'Phone' => '11999990003'
        });

        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>();
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>();
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>{
            LIVE_CHAT_ID => fakeLiveChat(LIVE_CHAT_ID, contactRow.Id)
        };
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>();

        WSWillContextResolverDTO.Request liveReq = new WSWillContextResolverDTO.Request();
        liveReq.routableId = String.valueOf(LIVE_CHAT_ID);
        liveReq.channelType = 'CHAT';

        WSWillContextResolverDTO.Request limitedReq = new WSWillContextResolverDTO.Request();
        limitedReq.channelType = 'WHATSAPP';

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ liveReq, limitedReq, null }
        );

        Assert.areEqual(3, res.size());
        Assert.areEqual(contactRow.Id, res[0].contactId);
        Assert.areEqual(true, res[0].shouldAskLanguage);
        Assert.areEqual('WhatsApp', res[1].channelName);
        Assert.areEqual(true, res[1].shouldAskLanguage);
        Assert.areEqual(true, res[2].success);
    }

    @IsTest
    static void shouldReturnEmptyForEmptyRequests() {
        WSWillContextResolverService.testAtendimentoParams = null;
        Assert.areEqual(0, WSWillContextResolverService.resolve(null).size());
        Assert.areEqual(0, WSWillContextResolverService.resolve(new List<WSWillContextResolverDTO.Request>()).size());
    }

    @IsTest
    static void shouldCoverHelperBranches() {
        Assert.areEqual('pt_BR', WSWillContextResolverHelper.normalizePreferredLanguage(' português '));
        Assert.areEqual('en_US', WSWillContextResolverHelper.normalizePreferredLanguage('english'));
        Assert.areEqual(null, WSWillContextResolverHelper.normalizePreferredLanguage('fr'));
        Assert.areEqual('UNRESOLVED', WSWillContextResolverHelper.inferBusinessUnitSource(false, SESSION_ID));
        Assert.areEqual('CHANNEL_ROUTING_METADATA', WSWillContextResolverHelper.inferBusinessUnitSource(true, SESSION_ID));
        Assert.areEqual('PARAMETROS_ATENDIMENTO', WSWillContextResolverHelper.inferBusinessUnitSource(true, null, 'PARAMETROS_ATENDIMENTO'));
        Assert.areEqual('CONTACT_OR_CHANNEL', WSWillContextResolverHelper.inferBusinessUnitSource(true, null));
        Assert.areEqual('SUCCESS_WITH_LIMITED_CONTEXT', WSWillContextResolverHelper.computeSuccessStatus(null, null, null));
        Assert.areEqual('SUCCESS_WITHOUT_CONTACT', WSWillContextResolverHelper.computeSuccessStatus(null, null, 'Tecon Salvador'));
        Assert.areEqual('SUCCESS_WITHOUT_BUSINESS_UNIT', WSWillContextResolverHelper.computeSuccessStatus(null, SESSION_ID, null));
        Assert.areEqual('SUCCESS', WSWillContextResolverHelper.computeSuccessStatus(null, SESSION_ID, 'Tecon Salvador'));
        Assert.areEqual('CASE_ERROR', WSWillContextResolverHelper.computeSuccessStatus('CASE_ERROR', SESSION_ID, 'Tecon Salvador'));
    }

    @IsTest
    static void shouldResolveBusinessUnitFromAtendimentoParamsWhenRoutingMetadataIsEmpty() {
        Contact contactRow = TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'Cliente BU',
            'Idioma__c' => 'pt_BR',
            'Phone' => '11999990004'
        });

        WSWillContextResolverService.testMessagingById = new Map<Id, SObject>{
            SESSION_ID => fakeSession(SESSION_ID, END_USER_ID, contactRow.Id, 'EmbeddedMessaging', 'WS_TSA_WebChat')
        };
        WSWillContextResolverService.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, contactRow.Id)
        };
        WSWillContextResolverService.testLiveChatById = new Map<Id, SObject>();
        WSWillContextResolverService.testAtendimentoParams = new List<AtendimentoConfigDTO>{
            buildConfig('Tecon Salvador', null, null, 'WS_TSA_WebChat', 'WebChat')
        };

        WSWillContextResolverDTO.Request req = new WSWillContextResolverDTO.Request();
        req.routableId = String.valueOf(SESSION_ID);

        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverService.resolve(
            new List<WSWillContextResolverDTO.Request>{ req }
        );

        Assert.areEqual('Tecon Salvador', res[0].businessUnitName);
        Assert.areEqual('PARAMETROS_ATENDIMENTO', res[0].businessUnitSource);

        WSWillContextResolverService.testAtendimentoParams = null;
    }

    @IsTest
    static void shouldReturnFallbackWhenServiceThrows() {
        ApexTestSeam.set('WSWillContextResolverService.throwException', true);

        Test.startTest();
        List<WSWillContextResolverDTO.Response> res = WSWillContextResolverInvocable.resolve(
            new List<WSWillContextResolverDTO.Request>{ new WSWillContextResolverDTO.Request() }
        );
        Test.stopTest();

        ApexTestSeam.clear('WSWillContextResolverService.throwException');

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual('UNRESOLVED', res[0].businessUnitSource);
        Assert.areEqual(true, res[0].shouldAskLanguage);
    }

    private static SObject fakeSession(Id sessionId, Id endUserId, Id contactId, String channelType, String channelKey) {
        return fakeSession(sessionId, endUserId, contactId, channelType, channelKey, null);
    }

    private static AtendimentoConfigDTO buildConfig(
        String businessUnit,
        String recordTypeDeveloperName,
        String queueDeveloperName,
        String channelDeveloperName,
        String channelType
    ) {
        return buildConfig(businessUnit, recordTypeDeveloperName, queueDeveloperName, channelDeveloperName, channelType, null);
    }

    private static AtendimentoConfigDTO buildConfig(
        String businessUnit,
        String recordTypeDeveloperName,
        String queueDeveloperName,
        String channelDeveloperName,
        String channelType,
        String whatsAppChannelDeveloperName
    ) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = businessUnit;
        config.masterLabel = businessUnit;
        config.developerName = channelDeveloperName;
        config.caseRecordTypeDeveloperName = recordTypeDeveloperName;
        config.defaultQueueDeveloperName = queueDeveloperName;
        config.messagingChannelDeveloperName = channelDeveloperName;
        config.whatsAppChannelDeveloperName = whatsAppChannelDeveloperName;
        config.messagingChannelType = channelType;
        config.isActive = true;
        return config;
    }

    private static SObject fakeSession(Id sessionId, Id endUserId, Id contactId, String channelType, String channelKey, Id messagingChannelId) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingSession' },
            'Id' => String.valueOf(sessionId)
        };
        if (endUserId != null) payload.put('MessagingEndUserId', String.valueOf(endUserId));
        if (contactId != null) payload.put('EndUserContactId', String.valueOf(contactId));
        if (channelType != null) payload.put('ChannelType', channelType);
        if (channelKey != null) payload.put('ChannelKey', channelKey);
        if (messagingChannelId != null) payload.put('MessagingChannelId', String.valueOf(messagingChannelId));
        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

    private static SObject fakeEndUser(Id endUserId, Id contactId) {
        return fakeEndUser(endUserId, contactId, null);
    }

    private static SObject fakeEndUser(Id endUserId, Id contactId, String messagingPlatformKey) {
        return fakeEndUser(endUserId, contactId, messagingPlatformKey, null);
    }

    private static SObject fakeEndUser(Id endUserId, Id contactId, String messagingPlatformKey, String language) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingEndUser' },
            'Id' => String.valueOf(endUserId)
        };
        if (contactId != null) payload.put('ContactId', String.valueOf(contactId));
        if (messagingPlatformKey != null) payload.put('MessagingPlatformKey', messagingPlatformKey);
        if (language != null) payload.put('Language', language);
        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

    private static SObject fakeLiveChat(Id liveChatId, Id contactId) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'LiveChatTranscript' },
            'Id' => String.valueOf(liveChatId)
        };
        if (contactId != null) payload.put('ContactId', String.valueOf(contactId));
        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

    private static SObject fakeChannel(Id channelId, String developerName, String masterLabel) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingChannel' },
            'Id' => String.valueOf(channelId)
        };
        if (developerName != null) payload.put('DeveloperName', developerName);
        if (masterLabel != null) payload.put('MasterLabel', masterLabel);
        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

}