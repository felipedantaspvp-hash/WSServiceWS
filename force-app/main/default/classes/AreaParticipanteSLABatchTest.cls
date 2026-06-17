/**
 * @description       : Testes unitários de AreaParticipanteSLABatch.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteSLABatchTest {
    private static String getBhName() {
        String bhName = 'BH_BATCH_TEST';
        BusinessHoursResolverService.injectedByName.put(bhName, (Id) '01m000000000001AAA');
        return bhName;
    }

    private static void enableDeterministicBusinessHoursMath() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
    }

    private static Categorizacao__c createCategorizacao() {
        Categorizacao__c c = CategorizacaoTestDataFactory.base(false, false);
        insert c;
        return c;
    }

    private static RegrasSLACategorizacao__c createRule(Id categId, String area, String priority) {
        List<Schema.PicklistEntry> ue = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        String unidade = ue.isEmpty() ? 'Salvador' : ue[0].getValue();
        GestaoSLA__c g = new GestaoSLA__c(
            Name = 'Gestao Batch ' + String.valueOf(Crypto.getRandomInteger()),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = getBhName(),
            Ativo__c = true
        );
        insert g;
        RegrasSLACategorizacao__c r = new RegrasSLACategorizacao__c(
            Categorizacao__c = categId,
            AreaAtendimento__c = area,
            BusinessHoursName__c = getBhName(),
            Ativo__c = true,
            GestaoSLA__c = g.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 30,
            TempoMedia__c = 30,
            TempoAlta__c = 30
        );
        insert r;
        Categorizacao__c categ = new Categorizacao__c(Id = categId);
        categ.GestaoSLA__c = g.Id;
        update categ;
        return r;
    }

    @IsTest
    static void testBatchRecalculatesAndMarksOverdue() {
        enableDeterministicBusinessHoursMath();
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            ComentarioSolicitacao__c = 'batch open'
        );
        insert ap;

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
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicioPausa__c = System.now().addMinutes(-30),
            ComentarioSolicitacao__c = 'batch paused'
        );
        insert ap;

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
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c closed = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO,
            DataHoraFim__c = System.now(),
            ComentarioSolicitacao__c = 'closed row'
        );
        insert closed;

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
        String area = AreaParticipanteTestDataFactory.commonAreaValues()[0];
        Categorizacao__c categ = createCategorizacao();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(area, null);
        c.Categorizacao__c = categ.Id;
        c.Priority = 'Medium';
        c.Origin = 'Manual';
        update c;

        createRule(categ.Id, area, 'Medium');

        AreaParticipante__c canceled = new AreaParticipante__c(
            Caso__c = c.Id,
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            AreaAtendimento__c = area,
            StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_CANCELADA,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_CANCELADO,
            DataHoraFim__c = System.now(),
            ComentarioSolicitacao__c = 'canceled row'
        );
        insert canceled;

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