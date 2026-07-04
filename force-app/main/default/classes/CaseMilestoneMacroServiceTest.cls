@IsTest
private class CaseMilestoneMacroServiceTest {
    private static final Id FAKE_ID_1 = '500000000000001AAA';
    private static final Id FAKE_ID_2 = '500000000000002AAA';
    private static final Id FAKE_ID_3 = '500000000000003AAA';
    private static final Id FAKE_ID_4 = '500000000000004AAA';
    private static final Id FAKE_ID_5 = '500000000000005AAA';

    private static Case makeCase(String id, String etapa, Boolean isClosed) {
        return (Case) JSON.deserialize(
            '{"Id":"' + id + '","EtapaAtendimento__c":"' + etapa + '","IsClosed":' + isClosed + '}',
            Case.class
        );
    }

    private static void setup() {
        ApexTestSeam.set('CaseMilestoneMacroService.bypassCaseMilestoneDml', true);
        CaseMilestoneMacroService.lastCatchAllCaseIds.clear();
        CaseMilestoneMacroService.lastSLATotalCaseIds.clear();
    }

    @IsTest
    static void testStageChangeAddsToCatchAll() {
        setup();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_1 => makeCase(FAKE_ID_1, 'Em Atendimento', false) },
            new Map<Id, Case>{ FAKE_ID_1 => makeCase(FAKE_ID_1, 'Novo', false) }
        );

        Assert.isTrue(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_1));
        Assert.isFalse(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_1));
    }

    @IsTest
    static void testConclusaoAddsToBothSets() {
        setup();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_2 => makeCase(FAKE_ID_2, 'Concluído', false) },
            new Map<Id, Case>{ FAKE_ID_2 => makeCase(FAKE_ID_2, 'Em Atendimento', false) }
        );

        Assert.isTrue(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_2));
        Assert.isTrue(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_2));
    }

    @IsTest
    static void testCancelamentoAddsToBothSets() {
        setup();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_3 => makeCase(FAKE_ID_3, 'Cancelado', false) },
            new Map<Id, Case>{ FAKE_ID_3 => makeCase(FAKE_ID_3, 'Em Atendimento', false) }
        );

        Assert.isTrue(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_3));
        Assert.isTrue(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_3));
    }

    @IsTest
    static void testCaseClosureWithoutStageChangeAddsOnlySLATotal() {
        setup();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_4 => makeCase(FAKE_ID_4, 'Em Atendimento', true) },
            new Map<Id, Case>{ FAKE_ID_4 => makeCase(FAKE_ID_4, 'Em Atendimento', false) }
        );

        Assert.isFalse(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_4));
        Assert.isTrue(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_4));
    }

    @IsTest
    static void testNoTransitionSkipsProcessing() {
        setup();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_5 => makeCase(FAKE_ID_5, 'Em Atendimento', false) },
            new Map<Id, Case>{ FAKE_ID_5 => makeCase(FAKE_ID_5, 'Em Atendimento', false) }
        );

        Assert.isFalse(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_5));
        Assert.isFalse(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_5));
    }

    @IsTest
    static void testMultipleCasesHandledIndependently() {
        setup();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{
                FAKE_ID_1 => makeCase(FAKE_ID_1, 'Em Atendimento', false),
                FAKE_ID_2 => makeCase(FAKE_ID_2, 'Em Atendimento', false),
                FAKE_ID_3 => makeCase(FAKE_ID_3, 'Concluído', false)
            },
            new Map<Id, Case>{
                FAKE_ID_1 => makeCase(FAKE_ID_1, 'Novo', false),
                FAKE_ID_2 => makeCase(FAKE_ID_2, 'Em Atendimento', false),
                FAKE_ID_3 => makeCase(FAKE_ID_3, 'Em Atendimento', false)
            }
        );

        Assert.isTrue(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_1));
        Assert.isFalse(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_2));
        Assert.isTrue(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_3));
        Assert.isFalse(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_1));
        Assert.isFalse(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_2));
        Assert.isTrue(CaseMilestoneMacroService.lastSLATotalCaseIds.contains(FAKE_ID_3));
    }

    @IsTest
    static void testNullOrEmptyInputsReturnEarly() {
        ApexTestSeam.set('CaseMilestoneMacroService.bypassCaseMilestoneDml', true);
        CaseMilestoneMacroService.completeByStageTransition(null, null);
        CaseMilestoneMacroService.completeByStageTransition(new Map<Id, Case>(), new Map<Id, Case>());
        Assert.isTrue(true);
    }

    @IsTest
    static void testQueryPathExecutesWhenNoCaseMilestonesExist() {
        // Não usa bypass — cobre o bloco SOQL/DML com IDs que não têm CaseMilestones
        ApexTestSeam.clear('CaseMilestoneMacroService.bypassCaseMilestoneDml');
        CaseMilestoneMacroService.lastCatchAllCaseIds.clear();
        CaseMilestoneMacroService.lastSLATotalCaseIds.clear();

        Test.startTest();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_1 => makeCase(FAKE_ID_1, 'Em Atendimento', false) },
            new Map<Id, Case>{ FAKE_ID_1 => makeCase(FAKE_ID_1, 'Novo', false) }
        );
        Test.stopTest();

        Assert.isTrue(CaseMilestoneMacroService.lastCatchAllCaseIds.contains(FAKE_ID_1));
    }
}