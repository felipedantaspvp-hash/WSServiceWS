@IsTest
private class CaseScheduleBatchTest {
    @IsTest
    static void shouldProcessMultipleSchedules_WhenBatchRuns() {
        TestContext ctx = prepareContext();
        Agendamento__c first = insertSchedule(ctx, 'Diária');
        Agendamento__c second = insertSchedule(ctx, 'Diária');

        Test.startTest();
        CaseScheduleService.testNow = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        Database.executeBatch(new CaseScheduleBatch(), 200);
        CaseScheduleService.testNow = null;
        Test.stopTest();

        Assert.areEqual(2, [SELECT count() FROM Case WHERE Agendamento__c IN :new Set<Id>{ first.Id, second.Id }], 'Batch should create Cases for eligible schedules');
    }

    private static TestContext prepareContext() {
        insert new Account(Name = 'Conta Batch Agendamento');
        Group queue = new Group(Name = 'TSV Batch Schedule', DeveloperName = 'TSV_BATCH_SCHEDULE', Type = 'Queue');
        insert queue;
        insert new List<QueueSobject>{
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Case'),
            new QueueSobject(QueueId = queue.Id, SobjectType = 'Agendamento__c')
        };

        TestContext ctx = new TestContext();
        ctx.caseRecordType = matchingCaseRecordType();
        ctx.scheduleRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Agendamento__c' AND DeveloperName = :ctx.caseRecordType.DeveloperName LIMIT 1];

        CaseCreationSelector.UnidadeConfig config = new CaseCreationSelector.UnidadeConfig();
        config.recordTypeDeveloperName = ctx.caseRecordType.DeveloperName;
        config.unidadeNegocio = 'Salvador';
        config.queueToken = 'TSV';
        config.ativo = true;
        CaseCreationSelector.testConfigs = new Map<String, CaseCreationSelector.UnidadeConfig>{ ctx.caseRecordType.DeveloperName => config };
        CaseCreationSelector.testCategorizacoes = new List<Categorizacao__c>{
            CaseCreationTestDataFactory.catRow(false, false, null, ctx.caseRecordType.Id)
        };
        return ctx;
    }

    private static Agendamento__c insertSchedule(TestContext ctx, String frequency) {
        Account account = [SELECT Id FROM Account WHERE Name = 'Conta Batch Agendamento' LIMIT 1];
        Agendamento__c row = new Agendamento__c(
            Conta__c = account.Id,
            RecordTypeId = ctx.scheduleRecordType.Id,
            Ativo__c = true,
            UnidadeNegocio__c = AccountCaseScheduleHelper.normalizeScheduleBusinessUnit('Salvador'),
            TipoCaso__c = 'Solicitação',
            Categoria__c = 'Operação',
            Assunto__c = 'Acesso',
            Subassunto__c = 'Acesso indisponível',
            DescricaoAtividade__c = 'Criar caso recorrente pelo batch',
            Frequencia__c = frequency,
            DataInicio__c = Date.today(),
            HorarioExecucao__c = Time.newInstance(8, 0, 0, 0),
            PularFimDeSemana__c = true,
            OwnerType__c = 'USER',
            OwnerUser__c = UserInfo.getUserId(),
            OwnerId = UserInfo.getUserId()
        );
        insert row;
        return row;
    }

    private static RecordType matchingCaseRecordType() {
        Set<String> scheduleRecordTypeDeveloperNames = new Set<String>();
        for (RecordType scheduleRecordType : [SELECT DeveloperName FROM RecordType WHERE SObjectType = 'Agendamento__c' AND IsActive = true]) {
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
        for (RecordType caseRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case' AND IsActive = true]) {
            if (scheduleRecordTypeDeveloperNames.contains(caseRecordType.DeveloperName)) {
                return caseRecordType;
            }
        }
        Assert.fail('Expected matching record type');
        return null;
    }

    private class TestContext {
        RecordType caseRecordType;
        RecordType scheduleRecordType;
    }
}