@IsTest
private class WSWillCaseCreationSelectorTest {
    @IsTest
    static void shouldQueryWithoutErrors_WhenIdSetsAreEmptyOrPopulated() {
        Test.startTest();
        Map<Id, MessagingSession> messagingById = WSWillCaseCreationSelector.selectMessagingSessionsByIds(new Set<Id>());
        Map<Id, MessagingEndUser> endUserById = WSWillCaseCreationSelector.selectMessagingEndUsersByIds(new Set<Id>());
        Map<Id, Case> casesById = WSWillCaseCreationSelector.selectCasesById(new Set<Id>());
        List<QueueSobject> queues = WSWillCaseCreationSelector.selectCaseQueuesBySobjectType();
        Test.stopTest();

        Assert.areEqual(0, messagingById.size(), 'No MessagingSession should be returned for an empty Id set');
        Assert.areEqual(0, endUserById.size(), 'No MessagingEndUser should be returned for an empty Id set');
        Assert.areEqual(0, casesById.size(), 'No Case should be returned for an empty Id set');
        Assert.areEqual(true, queues.size() >= 0, 'Queue list should be returned without error');
    }

    @IsTest
    static void shouldSelectContactsByIdsAndByEmails() {
        Account a = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Selector Contact' });
        Contact c = TestDataFactory.createContact(a.Id, new Map<String, Object>{
            'LastName' => 'Selector',
            'Email' => 'selector.contact@test.com',
            'Phone' => '71900000009'
        });

        Test.startTest();
        Map<Id, Contact> byId = WSWillCaseCreationSelector.selectContactsByIds(new Set<Id>{ c.Id }, null);
        List<Contact> byEmail = WSWillCaseCreationSelector.selectContactsByEmails(new Set<String>{ 'selector.contact@test.com' }, null);
        Map<Id, Contact> emptyIds = WSWillCaseCreationSelector.selectContactsByIds(new Set<Id>(), null);
        List<Contact> emptyEmails = WSWillCaseCreationSelector.selectContactsByEmails(new Set<String>(), null);
        Test.stopTest();

        Assert.areEqual(1, byId.size(), 'Deve encontrar o Contact pelo Id.');
        Assert.areEqual(c.Id, byId.get(c.Id).Id);
        Assert.areEqual(1, byEmail.size(), 'Deve encontrar o Contact pelo e-mail.');
        Assert.areEqual(c.Id, byEmail[0].Id);
        Assert.areEqual(0, emptyIds.size(), 'Set de Ids vazio não deve consultar nada.');
        Assert.areEqual(0, emptyEmails.size(), 'Set de e-mails vazio não deve consultar nada.');
    }

    @IsTest
    static void shouldSelectContactsWithRepresentedAccountFieldWhenProvided() {
        Account a = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Selector Contact Campo' });
        Contact c = TestDataFactory.createContact(a.Id, new Map<String, Object>{
            'LastName' => 'SelectorCampo',
            'Email' => 'selector.contact.campo@test.com',
            'Phone' => '71900000010'
        });

        Test.startTest();
        Map<Id, Contact> byId = WSWillCaseCreationSelector.selectContactsByIds(new Set<Id>{ c.Id }, 'MailingCity');
        List<Contact> byEmail = WSWillCaseCreationSelector.selectContactsByEmails(new Set<String>{ 'selector.contact.campo@test.com' }, 'MailingCity');
        Test.stopTest();

        Assert.areEqual(1, byId.size(), 'Deve encontrar o Contact pelo Id mesmo informando um campo dinâmico existente.');
        Assert.areEqual(1, byEmail.size(), 'Deve encontrar o Contact pelo e-mail mesmo informando um campo dinâmico existente.');
    }
}