@IsTest
private class CaseMilestoneSyncQueueableTest {

    // ── helpers ───────────────────────────────────────────────────────────────

    private static String fakeCmId(Integer n) {
        String pfx = Schema.SObjectType.CaseMilestone.getKeyPrefix();
        if (pfx == null) pfx = '0BL';
        return pfx + String.valueOf(n).leftPad(12, '0') + 'AAA';
    }

    private static Id fakeCmSfId(Integer n) {
        String pfx = Schema.SObjectType.CaseMilestone.getKeyPrefix();
        if (pfx == null) pfx = '0BL';
        return Id.valueOf(pfx + String.valueOf(n).leftPad(12, '0'));
    }

    /**
     * Builds a CaseMilestone via JSON deserialization — the only way to set
     * read-only system fields in tests. Same pattern as AreaParticipanteMilestoneSyncServiceTest.
     */
    private static CaseMilestone makeMock(
            String id, Id caseId, String milestoneName,
            Datetime startDate, Datetime targetDate, Datetime completionDate,
            Boolean isCompleted, Boolean isViolated,
            Integer elapsed, Integer remaining) {

        Map<String, Object> data = new Map<String, Object>{
            'Id'                  => id,
            'CaseId'              => String.valueOf(caseId),
            'MilestoneType'       => new Map<String, Object>{ 'Name' => milestoneName },
            'StartDate'           => startDate,
            'TargetDate'          => targetDate,
            'CompletionDate'      => completionDate,
            'IsCompleted'         => isCompleted,
            'IsViolated'          => isViolated,
            'ElapsedTimeInMins'   => elapsed,
            'TimeRemainingInMins' => remaining
        };
        return (CaseMilestone) JSON.deserialize(JSON.serialize(data), CaseMilestone.class);
    }

    // ── 1. afterInsert via CaseAfterInsertTriggerHandler cria AP Standard ────

    @IsTest
    static void testAfterInsertCriaMilestoneSync() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        CaseMilestoneSyncQueueable.bypassEnqueueForTests = true;

        String cmId = fakeCmId(1);
        CaseMilestone mockCm = makeMock(cmId, c.Id, 'Atendimento',
            Datetime.now().addHours(-1), Datetime.now().addHours(7), null,
            false, false, 60, 420);

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync =
            new List<CaseMilestone>{ mockCm };

        Test.startTest();
        CaseAfterInsertTriggerHandler.afterInsert(new List<Case>{ c });
        Test.stopTest();

