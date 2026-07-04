@IsTest
private class AccountCaseScheduleControllerTest {
    private static final String TEST_QUEUE = 'TSV_SCHED_CTRL_TEST';

    @TestSetup
    static void setupData() {
        insert new Account(Name = 'Conta Controller Agendamento');

        Group queue = new Group(Name = 'TSV Schedule Controller Test', DeveloperName = TEST_QUEUE, Type = 'Queue');
        insert queue;
        insert new List<QueueSobject>{
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Case'),
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Agendamento__c')
        };
    }

    @IsTest
    static void shouldReturnInitialState() {
        Account account = getAccount();

        Test.startTest();
        AccountCaseScheduleDTO.InitialStateDTO state = AccountCaseScheduleController.getInitialState(account.Id);
        Test.stopTest();

        Assert.areEqual(account.Id, state.accountId, 'Controller should return Account state');
    }

    @IsTest
    static void shouldReturnIndicator() {
        Account account = getAccount();

        Test.startTest();
        AccountCaseScheduleDTO.IndicatorDTO indicator = AccountCaseScheduleController.getIndicator(account.Id);
        Test.stopTest();

        Assert.areEqual(account.Id, indicator.accountId, 'Controller should return Account indicator');
        Assert.areEqual(0, indicator.totalSchedules, 'Controller should report no schedules for empty Account');
    }

