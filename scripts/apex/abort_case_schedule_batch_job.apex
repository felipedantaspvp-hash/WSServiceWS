String jobName = 'Case Schedule - Geracao Diaria';
for (CronTrigger existing : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
    System.abortJob(existing.Id);
}
