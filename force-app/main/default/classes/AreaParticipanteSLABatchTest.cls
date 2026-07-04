@IsTest
private class AreaParticipanteSLABatchTest {
    private static String getBhName() {
        String bhName = 'BH_BATCH_TEST';
        BusinessHoursResolverService.injectedByName.put(bhName, (Id) '01m000000000001AAA');
        return bhName;
    }

    private static void enableDeterministicBusinessHoursMath() {
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        BusinessHoursResolverService.injectedByName.clear();
    }

    private static Categorizacao__c createCategorizacao() {
        return TestDataFactory.createCategorizacao(null);
    }

    private static Case createCaseWithoutSla(String area1, String area2) {
        String mp = String.isBlank(area2) ? area1 : area1 + ';' + area2;
        return TestDataFactory.createCase(new Map<String, Object>{
            'AreasParticipantesSLA__c' => mp,
            'EtapaAtendimento__c' => 'Aguardando Área Interna'
        });
    }

    private static RegrasSLACategorizacao__c createRule(Id categId, String area, String priority) {
        String bhName = getBhName();
        GestaoSLA__c g = TestDataFactory.createGestaoSla(new Map<String, Object>{
            'Name' => 'Gestao Batch ' + String.valueOf(Crypto.getRandomInteger()),
            'BusinessHoursName__c' => bhName
        });
        RegrasSLACategorizacao__c r = TestDataFactory.createRegraSla(categId, g.Id, area, new Map<String, Object>{
            'BusinessHoursName__c' => bhName,
            'TempoBaixa__c' => 30,
            'TempoMedia__c' => 30,
            'TempoAlta__c' => 30
        });
        TestDataFactory.linkGestaoSla(categId, g.Id);
        return r;
    }

    @IsTest
    static void testBatchRecalculatesAndMarksOverdue() {
        enableDeterministicBusinessHoursMath();
        String area = TestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c ap = TestDataFactory.createAreaParticipante(c.Id, new Map<String, Object>{
            'TipoAreaParticipante__c' => AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            'AreaAtendimento__c' => area,
            'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            'ComentarioSolicitacao__c' => 'batch open'
        });

        ap = [SELECT Id, DataHoraPrazo__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        ap.DataHoraPrazo__c = System.now().addMinutes(-5);
        update ap;

        Test.startTest();
        Database.executeBatch(new AreaParticipanteSLABatch(), 50);
        Test.stopTest();

        AreaParticipante__c afterRow = [
            SELECT StatusSLA__c, ViolouSLA__c, TempoConsumidoMinutos__c, TempoRestanteMinutos__c, PercentualDecorrido__c, StatusAtuacao__c
            FROM AreaParticipante__c
            WHERE Id = :ap.Id
        ];
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO, afterRow.StatusSLA__c);
        Assert.areEqual(true, afterRow.ViolouSLA__c);
        Assert.areEqual(true, afterRow.TempoConsumidoMinutos__c != null);
        Assert.areEqual(true, afterRow.PercentualDecorrido__c != null);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, afterRow.StatusAtuacao__c);

        Case caseAfter = [SELECT QtdAreasParticipantesVencidas__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(1, Integer.valueOf(caseAfter.QtdAreasParticipantesVencidas__c));
    }

    @IsTest
    static void testBatchDoesNotChangePausedRows() {
        enableDeterministicBusinessHoursMath();
        String area = TestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c ap = TestDataFactory.createAreaParticipante(c.Id, new Map<String, Object>{
            'TipoAreaParticipante__c' => AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            'AreaAtendimento__c' => area,
            'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA,
            'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            'DataHoraInicioPausa__c' => System.now().addMinutes(-30),
            'ComentarioSolicitacao__c' => 'batch paused'
        });

        AreaParticipante__c beforeRow = [SELECT Id, StatusSLA__c, DataHoraInicioPausa__c FROM AreaParticipante__c WHERE Id = :ap.Id];

        Test.startTest();
        Database.executeBatch(new AreaParticipanteSLABatch(), 50);
        Test.stopTest();

        AreaParticipante__c afterRow = [SELECT StatusSLA__c, DataHoraInicioPausa__c FROM AreaParticipante__c WHERE Id = :ap.Id];
        Assert.areEqual(beforeRow.StatusSLA__c, afterRow.StatusSLA__c);
        Assert.areEqual(beforeRow.DataHoraInicioPausa__c, afterRow.DataHoraInicioPausa__c);
    }

    @IsTest
    static void testBatchDoesNotProcessClosedOrCanceledRows() {
        enableDeterministicBusinessHoursMath();
        String area = TestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c closed = TestDataFactory.createAreaParticipante(c.Id, new Map<String, Object>{
            'TipoAreaParticipante__c' => AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            'AreaAtendimento__c' => area,
            'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA,
            'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO,
            'DataHoraFim__c' => System.now(),
            'ComentarioSolicitacao__c' => 'closed row'
        });

        Datetime beforeFim = closed.DataHoraFim__c;
        AreaParticipante__c beforeRow = [SELECT Id, StatusSLA__c FROM AreaParticipante__c WHERE Id = :closed.Id];

        Test.startTest();
        Database.executeBatch(new AreaParticipanteSLABatch(), 50);
        Test.stopTest();

        AreaParticipante__c afterRow = [SELECT DataHoraFim__c, StatusSLA__c FROM AreaParticipante__c WHERE Id = :closed.Id];
        Assert.areEqual(beforeFim, afterRow.DataHoraFim__c);
        Assert.areEqual(beforeRow.StatusSLA__c, afterRow.StatusSLA__c);
    }

    @IsTest
    static void testBatchDoesNotProcessCanceledRows() {
        enableDeterministicBusinessHoursMath();
        String area = TestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c canceled = TestDataFactory.createAreaParticipante(c.Id, new Map<String, Object>{
            'TipoAreaParticipante__c' => AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            'AreaAtendimento__c' => area,
            'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_CANCELADA,
            'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_CANCELADO,
            'DataHoraFim__c' => System.now(),
            'ComentarioSolicitacao__c' => 'canceled row'
        });

        Datetime beforeFim = canceled.DataHoraFim__c;
        AreaParticipante__c beforeRow = [SELECT Id, StatusSLA__c FROM AreaParticipante__c WHERE Id = :canceled.Id];

        Test.startTest();
        Database.executeBatch(new AreaParticipanteSLABatch(), 50);
        Test.stopTest();

        AreaParticipante__c afterRow = [SELECT DataHoraFim__c, StatusSLA__c FROM AreaParticipante__c WHERE Id = :canceled.Id];
        Assert.areEqual(beforeFim, afterRow.DataHoraFim__c);
        Assert.areEqual(beforeRow.StatusSLA__c, afterRow.StatusSLA__c);
    }

    @IsTest
    static void testSchedulerExecutesBatch() {
        String cron = '0 0 2 1 1 ? 2099';
        Test.startTest();
        String jobId = System.schedule('SLA N3 Scheduler Test', cron, new AreaParticipanteSLAScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(cron, ct.CronExpression);
        Assert.areEqual(true, ct.TimesTriggered >= 0);
        Integer batchJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'AreaParticipanteSLABatch'];
        Assert.areEqual(true, batchJobs > 0);
    }
}