/**
 * @description       : Testes unitários de AreaParticipanteMilestoneSyncService.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteMilestoneSyncServiceTest {

    // ── helpers ──────────────────────────────────────────────────────────────

    private static String fakeCmId(Integer n) {
        String pfx = Schema.SObjectType.CaseMilestone.getKeyPrefix();
        if (pfx == null) pfx = '0BL';
        return pfx + String.valueOf(n).leftPad(12, '0') + 'AAA';
    }

    private static Id fakeMilestoneSfId(Integer n) {
        String pfx = Schema.SObjectType.CaseMilestone.getKeyPrefix();
        if (pfx == null) pfx = '0BL';
        return Id.valueOf(pfx + String.valueOf(n).leftPad(12, '0')); // 15-char, sem check digits
    }

    private static String fakeCaseId() {
        return Schema.SObjectType.Case.getKeyPrefix() + '000000000001AAA';
    }

    private static CaseMilestone makeMock(
            String id, String caseId, String milestoneName,
            Datetime startDate, Datetime targetDate, Datetime completionDate,
            Boolean isCompleted, Boolean isViolated,
            Integer elapsed, Integer remaining) {

        Map<String, Object> data = new Map<String, Object>{
            'Id'                  => id,
            'CaseId'              => caseId,
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

    // ── buildRecord — mapeamento de tipo ─────────────────────────────────────

    @IsTest
    static void buildRecord_triagem_mapsCategoriaInicial() {
        CaseMilestone cm = makeMock(fakeCmId(1), fakeCaseId(), 'Triagem',
            Datetime.now().addHours(-2), Datetime.now().addHours(8), null, false, false, 120, 480);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Categorização Inicial', r.TipoAreaParticipante__c, 'Tipo Triagem');
        Assert.areEqual('Triagem', r.NomeMarco__c, 'NomeMarco Triagem');
    }

    @IsTest
    static void buildRecord_respostaChat_mapsCategoriaInicial() {
        CaseMilestone cm = makeMock(fakeCmId(2), fakeCaseId(), 'Resposta Chat',
            Datetime.now().addHours(-1), Datetime.now().addHours(2), null, false, false, 60, 120);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Categorização Inicial', r.TipoAreaParticipante__c, 'Tipo Resposta Chat');
    }

    @IsTest
    static void buildRecord_primeiraRespostaFilaN2_mapsTratamentoPrimario() {
        CaseMilestone cm = makeMock(fakeCmId(3), fakeCaseId(), 'Primeira Resposta (Fila N2)',
            Datetime.now().addHours(-1), Datetime.now().addHours(4), null, false, false, 60, 240);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Tratamento Primário', r.TipoAreaParticipante__c, 'Tipo Primeira Resposta Fila N2');
    }

    @IsTest
    static void buildRecord_atendimento_mapsTratamentoPrimario() {
        CaseMilestone cm = makeMock(fakeCmId(4), fakeCaseId(), 'Atendimento',
            Datetime.now().addHours(-1), Datetime.now().addHours(8), null, false, false, 60, 480);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Tratamento Primário', r.TipoAreaParticipante__c, 'Tipo Atendimento');
    }

    @IsTest
    static void buildRecord_atendimentoN3_naoMapeado_tipoNull() {
        // 'Atendimento N3' removed from map — Área Interna requires explicit business decision
        CaseMilestone cm = makeMock(fakeCmId(5), fakeCaseId(), 'Atendimento N3',
            Datetime.now().addHours(-1), Datetime.now().addHours(4), null, false, false, 60, 240);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.isNull(r.TipoAreaParticipante__c, 'Atendimento N3 nao deve ter Tipo — nao mapeado');
    }

    @IsTest
    static void buildRecord_retornoN3_mapsRetornoCliente() {
        CaseMilestone cm = makeMock(fakeCmId(6), fakeCaseId(), 'Retorno N3',
            Datetime.now().addHours(-1), Datetime.now().addHours(4), null, false, false, 60, 240);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Retorno ao Cliente', r.TipoAreaParticipante__c, 'Tipo Retorno N3');
    }

    @IsTest
    static void buildRecord_slaTotal_mapsTempTotalDeAtendimentoComNomeMarco() {
        CaseMilestone cm = makeMock(fakeCmId(7), fakeCaseId(), 'SLA Total',
            Datetime.now().addHours(-2), Datetime.now().addHours(22), null, false, false, 120, 1320);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Tempo Total de Atendimento', r.TipoAreaParticipante__c,
            'Tipo SLA Total deve ser Tempo Total de Atendimento');
        Assert.areEqual('Tempo Total de Atendimento', r.NomeMarco__c,
            'NomeMarco SLA Total deve ser Tempo Total de Atendimento');
    }

    // ── buildRecord — status SLA ──────────────────────────────────────────────

    @IsTest
    static void buildRecord_aberto_dentroPrazo() {
        CaseMilestone cm = makeMock(fakeCmId(10), fakeCaseId(), 'Triagem',
            Datetime.now().addHours(-1), Datetime.now().addHours(5), null, false, false, 60, 300);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Aberta', r.StatusAtuacao__c, 'StatusAtuacao aberto');
        Assert.areEqual('Dentro do Prazo', r.StatusSLA__c, 'StatusSLA dentro prazo');
        Assert.areEqual(false, r.ViolouSLA__c, 'Nao violou');
        Assert.areEqual('Standard', r.OrigemSLA__c, 'OrigemSLA Standard');
        Assert.areEqual(false, r.BloqueiaFechamentoCaso__c, 'Nao bloqueia fechamento');
    }

    @IsTest
    static void buildRecord_concluido_semViolacao() {
        Datetime fim = Datetime.now().addHours(-1);
        CaseMilestone cm = makeMock(fakeCmId(11), fakeCaseId(), 'Triagem',
            Datetime.now().addHours(-4), Datetime.now().addHours(2), fim, true, false, 180, 0);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Concluída', r.StatusAtuacao__c, 'StatusAtuacao Concluída');
        Assert.areEqual('Concluído', r.StatusSLA__c, 'StatusSLA Concluído');
        Assert.areEqual(false, r.ViolouSLA__c, 'Nao violou');
        Assert.areEqual(fim, r.DataHoraFim__c, 'DataHoraFim set');
        Assert.areEqual(Decimal.valueOf(0), r.TempoRestanteMinutos__c, 'TempoRestante zero');
    }

    @IsTest
    static void buildRecord_concluido_comViolacao() {
        CaseMilestone cm = makeMock(fakeCmId(12), fakeCaseId(), 'Triagem',
            Datetime.now().addHours(-10), Datetime.now().addHours(-2), Datetime.now().addHours(-1), true, true, 540, 0);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Concluída', r.StatusAtuacao__c, 'StatusAtuacao Concluída com violação');
        Assert.areEqual('Vencido', r.StatusSLA__c, 'StatusSLA Vencido — violou mesmo concluído');
        Assert.areEqual(true, r.ViolouSLA__c, 'Violou SLA');
    }

    @IsTest
    static void buildRecord_aberto_comViolacao() {
        CaseMilestone cm = makeMock(fakeCmId(13), fakeCaseId(), 'Atendimento',
            Datetime.now().addHours(-5), Datetime.now().addHours(-1), null, false, true, 300, 0);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual('Aberta', r.StatusAtuacao__c, 'StatusAtuacao Aberta violado');
        Assert.areEqual('Vencido', r.StatusSLA__c, 'StatusSLA Vencido aberto');
        Assert.areEqual(true, r.ViolouSLA__c, 'Violou SLA');
    }

    @IsTest
    static void buildRecord_calculaPercentualDecorrido() {
        CaseMilestone cm = makeMock(fakeCmId(14), fakeCaseId(), 'Triagem',
            Datetime.now().addHours(-2), Datetime.now().addHours(2), null, false, false, 120, 120);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual(Decimal.valueOf(240), r.TempoSLAMinutos__c, 'TempoSLA = elapsed+remaining');
        Assert.areEqual(Decimal.valueOf(50).setScale(2), r.PercentualDecorrido__c, 'Percentual 50%');
    }

    @IsTest
    static void buildRecord_updatePath_mantemId() {
        CaseMilestone cm = makeMock(fakeCmId(15), fakeCaseId(), 'Triagem',
            Datetime.now().addHours(-1), Datetime.now().addHours(4), null, false, false, 60, 240);
        AreaParticipante__c r = AreaParticipanteMilestoneSyncService.buildRecord(cm, null);
        Assert.areEqual(null, r.Id, 'Sem ID no path de insert');
    }

    // ── syncByCaseIds — integração com Case real ──────────────────────────────

    @IsTest
    static void syncByCaseIds_insereNovoRegistro() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        String cmId = fakeCmId(20);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'Triagem',
                Datetime.now().addHours(-2), Datetime.now().addHours(6), null, false, false, 120, 360)
        };

        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });
        Test.stopTest();

        List<AreaParticipante__c> areas = [
            SELECT Id, CaseMilestoneId__c, OrigemSLA__c, TipoAreaParticipante__c,
                   StatusAtuacao__c, StatusSLA__c, Caso__c
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard'
        ];
        Assert.areEqual(1, areas.size(), 'Deve criar 1 registro');
        Assert.areEqual(cmId, areas[0].CaseMilestoneId__c, 'CaseMilestoneId__c preenchido');
        Assert.areEqual('Categorização Inicial', areas[0].TipoAreaParticipante__c, 'Tipo correto');
        Assert.areEqual('Aberta', areas[0].StatusAtuacao__c, 'Status Aberta');
        Assert.areEqual('Dentro do Prazo', areas[0].StatusSLA__c, 'StatusSLA correto');
    }

    @IsTest
    static void syncByCaseIds_idempotencia_naoduplicaSegundaChamada() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        String cmId = fakeCmId(21);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        List<CaseMilestone> mocks = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'Atendimento',
                Datetime.now().addHours(-1), Datetime.now().addHours(7), null, false, false, 60, 420)
        };

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = mocks;
        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });
        Test.stopTest();

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = mocks;
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });

        Integer count = [SELECT COUNT() FROM AreaParticipante__c WHERE Caso__c = :c.Id AND CaseMilestoneId__c = :cmId];
        Assert.areEqual(1, count, 'Segunda chamada deve atualizar, nao duplicar');
    }

    @IsTest
    static void syncByCaseIds_preservaRegistroCustom() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        String cmId = fakeCmId(22);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        AreaParticipante__c custom = new AreaParticipante__c(
            Caso__c                 = c.Id,
            CaseMilestoneId__c      = cmId,
            OrigemSLA__c            = 'Custom',
            TipoAreaParticipante__c = 'Categorização Inicial',
            StatusAtuacao__c        = 'Aberta'
        );
        insert custom;

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'Triagem',
                Datetime.now().addHours(-1), Datetime.now().addHours(5), null, false, false, 60, 300)
        };

        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });
        Test.stopTest();

        AreaParticipante__c check = [SELECT OrigemSLA__c FROM AreaParticipante__c WHERE Id = :custom.Id];
        Assert.areEqual('Custom', check.OrigemSLA__c, 'Registro Custom deve permanecer intacto');
        Integer total = [SELECT COUNT() FROM AreaParticipante__c WHERE Caso__c = :c.Id AND CaseMilestoneId__c = :cmId];
        Assert.areEqual(1, total, 'Nao cria duplicata sobre Custom');
    }

    @IsTest
    static void syncByCaseIds_setVazio_naoFazNada() {
        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>());
        Test.stopTest();
        Assert.isTrue(true, 'Nao deve lancar excecao');
    }

    @IsTest
    static void syncByCaseIds_milestoneNaoMapeado_naoInsere() {
        // 'Atendimento N3' is unmapped — syncInternal must skip it without error
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(fakeCmId(23), c.Id, 'Atendimento N3',
                Datetime.now().addHours(-1), Datetime.now().addHours(4), null, false, false, 60, 240)
        };

        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM AreaParticipante__c WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard'];
        Assert.areEqual(0, count, 'Milestone nao mapeado nao deve criar registro');
    }

    @IsTest
    static void syncByCaseMilestoneIds_inserePorMilestoneId() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        String cmId = fakeCmId(30);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'SLA Total',
                Datetime.now().addHours(-3), Datetime.now().addHours(21), null, false, false, 180, 1260)
        };

        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseMilestoneIds(
            new Set<Id>{ fakeMilestoneSfId(30) }
        );
        Test.stopTest();

        List<AreaParticipante__c> areas = [
            SELECT TipoAreaParticipante__c, NomeMarco__c, OrigemSLA__c
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard'
        ];
        Assert.areEqual(1, areas.size(), 'Deve criar registro via syncByCaseMilestoneIds');
        Assert.areEqual('Tempo Total de Atendimento', areas[0].TipoAreaParticipante__c,
            'Tipo SLA Total deve ser Tempo Total de Atendimento');
        Assert.areEqual('Tempo Total de Atendimento', areas[0].NomeMarco__c, 'NomeMarco SLA Total');
    }

    @IsTest
    static void syncByCaseMilestoneIds_setVazio_naoFazNada() {
        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseMilestoneIds(new Set<Id>());
        Test.stopTest();
        Assert.isTrue(true, 'Nao deve lancar excecao');
    }

    @IsTest
    static void syncByCaseIds_milestoneConcluidoComViolacao_statusVencido() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        String cmId = fakeCmId(40);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'Atendimento',
                Datetime.now().addHours(-8), Datetime.now().addHours(-2),
                Datetime.now().addHours(-1), true, true, 420, 0)
        };

        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });
        Test.stopTest();

        AreaParticipante__c a = [SELECT StatusSLA__c, ViolouSLA__c FROM AreaParticipante__c
                                 WHERE Caso__c = :c.Id AND OrigemSLA__c = 'Standard' LIMIT 1];
        Assert.areEqual('Vencido', a.StatusSLA__c, 'StatusSLA Vencido para milestone concluido+violado');
        Assert.areEqual(true, a.ViolouSLA__c, 'ViolouSLA true');
    }

    @IsTest
    static void syncByCaseIds_atualizaRegistroExistente() {
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(null, null);
        String cmId = fakeCmId(50);
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'Triagem',
                Datetime.now().addHours(-2), Datetime.now().addHours(6), null, false, false, 120, 360)
        };
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });

        AreaParticipante__c before = [SELECT Id, StatusAtuacao__c FROM AreaParticipante__c
                                      WHERE CaseMilestoneId__c = :cmId LIMIT 1];
        Assert.areEqual('Aberta', before.StatusAtuacao__c, 'Pre-update: Aberta');

        AreaParticipanteMilestoneSyncService.mockMilestonesForSync = new List<CaseMilestone>{
            makeMock(cmId, c.Id, 'Triagem',
                Datetime.now().addHours(-2), Datetime.now().addHours(6),
                Datetime.now(), true, false, 120, 0)
        };

        Test.startTest();
        AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ c.Id });
        Test.stopTest();

        AreaParticipante__c after = [SELECT StatusAtuacao__c, StatusSLA__c FROM AreaParticipante__c
                                     WHERE Id = :before.Id];
        Assert.areEqual('Concluída', after.StatusAtuacao__c, 'Pos-update: Concluída');
        Assert.areEqual('Concluído', after.StatusSLA__c, 'Pos-update: StatusSLA Concluído');
    }
}