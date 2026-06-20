@IsTest
private class CaseScheduleServiceTest {
    private static final String TEST_UNIT = 'Salvador';
    private static final String TEST_QUEUE = 'TSV_SCHEDULE_ENGINE';

    @TestSetup
    static void setupData() {
        insert new Account(Name = 'Conta Motor Agendamento');

        Group queue = new Group(Name = 'TSV Schedule Engine', DeveloperName = TEST_QUEUE, Type = 'Queue');
        insert queue;
        insert new List<QueueSobject>{
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Case'),
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Agendamento__c')
        };
    }

    @IsTest
    static void shouldCreateCase_WhenDailyScheduleIsEligibleForUserOwner() {
        TestContext ctx = setupContext(false);
        Datetime nowValue = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);
        CaseScheduleDTO scheduleDTO = CaseScheduleDTO.fromSchedule(schedule);
        Assert.areEqual(schedule.Id, scheduleDTO.scheduleId, 'DTO should map schedule Id');

        Test.startTest();
        CaseScheduleService.testNow = nowValue;
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Case createdCase = [SELECT AccountId, Agendamento__c, Origin, OwnerId, Status FROM Case WHERE Agendamento__c = :schedule.Id LIMIT 1];
        Assert.areEqual(1, results.size(), 'One schedule should be processed');
        Assert.areEqual(true, results[0].success, 'Schedule should succeed');
        Assert.areEqual(schedule.Conta__c, createdCase.AccountId, 'Case should keep schedule Account');
        Assert.areEqual(schedule.Id, createdCase.Agendamento__c, 'Case should reference source schedule');
        Assert.areEqual(UserInfo.getUserId(), createdCase.OwnerId, 'Case should be assigned to configured user');
        Assert.areEqual('Aberto', createdCase.Status, 'Case should start open');
    }

    @IsTest
    static void shouldCreateCase_WhenQueueOwnerIsValid() {
        TestContext ctx = setupContext(true);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'QUEUE', TEST_QUEUE, true, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = :TEST_QUEUE LIMIT 1];
        Case createdCase = [SELECT OwnerId, Agendamento__c FROM Case WHERE Agendamento__c = :schedule.Id LIMIT 1];
        Assert.areEqual(queue.Id, createdCase.OwnerId, 'Case should be assigned to configured queue');
    }

    @IsTest
    static void shouldNotCreateCase_WhenBeforeExecutionTime() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(11, 0, 0, 0), 'USER', null, true, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(true, results[0].skipped, 'Schedule should be skipped before execution time');
        Assert.areEqual(0, [SELECT count() FROM Case WHERE Agendamento__c = :schedule.Id], 'No Case should be created');
    }

    @IsTest
    static void shouldNotCreateCase_WhenStartDateIsFuture() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today().addDays(1), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(true, results[0].skipped, 'Future schedule should be skipped');
        Assert.areEqual(0, [SELECT count() FROM Case WHERE Agendamento__c = :schedule.Id], 'No Case should be created');
    }

    @IsTest
    static void shouldRegisterError_WhenFrequencyIsMissing() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);
        update new Agendamento__c(Id = schedule.Id, Frequencia__c = null);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Agendamento__c updated = [SELECT UltimoErroExecucao__c FROM Agendamento__c WHERE Id = :schedule.Id];
        Assert.areEqual(false, results[0].success, 'Schedule should fail validation');
        Assert.areEqual(true, updated.UltimoErroExecucao__c.contains('Frequência'), 'Error should be stored on schedule');
    }

    @IsTest
    static void shouldRegisterError_WhenQueueDoesNotExist() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'QUEUE', 'QUEUE_NOT_FOUND_SCHEDULE', true, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Agendamento__c updated = [SELECT UltimoErroExecucao__c FROM Agendamento__c WHERE Id = :schedule.Id];
        Assert.areEqual(true, updated.UltimoErroExecucao__c.contains('Fila'), 'Queue error should be stored');
        Assert.areEqual(0, [SELECT count() FROM Case WHERE Agendamento__c = :schedule.Id], 'No Case should be created');
    }

    @IsTest
    static void shouldSkipWeekend_WhenConfiguredToSkipWeekend() {
        TestContext ctx = setupContext(false);
        Date saturday = Date.newInstance(2026, 6, 20);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', saturday.addDays(-1), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(saturday, Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(true, results[0].skipped, 'Weekend should be skipped');
        Assert.areEqual(null, [SELECT UltimoErroExecucao__c FROM Agendamento__c WHERE Id = :schedule.Id].UltimoErroExecucao__c, 'Weekend skip should not register error');
    }

    @IsTest
    static void shouldCreateOnWeekend_WhenWeekendSkipIsFalse() {
        TestContext ctx = setupContext(false);
        Date saturday = Date.newInstance(2026, 6, 20);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', saturday.addDays(-1), Time.newInstance(8, 0, 0, 0), 'USER', null, false, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(saturday, Time.newInstance(10, 0, 0, 0));
        CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(1, [SELECT count() FROM Case WHERE Agendamento__c = :schedule.Id], 'Weekend execution should create Case when allowed');
    }

    @IsTest
    static void shouldCreateOnlyOnceForSameDailyWindow() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(1, [SELECT count() FROM Case WHERE Agendamento__c = :schedule.Id], 'Only one Case should exist for the daily window');
    }

    @IsTest
    static void shouldRespectWeeklyMonthlyQuarterlyAndAnnualFrequencies() {
        Date today = Date.today();
        Assert.areEqual(true, CaseScheduleService.isEligibleToRun(lightSchedule('Semanal', today.addDays(-7)), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0))), 'Weekly should run on same weekday');
        Assert.areEqual(false, CaseScheduleService.isEligibleToRun(lightSchedule('Semanal', today.addDays(-1)), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0))), 'Weekly should skip different weekday');
        Assert.areEqual(true, CaseScheduleService.isEligibleToRun(lightSchedule('Mensal', today.addMonths(-1)), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0))), 'Monthly should run on matching day');
        Assert.areEqual(true, CaseScheduleService.isEligibleToRun(lightSchedule('Trimestral', today.addMonths(-3)), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0))), 'Quarterly should run each three months');
        Assert.areEqual(true, CaseScheduleService.isEligibleToRun(lightSchedule('Anual', today.addYears(-1)), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0))), 'Annual should run on matching month and day');
    }

    @IsTest
    static void shouldClearPreviousError_WhenCaseCreationSucceeds() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);
        update new Agendamento__c(Id = schedule.Id, UltimoErroExecucao__c = 'Erro anterior');

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        CaseScheduleService.processSchedules(loadSchedules(new Set<Id>{ schedule.Id }));
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(null, [SELECT UltimoErroExecucao__c FROM Agendamento__c WHERE Id = :schedule.Id].UltimoErroExecucao__c, 'Previous error should be cleared after success');
    }

    @IsTest
    static void shouldHandleValidationBranches_WhenScheduleDataIsIncomplete() {
        TestContext ctx = setupContext(false);
        Agendamento__c base = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);

        List<Agendamento__c> rows = loadSchedules(new Set<Id>{ base.Id });
        Agendamento__c missingAccount = rows[0].clone(true, true, false, false);
        missingAccount.Conta__c = null;
        Agendamento__c missingBusinessUnit = rows[0].clone(true, true, false, false);
        missingBusinessUnit.UnidadeNegocio__c = null;
        Agendamento__c missingCaseType = rows[0].clone(true, true, false, false);
        missingCaseType.TipoCaso__c = null;
        Agendamento__c missingCategory = rows[0].clone(true, true, false, false);
        missingCategory.Categoria__c = null;
        Agendamento__c missingDescription = rows[0].clone(true, true, false, false);
        missingDescription.DescricaoAtividade__c = null;
        Agendamento__c missingStartDate = rows[0].clone(true, true, false, false);
        missingStartDate.DataInicio__c = null;
        Agendamento__c missingTime = rows[0].clone(true, true, false, false);
        missingTime.HorarioExecucao__c = null;
        Agendamento__c missingOwnerType = rows[0].clone(true, true, false, false);
        missingOwnerType.OwnerType__c = null;
        Agendamento__c missingOwnerUser = rows[0].clone(true, true, false, false);
        missingOwnerUser.OwnerUser__c = null;

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(new List<Agendamento__c>{
            missingAccount,
            missingBusinessUnit,
            missingCaseType,
            missingCategory,
            missingDescription,
            missingStartDate,
            missingTime,
            missingOwnerType,
            missingOwnerUser
        });
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(9, results.size(), 'All invalid branches should return a result');
        for (CaseScheduleResultDTO result : results) {
            Assert.areEqual(false, result.success, 'Invalid schedule should fail');
        }
    }

    @IsTest
    static void shouldHandleQueueAndCategorizationErrors() {
        TestContext ctx = setupContext(false);
        Group disabledQueue = new Group(Name = 'Disabled Schedule Queue', DeveloperName = 'TSV_DISABLED_SCHEDULE', Type = 'Queue');
        insert disabledQueue;

        Agendamento__c base = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);
        Agendamento__c disabledQueueSchedule = loadSchedules(new Set<Id>{ base.Id })[0].clone(true, true, false, false);
        disabledQueueSchedule.OwnerType__c = 'QUEUE';
        disabledQueueSchedule.OwnerQueueDeveloperName__c = disabledQueue.DeveloperName;
        disabledQueueSchedule.OwnerUser__c = null;

        Agendamento__c invalidCategorization = loadSchedules(new Set<Id>{ base.Id })[0].clone(true, true, false, false);
        invalidCategorization.Categoria__c = 'Categoria inexistente';

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(new List<Agendamento__c>{ disabledQueueSchedule, invalidCategorization });
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two invalid schedules should be processed');
        Assert.areEqual(false, results[0].success, 'Disabled queue should fail');
        Assert.areEqual(false, results[1].success, 'Invalid categorization should fail');
    }

    @IsTest
    static void shouldCoverUtilityBranches() {
        Assert.areEqual(0, CaseScheduleService.processSchedules(null).size(), 'Null input should return empty result');
        Assert.areEqual(0, CaseScheduleService.processSchedules(new List<Agendamento__c>()).size(), 'Empty input should return empty result');
        Assert.areEqual(false, CaseScheduleService.processSchedules(new List<Agendamento__c>{ null })[0].success, 'Null schedule in list should return error');
        Assert.areEqual(null, CaseScheduleService.buildExecutionWindow(null, System.now()), 'Null schedule should not build window');
        Assert.areEqual(false, CaseScheduleService.isEligibleToRun(null, System.now()), 'Null schedule should not be eligible');
        Assert.areEqual(false, CaseScheduleService.isEligibleToRun(lightSchedule('Diária', Date.today()), null), 'Null datetime should not be eligible');
        Assert.areEqual(false, CaseScheduleService.isEligibleToRun(new Agendamento__c(Ativo__c = false), System.now()), 'Inactive schedule should not be eligible');
        Assert.areEqual(false, CaseScheduleService.isEligibleToRun(lightSchedule('Quinzenal', Date.today()), Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0))), 'Unknown frequency should not be eligible');
        Assert.areEqual(null, CaseScheduleDTO.fromSchedule(null).scheduleId, 'Null schedule DTO should be empty');
        Assert.areEqual(0, CaseScheduleHelper.getCaseRecordTypesByDeveloperName(null).size(), 'Null record type set should return empty map');
        Assert.areEqual(0, CaseScheduleHelper.getCasesCreatedForSchedules(null, System.now(), System.now()).size(), 'Null schedule Ids should return empty cases');
        Assert.areEqual('abc', CaseScheduleHelper.safeLeft('abcdef', 3), 'Text should be trimmed');
        CaseScheduleHelper.putIfFieldExists(null, 'Name', 'Ignored');

        Date today = Date.today();
        CaseScheduleExecutionWindowDTO daily = CaseScheduleService.buildExecutionWindow(lightSchedule('Daily', today), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0)));
        CaseScheduleExecutionWindowDTO weekly = CaseScheduleService.buildExecutionWindow(lightSchedule('Weekly', today), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0)));
        CaseScheduleExecutionWindowDTO monthly = CaseScheduleService.buildExecutionWindow(lightSchedule('Monthly', today), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0)));
        CaseScheduleExecutionWindowDTO quarterly = CaseScheduleService.buildExecutionWindow(lightSchedule('Quarterly', today), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0)));
        CaseScheduleExecutionWindowDTO annual = CaseScheduleService.buildExecutionWindow(lightSchedule('Annual', today), Datetime.newInstance(today, Time.newInstance(10, 0, 0, 0)));

        Assert.areEqual(today, daily.windowStartDate, 'Daily window should start today');
        Assert.areEqual(7, weekly.windowStartDate.daysBetween(weekly.windowEndDate) + 1, 'Weekly window should have seven days');
        Assert.areEqual(1, monthly.windowStartDate.day(), 'Monthly window should start on day one');
        Assert.areEqual(1, quarterly.windowStartDate.day(), 'Quarterly window should start on day one');
        Assert.areEqual(1, annual.windowStartDate.month(), 'Annual window should start in January');
    }

    @IsTest
    static void shouldRegisterError_WhenOwnerUserDoesNotExist() {
        TestContext ctx = setupContext(false);
        Agendamento__c schedule = insertSchedule(ctx, 'Diária', Date.today(), Time.newInstance(8, 0, 0, 0), 'USER', null, true, true);
        Agendamento__c loaded = loadSchedules(new Set<Id>{ schedule.Id })[0];
        loaded.OwnerUser__c = createInactiveUser().Id;

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        List<CaseScheduleResultDTO> results = CaseScheduleService.processSchedules(new List<Agendamento__c>{ loaded });
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(false, results[0].success, 'Missing active user should fail');
        Assert.areEqual(true, results[0].errorMessage.contains('Usuário'), 'Error should mention user');
    }

    private static TestContext setupContext(Boolean parametrizedQueue) {
        TestContext ctx = new TestContext();
        ctx.caseRecordType = matchingCaseRecordType();
        ctx.scheduleRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Agendamento__c' AND DeveloperName = :ctx.caseRecordType.DeveloperName LIMIT 1];

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

    private static Agendamento__c insertSchedule(
        TestContext ctx,
        String frequency,
        Date startDate,
        Time executionTime,
        String ownerType,
        String queueDeveloperName,
        Boolean skipWeekend,
        Boolean active
    ) {
        Account account = [SELECT Id FROM Account WHERE Name = 'Conta Motor Agendamento' LIMIT 1];
        Agendamento__c row = new Agendamento__c();
        row.Conta__c = account.Id;
        row.RecordTypeId = ctx.scheduleRecordType.Id;
        row.Ativo__c = active;
        row.UnidadeNegocio__c = AccountCaseScheduleHelper.normalizeScheduleBusinessUnit(TEST_UNIT);
        row.TipoCaso__c = 'Solicitação';
        row.Categoria__c = 'Operação';
        row.Assunto__c = 'Acesso';
        row.Subassunto__c = 'Acesso indisponível';
        row.DescricaoAtividade__c = 'Criar caso recorrente pelo motor';
        row.Frequencia__c = frequency;
        row.DataInicio__c = startDate;
        row.HorarioExecucao__c = executionTime;
        row.PularFimDeSemana__c = skipWeekend;
        row.OwnerType__c = ownerType;
        if (ownerType == 'USER') {
            row.OwnerUser__c = UserInfo.getUserId();
            row.OwnerId = UserInfo.getUserId();
        } else {
            row.OwnerQueueDeveloperName__c = queueDeveloperName;
            List<Group> queues = [SELECT Id FROM Group WHERE DeveloperName = :queueDeveloperName LIMIT 1];
            row.OwnerId = queues.isEmpty() ? UserInfo.getUserId() : queues[0].Id;
        }
        insert row;
        return row;
    }

    private static List<Agendamento__c> loadSchedules(Set<Id> scheduleIds) {
        return [
            SELECT Id, Name, Conta__c, Ativo__c, UnidadeNegocio__c, TipoCaso__c,
                Categoria__c, Assunto__c, Subassunto__c, DataInicio__c,
                DescricaoAtividade__c, UltimoErroExecucao__c, PularFimDeSemana__c,
                Frequencia__c, HorarioExecucao__c, OwnerType__c,
                OwnerQueueDeveloperName__c, OwnerUser__c, RecordTypeId,
                RecordType.DeveloperName
            FROM Agendamento__c
            WHERE Id IN :scheduleIds
        ];
    }

    private static Agendamento__c lightSchedule(String frequency, Date startDate) {
        return new Agendamento__c(
            Ativo__c = true,
            Frequencia__c = frequency,
            DataInicio__c = startDate,
            HorarioExecucao__c = Time.newInstance(8, 0, 0, 0),
            PularFimDeSemana__c = false
        );
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
                AND DeveloperName = 'AtendimentoTeconSalvador'
        ]) {
            if (scheduleRecordTypeDeveloperNames.contains(caseRecordType.DeveloperName)) {
                return caseRecordType;
            }
        }
        for (RecordType caseRecordType : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
                AND IsActive = true
        ]) {
            if (scheduleRecordTypeDeveloperNames.contains(caseRecordType.DeveloperName)) {
                return caseRecordType;
            }
        }
        Assert.fail('Expected at least one matching Case and Agendamento record type');
        return null;
    }

    private static User createInactiveUser() {
        Profile profile = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User userRow = new User(
            Alias = 'iusr',
            Email = 'inactive.schedule' + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Inactive',
            LanguageLocaleKey = 'pt_BR',
            LocaleSidKey = 'pt_BR',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            UserName = 'inactive.schedule' + uniqueValue + '@example.com',
            IsActive = false
        );
        insert userRow;
        return userRow;
    }

    private class TestContext {
        RecordType caseRecordType;
        RecordType scheduleRecordType;
    }
}