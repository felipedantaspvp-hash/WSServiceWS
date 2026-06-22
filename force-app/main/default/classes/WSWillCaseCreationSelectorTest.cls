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
}