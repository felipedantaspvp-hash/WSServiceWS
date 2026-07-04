String jobName = 'Case Schedule - Geracao Diaria';
for (CronTrigger existing : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
    System.abortJob(existing.Id);
}
System.schedule(jobName, '0 1 0 * * ?', new CaseScheduleScheduler());
