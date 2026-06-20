@IsTest
private class CaseScheduleSchedulerTest {
    @IsTest
    static void shouldScheduleBatch_WhenSchedulerExecutes() {
        Test.startTest();
        String jobId = System.schedule(
            'Wilson Sons - Motor Agendamento Teste',
            '0 0 1 * * ?',
            new CaseScheduleScheduler()
        );
        Test.stopTest();

        CronTrigger row = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId LIMIT 1];
        Assert.areEqual('Wilson Sons - Motor Agendamento Teste', row.CronJobDetail.Name, 'Scheduler job should be registered');
    }
}