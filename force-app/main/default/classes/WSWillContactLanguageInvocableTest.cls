@IsTest
private class WSWillContactLanguageInvocableTest {
    private static final Id SESSION_ID = Id.valueOf('0Mw000000000002');
    private static final Id SESSION_WITH_DIRECT_CONTACT_ID = Id.valueOf('0Mw000000000003');
    private static final Id END_USER_ID = Id.valueOf('0PA000000000002');
    private static final Id END_USER_WITHOUT_CONTACT_ID = Id.valueOf('0PA000000000003');

    @IsTest
    static void shouldUpdateContactLanguageFromMessagingSessionEndUser() {
        Contact contactRow = TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'Idioma Session',
            'Phone' => '11999991001'
        });

        WSWillContactLanguageInvocable.testSessionById = new Map<Id, SObject>{
            SESSION_ID => fakeSession(SESSION_ID, END_USER_ID, null)
        };
        WSWillContactLanguageInvocable.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, contactRow.Id)
        };

        WSWillContactLanguageInvocable.Request req = new WSWillContactLanguageInvocable.Request();
        req.routableId = String.valueOf(SESSION_ID);
        req.language = 'English';

        Test.startTest();
        List<WSWillContactLanguageInvocable.Response> out = WSWillContactLanguageInvocable.updateLanguage(
            new List<WSWillContactLanguageInvocable.Request>{ req }
        );
        Test.stopTest();

        Contact updatedContact = [SELECT Idioma__c FROM Contact WHERE Id = :contactRow.Id];
        Assert.areEqual(1, out.size());
        Assert.areEqual(true, out[0].success);
        Assert.areEqual('SUCCESS', out[0].statusCode);
        Assert.areEqual(contactRow.Id, out[0].resolvedContactId);
        Assert.areEqual('en_US', updatedContact.Idioma__c);
    }

    @IsTest
    static void shouldUpdateContactLanguageFromDirectSessionContact() {
        Contact contactRow = TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'Idioma Direto',
            'Idioma__c' => 'pt_BR',
            'Phone' => '11999991002'
        });

        WSWillContactLanguageInvocable.testSessionById = new Map<Id, SObject>{
            SESSION_WITH_DIRECT_CONTACT_ID => fakeSession(SESSION_WITH_DIRECT_CONTACT_ID, null, contactRow.Id)
        };
        WSWillContactLanguageInvocable.testEndUserById = new Map<Id, SObject>();

        WSWillContactLanguageInvocable.Request req = new WSWillContactLanguageInvocable.Request();
        req.routableId = String.valueOf(SESSION_WITH_DIRECT_CONTACT_ID);
        req.language = 'pt_BR';

        List<WSWillContactLanguageInvocable.Response> out = WSWillContactLanguageInvocable.updateLanguage(
            new List<WSWillContactLanguageInvocable.Request>{ req }
        );

        Assert.areEqual(true, out[0].success);
        Assert.areEqual(contactRow.Id, out[0].resolvedContactId);
        Assert.areEqual('pt_BR', [SELECT Idioma__c FROM Contact WHERE Id = :contactRow.Id].Idioma__c);
    }

    @IsTest
    static void shouldUpdateContactLanguageFromEndUserInput() {
        Contact contactRow = TestDataFactory.createContact(null, new Map<String, Object>{
            'LastName' => 'Idioma EndUser',
            'Phone' => '11999991003'
        });

        WSWillContactLanguageInvocable.testSessionById = new Map<Id, SObject>();
        WSWillContactLanguageInvocable.testEndUserById = new Map<Id, SObject>{
            END_USER_ID => fakeEndUser(END_USER_ID, contactRow.Id)
        };

        WSWillContactLanguageInvocable.Request req = new WSWillContactLanguageInvocable.Request();
        req.endUserId = String.valueOf(END_USER_ID);
        req.language = 'Português';

        List<WSWillContactLanguageInvocable.Response> out = WSWillContactLanguageInvocable.updateLanguage(
            new List<WSWillContactLanguageInvocable.Request>{ req }
        );

        Assert.areEqual(true, out[0].success);
        Assert.areEqual('pt_BR', [SELECT Idioma__c FROM Contact WHERE Id = :contactRow.Id].Idioma__c);
    }

    @IsTest
    static void shouldHandleInvalidAndMissingInputs() {
        WSWillContactLanguageInvocable.testSessionById = new Map<Id, SObject>();
        WSWillContactLanguageInvocable.testEndUserById = new Map<Id, SObject>{
            END_USER_WITHOUT_CONTACT_ID => fakeEndUser(END_USER_WITHOUT_CONTACT_ID, null)
        };

        WSWillContactLanguageInvocable.Request invalidLanguage = new WSWillContactLanguageInvocable.Request();
        invalidLanguage.language = 'de_DE';

        WSWillContactLanguageInvocable.Request missingContact = new WSWillContactLanguageInvocable.Request();
        missingContact.endUserId = String.valueOf(END_USER_WITHOUT_CONTACT_ID);
        missingContact.language = 'en_US';

        List<WSWillContactLanguageInvocable.Response> out = WSWillContactLanguageInvocable.updateLanguage(
            new List<WSWillContactLanguageInvocable.Request>{ null, invalidLanguage, missingContact }
        );

        Assert.areEqual(3, out.size());
        Assert.areEqual('INVALID_INPUT', out[0].statusCode);
        Assert.areEqual('INVALID_LANGUAGE', out[1].statusCode);
        Assert.areEqual('CONTACT_NOT_FOUND', out[2].statusCode);
    }

    @IsTest
    static void shouldExerciseRealFetchFallbacksWhenNoTestSeamIsProvided() {
        WSWillContactLanguageInvocable.testSessionById = null;
        WSWillContactLanguageInvocable.testEndUserById = null;

        WSWillContactLanguageInvocable.Request noRecord = new WSWillContactLanguageInvocable.Request();
        noRecord.routableId = String.valueOf(SESSION_ID);
        noRecord.endUserId = String.valueOf(END_USER_ID);
        noRecord.language = 'en_US';

        WSWillContactLanguageInvocable.Request invalidId = new WSWillContactLanguageInvocable.Request();
        invalidId.endUserId = '!!!!!!!!!!!!!!!';
        invalidId.language = 'pt_BR';

        List<WSWillContactLanguageInvocable.Response> out = WSWillContactLanguageInvocable.updateLanguage(
            new List<WSWillContactLanguageInvocable.Request>{ noRecord, invalidId }
        );

        Assert.areEqual(2, out.size());
        Assert.areEqual('CONTACT_NOT_FOUND', out[0].statusCode);
        Assert.areEqual('CONTACT_NOT_FOUND', out[1].statusCode);
    }

    @IsTest
    static void shouldCoverUtilityBranches() {
        Account accountRow = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Idioma Fetch' });

        Map<Id, SObject> emptyByObject = WSWillContactLanguageInvocable.fetchByIds(
            null,
            new Set<Id>{ accountRow.Id },
            new Set<String>{ 'Id' }
        );
        Map<Id, SObject> emptyByIds = WSWillContactLanguageInvocable.fetchByIds(
            'Account',
            new Set<Id>(),
            new Set<String>{ 'Id' }
        );
        Map<Id, SObject> fetched = WSWillContactLanguageInvocable.fetchByIds(
            'Account',
            new Set<Id>{ accountRow.Id },
            new Set<String>{ 'Id', 'Name', 'CampoInexistente__c' }
        );

        Assert.areEqual(0, emptyByObject.size());
        Assert.areEqual(0, emptyByIds.size());
        Assert.areEqual(accountRow.Id, fetched.get(accountRow.Id).get('Id'));
        Assert.areEqual(null, WSWillContactLanguageInvocable.parseId('!!!!!!!!!!!!!!!'));
    }

    @IsTest
    static void shouldReturnEmptyForEmptyRequests() {
        Assert.areEqual(0, WSWillContactLanguageInvocable.updateLanguage(null).size());
        Assert.areEqual(0, WSWillContactLanguageInvocable.updateLanguage(new List<WSWillContactLanguageInvocable.Request>()).size());
    }

    private static SObject fakeSession(Id sessionId, Id endUserId, Id contactId) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingSession' },
            'Id' => String.valueOf(sessionId)
        };
        if (endUserId != null) payload.put('MessagingEndUserId', String.valueOf(endUserId));
        if (contactId != null) payload.put('EndUserContactId', String.valueOf(contactId));
        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

    private static SObject fakeEndUser(Id endUserId, Id contactId) {
        Map<String, Object> payload = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'MessagingEndUser' },
            'Id' => String.valueOf(endUserId)
        };
        if (contactId != null) payload.put('ContactId', String.valueOf(contactId));
        return (SObject) JSON.deserialize(JSON.serialize(payload), SObject.class);
    }

}