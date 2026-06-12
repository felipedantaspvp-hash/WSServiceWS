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

    @IsTest
    static void testComputeMilestonesByStageTransition() {
        Case oldCase = makeCase(FAKE_ID_1, 'Novo', false);
        Case newCase = makeCase(FAKE_ID_1, 'Em Atendimento', false);

        CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests = true;
        CaseMilestoneMacroService.lastComputedByCase.clear();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_1 => newCase },
            new Map<Id, Case>{ FAKE_ID_1 => oldCase }
        );

        Assert.areEqual(true, CaseMilestoneMacroService.lastComputedByCase.containsKey(FAKE_ID_1));
        Set<String> names = CaseMilestoneMacroService.lastComputedByCase.get(FAKE_ID_1);
        Assert.areEqual(true, names.contains('Primeira Resposta'));
        Assert.areEqual(false, names.contains('SLA Total'));
    }

    @IsTest
    static void testAtendimentoTransition() {
        Case oldCase = makeCase(FAKE_ID_2, 'Em Atendimento', false);
        Case newCase = makeCase(FAKE_ID_2, 'Concluído', false);

        CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests = true;
        CaseMilestoneMacroService.lastComputedByCase.clear();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_2 => newCase },
            new Map<Id, Case>{ FAKE_ID_2 => oldCase }
        );

        Assert.areEqual(true, CaseMilestoneMacroService.lastComputedByCase.containsKey(FAKE_ID_2));
        Set<String> names = CaseMilestoneMacroService.lastComputedByCase.get(FAKE_ID_2);
        Assert.areEqual(true, names.contains('Atendimento'));
        Assert.areEqual(true, names.contains('SLA Total'));
    }

    @IsTest
    static void testRetornoN3Transition() {
        Case oldCase = makeCase(FAKE_ID_3, 'Preparando Retorno ao Cliente', false);
        Case newCase = makeCase(FAKE_ID_3, 'Em Atendimento', false);

        CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests = true;
        CaseMilestoneMacroService.lastComputedByCase.clear();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_3 => newCase },
            new Map<Id, Case>{ FAKE_ID_3 => oldCase }
        );

        Assert.areEqual(true, CaseMilestoneMacroService.lastComputedByCase.containsKey(FAKE_ID_3));
        Set<String> names = CaseMilestoneMacroService.lastComputedByCase.get(FAKE_ID_3);
        Assert.areEqual(true, names.contains('Retorno N3'));
    }

    @IsTest
    static void testAtendimentoN3AndAcompanhamentoTransitions() {
        CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests = true;

        Case oldN3 = makeCase(FAKE_ID_4, 'Aguardando Área Interna', false);
        Case newN3 = makeCase(FAKE_ID_4, 'Em Atendimento', false);
        CaseMilestoneMacroService.lastComputedByCase.clear();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_4 => newN3 },
            new Map<Id, Case>{ FAKE_ID_4 => oldN3 }
        );
        Set<String> namesN3 = CaseMilestoneMacroService.lastComputedByCase.get(FAKE_ID_4);
        Assert.areEqual(true, namesN3.contains('Atendimento N3'));

        Case oldAcomp = makeCase(FAKE_ID_5, 'Aguardando Cliente', false);
        Case newAcomp = makeCase(FAKE_ID_5, 'Em Atendimento', false);
        CaseMilestoneMacroService.lastComputedByCase.clear();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_5 => newAcomp },
            new Map<Id, Case>{ FAKE_ID_5 => oldAcomp }
        );
        Set<String> namesAcomp = CaseMilestoneMacroService.lastComputedByCase.get(FAKE_ID_5);
        Assert.areEqual(true, namesAcomp.contains('Acompanhamento'));
    }

    @IsTest
    static void testNoTransitionSkipsProcessing() {
        Case c1 = makeCase(FAKE_ID_1, 'Em Atendimento', false);
        Case c2 = makeCase(FAKE_ID_1, 'Em Atendimento', false);

        CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests = true;
        CaseMilestoneMacroService.lastComputedByCase.clear();
        CaseMilestoneMacroService.completeByStageTransition(
            new Map<Id, Case>{ FAKE_ID_1 => c2 },
            new Map<Id, Case>{ FAKE_ID_1 => c1 }
        );

        Assert.areEqual(false, CaseMilestoneMacroService.lastComputedByCase.containsKey(FAKE_ID_1));
    }

    @IsTest
    static void testNullOrEmptyInputsReturnEarly() {
        CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests = true;
        CaseMilestoneMacroService.completeByStageTransition(null, null);
        CaseMilestoneMacroService.completeByStageTransition(new Map<Id, Case>(), new Map<Id, Case>());
        Assert.areEqual(true, true);
    }
}