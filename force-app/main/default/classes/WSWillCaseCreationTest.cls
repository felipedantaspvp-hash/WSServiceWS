@IsTest
private class WSWillCaseCreationTest {
    private static final Id SESSION_ID = Id.valueOf('0Mw000000000004');
    private static final Id END_USER_ID = Id.valueOf('0PA000000000004');

    @IsTest
    static void shouldCreateCaseAndContact() {
        Account a = new Account(Name = 'Conta Caso Bot');
        insert a;
        Group queue = createCaseQueue('WSTEST_TSV_AtendimentoN1');

        WSWillCaseCreationService.testUnitConfigs = new List<AtendimentoConfigDTO>{
            buildConfig('Atendimento Tecon Salvador', 'AtendimentoTeconSalvador',queue.DeveloperName)
        };

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.accountId = a.Id;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'pt_BR';
        req.channelName = 'WhatsApp';
        req.origin = 'Bot';
        req.customerFullName = 'Maria Silva';
        req.customerEmail = 'maria.bot@test.com';
        req.customerPhone = '71999999999';
        req.caseType = 'Teste bot';
        req.description = 'Descricao de teste';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(new List<WSWillCaseCreationDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success, 'statusCode=' + res[0].statusCode + ' msg=' + res[0].message);
        Assert.areEqual(true, res[0].statusCode == 'SUCCESS' || res[0].statusCode == 'SUCCESS_WITHOUT_CONTACT');
        Assert.areEqual(false, res[0].caseId == null);
        Case createdCase = [
            SELECT Id, Origin, OwnerId, FilaDestinoDeveloperName__c, UnidadeNegocio__c, RecordType.DeveloperName
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual('Bot', createdCase.Origin);
        Assert.areEqual(queue.Id, createdCase.OwnerId);
        Assert.areEqual(queue.DeveloperName, createdCase.FilaDestinoDeveloperName__c);
        Assert.areEqual('Atendimento Tecon Salvador', createdCase.UnidadeNegocio__c);
        Assert.areEqual('AtendimentoTeconSalvador', createdCase.RecordType.DeveloperName);
        Assert.areEqual('Bot', WSWillCaseCreationHelper.normalizeDistributionOrigin());
        WSWillCaseCreationService.testUnitConfigs = null;
    }

    @IsTest
    static void shouldCreateCaseWithoutAccount() {
        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'en_US';
        req.channelName = 'Chat';
        req.origin = 'Chat';
        req.customerFullName = 'John Doe';
        req.customerEmail = 'john.bot@test.com';
        req.customerPhone = '71988887777';
        req.caseType = 'Support';
        req.description = 'Need help';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success, 'statusCode=' + res[0].statusCode + ' msg=' + res[0].message);
        Assert.areEqual(true, res[0].statusCode == 'SUCCESS' || res[0].statusCode == 'SUCCESS_WITHOUT_CONTACT');
        Assert.areEqual(false, res[0].caseId == null);
        Case createdCase = [
            SELECT Id, Origin, OwnerId, UnidadeNegocio__c, RecordType.DeveloperName
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual('Chat', createdCase.Origin);
        Assert.areEqual(UserInfo.getUserId(), createdCase.OwnerId);
        Assert.areEqual('Atendimento Tecon Salvador', createdCase.UnidadeNegocio__c);
        Assert.areEqual('AtendimentoTeconSalvador', createdCase.RecordType.DeveloperName);
    }

    @IsTest
    static void shouldReuseExistingContactByEmailAndUpdateLanguage() {
        Account a = new Account(Name = 'Conta Reuso');
        insert a;
        Contact existing = new Contact(
            LastName = 'Reuso',
            AccountId = a.Id,
            Email = 'reuse.bot@test.com',
            Phone = '71911112222',
            Idioma__c = 'pt_BR'
        );
        insert existing;

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.accountId = a.Id;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'en_US';
        req.channelName = 'Chat';
        req.customerFullName = 'Contato Reuso';
        req.customerEmail = 'reuse.bot@test.com';
        req.customerPhone = '71911112222';
        req.caseType = 'Support';
        req.description = 'Case com contato existente';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        Contact updated = [SELECT Id, Idioma__c FROM Contact WHERE Id = :existing.Id];
        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual(existing.Id, res[0].contactId);
        Assert.areEqual('en_US', updated.Idioma__c);
        // Existing contact is reused, bypass flag remains as-is for existing records.
    }

    @IsTest
    static void shouldCreateCaseFromMessagingSessionAndOverrideOrigin() {
        Account a = new Account(Name = 'Conta Conversa');
        insert a;
        Group queue = createCaseQueue('WSTEST_TSV_Messaging');
        WSWillCaseCreationService.testUnitConfigs = new List<AtendimentoConfigDTO>{
            buildConfig('Atendimento Tecon Salvador', 'AtendimentoTeconSalvador',queue.DeveloperName)
        };
        Contact contactRow = new Contact(
            LastName = 'Conversa',
            AccountId = a.Id,
            Email = 'conversa.bot@test.com',
            Phone = '71922223333',
            Idioma__c = 'pt_BR'
        );
        insert contactRow;

        WSWillCaseCreationService.testMessagingById = new Map<Id, MessagingSession>{
            SESSION_ID => new MessagingSession(Id = SESSION_ID, MessagingEndUserId = END_USER_ID)
        };
        WSWillCaseCreationService.testEndUserById = new Map<Id, MessagingEndUser>{
            END_USER_ID => new MessagingEndUser(
                Id = END_USER_ID,
                ContactId = contactRow.Id,
                Name = 'Contato Conversa',
                Language = 'en_US'
            )
        };
        WSWillCaseCreationService.bypassConversationWriteBack = true;

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.conversationId = SESSION_ID;
        req.endUserId = END_USER_ID;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'pt_BR';
        req.channelName = 'WhatsApp';
        req.origin = 'Bot';
        req.customerFullName = 'Contato Conversa';
        req.customerEmail = 'conversa.bot@test.com';
        req.customerPhone = '71922223333';
        req.caseType = 'Support';
        req.description = 'Case via messaging session';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        WSWillCaseCreationService.testMessagingById = null;
        WSWillCaseCreationService.testEndUserById = null;
        WSWillCaseCreationService.bypassConversationWriteBack = false;

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual(contactRow.Id, res[0].contactId);
        Assert.areEqual(false, res[0].caseId == null);
        Assert.areEqual('SUCCESS', res[0].statusCode);
        Case createdCase = [
            SELECT Id, Origin, OwnerId, UnidadeNegocio__c, RecordType.DeveloperName
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual('Bot', createdCase.Origin);
        Assert.areEqual(queue.Id, createdCase.OwnerId);
        Assert.areEqual('Atendimento Tecon Salvador', createdCase.UnidadeNegocio__c);
        Assert.areEqual('AtendimentoTeconSalvador', createdCase.RecordType.DeveloperName);
        WSWillCaseCreationService.testUnitConfigs = null;
    }

    @IsTest
    static void shouldCreateBotCaseAssignedToQueueFromUnitMetadata() {
        Group queue = createCaseQueue('WSTEST_TSV_AtendimentoN1');
        WSWillCaseCreationService.testUnitConfigs = new List<AtendimentoConfigDTO>{
            buildConfig('Atendimento Tecon Salvador', 'AtendimentoTeconSalvador',queue.DeveloperName)
        };

        Account a = new Account(Name = 'Conta Fila Bot');
        insert a;
        Contact contactRow = new Contact(
            LastName = 'Fila',
            AccountId = a.Id,
            Email = 'queue.bot@test.com',
            Phone = '71944445555',
            Idioma__c = 'pt_BR'
        );
        insert contactRow;

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.accountId = a.Id;
        req.contactId = contactRow.Id;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'pt_BR';
        req.channelName = 'Chat';
        req.origin = 'Bot';
        req.customerFullName = 'Cliente Fila';
        req.customerEmail = 'queue.bot@test.com';
        req.customerPhone = '71944445555';
        req.caseType = 'Solicitação';
        req.description = 'Case direcionado para fila';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        WSWillCaseCreationService.testUnitConfigs = null;

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success, 'statusCode=' + res[0].statusCode + ' msg=' + res[0].message);
        Assert.areEqual('SUCCESS', res[0].statusCode);
        Case createdCase = [
            SELECT Id, OwnerId, FilaDestinoDeveloperName__c, FilaDestinoId__c, UnidadeNegocio__c
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual(queue.Id, createdCase.OwnerId);
        Assert.areEqual(queue.DeveloperName, createdCase.FilaDestinoDeveloperName__c);
        Assert.areEqual(String.valueOf(queue.Id), createdCase.FilaDestinoId__c);
        Assert.areEqual('Atendimento Tecon Salvador', createdCase.UnidadeNegocio__c);
    }

    @IsTest
    static void shouldKeepChatCaseWithCurrentUserOwnerEvenWhenSendToQueueIsTrue() {
        Account a = new Account(Name = 'Conta Fila Metadata');
        insert a;
        Contact contactRow = new Contact(
            LastName = 'Metadata',
            AccountId = a.Id,
            Email = 'config.queue.bot@test.com',
            Phone = '71955556666',
            Idioma__c = 'pt_BR'
        );
        insert contactRow;

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.accountId = a.Id;
        req.contactId = contactRow.Id;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'pt_BR';
        req.channelName = 'WebChat';
        req.origin = 'Chat';
        req.customerFullName = 'Cliente Config';
        req.customerEmail = 'config.queue.bot@test.com';
        req.customerPhone = '71955556666';
        req.caseType = 'Informação';
        req.description = 'Case com fila por metadata';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success, 'statusCode=' + res[0].statusCode + ' msg=' + res[0].message);
        Assert.areEqual('SUCCESS', res[0].statusCode);
        Case createdCase = [
            SELECT Id, OwnerId, Origin, FilaDestinoDeveloperName__c, RecordType.DeveloperName
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual(UserInfo.getUserId(), createdCase.OwnerId);
        Assert.areEqual('Chat', createdCase.Origin);
        Assert.areEqual(null, createdCase.FilaDestinoDeveloperName__c);
        Assert.areEqual('AtendimentoTeconSalvador', createdCase.RecordType.DeveloperName);
    }

    @IsTest
    static void shouldInferWhatsappOriginFromChannelAndKeepCurrentUserOwner() {
        Account a = new Account(Name = 'Conta Fila Prefixo');
        insert a;
        Contact contactRow = new Contact(
            LastName = 'Prefixo',
            AccountId = a.Id,
            Email = 'prefix.queue.bot@test.com',
            Phone = '71977778888',
            Idioma__c = 'pt_BR'
        );
        insert contactRow;

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.accountId = a.Id;
        req.contactId = contactRow.Id;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'pt_BR';
        req.channelName = 'WhatsApp';
        req.origin = null;
        req.customerFullName = 'Cliente Prefixo';
        req.customerEmail = 'prefix.queue.bot@test.com';
        req.customerPhone = '71977778888';
        req.caseType = 'Informação';
        req.description = 'Case com origem inferida do canal';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success, 'statusCode=' + res[0].statusCode + ' msg=' + res[0].message);
        Assert.areEqual('SUCCESS', res[0].statusCode);
        Case createdCase = [
            SELECT Id, OwnerId, Origin, RecordType.DeveloperName
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual(UserInfo.getUserId(), createdCase.OwnerId);
        Assert.areEqual('Whatsapp', createdCase.Origin);
        Assert.areEqual('AtendimentoTeconSalvador', createdCase.RecordType.DeveloperName);
    }

    @IsTest
    static void shouldCreateCaseWithoutQueueWhenRequestedQueueIsInvalid() {
        Account a = new Account(Name = 'Conta Fila Invalida');
        insert a;
        Contact contactRow = new Contact(
            LastName = 'Sem Fila',
            AccountId = a.Id,
            Email = 'no.queue.bot@test.com',
            Phone = '71966667777',
            Idioma__c = 'pt_BR'
        );
        insert contactRow;

        WSWillCaseCreationService.testUnitConfigs = new List<AtendimentoConfigDTO>{
            buildConfig('Atendimento Tecon Salvador', 'AtendimentoTeconSalvador','QUEUE_NOT_FOUND_FOR_BOT')
        };

        WSWillCaseCreationDTO.Request req = new WSWillCaseCreationDTO.Request();
        req.accountId = a.Id;
        req.contactId = contactRow.Id;
        req.businessUnitName = 'Tecon Salvador';
        req.language = 'pt_BR';
        req.channelName = 'Chat';
        req.origin = 'Bot';
        req.customerFullName = 'Cliente Sem Fila';
        req.customerEmail = 'no.queue.bot@test.com';
        req.customerPhone = '71966667777';
        req.caseType = 'Reclamação';
        req.description = 'Case sem fila valida';

        Test.startTest();
        List<WSWillCaseCreationDTO.Response> res = WSWillCaseCreationInvocable.createCases(
            new List<WSWillCaseCreationDTO.Request>{ req }
        );
        Test.stopTest();

        WSWillCaseCreationService.testUnitConfigs = null;

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success, 'statusCode=' + res[0].statusCode + ' msg=' + res[0].message);
        Assert.areEqual('SUCCESS_WITHOUT_QUEUE', res[0].statusCode);
        Case createdCase = [
            SELECT Id, OwnerId, Origin, FilaDestinoDeveloperName__c
            FROM Case
            WHERE Id = :res[0].caseId
            LIMIT 1
        ];
        Assert.areEqual(false, String.isBlank(res[0].caseNumber));
        Assert.areEqual('Bot', createdCase.Origin);
        Assert.areEqual(UserInfo.getUserId(), createdCase.OwnerId);
        Assert.areEqual('QUEUE_NOT_FOUND_FOR_BOT', createdCase.FilaDestinoDeveloperName__c);
    }

    private static Group createCaseQueue(String developerName) {
        Group queue;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queue = new Group(Name = developerName, DeveloperName = developerName, Type = 'Queue');
            insert queue;
            insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
        }
        return queue;
    }

    private static AtendimentoConfigDTO buildConfig(String businessUnit, String recordTypeDeveloperName, String queueDeveloperName) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = businessUnit;
        config.masterLabel = businessUnit;
        config.developerName = businessUnit == null ? null : businessUnit.replaceAll('[^A-Za-z0-9]+', '_');
        config.caseRecordTypeDeveloperName = recordTypeDeveloperName;
        config.defaultQueueDeveloperName = queueDeveloperName;
        config.queueDeveloperNamePrefix = queueDeveloperName;
        config.isActive = true;
        return config;
    }

}