@IsTest
private class CaseControllerLogHelperTest {
    @IsTest
    static void shouldLogUnexpectedErrorWithRelatedRecord() {
        Id fakeCaseId = TestDataFactory.createCase(null).Id;

        Test.startTest();
        try {
            Integer x = 1 / 0;
        } catch (Exception ex) {
            CaseControllerLogHelper.logUnexpectedError('CaseControllerLogHelperTest.withRelated', 'Case', fakeCaseId, ex);
        }
        Test.stopTest();

        LogIntegracao__c log = [
            SELECT Name, MetodoCallout__c, DescritivoErroLog__c, ComentariosObservacoes__c, Endpoint__c, ObjetoRelacionamento__c, IdRelacionamento__c
            FROM LogIntegracao__c
            WHERE MetodoCallout__c = 'CASE_CTRL'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Assert.areEqual('CaseControllerLogHelperTest.withRelated', log.Name, 'Name deve receber o origin informado.');
        Assert.areEqual('CASE_CTRL', log.MetodoCallout__c);
        Assert.isNotNull(log.DescritivoErroLog__c, 'Mensagem da exceção deve ser gravada.');
        Assert.isNotNull(log.ComentariosObservacoes__c, 'Stack trace deve ser gravado.');
        Assert.areEqual('CaseControllerLogHelperTest.withRelated', log.Endpoint__c);
        Assert.areEqual('Case', log.ObjetoRelacionamento__c);
        Assert.areEqual(String.valueOf(fakeCaseId), log.IdRelacionamento__c);
    }

    @IsTest
    static void shouldLogUnexpectedErrorWithoutRelatedRecord() {
        Test.startTest();
        try {
            Integer x = 1 / 0;
        } catch (Exception ex) {
            CaseControllerLogHelper.logUnexpectedError('CaseControllerLogHelperTest.noRelated', null, null, ex);
        }
        Test.stopTest();

        LogIntegracao__c log = [
            SELECT ObjetoRelacionamento__c, IdRelacionamento__c
            FROM LogIntegracao__c
            WHERE MetodoCallout__c = 'CASE_CTRL' AND Endpoint__c = 'CaseControllerLogHelperTest.noRelated'
            LIMIT 1
        ];
        Assert.areEqual(null, log.ObjetoRelacionamento__c, 'Sem Id relacionado, o objeto relacionado não deve ser preenchido.');
        Assert.areEqual(null, log.IdRelacionamento__c, 'Sem Id relacionado, o Id relacionado não deve ser preenchido.');
    }

    @IsTest
    static void shouldNoOpWhenExceptionIsNull() {
        Test.startTest();
        CaseControllerLogHelper.logUnexpectedError('CaseControllerLogHelperTest.nullException', 'Case', null, null);
        Test.stopTest();

        Integer logsCount = [SELECT count() FROM LogIntegracao__c WHERE MetodoCallout__c = 'CASE_CTRL'];
        Assert.areEqual(0, logsCount, 'Sem exceção, nenhum log deve ser gravado.');
    }
}
