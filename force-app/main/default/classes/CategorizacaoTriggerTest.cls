@IsTest
private class CategorizacaoTriggerTest {
    @IsTest
    static void testTriggerBeforeInsertUpdate() {
        Categorizacao__c row = CategorizacaoTestDataFactory.base(false, false);
        insert row;
        row.Ativo__c = false;
        row.MotivoInativacao__c = 'Inativado';
        update row;
        Categorizacao__c saved = [SELECT Ativo__c, MotivoInativacao__c FROM Categorizacao__c WHERE Id = :row.Id];
        Assert.areEqual(false, saved.Ativo__c);
        Assert.areEqual('Inativado', saved.MotivoInativacao__c);
    }
}