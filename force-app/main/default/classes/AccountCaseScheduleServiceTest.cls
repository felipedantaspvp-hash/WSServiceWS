@IsTest
private class AccountCaseScheduleServiceTest {
    private static final String TEST_UNIT = 'Salvador';
    private static final String TEST_QUEUE = 'TSV_SCHED_TEST';

    @TestSetup
    static void setupData() {
        insert new Account(Name = 'Conta Agendamento Teste');

        Group queue = new Group(Name = 'TSV Schedule Test', DeveloperName = TEST_QUEUE, Type = 'Queue');
        insert queue;
        insert new List<QueueSobject>{
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Case'),
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Agendamento__c')
        };
    }

    @IsTest
    static void shouldGetSchedules_WhenAccountHasRows() {
        TestContext ctx = setupContext(false);
        Account account = getAccount();
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(account.Id, ctx, 'USER');
        request.ownerUserId = UserInfo.getUserId();
        AccountCaseScheduleService.saveSchedule(request);

        Test.startTest();
        AccountCaseScheduleDTO.InitialStateDTO state = AccountCaseScheduleService.getInitialState(account.Id);
        Test.stopTest();

        Assert.areEqual(account.Id, state.accountId, 'Account should be preserved in state');
        Assert.areEqual(1, state.schedules.size(), 'One schedule should be returned');
        Assert.areEqual(AccountCaseScheduleHelper.getAgendamentoObjectApiName(), state.agendamentoObjectApiName, 'Object API name should be reported');
    }

    @IsTest
    static void shouldGetIndicator_WhenAccountHasActiveAndInactiveSchedules() {
        TestContext ctx = setupContext(false);
        Account account = getAccount();
        AccountCaseScheduleDTO.SaveRequestDTO activeRequest = baseRequest(account.Id, ctx, 'USER');
        activeRequest.ownerUserId = UserInfo.getUserId();
        AccountCaseScheduleService.saveSchedule(activeRequest);

        AccountCaseScheduleDTO.SaveRequestDTO inactiveRequest = baseRequest(account.Id, ctx, 'USER');
        inactiveRequest.ownerUserId = UserInfo.getUserId();
        inactiveRequest.ativo = false;
        AccountCaseScheduleService.saveSchedule(inactiveRequest);

        Test.startTest();
        AccountCaseScheduleDTO.IndicatorDTO indicator = AccountCaseScheduleService.getIndicator(account.Id);
        Test.stopTest();

        Assert.areEqual(account.Id, indicator.accountId, 'Indicator should preserve Account Id');
        Assert.areEqual(2, indicator.totalSchedules, 'Indicator should count all schedules');
        Assert.areEqual(1, indicator.activeSchedules, 'Indicator should count active schedules');
        Assert.areEqual(1, indicator.inactiveSchedules, 'Indicator should count inactive schedules');
    }

    @IsTest
    static void shouldGetIndicator_WhenAccountHasNoSchedules() {
        Account account = getAccount();

        Test.startTest();
        AccountCaseScheduleDTO.IndicatorDTO indicator = AccountCaseScheduleService.getIndicator(account.Id);
        Test.stopTest();

        Assert.areEqual(0, indicator.totalSchedules, 'Indicator should return zero total schedules');
        Assert.areEqual(0, indicator.activeSchedules, 'Indicator should return zero active schedules');
        Assert.areEqual(0, indicator.inactiveSchedules, 'Indicator should return zero inactive schedules');
    }

    @IsTest
    static void shouldCreateSchedule_WhenOwnerIsUser() {
        TestContext ctx = setupContext(false);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'USER');
        request.ownerUserId = UserInfo.getUserId();

        Test.startTest();
        AccountCaseScheduleDTO.ScheduleDTO saved = AccountCaseScheduleService.saveSchedule(request);
        Test.stopTest();

