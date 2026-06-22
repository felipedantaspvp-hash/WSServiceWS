/**
 * @description       : Classe de teste do modulo Email-to-Case.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
@IsTest
private class WS_EmailToCaseServiceTest {
    private class FixedClock extends WS_EmailToCaseClock {
        private Datetime fixedNow;
        FixedClock(Datetime fixedNow) {
            this.fixedNow = fixedNow;
        }
        public override Datetime now() {
            return fixedNow;
        }
    }

    @TestSetup
    static void setupData() {
        Group g = new Group(Name = 'WS Q TEST', DeveloperName = 'WS_Q_TEST', Type = 'Queue');
        insert g;
        insert new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
    }

    @IsTest
    static void testCreateNewCaseWhenNoThread() {
        Group queue = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'route1@company.com', WS_EmailToCaseConstants.OWNER_TYPE_QUEUE, queue.DeveloperName,
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN, 60
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        Messaging.InboundEmail email = WS_EmailToCaseTestDataFactory.buildEmail(
            '<m1@x>', 'route1@company.com', 'sender@example.com', 'Assunto 1', 'Body 1', null
        );
        Messaging.InboundEnvelope env = WS_EmailToCaseTestDataFactory.buildEnvelope('route1@company.com', 'sender@example.com');

        Test.startTest();
        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(email, env);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(WS_EmailToCaseConstants.ACTION_NEW_CASE, result.action);
        Case created = [SELECT Id, Subject, Origin, Priority, OwnerId, WS_Email_Route_Key__c FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals('Assunto 1', created.Subject);
        System.assertEquals('Email', created.Origin);
        System.assertEquals('Medium', created.Priority);
        System.assertEquals(queue.Id, created.OwnerId);
        System.assertEquals('route1@company.com', created.WS_Email_Route_Key__c);
        Integer emailMessages = [SELECT count() FROM EmailMessage WHERE ParentId = :result.caseId];
        System.assertEquals(1, emailMessages, 'Deve existir EmailMessage vinculado ao Case.');
        cleanupStatics();
    }

    @IsTest
    static void testCreateNewCaseAssociatesExistingContactByEmail() {
        Group queue = getQueue();
        Account accountRow = new Account(Name = 'Cliente Email', Status__c = 'Nova');
        insert accountRow;
        Contact contactRow = new Contact(
            LastName = 'Cliente Email',
            Email = 'sender@example.com',
            Phone = '11999990000',
            AccountId = accountRow.Id
        );
        insert contactRow;

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'route-contact@company.com', WS_EmailToCaseConstants.OWNER_TYPE_QUEUE, queue.DeveloperName,
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN, 60
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        Test.startTest();
        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<m-contact@x>', 'route-contact@company.com', 'sender@example.com', 'Assunto contato', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('route-contact@company.com', 'sender@example.com')
        );
        Test.stopTest();

        Case created = [SELECT AccountId, ContactId, Representante__c FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals(accountRow.Id, created.AccountId);
        System.assertEquals(contactRow.Id, created.ContactId);
        System.assertEquals(null, created.Representante__c);
        cleanupStatics();
    }

    @IsTest
    static void testCreateNewCaseUsesRepresentedAccountWhenConfigured() {
        Group queue = getQueue();
        Account representative = new Account(Name = 'Despachante', Status__c = 'Nova');
        Account represented = new Account(Name = 'Cliente Final', Status__c = 'Nova');
        insert new List<Account>{ representative, represented };

        Contact contactRow = new Contact(
            LastName = 'Contato Representado',
            Email = 'represented@example.com',
            Phone = '11999990001',
            AccountId = representative.Id,
            ContaRepresentadaAtual__c = represented.Id
        );
        insert contactRow;

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'route-represented@company.com', WS_EmailToCaseConstants.OWNER_TYPE_QUEUE, queue.DeveloperName,
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN, 60
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<m-represented@x>', 'route-represented@company.com', 'represented@example.com', 'Assunto representante', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('route-represented@company.com', 'represented@example.com')
        );

        Case created = [SELECT AccountId, ContactId, Representante__c FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals(represented.Id, created.AccountId);
        System.assertEquals(contactRow.Id, created.ContactId);
        System.assertEquals(representative.Id, created.Representante__c);
        cleanupStatics();
    }

    @IsTest
    static void testCreateNewCaseMatchesAccountByDomainAndCreatesContact() {
        Group queue = getQueue();
        Account accountRow = new Account(
            Name = 'Cliente Dominio',
            Status__c = 'Nova',
            DominiosEmail__c = 'example.com;example.org'
        );
        insert accountRow;

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'route-domain@company.com', WS_EmailToCaseConstants.OWNER_TYPE_QUEUE, queue.DeveloperName,
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN, 60
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        Messaging.InboundEmail email = WS_EmailToCaseTestDataFactory.buildEmail(
            '<m-domain@x>', 'route-domain@company.com', 'novo.contato@example.com', 'Assunto dominio', 'Body', null
        );
        email.fromName = 'Novo Contato';

        Test.startTest();
        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            email,
            WS_EmailToCaseTestDataFactory.buildEnvelope('route-domain@company.com', 'novo.contato@example.com')
        );
        Test.stopTest();

        Case created = [SELECT AccountId, ContactId FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals(accountRow.Id, created.AccountId);
        System.assertNotEquals(null, created.ContactId);

        Contact createdContact = [
            SELECT AccountId, Email, BypassValidationsFromBot__c
            FROM Contact
            WHERE Id = :created.ContactId
            LIMIT 1
        ];
        System.assertEquals(accountRow.Id, createdContact.AccountId);
        System.assertEquals('novo.contato@example.com', createdContact.Email);
        System.assertEquals(true, createdContact.BypassValidationsFromBot__c);
        cleanupStatics();
    }

    @IsTest
    static void testInboundHandlerDelegatesToInboundService() {
        Group queue = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'handler@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_QUEUE,
            queue.DeveloperName,
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            60
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        Messaging.InboundEmail email = WS_EmailToCaseTestDataFactory.buildEmail(
            '<handler@x>',
            'handler@company.com',
            'sender@example.com',
            'Assunto Handler',
            'Body Handler',
            null
        );
        Messaging.InboundEnvelope env = WS_EmailToCaseTestDataFactory.buildEnvelope('handler@company.com', 'sender@example.com');

        Test.startTest();
        Messaging.InboundEmailResult inboundResult = new WS_EmailToCaseInboundHandler().handleInboundEmail(email, env);
        Test.stopTest();

        System.assertEquals(true, inboundResult.success);
        System.assert(inboundResult.message != null && inboundResult.message.contains('Email processado'));
        System.assertEquals(1, [SELECT count() FROM Case WHERE WS_Email_Route_Key__c = 'handler@company.com']);
        cleanupStatics();
    }

    @IsTest
    static void testSameMessageTwoRoutesCreateTwoCases() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig r1 = WS_EmailToCaseTestDataFactory.buildRoute('a@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 60);
        WS_EmailToCaseRouteConfig r2 = WS_EmailToCaseTestDataFactory.buildRoute('b@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 60);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ r1, r2 });

        String messageId = '<same@id>';
        WS_EmailToCaseOrchestrator orch = new WS_EmailToCaseOrchestrator();
        WS_EmailToCaseProcessResult first = orch.process(
            WS_EmailToCaseTestDataFactory.buildEmail(messageId, 'a@company.com', 'sender@example.com', 'S', 'B', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('a@company.com', 'sender@example.com')
        );
        WS_EmailToCaseProcessResult second = orch.process(
            WS_EmailToCaseTestDataFactory.buildEmail(messageId, 'b@company.com', 'sender@example.com', 'S', 'B', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('b@company.com', 'sender@example.com')
        );

        System.assertNotEquals(first.caseId, second.caseId);
        System.assertEquals(2, [SELECT count() FROM Case WHERE Id IN :new Set<Id>{first.caseId, second.caseId}]);
        cleanupStatics();
    }

    @IsTest
    static void testIgnoreDuplicateSameRoute() {
        Group q1 = getQueue();
        WS_EmailToCaseRouteConfig r1 = WS_EmailToCaseTestDataFactory.buildRoute('dup@company.com', 'QUEUE', q1.DeveloperName, 'REOPEN', 60);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ r1 });

        String messageId = '<dup@id>';
        WS_EmailToCaseOrchestrator orch = new WS_EmailToCaseOrchestrator();

        WS_EmailToCaseProcessResult first = orch.process(
            WS_EmailToCaseTestDataFactory.buildEmail(messageId, 'dup@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('dup@company.com', 'sender@example.com')
        );
        WS_EmailToCaseProcessResult second = orch.process(
            WS_EmailToCaseTestDataFactory.buildEmail(messageId, 'dup@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('dup@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_NEW_CASE, first.action);
        System.assertEquals(WS_EmailToCaseConstants.ACTION_DUPLICATE_IGNORED, second.action);
        System.assertEquals(1, [SELECT count() FROM Case WHERE WS_Email_Route_Key__c = 'dup@company.com']);
        cleanupStatics();
    }

    @IsTest
    static void testAppendOpenCaseByToken() {
        Group q = getQueue();
        Case existing = WS_EmailToCaseTestDataFactory.createCase(q.Id, WS_EmailToCaseTestDataFactory.getAnyOpenStatus(), null);

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('app@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 60);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(existing.Id, null);

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<app@id>', 'app@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('app@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_APPEND_OPEN_CASE, result.action);
        System.assertEquals(existing.Id, result.caseId);
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id = :existing.Id]);
        Integer emailMessages = [SELECT count() FROM EmailMessage WHERE ParentId = :existing.Id];
        System.assertEquals(1, emailMessages, 'Append em case aberto deve criar EmailMessage vinculado.');
        cleanupStatics();
    }

    @IsTest
    static void testHeaderFallbackWhenTokenMissing() {
        Group q = getQueue();
        Case existing = WS_EmailToCaseTestDataFactory.createCase(q.Id, WS_EmailToCaseTestDataFactory.getAnyOpenStatus(), null);
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('hdr@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 60);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(UserInfo.getUserId(), existing.Id);

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<hdr@id>', 'hdr@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('hdr@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_APPEND_OPEN_CASE, result.action);
        System.assertEquals(existing.Id, result.caseId);
        cleanupStatics();
    }

    @IsTest
    static void testReopenClosedCaseWithinWindow() {
        Group q = getQueue();
        Case closedCase = closeCaseNow(q.Id);

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('reopen@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 30);
        route.reopenStatus = WS_EmailToCaseTestDataFactory.getAnyOpenStatus();
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(closedCase.Id, null);
        WS_EmailToCaseClock.setTestClock(new FixedClock(System.now()));

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<reopen@id>', 'reopen@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('reopen@company.com', 'sender@example.com')
        );

        Case updated = [SELECT Id, IsClosed, Status FROM Case WHERE Id = :closedCase.Id];
        System.assertEquals(WS_EmailToCaseConstants.ACTION_REOPEN_CLOSED_CASE, result.action);
        System.assertEquals(false, updated.IsClosed);
        cleanupStatics();
    }

    @IsTest
    static void testCreateNewWhenClosedOutsideWindow() {
        Group q = getQueue();
        Case closedCase = closeCaseNow(q.Id);

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('out@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 0);
        route.reopenStatus = WS_EmailToCaseTestDataFactory.getAnyOpenStatus();
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(closedCase.Id, null);
        WS_EmailToCaseClock.setTestClock(new FixedClock(System.now().addMinutes(10)));

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<out@id>', 'out@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('out@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_NEW_AFTER_REOPEN_WINDOW, result.action);
        Case created = [SELECT Id, WS_Original_Case__c FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals(closedCase.Id, created.WS_Original_Case__c);
        cleanupStatics();
    }

    @IsTest
    static void testCreateNewBehaviorAlwaysNew() {
        Group q = getQueue();
        Case closedCase = closeCaseNow(q.Id);

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('cn@company.com', 'QUEUE', q.DeveloperName, 'CREATE_NEW', 999);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(closedCase.Id, null);

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<cn@id>', 'cn@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('cn@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_NEW_CASE, result.action);
        System.assertNotEquals(closedCase.Id, result.caseId);
        cleanupStatics();
    }

    @IsTest
    static void testRelatesOriginalCaseWhenConfigured() {
        Group q = getQueue();
        Case closedCase = closeCaseNow(q.Id);

        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('rel@company.com', 'QUEUE', q.DeveloperName, 'CREATE_NEW', 0);
        route.relateNewCaseToOriginal = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(closedCase.Id, null);

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<rel@id>', 'rel@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('rel@company.com', 'sender@example.com')
        );

        Case created = [SELECT WS_Original_Case__c FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals(closedCase.Id, created.WS_Original_Case__c);
        cleanupStatics();
    }

    @IsTest
    static void testResolveOwnerByQueue() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('ownerq@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<ownerq@id>', 'ownerq@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('ownerq@company.com', 'sender@example.com')
        );

        Case c = [SELECT OwnerId FROM Case WHERE Id = :result.caseId];
        System.assertEquals(q.Id, c.OwnerId);
        cleanupStatics();
    }

    @IsTest
    static void testResolveOwnerByUser() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('owneru@company.com', 'USER', UserInfo.getUserName(), 'REOPEN', 10);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<owneru@id>', 'owneru@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('owneru@company.com', 'sender@example.com')
        );

        Case c = [SELECT OwnerId FROM Case WHERE Id = :result.caseId];
        System.assertEquals(UserInfo.getUserId(), c.OwnerId);
        cleanupStatics();
    }

    @IsTest
    static void testFailsWithClearErrorWhenQueueNotFound() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('noqueue@company.com', 'QUEUE', 'DOES_NOT_EXIST', 'REOPEN', 10);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<nq@id>', 'noqueue@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('noqueue@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_ERROR, result.action);
        System.assert(result.message.contains('Fila nÃ£o encontrada'));
        cleanupStatics();
    }

    @IsTest
    static void testFailsWithClearErrorWhenUserNotFound() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('nouser@company.com', 'USER', 'missing.user@example.com', 'REOPEN', 10);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<nu@id>', 'nouser@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('nouser@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_ERROR, result.action);
        System.assert(result.message.contains('UsuÃ¡rio nÃ£o encontrado'));
        cleanupStatics();
    }

    @IsTest
    static void testFailsWithClearErrorWhenRecordTypeNotFound() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('rterr@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        route.caseRecordTypeDeveloperName = 'NOT_EXISTS_RECORDTYPE';
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<rt@id>', 'rterr@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('rterr@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_ERROR, result.action);
        System.assert(result.message.contains('Record Type de Case nÃ£o encontrado'));
        cleanupStatics();
    }

    @IsTest
    static void testFailsWhenReopenStatusInvalid() {
        Group q = getQueue();
        Case closedCase = closeCaseNow(q.Id);
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('rserr@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 30);
        route.reopenStatus = 'INVALID_STATUS';
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });
        WS_EmailToCaseThreadingService.setTestThreadingIds(closedCase.Id, null);

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<rserr@id>', 'rserr@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('rserr@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_ERROR, result.action);
        System.assert(result.message.contains('Reopen_Status__c invÃ¡lido'));
        cleanupStatics();
    }

    @IsTest
    static void testDefaultRouteFallback() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('default@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        route.isDefaultRoute = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<def@id>', 'unknown@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('unknown@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_NEW_CASE, result.action);
        Case c = [SELECT WS_Email_Route_Key__c FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals('default@company.com', c.WS_Email_Route_Key__c);
        cleanupStatics();
    }

    @IsTest
    static void testIgnoreInactiveRoute() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('inactive@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        route.active = false;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<inactive@id>', 'inactive@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('inactive@company.com', 'sender@example.com')
        );

        System.assertEquals(WS_EmailToCaseConstants.ACTION_ERROR, result.action);
        System.assertEquals(0, [SELECT count() FROM Case WHERE Subject = 'Sub']);
        cleanupStatics();
    }

    @IsTest
    static void testPublishesAttachmentsAsContentVersion() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('attach@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        route.createContentFiles = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        Messaging.InboundEmail email = WS_EmailToCaseTestDataFactory.buildEmail('<att@id>', 'attach@company.com', 'sender@example.com', 'Sub', 'Body', null);
        Messaging.InboundEmail.BinaryAttachment b = new Messaging.InboundEmail.BinaryAttachment();
        b.body = Blob.valueOf('bin');
        b.fileName = 'file.bin';
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { b };
        Messaging.InboundEmail.TextAttachment t = new Messaging.InboundEmail.TextAttachment();
        t.body = 'txt';
        t.fileName = 'file.txt';
        email.textAttachments = new Messaging.InboundEmail.TextAttachment[] { t };

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            email,
            WS_EmailToCaseTestDataFactory.buildEnvelope('attach@company.com', 'sender@example.com')
        );

        Integer links = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :result.caseId];
        System.assert(links > 0);
        cleanupStatics();
    }

    @IsTest
    static void testSuccessDoesNotCreateIntegrationLog() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('logs@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        route.persistEmailAudit = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<logs@id>', 'logs@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('logs@company.com', 'sender@example.com')
        );

        Integer logsCount = [SELECT count() FROM LogIntegracao__c WHERE MetodoCallout__c = 'EMAIL'];
        System.assertEquals(0, logsCount);
        cleanupStatics();
    }

    @IsTest
    static void testDuplicateDoesNotCreateIntegrationLog() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('logdup@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        route.persistEmailAudit = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseOrchestrator orch = new WS_EmailToCaseOrchestrator();
        orch.process(
            WS_EmailToCaseTestDataFactory.buildEmail('<logdup@id>', 'logdup@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('logdup@company.com', 'sender@example.com')
        );
        orch.process(
            WS_EmailToCaseTestDataFactory.buildEmail('<logdup@id>', 'logdup@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('logdup@company.com', 'sender@example.com')
        );

        Integer logsCount = [SELECT count() FROM LogIntegracao__c WHERE MetodoCallout__c = 'EMAIL'];
        System.assertEquals(0, logsCount);
        cleanupStatics();
    }

    @IsTest
    static void testErrorLogIsCoherent() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('errlog@company.com', 'QUEUE', 'MISSING_Q', 'REOPEN', 10);
        route.persistEmailAudit = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<err@id>', 'errlog@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('errlog@company.com', 'sender@example.com')
        );

        LogIntegracao__c log = [
            SELECT DescritivoErroLog__c, ComentariosObservacoes__c, MetodoCallout__c, RequestBody__c
            FROM LogIntegracao__c
            WHERE MetodoCallout__c = 'EMAIL'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('EMAIL', log.MetodoCallout__c);
        System.assert(log.DescritivoErroLog__c != null);
        System.assert(log.ComentariosObservacoes__c.contains('From: sender@example.com'));
        System.assert(log.ComentariosObservacoes__c.contains('Envelope To: errlog@company.com'));
        System.assert(log.RequestBody__c != null);
        System.assert(log.RequestBody__c.contains('PlainTextBody:'));
        System.assert(log.RequestBody__c.contains('Body'));
        cleanupStatics();
    }

    @IsTest
    static void testClockServicePassageOfTime() {
        WS_EmailToCaseCaseService caseService = new WS_EmailToCaseCaseService();
        Group q = getQueue();
        Case closedCase = closeCaseNow(q.Id);
        Case loaded = [SELECT Id, ClosedDate, IsClosed FROM Case WHERE Id = :closedCase.Id LIMIT 1];

        Boolean within = caseService.isWithinReopenWindow(loaded, 5, loaded.ClosedDate.addMinutes(4));
        Boolean outside = caseService.isWithinReopenWindow(loaded, 5, loaded.ClosedDate.addMinutes(6));

        System.assertEquals(true, within);
        System.assertEquals(false, outside);
        cleanupStatics();
    }

    @IsTest
    static void testEmptyBodyFallbackDescription() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('body@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail('<body@id>', 'body@company.com', 'sender@example.com', 'Sub', null, null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('body@company.com', 'sender@example.com')
        );

        Case c = [SELECT Description FROM Case WHERE Id = :result.caseId LIMIT 1];
        System.assertEquals(WS_EmailToCaseConstants.NO_BODY_FALLBACK, c.Description);
        cleanupStatics();
    }

    @IsTest
    static void testNullMessageIdUsesHashFallback() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute('hash@company.com', 'QUEUE', q.DeveloperName, 'REOPEN', 10);
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseProcessResult result = new WS_EmailToCaseOrchestrator().process(
            WS_EmailToCaseTestDataFactory.buildEmail(null, 'hash@company.com', 'sender@example.com', 'Sub', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('hash@company.com', 'sender@example.com')
        );

        EmailMessage emailMessage = [SELECT MessageIdentifier FROM EmailMessage WHERE ParentId = :result.caseId LIMIT 1];
        System.assert(emailMessage.MessageIdentifier.startsWith('hash:'));
        cleanupStatics();
    }

    @IsTest
    static void testLegacyOrchestratorConstructorDelegatesToInboundService() {
        Group q = getQueue();
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'legacy@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_QUEUE,
            q.DeveloperName,
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            60
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseOrchestrator orchestrator = new WS_EmailToCaseOrchestrator(
            new WS_EmailToCaseRouteService(),
            new WS_EmailToCaseDedupService(),
            new WS_EmailToCaseThreadingService(),
            new WS_EmailToCaseCaseService(),
            new WS_EmailToCaseOwnerService(),
            new WS_EmailToCaseAttachmentService(),
            new WS_EmailToCaseEmailMessageService(),
            new WS_EmailToCaseLogService(),
            WS_EmailToCaseClock.get()
        );

        WS_EmailToCaseProcessResult result = orchestrator.process(
            WS_EmailToCaseTestDataFactory.buildEmail('<legacy@id>', 'legacy@company.com', 'sender@example.com', 'Legacy', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('legacy@company.com', 'sender@example.com')
        );

        Assert.areEqual(true, result.success);
        Assert.areEqual(WS_EmailToCaseConstants.ACTION_NEW_CASE, result.action);
        cleanupStatics();
    }

    @IsTest
    static void testEmailToCaseUtilsHappyPaths() {
        Assert.areEqual('abc', WS_EmailToCaseUtils.normalize('  ABC  '));
        Assert.areEqual('msg@test.com', WS_EmailToCaseUtils.normalizeMessageId('<MSG@Test.com>'));
        Assert.areEqual('a@test.com;b@test.com', WS_EmailToCaseUtils.joinAddresses(new String[]{ 'a@test.com', 'b@test.com' }));
        Assert.areEqual(null, WS_EmailToCaseUtils.joinAddresses(null));
        Assert.areEqual(new Set<String>{ 'a@test.com', 'b@test.com' }, WS_EmailToCaseUtils.normalizeAddressSet(new String[]{ ' A@Test.com ', null, 'b@test.com', 'a@test.com' }));
        Assert.areEqual(null, WS_EmailToCaseUtils.normalizeAddressSet(null).isEmpty() ? null : 'unexpected');
        Assert.areEqual(64, WS_EmailToCaseUtils.computeSha256('abc').length());
        Assert.areEqual('abc', WS_EmailToCaseUtils.safeLeft('abcdef', 3));
        Assert.areEqual('abc', WS_EmailToCaseUtils.safeLeft('abc', 10));
        Assert.areEqual(null, WS_EmailToCaseUtils.safeLeft(null, 3));
        Assert.areEqual('teste html', WS_EmailToCaseUtils.htmlToText('<p>teste <b>html</b></p>'));
        Assert.areEqual(null, WS_EmailToCaseUtils.htmlToText(null));

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail.Header h1 = new Messaging.InboundEmail.Header();
        h1.name = 'X-Test';
        h1.value = 'valor';
        Messaging.InboundEmail.Header h2 = new Messaging.InboundEmail.Header();
        h2.name = 'Other';
        h2.value = 'outro';
        email.headers = new Messaging.InboundEmail.Header[]{ h1, h2 };
        Assert.areEqual('valor', WS_EmailToCaseUtils.getHeaderValue(email, 'x-test'));
        Assert.areEqual(null, WS_EmailToCaseUtils.getHeaderValue(email, 'missing'));
        Assert.areEqual(true, WS_EmailToCaseUtils.canWriteCaseField('Subject'));
        Assert.areEqual(false, WS_EmailToCaseUtils.canWriteCaseField('CampoInexistente__c'));
        WS_EmailToCaseUtils.ensureCaseCreateAccess();
        WS_EmailToCaseUtils.ensureCaseUpdateAccess();
    }

    @IsTest
    static void testOwnerServiceValidationBranches() {
        WS_EmailToCaseOwnerService ownerService = new WS_EmailToCaseOwnerService();

        try {
            ownerService.resolveOwnerId(null);
            Assert.fail('Deveria validar rota nula.');
        } catch (Exception ex) {
            Assert.areEqual(true, ex.getMessage().contains('Rota'));
        }

        try {
            WS_EmailToCaseRouteConfig invalidTypeRoute = new WS_EmailToCaseRouteConfig();
            invalidTypeRoute.routeKey = 'route-key';
            invalidTypeRoute.ownerType = 'INVALID';
            ownerService.resolveOwnerId(invalidTypeRoute);
            Assert.fail('Deveria validar owner type inválido.');
        } catch (Exception ex) {
            Assert.areEqual(true, ex.getMessage().contains('Owner_Type__c'));
        }

        try {
            WS_EmailToCaseRouteConfig blankQueueRoute = new WS_EmailToCaseRouteConfig();
            blankQueueRoute.ownerType = WS_EmailToCaseConstants.OWNER_TYPE_QUEUE;
            blankQueueRoute.ownerKey = '   ';
            ownerService.resolveOwnerId(blankQueueRoute);
            Assert.fail('Deveria exigir Owner_Key__c para fila.');
        } catch (Exception ex) {
            Assert.areEqual(true, ex.getMessage().contains('Owner_Key__c'));
        }

        try {
            WS_EmailToCaseRouteConfig blankUserRoute = new WS_EmailToCaseRouteConfig();
            blankUserRoute.ownerType = WS_EmailToCaseConstants.OWNER_TYPE_USER;
            blankUserRoute.ownerKey = null;
            ownerService.resolveOwnerId(blankUserRoute);
            Assert.fail('Deveria exigir Owner_Key__c para usuário.');
        } catch (Exception ex) {
            Assert.areEqual(true, ex.getMessage().contains('Owner_Key__c'));
        }
    }

    @IsTest
    static void testOwnerServiceCacheAndQueueWithoutCaseAccess() {
        WS_EmailToCaseOwnerService ownerService = new WS_EmailToCaseOwnerService();

        Group queueWithoutAccess = new Group(Name = 'WS Q NO ACCESS', DeveloperName = 'WS_Q_NO_ACCESS', Type = 'Queue');
        insert queueWithoutAccess;

        try {
            WS_EmailToCaseRouteConfig noAccessRoute = new WS_EmailToCaseRouteConfig();
            noAccessRoute.ownerType = WS_EmailToCaseConstants.OWNER_TYPE_QUEUE;
            noAccessRoute.ownerKey = queueWithoutAccess.DeveloperName;
            ownerService.resolveOwnerId(noAccessRoute);
            Assert.fail('Deveria validar queue sem acesso a Case.');
        } catch (Exception ex) {
            Assert.areEqual(true, ex.getMessage().contains('Case'));
        }

        Group queue = getQueue();
        WS_EmailToCaseRouteConfig queueRoute = new WS_EmailToCaseRouteConfig();
        queueRoute.ownerType = WS_EmailToCaseConstants.OWNER_TYPE_QUEUE;
        queueRoute.ownerKey = queue.DeveloperName;
        Id firstQueueOwner = ownerService.resolveOwnerId(queueRoute);
        Id secondQueueOwner = ownerService.resolveOwnerId(queueRoute);
        Assert.areEqual(firstQueueOwner, secondQueueOwner);

        WS_EmailToCaseRouteConfig userRoute = new WS_EmailToCaseRouteConfig();
        userRoute.ownerType = WS_EmailToCaseConstants.OWNER_TYPE_USER;
        userRoute.ownerKey = UserInfo.getUserName();
        Id firstUserOwner = ownerService.resolveOwnerId(userRoute);
        Id secondUserOwner = ownerService.resolveOwnerId(userRoute);
        Assert.areEqual(firstUserOwner, secondUserOwner);
    }

    private static Group getQueue() {
        return [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'WS_Q_TEST'
            LIMIT 1
        ];
    }

    private static Case closeCaseNow(Id ownerId) {
        Case c = new Case(
            Subject = 'Case fechado',
            Origin = 'Email',
            Priority = 'Medium',
            OwnerId = ownerId,
            Status = WS_EmailToCaseTestDataFactory.getAnyOpenStatus()
        );
        insert c;
        c.Status = WS_EmailToCaseTestDataFactory.getAnyClosedStatus();
        update c;
        return [SELECT Id, IsClosed, ClosedDate FROM Case WHERE Id = :c.Id LIMIT 1];
    }

    private static void cleanupStatics() {
        WS_EmailToCaseClock.clearTestClock();
        WS_EmailToCaseThreadingService.clearTestThreadingIds();
        WS_EmailToCaseConfigService.clearTestRoutes();
    }
}