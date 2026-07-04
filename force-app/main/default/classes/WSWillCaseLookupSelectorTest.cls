@IsTest
private class WSWillCaseLookupSelectorTest {
    @IsTest
    static void shouldReturnEmptyMapWhenCaseNumbersAreNullOrEmpty() {
        Test.startTest();
        Map<String, Case> nullResult = WSWillCaseLookupSelector.selectCasesByCaseNumbers(null);
        Map<String, Case> emptyResult = WSWillCaseLookupSelector.selectCasesByCaseNumbers(new Set<String>());
        Test.stopTest();

        Assert.areEqual(0, nullResult.size(), 'Null input should return an empty map.');
        Assert.areEqual(0, emptyResult.size(), 'Empty input should return an empty map.');
    }

    @IsTest
    static void shouldReturnCasesIndexedByCaseNumberWhenNumbersExist() {
        Account accountRow = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Selector Lookup' });
        Contact contactRow = TestDataFactory.createContact(accountRow.Id, new Map<String, Object>{
            'LastName' => 'Contato Selector Lookup',
            'Phone' => '11999990007'
        });
        Case caseRow = TestDataFactory.createCase(new Map<String, Object>{
            'Subject' => 'Case Selector Lookup',
            'Status' => 'Aberto',
            'AccountId' => accountRow.Id,
            'ContactId' => contactRow.Id,
            'TipoCaso__c' => 'Solicitação',
            'Categoria__c' => 'Solicitação',
            'Assunto__c' => 'Informativo',
            'EtapaAtendimento__c' => 'Novo'
        });
        caseRow = [
            SELECT Id, CaseNumber, ContactId, AccountId, Status, TipoCaso__c, Categoria__c, Assunto__c, EtapaAtendimento__c
            FROM Case
            WHERE Id = :caseRow.Id
        ];

        Test.startTest();
        Map<String, Case> result = WSWillCaseLookupSelector.selectCasesByCaseNumbers(
            new Set<String>{ caseRow.CaseNumber, '00999999' }
        );
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Only the existing CaseNumber should be returned.');
        Assert.areEqual(caseRow.Id, result.get(caseRow.CaseNumber).Id, 'The Case should be indexed by CaseNumber.');
        Assert.areEqual(accountRow.Id, result.get(caseRow.CaseNumber).AccountId, 'The selector should preserve the account context.');
        Assert.areEqual(contactRow.Id, result.get(caseRow.CaseNumber).ContactId, 'The selector should preserve the contact context.');
    }
}
