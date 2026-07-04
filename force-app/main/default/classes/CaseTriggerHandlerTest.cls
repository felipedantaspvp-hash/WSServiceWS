@IsTest
private class CaseTriggerHandlerTest {

    // ── helpers ──────────────────────────────────────────────────────────────

    private static Id makeFakeCaseId(Integer n) {
        String pfx = Schema.SObjectType.Case.getKeyPrefix();
        return Id.valueOf(pfx + String.valueOf(n).leftPad(12, '0'));
    }

    private static Case fakeCase(Integer n, Boolean isClosed, String etapa) {
        String caseId = makeFakeCaseId(n);
        Map<String, Object> data = new Map<String, Object>{
            'Id' => caseId,
            'IsClosed' => isClosed
        };
        if (etapa != null) data.put('EtapaAtendimento__c', etapa);
        return (Case) JSON.deserialize(JSON.serialize(data), Case.class);
    }

    // ── fechamento por IsClosed ───────────────────────────────────────────────

    @IsTest
    static void testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen() {
        Id caseId = makeFakeCaseId(1);
        Case oldCase = fakeCase(1, false, null);
        Case newCase = fakeCase(1, true, null);

        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.injectedBlockersByCase.put(caseId, 1);
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId => newCase },
            new Map<Id, Case>{ caseId => oldCase }
        );

        Assert.areEqual(true, newCase.hasErrors(), 'Fechamento com bloqueador deve gerar erro');
        Assert.areEqual(1, newCase.getErrors().size(), 'Exatamente 1 erro por Case');
        Assert.isTrue(newCase.getErrors()[0].getMessage().contains('áreas internas abertas'),
            'Mensagem funcional deve mencionar áreas internas abertas');
    }

    @IsTest
    static void testBeforeUpdateNoErrorWhenNoBlockersOnClose() {
        Id caseId = makeFakeCaseId(2);
        Case oldCase = fakeCase(2, false, null);
        Case newCase = fakeCase(2, true, null);

        CaseTriggerHandler.injectedBlockersByCase.clear();
        // SOQL roda contra ID fictício → 0 registros → sem bloqueio
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId => newCase },
            new Map<Id, Case>{ caseId => oldCase }
        );

        Assert.areEqual(false, newCase.hasErrors(), 'Sem bloqueadores → fechamento permitido');
    }

    // ── cancelamento por EtapaAtendimento__c ─────────────────────────────────

    @IsTest
    static void testBeforeUpdateBlocksCancelViaEtapaCancelado() {
        Id caseId = makeFakeCaseId(3);
        Case oldCase = fakeCase(3, false, 'Em Atendimento');
        Case newCase = fakeCase(3, false, 'Cancelado');

        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.injectedBlockersByCase.put(caseId, 1);
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId => newCase },
            new Map<Id, Case>{ caseId => oldCase }
        );

        Assert.areEqual(true, newCase.hasErrors(), 'Cancelamento via EtapaAtendimento com área aberta deve bloquear');
        Assert.isTrue(newCase.getErrors()[0].getMessage().contains('áreas internas abertas'),
            'Mensagem funcional deve mencionar áreas internas abertas');
    }

    @IsTest
    static void testBeforeUpdateNoErrorWhenNoBlockersOnCancel() {
        Id caseId = makeFakeCaseId(4);
        Case oldCase = fakeCase(4, false, 'Em Atendimento');
        Case newCase = fakeCase(4, false, 'Cancelado');

        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId => newCase },
            new Map<Id, Case>{ caseId => oldCase }
        );

        Assert.areEqual(false, newCase.hasErrors(), 'Cancelamento sem bloqueadores deve ser permitido');
    }

    // ── update sem fechamento/cancelamento ────────────────────────────────────

    @IsTest
    static void testBeforeUpdateNoCheckOnNonClosingUpdate() {
        Id caseId = makeFakeCaseId(5);
        Case oldCase = fakeCase(5, false, 'Em Atendimento');
        Case newCase = fakeCase(5, false, 'Em Acompanhamento');

        // Mesmo com bloqueador injetado, update sem transição não deve acionar a verificação
        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.injectedBlockersByCase.put(caseId, 99);
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId => newCase },
            new Map<Id, Case>{ caseId => oldCase }
        );

        // closing set vazio → método retorna antes de checar bloqueadores
        Assert.areEqual(false, newCase.hasErrors(), 'Update sem fechamento/cancelamento não verifica bloqueio');
    }

    // ── bulk ─────────────────────────────────────────────────────────────────

    @IsTest
    static void testBeforeUpdateBulkBlocksOnlyClosingCases() {
        Id caseId1 = makeFakeCaseId(6); // fechando
        Id caseId2 = makeFakeCaseId(7); // apenas atualizando etapa

        Case oldCase1 = fakeCase(6, false, null);
        Case newCase1 = fakeCase(6, true, null); // IsClosed: false → true

        Case oldCase2 = fakeCase(7, false, 'Em Atendimento');
        Case newCase2 = fakeCase(7, false, 'Em Acompanhamento'); // sem transição de fechamento

        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.injectedBlockersByCase.put(caseId1, 2);

        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId1 => newCase1, caseId2 => newCase2 },
            new Map<Id, Case>{ caseId1 => oldCase1, caseId2 => oldCase2 }
        );

        Assert.areEqual(true, newCase1.hasErrors(), 'Case fechando com bloqueador deve ter erro');
        Assert.areEqual(false, newCase2.hasErrors(), 'Case sem transição não deve ter erro');
    }

    // ── standard não bloqueia ─────────────────────────────────────────────────

    @IsTest
    static void testStandardOrigemDoesNotBlockClosure() {
        // AreaParticipante__c Standard tem BloqueiaFechamentoCaso__c = false (set por buildRecord())
        // A query filtra BloqueiaFechamentoCaso__c = true E OrigemSLA__c = 'Custom' → Standard excluído
        Case c = TestDataFactory.createCase(new Map<String, Object>{ 'RecordTypeId' => null });

        // Standard: guard em AreaParticipanteSLAService.beforeSave skips validações
        TestDataFactory.createAreaParticipante(c.Id, new Map<String, Object>{
            'TipoAreaParticipante__c' => AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            'OrigemSLA__c' => AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            'BloqueiaFechamentoCaso__c' => false,
            'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA
        });

        Case oldCase = (Case) JSON.deserialize('{"Id":"' + c.Id + '","IsClosed":false}', Case.class);
        Case newCase = (Case) JSON.deserialize('{"Id":"' + c.Id + '","IsClosed":true}', Case.class);

        CaseTriggerHandler.injectedBlockersByCase.clear(); // SOQL roda com registro real
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ c.Id => newCase },
            new Map<Id, Case>{ c.Id => oldCase }
        );

        Assert.areEqual(false, newCase.hasErrors(),
            'AreaParticipante Standard (BloqueiaFechamentoCaso=false) não deve bloquear fechamento');
    }

    // ── múltiplos bloqueadores ────────────────────────────────────────────────

    @IsTest
    static void testBeforeUpdateMultipleBlockersStillBlocks() {
        Id caseId = makeFakeCaseId(8);
        Case oldCase = fakeCase(8, false, null);
        Case newCase = fakeCase(8, true, null);

        CaseTriggerHandler.injectedBlockersByCase.clear();
        CaseTriggerHandler.injectedBlockersByCase.put(caseId, 3);
        CaseTriggerHandler.beforeUpdate(
            new Map<Id, Case>{ caseId => newCase },
            new Map<Id, Case>{ caseId => oldCase }
        );

        Assert.areEqual(true, newCase.hasErrors(), 'Múltiplos bloqueadores ainda devem bloquear');
        Assert.areEqual(1, newCase.getErrors().size(), 'Exatamente 1 erro por Case independente do nº de bloqueadores');
    }
}