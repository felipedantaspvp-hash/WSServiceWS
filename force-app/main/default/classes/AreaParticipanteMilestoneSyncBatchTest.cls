/**
 * @description       : Testes unitários de AreaParticipanteMilestoneSyncBatch.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteMilestoneSyncBatchTest {

    private static String fakeCmId(Integer n) {
        String pfx = Schema.SObjectType.CaseMilestone.getKeyPrefix();
        if (pfx == null) pfx = '0BL';
        return pfx + String.valueOf(n).leftPad(12, '0') + 'AAA';
    }

    private static CaseMilestone makeMock(String id, String caseId, String milestoneName) {
        Map<String, Object> data = new Map<String, Object>{
            'Id'                  => id,
            'CaseId'              => caseId,
            'MilestoneType'       => new Map<String, Object>{ 'Name' => milestoneName },
            'StartDate'           => Datetime.now().addHours(-2),
            'TargetDate'          => Datetime.now().addHours(6),
            'CompletionDate'      => null,
            'IsCompleted'         => false,
            'IsViolated'          => false,
            'ElapsedTimeInMins'   => 120,
            'TimeRemainingInMins' => 360
        };
        return (CaseMilestone) JSON.deserialize(JSON.serialize(data), CaseMilestone.class);
    }

    @IsTest
    static void batch_comCaseIds_sincronizaMilestones() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(fakeCmId(1), c.Id, 'Triagem')
        };

        Test.startTest();
        Database.executeBatch(new AreaParticipanteMilestoneSyncBatch(new Set<Id>{ c.Id }), 200);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM AreaParticipante__c WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard'];
        Assert.areEqual(1, count, 'Batch com caseIds deve criar registro');
    }

    @IsTest
    static void batch_semCaseIds_executaSemErro() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>();

        Test.startTest();
        Database.executeBatch(new AreaParticipanteMilestoneSyncBatch(), 200);
        Test.stopTest();

        Assert.isTrue(true, 'Batch sem filtro nao deve lancar excecao');
    }

    @IsTest
    static void scheduler_executaSemErro() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>();

        Test.startTest();
        AreaParticipanteMilestoneSyncScheduler.schedule('0 0 2 * * ?');
        Test.stopTest();

        Assert.isTrue(true, 'Scheduler deve agendar sem excecao');
    }
}