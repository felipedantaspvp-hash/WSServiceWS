@IsTest
private class CaseTriggerHandlerTest {
    @IsTest
    static void testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen() {
        Case c = new Case();
        c.Id = '500000000000002AAA';

        Case oldCase = (Case) JSON.deserialize('{"Id":"500000000000002AAA","IsClosed":false}', Case.class);
        Case newCase = (Case) JSON.deserialize('{"Id":"500000000000002AAA","IsClosed":true}', Case.class);

        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.injectedBlockersByCase.put(c.Id, 1);
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );

        Assert.areEqual(true, newCase.hasErrors());
        Assert.areEqual(1, newCase.getErrors().size());
    }
}