        List<AreaParticipante__c> areas = [
            SELECT Id, CaseMilestoneId__c, OrigemSLA__c, TipoAreaParticipante__c, StatusAtuacao__c
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard'
        ];
        Assert.areEqual(1, areas.size(), 'afterInsert deve criar 1 AreaParticipante Standard');
        Assert.areEqual(cmId, areas[0].CaseMilestoneId__c, 'CaseMilestoneId__c deve ser preenchido');
        Assert.areEqual('Tratamento Primário', areas[0].TipoAreaParticipante__c,
            'Tipo Atendimento => Tratamento Primário');
        Assert.areEqual('Aberta', areas[0].StatusAtuacao__c, 'Status inicial deve ser Aberta');
    }

    // ── 2. afterInsert é idempotente ──────────────────────────────────────────

    @IsTest
    static void testAfterInsertIdempotente() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        CaseMilestoneSyncQueueable.bypassEnqueueForTests = true;

        String cmId = fakeCmId(2);
        CaseMilestone mockCm = makeMock(cmId, c.Id, 'Triagem',
            Datetime.now().addHours(-2), Datetime.now().addHours(6), null,
            false, false, 120, 360);

        // First sync
        AreaParticipanteMilestoneSyncService.mockMilestonesForSync =
            new List<CaseMilestone>{ mockCm };
        CaseAfterInsertTriggerHandler.afterInsert(new List<Case>{ c });

        // Second sync — idempotency check
        AreaParticipanteMilestoneSyncService.mockMilestonesForSync =
            new List<CaseMilestone>{ mockCm };

        Test.startTest();
        CaseAfterInsertTriggerHandler.afterInsert(new List<Case>{ c });
        Test.stopTest();

        Integer count = [
            SELECT COUNT() FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND CaseMilestoneId__c = :cmId
        ];
        Assert.areEqual(1, count, 'Segunda chamada deve atualizar, nao duplicar');
    }

    // ── 3. Queueable executa syncByCaseIds quando chamado diretamente ─────────

    @IsTest
    static void testQueueableExecuteSyncByCaseIds() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);

        String cmId = fakeCmId(3);
        CaseMilestone mockCm = makeMock(cmId, c.Id, 'SLA Total',
            Datetime.now().addHours(-3), Datetime.now().addHours(21), null,
            false, false, 180, 1260);

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync =
            new List<CaseMilestone>{ mockCm };

        Test.startTest();
        new CaseMilestoneSyncQueueable(new Set<Id>{ c.Id }).execute(null);
        Test.stopTest();

        List<AreaParticipante__c> areas = [
            SELECT TipoAreaParticipante__c, NomeMarco__c
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard'
        ];
        Assert.areEqual(1, areas.size(), 'Queueable.execute deve criar AP Standard');
        Assert.areEqual('Tempo Total de Atendimento', areas[0].TipoAreaParticipante__c,
            'Tipo SLA Total => Tempo Total de Atendimento');
        Assert.areEqual('Tempo Total de Atendimento', areas[0].NomeMarco__c,
            'NomeMarco SLA Total deve ser Tempo Total de Atendimento');
    }

    // ── 4. afterInsert com set vazio nao executa sync ─────────────────────────

    @IsTest
    static void testAfterInsertSetVazioNaoFazNada() {
        CaseMilestoneSyncQueueable.bypassEnqueueForTests = true;
        Test.startTest();
        CaseAfterInsertTriggerHandler.afterInsert(new List<Case>());
        Test.stopTest();
        Assert.isTrue(true, 'Lista vazia nao deve lancar excecao');
    }

    // ── 5. bulk — múltiplos Cases ─────────────────────────────────────────────

    @IsTest
    static void testBulkMultiplosCases() {
        Case c1 = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        Case c2 = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        Case c3 = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        CaseMilestoneSyncQueueable.bypassEnqueueForTests = true;

        String cmId1 = fakeCmId(51);
        String cmId2 = fakeCmId(52);
        String cmId3 = fakeCmId(53);

        CaseMilestone m1 = makeMock(cmId1, c1.Id, 'Atendimento',
            Datetime.now().addHours(-1), Datetime.now().addHours(7), null, false, false, 60, 420);
        CaseMilestone m2 = makeMock(cmId2, c2.Id, 'Triagem',
            Datetime.now().addHours(-2), Datetime.now().addHours(6), null, false, false, 120, 360);
        CaseMilestone m3 = makeMock(cmId3, c3.Id, 'SLA Total',
            Datetime.now().addHours(-3), Datetime.now().addHours(21), null, false, false, 180, 1260);

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync =
            new List<CaseMilestone>{ m1, m2, m3 };

        Test.startTest();
        CaseAfterInsertTriggerHandler.afterInsert(new List<Case>{ c1, c2, c3 });
        Test.stopTest();

        Set<Id> caseIds = new Set<Id>{ c1.Id, c2.Id, c3.Id };
        Integer total = [
            SELECT COUNT() FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds AND OrigemSLA__c = 'Standard'
        ];
        Assert.areEqual(3, total, 'Bulk: deve criar 1 AP Standard por milestone');
    }

    // ── 6. Custom manual nao é afetado ────────────────────────────────────────

    @IsTest
    static void testCustomManualNaoAfetado() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        CaseMilestoneSyncQueueable.bypassEnqueueForTests = true;

        String cmId = fakeCmId(61);

        // Pre-existing Custom AP on the same milestone
        AreaParticipante__c customAp = new AreaParticipante__c(
            Caso__c                 = c.Id,
            CaseMilestoneId__c      = cmId,
            OrigemSLA__c            = 'Custom',
            TipoAreaParticipante__c = 'Categorização Inicial',
            StatusAtuacao__c        = 'Aberta',
            StatusSLA__c            = 'Dentro do Prazo'
        );
        insert customAp;

        CaseMilestone mockCm = makeMock(cmId, c.Id, 'Triagem',
            Datetime.now().addHours(-1), Datetime.now().addHours(5), null, false, false, 60, 300);

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync =
            new List<CaseMilestone>{ mockCm };

        Test.startTest();
        CaseAfterInsertTriggerHandler.afterInsert(new List<Case>{ c });
        Test.stopTest();

        AreaParticipante__c check = [
            SELECT OrigemSLA__c, StatusAtuacao__c FROM AreaParticipante__c WHERE Id = :customAp.Id
        ];
        Assert.areEqual('Custom', check.OrigemSLA__c,
            'OrigemSLA Custom deve permanecer intacto');
        Assert.areEqual('Aberta', check.StatusAtuacao__c,
            'StatusAtuacao Custom nao deve ser alterado pelo sync');

        Integer total = [
            SELECT COUNT() FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND CaseMilestoneId__c = :cmId
        ];
        Assert.areEqual(1, total, 'Nao deve criar AP Standard sobre milestone com Custom existente');
    }
}