    @IsTest
    static void shouldWrapInitialStateErrors() {
        Test.startTest();
        try {
            AccountCaseScheduleController.getInitialState(null);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException ex) {
            Assert.areEqual(true, ex.getMessage() != null, 'Controller should expose a friendly handled error');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldDelegateTreeAndQueues() {
        RecordType rt = setupCaseCreationContext(false);

        CaseCreationDTO.CategorizationRequestDTO request = new CaseCreationDTO.CategorizationRequestDTO();
        request.recordTypeId = rt.Id;
        request.recordTypeDeveloperName = rt.DeveloperName;
        request.unidadeNegocio = 'Salvador';

        Test.startTest();
        CaseCreationDTO.TreeOptionsDTO tree = AccountCaseScheduleController.getTreeOptions(request);
        List<CaseCreationDTO.QueueOptionDTO> queues = AccountCaseScheduleController.getAvailableQueues(rt.DeveloperName, 'Salvador');
        Test.stopTest();

        Assert.isNotNull(tree, 'Tree options should be returned');
        Assert.isNotNull(queues, 'Queue list should be returned');
    }

    @IsTest
    static void shouldResolveSaveAndToggleThroughController() {
        RecordType rt = setupCaseCreationContext(true);
        Account account = getAccount();
        AccountCaseScheduleDTO.SaveRequestDTO request = baseRequest(account.Id, rt);
        request.ownerType = 'QUEUE';
        request.ownerQueueDeveloperName = TEST_QUEUE;

        Test.startTest();
        CaseCreationDTO.ResolveSelectionResponseDTO resolved = AccountCaseScheduleController.resolveCategorizationSelection(request.categorization);
        AccountCaseScheduleDTO.ScheduleDTO saved = AccountCaseScheduleController.saveSchedule(request);
        AccountCaseScheduleDTO.ScheduleDTO inactive = AccountCaseScheduleController.setActive(account.Id, saved.id, false);
        Test.stopTest();

        Assert.areEqual(true, resolved.hasParametrizedQueue, 'Controller should resolve parametrized queue');
        Assert.areEqual(TEST_QUEUE, saved.ownerQueueDeveloperName, 'Controller should save queue owner');
        Assert.areEqual(false, inactive.ativo, 'Controller should toggle active flag');
    }

    @IsTest
    static void shouldSearchUsersThroughController() {
        Test.startTest();
        List<AccountCaseScheduleDTO.OptionDTO> users = AccountCaseScheduleController.searchUsers('User');
        Test.stopTest();

        Assert.areEqual(true, users.size() >= 0, 'User search should return a non-null list');
    }

    @IsTest
    static void shouldWrapUnexpectedControllerErrors() {
        ApexTestSeam.set('AccountCaseScheduleController.testException', new ListException('Erro forçado'));

        Test.startTest();
        assertHandledException(new ControllerCall('initialState'));
        assertHandledException(new ControllerCall('indicator'));
        assertHandledException(new ControllerCall('tree'));
        assertHandledException(new ControllerCall('resolve'));
        assertHandledException(new ControllerCall('queues'));
        assertHandledException(new ControllerCall('users'));
        assertHandledException(new ControllerCall('save'));
        assertHandledException(new ControllerCall('active'));
        Test.stopTest();

        ApexTestSeam.clear('AccountCaseScheduleController.testException');
    }

    @IsTest
    static void shouldWrapFunctionalControllerErrors() {
        ApexTestSeam.set('AccountCaseScheduleController.testException', new AccountCaseScheduleService.FunctionalException('Erro funcional'));

        Test.startTest();
        assertHandledException(new ControllerCall('initialState'));
        assertHandledException(new ControllerCall('indicator'));
        assertHandledException(new ControllerCall('resolve'));
        assertHandledException(new ControllerCall('save'));
        assertHandledException(new ControllerCall('active'));
        Test.stopTest();

        ApexTestSeam.clear('AccountCaseScheduleController.testException');
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Conta Controller Agendamento' LIMIT 1];
    }

    private static RecordType setupCaseCreationContext(Boolean parametrizedQueue) {
        RecordType rt = matchingCaseRecordType();
        CaseCreationSelector.UnidadeConfig config = new CaseCreationSelector.UnidadeConfig();
        config.recordTypeDeveloperName = rt.DeveloperName;
        config.unidadeNegocio = 'Salvador';
        config.queueToken = 'TSV';
        config.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{ rt.DeveloperName => config };
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(parametrizedQueue, parametrizedQueue, parametrizedQueue ? TEST_QUEUE : null, rt.Id)
        };
        return rt;
    }

    private static AccountCaseScheduleDTO.SaveRequestDTO baseRequest(Id accountId, RecordType rt) {
        AccountCaseScheduleDTO.SaveRequestDTO request = new AccountCaseScheduleDTO.SaveRequestDTO();
        request.accountId = accountId;
        request.ativo = true;
        request.categorization = CaseCreationTestDataFactory.baseCategorization();
        request.categorization.recordTypeId = rt.Id;
        request.categorization.recordTypeDeveloperName = rt.DeveloperName;
        request.categorization.unidadeNegocio = 'Salvador';
        request.frequencia = 'Diária';
        request.horarioExecucao = '09:00';
        request.dataInicio = Date.today();
        request.pularFimDeSemana = true;
        request.descricaoAtividade = 'Criar caso recorrente via controller';
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
        Assert.fail('Expected matching Case and Agendamento Record Types');
        return null;
    }

    private static void assertHandledException(ControllerCall call) {
        try {
            call.run();
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException ex) {
            Assert.areEqual(true, ex.getMessage() != null, 'Controller should throw a handled exception');
        }
    }

    private class ControllerCall {
        private String methodName;

        ControllerCall(String methodName) {
            this.methodName = methodName;
        }

        void run() {
            if (methodName == 'initialState') {
                AccountCaseScheduleController.getInitialState(null);
            } else if (methodName == 'indicator') {
                AccountCaseScheduleController.getIndicator(null);
            } else if (methodName == 'tree') {
                AccountCaseScheduleController.getTreeOptions(null);
            } else if (methodName == 'resolve') {
                AccountCaseScheduleController.resolveCategorizationSelection(null);
            } else if (methodName == 'queues') {
                AccountCaseScheduleController.getAvailableQueues(null, null);
            } else if (methodName == 'users') {
                AccountCaseScheduleController.searchUsers(null);
            } else if (methodName == 'save') {
                AccountCaseScheduleController.saveSchedule(null);
            } else if (methodName == 'active') {
                AccountCaseScheduleController.setActive(null, null, false);
            }
        }
    }
}