        Agendamento__c row = [SELECT Conta__c, OwnerType__c, OwnerUser__c, OwnerQueueDeveloperName__c FROM Agendamento__c WHERE Id = :saved.id];
        Assert.areEqual(request.accountId, row.Conta__c, 'Schedule should stay linked to current Account');
        Assert.areEqual('USER', row.OwnerType__c, 'Owner type should be User');
        Assert.areEqual(UserInfo.getUserId(), row.OwnerUser__c, 'Owner user lookup should be saved');
        Assert.areEqual(null, row.OwnerQueueDeveloperName__c, 'Queue DeveloperName should be cleared for user owner');
    }

    @IsTest
    static void shouldCreateSchedule_WhenOwnerIsQueue() {
        TestContext ctx = setupContext(true);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'QUEUE');
        request.ownerQueueDeveloperName = TEST_QUEUE;

        Test.startTest();
        AccountCaseScheduleDTO.ScheduleDTO saved = AccountCaseScheduleService.saveSchedule(request);
        Test.stopTest();

        Agendamento__c row = [SELECT OwnerType__c, OwnerUser__c, OwnerQueueDeveloperName__c FROM Agendamento__c WHERE Id = :saved.id];
        Assert.areEqual('QUEUE', row.OwnerType__c, 'Owner type should be Queue');
        Assert.areEqual(null, row.OwnerUser__c, 'Owner user should be cleared for queue owner');
        Assert.areEqual(TEST_QUEUE, row.OwnerQueueDeveloperName__c, 'Queue DeveloperName should be saved');
    }

    @IsTest
    static void shouldUpdateSchedule_WhenExistingScheduleEdited() {
        TestContext ctx = setupContext(false);
        Account account = getAccount();
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(account.Id, ctx, 'USER');
        request.ownerUserId = UserInfo.getUserId();
        AccountCaseScheduleDTO.ScheduleDTO saved = AccountCaseScheduleService.saveSchedule(request);

        request.id = saved.id;
        request.descricaoAtividade = 'Descrição alterada';
        request.ativo = false;

        Test.startTest();
        AccountCaseScheduleDTO.ScheduleDTO updated = AccountCaseScheduleService.saveSchedule(request);
        Test.stopTest();

        Assert.areEqual(saved.id, updated.id, 'Update should keep the same Id');
        Assert.areEqual(false, updated.ativo, 'Active flag should be updated');
        Assert.areEqual('Descrição alterada', [SELECT DescricaoAtividade__c FROM Agendamento__c WHERE Id = :saved.id].DescricaoAtividade__c, 'Description should be updated');
    }

    @IsTest
    static void shouldSetInactive_WhenToggleRequested() {
        TestContext ctx = setupContext(false);
        Account account = getAccount();
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(account.Id, ctx, 'USER');
        request.ownerUserId = UserInfo.getUserId();
        AccountCaseScheduleDTO.ScheduleDTO saved = AccountCaseScheduleService.saveSchedule(request);

        Test.startTest();
        AccountCaseScheduleDTO.ScheduleDTO updated = AccountCaseScheduleService.setActive(account.Id, saved.id, false);
        Test.stopTest();

        Assert.areEqual(false, updated.ativo, 'Schedule should be inactive');
    }

    @IsTest
    static void shouldFail_WhenAccountIsMissing() {
        TestContext ctx = setupContext(false);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(null, ctx, 'USER');
        request.ownerUserId = UserInfo.getUserId();

        Test.startTest();
        try {
            AccountCaseScheduleService.saveSchedule(request);
            Assert.fail('Expected missing Account error');
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            Assert.areEqual(Label.AccountCaseSchedule_AccountRequired, ex.getMessage(), 'Error should mention Account');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldFail_WhenCategorizationIsInvalid() {
        TestContext ctx = setupContext(false);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'USER');
        request.ownerUserId = UserInfo.getUserId();
        request.categorization.categoria = 'Categoria inválida';

        Test.startTest();
        try {
            AccountCaseScheduleService.saveSchedule(request);
            Assert.fail('Expected invalid categorization error');
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            Assert.areEqual(true, ex.getMessage().contains('categorização'), 'Error should mention categorization');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldFail_WhenUserOwnerIsMissing() {
        TestContext ctx = setupContext(false);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'USER');

        Test.startTest();
        try {
            AccountCaseScheduleService.saveSchedule(request);
            Assert.fail('Expected missing owner user error');
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            Assert.areEqual(Label.AccountCaseSchedule_OwnerUserRequired, ex.getMessage(), 'Error should mention user');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldFail_WhenQueueOwnerIsMissing() {
        TestContext ctx = setupContext(false);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'QUEUE');

        Test.startTest();
        try {
            AccountCaseScheduleService.saveSchedule(request);
            Assert.fail('Expected missing queue error');
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            Assert.areEqual(Label.AccountCaseSchedule_QueueRequired, ex.getMessage(), 'Error should mention queue');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldFail_WhenQueueDoesNotExist() {
        TestContext ctx = setupContext(false);
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'QUEUE');
        request.ownerQueueDeveloperName = 'QUEUE_DOES_NOT_EXIST';

        Test.startTest();
        try {
            AccountCaseScheduleService.saveSchedule(request);
            Assert.fail('Expected invalid queue error');
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            Assert.areEqual(Label.AccountCaseSchedule_QueueNotFoundCase, ex.getMessage(), 'Error should mention queue');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldFail_WhenUserIsInactive() {
        TestContext ctx = setupContext(false);
        User inactiveUser = createInactiveUser();
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(getAccount().Id, ctx, 'USER');
        request.ownerUserId = inactiveUser.Id;

        Test.startTest();
        try {
            AccountCaseScheduleService.saveSchedule(request);
            Assert.fail('Expected inactive user error');
        } catch (AccountCaseScheduleService.FunctionalException ex) {
            Assert.areEqual(Label.AccountCaseSchedule_InactiveUser, ex.getMessage(), 'Error should mention inactive user');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldSearchActiveUsers() {
        Test.startTest();
        List<AccountCaseScheduleDTO.OptionDTO> users = AccountCaseScheduleService.searchUsers('User');
        Test.stopTest();

        Assert.areEqual(true, users.size() >= 0, 'Search should return a non-null list');
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Conta Agendamento Teste' LIMIT 1];
    }

    private static TestContext setupContext(Boolean parametrizedQueue) {
        TestContext ctx = new TestContext();
        ctx.caseRecordType = matchingCaseRecordType();

        CaseCreationSelector.UnidadeConfig config = new CaseCreationSelector.UnidadeConfig();
        config.recordTypeDeveloperName = ctx.caseRecordType.DeveloperName;
        config.unidadeNegocio = TEST_UNIT;
        config.queueToken = 'TSV';
        config.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{ ctx.caseRecordType.DeveloperName => config };
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(parametrizedQueue, parametrizedQueue, parametrizedQueue ? TEST_QUEUE : null, ctx.caseRecordType.Id)
        };
        return ctx;
    }

    private static AccountCaseScheduleDTO.SaveRequestDTO baseRequest(Id accountId, TestContext ctx, String ownerType) {
        AccountCaseScheduleDTO.SaveRequestDTO request = new AccountCaseScheduleDTO.SaveRequestDTO();
        request.accountId = accountId;
        request.ativo = true;
        request.categorization = CaseCreationTestDataFactory.baseCategorization();
        request.categorization.recordTypeId = ctx.caseRecordType.Id;
        request.categorization.recordTypeDeveloperName = ctx.caseRecordType.DeveloperName;
        request.categorization.unidadeNegocio = TEST_UNIT;
        request.frequencia = 'Diária';
        request.horarioExecucao = '08:30';
        request.dataInicio = Date.today();
        request.pularFimDeSemana = true;
        request.descricaoAtividade = 'Criar caso recorrente de teste';
        request.ownerType = ownerType;
        return request;
    }

    private static RecordType matchingCaseRecordType() {
        Set<String> scheduleRecordTypeDeveloperNames = new Set<String>();
        for (RecordType scheduleRecordType : [
            SELECT DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Agendamento__c'
                AND IsActive = true
        ]) {
            scheduleRecordTypeDeveloperNames.add(scheduleRecordType.DeveloperName);
        }
        for (RecordType caseRecordType : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
                AND IsActive = true
        ]) {
            if (scheduleRecordTypeDeveloperNames.contains(caseRecordType.DeveloperName)) return caseRecordType;
        }
        Assert.fail('Expected at least one Case Record Type also defined for Agendamento__c');
        return null;
    }

    private static User createInactiveUser() {
        Profile profile = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User userRow = new User(
            Alias = 'iusr',
            Email = 'inactive' + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Inactive',
            LanguageLocaleKey = 'pt_BR',
            LocaleSidKey = 'pt_BR',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            UserName = 'inactive' + uniqueValue + '@example.com',
            IsActive = false
        );
        insert userRow;
        return userRow;
    }

    private class TestContext {
        RecordType caseRecordType;
    }
}