@IsTest
private class ContactWhatsappMessageControllerTest {
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'WhatsApp Action Test',
            'Phone' => '+5511999990000'
        });
    }

    @IsTest
    static void shouldReturnEmptyCandidatesWhenContactHasNoWhatsAppMessagingUser() {
        setAllowedWhatsAppConfigs(new Map<String, String>{
            'Atendimento Tecon Salvador' => 'ContactWhatsAppActionTest'
        }, new Set<String>{ 'Atendimento Tecon Salvador' });
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        ContactWhatsappMessageDTO result = ContactWhatsappMessageController.getContext(contactRecord.Id);
        Test.stopTest();

        Assert.areEqual(contactRecord.Id, result.contactId, 'The Contact id should be returned.');
        Assert.areEqual(false, result.hasCandidates, 'No WhatsApp candidates should be found.');
        Assert.areEqual(0, result.candidates.size(), 'Candidate list should be empty.');
        Assert.areEqual(null, result.errorMessage, 'No functional error should be returned.');
    }

    @IsTest
    static void shouldReturnCandidateWhenServiceFindsEligibleMessagingUser() {
        setAllowedWhatsAppConfigs(new Map<String, String>{
            'Atendimento Tecon Salvador' => 'ContactWhatsAppActionTest'
        }, new Set<String>{ 'Atendimento Tecon Salvador' });
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        MessagingChannel channel = new MessagingChannel(
            DeveloperName = 'ContactWhatsAppActionTest',
            MasterLabel = 'Contact WhatsApp Action Test',
            MessageType = 'WhatsApp',
            MessagingPlatformKey = 'contact-whatsapp-action-test'
        );
        insert channel;
        MessagingEndUser endUser = new MessagingEndUser(
            Name = 'Cliente WhatsApp',
            ContactId = contactRecord.Id,
            MessagingChannelId = channel.Id,
            MessageType = 'WhatsApp',
            MessagingPlatformKey = '5511999999999',
            MessagingConsentStatus = 'ImplicitlyOptedIn'
        );
        insert endUser;

        Test.startTest();
        ContactWhatsappMessageDTO result = ContactWhatsappMessageController.getContext(contactRecord.Id);
        Test.stopTest();

        Assert.areEqual(true, result.hasCandidates, 'The DTO should indicate available candidates.');
        Assert.areEqual(1, result.candidates.size(), 'One test candidate should be returned.');
        Assert.areEqual(endUser.Id, result.candidates[0].messagingEndUserId, 'The candidate id should match.');
        Assert.areEqual(channel.Id, result.candidates[0].messagingChannelId, 'The channel id should match.');
        Assert.areEqual(channel.MasterLabel, result.candidates[0].messagingChannelName, 'The channel label should match.');
        Assert.areEqual(endUser.MessagingPlatformKey, result.candidates[0].messagingPlatformKey, 'The platform key should match.');
        Assert.areEqual(true, result.candidates[0].recommended, 'The first candidate should be recommended.');
    }

    @IsTest
    static void shouldHideWhatsAppChannelWhenBusinessUnitIsNotAllowed() {
        setAllowedWhatsAppConfigs(new Map<String, String>{
            'Atendimento Tecon Salvador' => 'ContactWhatsAppActionAllowed',
            'Atendimento Tecon Rio Grande' => 'ContactWhatsAppActionBlocked'
        }, new Set<String>{ 'Atendimento Tecon Salvador' });
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        MessagingChannel allowedChannel = createChannel('ContactWhatsAppActionAllowed', 'WhatsApp Allowed');
        MessagingChannel blockedChannel = createChannel('ContactWhatsAppActionBlocked', 'WhatsApp Blocked');
        insert new List<MessagingEndUser>{
            buildEndUser(contactRecord.Id, allowedChannel.Id, '5511999991111'),
            buildEndUser(contactRecord.Id, blockedChannel.Id, '5511999992222')
        };

        Test.startTest();
        ContactWhatsappMessageDTO result = ContactWhatsappMessageController.getContext(contactRecord.Id);
        Test.stopTest();

        Assert.areEqual(true, result.hasCandidates, 'The allowed unit channel should be returned.');
        Assert.areEqual(1, result.candidates.size(), 'Only channels for allowed business units should be returned.');
        Assert.areEqual(allowedChannel.Id, result.candidates[0].messagingChannelId, 'The allowed channel should remain visible.');
        Assert.areEqual('5511999991111', result.candidates[0].messagingPlatformKey, 'The blocked channel phone must not leak.');
    }

    @IsTest
    static void shouldReturnFunctionalErrorWhenContactIdIsMissing() {
        setAllowedWhatsAppConfigs(new Map<String, String>(), new Set<String>());
        Test.startTest();
        ContactWhatsappMessageDTO result = ContactWhatsappMessageController.getContext(null);
        Test.stopTest();

        Assert.areEqual(false, result.hasCandidates, 'Missing Contact should not return candidates.');
        Assert.areEqual(Label.ContactWhatsApp_ErrorContactRequired, result.errorMessage, 'The functional error should be localized.');
    }

    @IsTest
    static void shouldReturnUnexpectedErrorWhenUnexpectedExceptionOccurs() {
        setAllowedWhatsAppConfigs(new Map<String, String>(), new Set<String>());
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        ContactWhatsappMessageController.forceUnexpectedErrorForTest = true;

        Test.startTest();
        ContactWhatsappMessageDTO result = ContactWhatsappMessageController.getContext(contactRecord.Id);
        Test.stopTest();

        Assert.areEqual(Label.ContactWhatsApp_ErrorUnexpected, result.errorMessage, 'Unexpected errors should be sanitized.');
    }

    private static MessagingChannel createChannel(String developerName, String masterLabel) {
        MessagingChannel channel = new MessagingChannel(
            DeveloperName = developerName,
            MasterLabel = masterLabel,
            MessageType = 'WhatsApp',
            MessagingPlatformKey = developerName.toLowerCase()
        );
        insert channel;
        return channel;
    }

    private static MessagingEndUser buildEndUser(Id contactId, Id channelId, String platformKey) {
        return new MessagingEndUser(
            Name = 'Cliente WhatsApp ' + platformKey.right(4),
            ContactId = contactId,
            MessagingChannelId = channelId,
            MessageType = 'WhatsApp',
            MessagingPlatformKey = platformKey,
            MessagingConsentStatus = 'ImplicitlyOptedIn'
        );
    }

    private static void setAllowedWhatsAppConfigs(Map<String, String> channelByBusinessUnit, Set<String> allowedBusinessUnits) {
        List<AtendimentoConfigDTO> configs = new List<AtendimentoConfigDTO>();
        for (String businessUnit : channelByBusinessUnit.keySet()) {
            AtendimentoConfigDTO config = new AtendimentoConfigDTO();
            config.businessUnit = businessUnit;
            config.isActive = true;
            config.caseRecordTypeDeveloperName = businessUnit.replace(' ', '_');
            config.whatsAppChannelDeveloperName = channelByBusinessUnit.get(businessUnit);
            configs.add(config);
        }
        AtendimentoConfigService.setTestSurveyConfigs(configs);
        GestaoSLAHelper.setAllowedUnidadesOverride(allowedBusinessUnits);
    }
}