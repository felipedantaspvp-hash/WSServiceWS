@IsTest
private class WSWillCaseLookupTest {
    @IsTest
    static void shouldLookupCaseWhenAuthorized() {
        Account a = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Lookup' });
        Contact c = TestDataFactory.createContact(a.Id, new Map<String, Object>{
            'LastName' => 'Contato Lookup',
            'Email' => 'lookup@test.com',
            'Phone' => '11999990003'
        });

        Case cs = TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => null,
            'Subject' => 'Teste',
            'Status' => 'Aberto',
            'AccountId' => a.Id,
            'ContactId' => c.Id,
            'TipoCaso__c' => 'Solicitação',
            'Categoria__c' => 'Solicitação',
            'Assunto__c' => 'Informativo',
            'EtapaAtendimento__c' => 'Em Atendimento'
        });
        cs = [SELECT Id, CaseNumber, ContactId, AccountId, EtapaAtendimento__c FROM Case WHERE Id = :cs.Id];

        WSWillCaseLookupDTO.Request req = new WSWillCaseLookupDTO.Request();
        req.caseNumber = String.valueOf(Integer.valueOf(cs.CaseNumber));
        req.language = 'en_US';
        req.contactId = c.Id;

        Test.startTest();
        List<WSWillCaseLookupDTO.Response> res = WSWillCaseLookupInvocable.lookup(new List<WSWillCaseLookupDTO.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, res.size());
        Assert.areEqual(true, res[0].success);
        Assert.areEqual('SUCCESS', res[0].statusCode);
        Assert.areEqual(cs.Id, res[0].caseId);
        Assert.areEqual(true, res[0].caseFound);
        Assert.areEqual(cs.CaseNumber, res[0].caseNumber);
        Assert.areEqual('Request', res[0].caseType);
        Assert.areEqual('Request', res[0].caseCategory);
        Assert.areEqual('Informative', res[0].caseSubject);
        Assert.areEqual('Open', res[0].caseStatus);
        Assert.areEqual('Em Atendimento', res[0].caseStage);
        Assert.areEqual('Request | Request | Informative', res[0].message);

        req.language = 'pt_BR';
        List<WSWillCaseLookupDTO.Response> ptRes = WSWillCaseLookupService.lookup(new List<WSWillCaseLookupDTO.Request>{ req });
        Assert.areEqual(true, ptRes[0].success);
        Assert.areEqual('Solicitação', ptRes[0].caseType);
        Assert.areEqual('Aberto', ptRes[0].caseStatus);
        Assert.areEqual('Em Atendimento', ptRes[0].caseStage);
        Assert.areEqual('Solicitação | Solicitação | Informativo', ptRes[0].message);
    }

    @IsTest
    static void shouldOmitBlankPartsFromMessageAndReturnStage() {
        Account a = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Lookup Parcial' });
        Contact c = TestDataFactory.createContact(a.Id, new Map<String, Object>{
            'LastName' => 'Contato Parcial',
            'Phone' => '11999990004'
        });

        Case cs = TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => null,
            'Subject' => 'Teste parcial',
            'Status' => 'Aberto',
            'AccountId' => a.Id,
            'ContactId' => c.Id,
            'TipoCaso__c' => 'Informação',
            'Categoria__c' => null,
            'Assunto__c' => 'Informativo',
            'EtapaAtendimento__c' => 'Novo'
        });
        cs = [SELECT Id, CaseNumber, EtapaAtendimento__c FROM Case WHERE Id = :cs.Id];

        WSWillCaseLookupDTO.Request req = new WSWillCaseLookupDTO.Request();
        req.caseNumber = String.valueOf(Integer.valueOf(cs.CaseNumber));
        req.language = 'pt_BR';
        req.accountId = a.Id;

        List<WSWillCaseLookupDTO.Response> res = WSWillCaseLookupService.lookup(new List<WSWillCaseLookupDTO.Request>{ req });

        Assert.areEqual(1, res.size());
        Assert.areEqual('Informação | Informativo', res[0].message);
        Assert.areEqual('Novo', res[0].caseStage);
    }

    @IsTest
    static void shouldNotReturnCaseDataWhenRequesterDoesNotOwnCase() {
        Account owner = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Dona do Caso' });
        Contact ownerContact = TestDataFactory.createContact(owner.Id, new Map<String, Object>{
            'LastName' => 'Contato Dono',
            'Phone' => '11999990005'
        });

        Case cs = TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => null,
            'Subject' => 'Teste posse',
            'Status' => 'Aberto',
            'AccountId' => owner.Id,
            'ContactId' => ownerContact.Id,
            'TipoCaso__c' => 'Solicitação',
            'Assunto__c' => 'Informativo',
            'EtapaAtendimento__c' => 'Novo'
        });
        cs = [SELECT Id, CaseNumber FROM Case WHERE Id = :cs.Id];

        Account stranger = TestDataFactory.createAccount(new Map<String, Object>{ 'Name' => 'Conta Estranha' });
        Contact strangerContact = TestDataFactory.createContact(stranger.Id, new Map<String, Object>{
            'LastName' => 'Contato Estranho',
            'Phone' => '11999990006'
        });

        WSWillCaseLookupDTO.Request req = new WSWillCaseLookupDTO.Request();
        req.caseNumber = String.valueOf(Integer.valueOf(cs.CaseNumber));
        req.language = 'pt_BR';
        req.contactId = strangerContact.Id;
        req.accountId = stranger.Id;

        List<WSWillCaseLookupDTO.Response> res = WSWillCaseLookupService.lookup(new List<WSWillCaseLookupDTO.Request>{ req });

        Assert.areEqual(1, res.size());
        Assert.areEqual(false, res[0].success);
        Assert.areEqual(false, res[0].caseFound);
        Assert.areEqual('CASE_NOT_FOUND', res[0].statusCode);

        WSWillCaseLookupDTO.Request noOwnerReq = new WSWillCaseLookupDTO.Request();
        noOwnerReq.caseNumber = String.valueOf(Integer.valueOf(cs.CaseNumber));
        noOwnerReq.language = 'pt_BR';

        List<WSWillCaseLookupDTO.Response> resWithoutOwner = WSWillCaseLookupService.lookup(new List<WSWillCaseLookupDTO.Request>{ noOwnerReq });
        Assert.areEqual('CASE_NOT_FOUND', resWithoutOwner[0].statusCode);
    }

    @IsTest
    static void shouldReturnNotFoundAndInvalidInput() {
        WSWillCaseLookupDTO.Request notFound = new WSWillCaseLookupDTO.Request();
        notFound.caseNumber = '999999';
        notFound.language = 'pt_BR';

        WSWillCaseLookupDTO.Request invalid = new WSWillCaseLookupDTO.Request();
        invalid.caseNumber = 'ABC';

        List<WSWillCaseLookupDTO.Response> res = WSWillCaseLookupService.lookup(
            new List<WSWillCaseLookupDTO.Request>{ notFound, invalid, null }
        );

        Assert.areEqual(3, res.size());
        Assert.areEqual(false, res[0].caseFound);
        Assert.areEqual('CASE_NOT_FOUND', res[0].statusCode);
        Assert.areEqual('INVALID_INPUT', res[1].statusCode);
        Assert.areEqual('INVALID_INPUT', res[2].statusCode);
    }

    @IsTest
    static void shouldReturnEmptyForEmptyRequests() {
        Assert.areEqual(0, WSWillCaseLookupService.lookup(null).size());
        Assert.areEqual(0, WSWillCaseLookupService.lookup(new List<WSWillCaseLookupDTO.Request>()).size());
    }

    @IsTest
    static void shouldCoverHelperTranslations() {
        Assert.areEqual(null, WSWillCaseLookupHelper.normalizeCaseNumber(null));
        Assert.areEqual(null, WSWillCaseLookupHelper.normalizeCaseNumber('ABC'));
        Assert.areEqual('00435267', WSWillCaseLookupHelper.normalizeCaseNumber('435267'));
        Assert.areEqual('00435267', WSWillCaseLookupHelper.normalizeCaseNumber('Ticket 435267'));
        Assert.areEqual('Solicitação', WSWillCaseLookupHelper.translateValue('TipoCaso__c', 'Solicitação', 'pt_BR'));
        Assert.areEqual('Request', WSWillCaseLookupHelper.translateValue('TipoCaso__c', 'Solicitação', 'en_US'));
        Assert.areEqual('Valor Sem Traducao', WSWillCaseLookupHelper.translateValue('Assunto__c', 'Valor Sem Traducao', 'en_US'));
        Assert.areEqual(null, WSWillCaseLookupHelper.translateValue('Assunto__c', null, 'en_US'));
        Assert.areEqual('A | B', WSWillCaseLookupService.buildCaseSummary(new List<String>{ 'A', null, 'B' }));
        Assert.areEqual(null, WSWillCaseLookupService.buildCaseSummary(new List<String>{ null, '' }));
    }
}