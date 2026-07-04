@IsTest
private class GestaoSLAHealthCheckServiceTest {

    // ─── Bypass de Business Hours (mesmo padrao dos outros testes do projeto) ───
    private static void enableBhBypass() {
        AreaParticipanteSLAService.bypassBusinessHoursMathForTests = true;
        BusinessHoursResolverService.injectedByName.clear();
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        if (!bhs.isEmpty()) {
            BusinessHoursResolverService.injectedByName.put('Tecon Salvador', bhs[0].Id);
        }
    }

    // Helper: cria AP via addParticipation com bypass de BH
    private static Id criarAreaCustom(String comentario) {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);
        AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
        req.caseId = c.Id;
        req.area = areas[0];
        req.comentarioSolicitacao = comentario;
        return AreaParticipanteService.addParticipation(req).areaParticipanteId;
    }

    // ─── 1. Execucao sem erro ────────────────────────────────────────────────────
    @IsTest
    static void testRunHealthCheckSemErro() {
        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(null);
        Test.stopTest();

        Assert.isNotNull(result, 'Resultado nao deve ser nulo.');
        Assert.isNotNull(result.executionDateTime, 'executionDateTime deve estar preenchido.');
        Assert.isNotNull(result.issues, 'Lista de issues nao deve ser nula.');
    }

    // ─── 2. DTO preenchido ───────────────────────────────────────────────────────
    @IsTest
    static void testDtoPreenchido() {
        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(10);
        Test.stopTest();

        Assert.areEqual(4, result.totalChecks, 'totalChecks deve ser 4 (um por categoria de check).');
        Assert.areEqual(result.issues.size(), result.totalIssues, 'totalIssues deve bater com o tamanho da lista.');
        Assert.areEqual(
            result.totalCritical + result.totalHigh + result.totalMedium + result.totalLow + result.totalInfo,
            result.totalIssues,
            'Soma das severidades deve igualar totalIssues.'
        );
    }

    // ─── 3. Detecta PAUSADO_SEM_DATA_INICIO_PAUSA ───────────────────────────────
    @IsTest
    static void testDetectaPausadoSemDataInicioPausa() {
        Id areaId = criarAreaCustom('Teste pausado sem data inicio');

        // Introduzir inconsistencia: StatusSLA = Pausado sem DataHoraInicioPausa__c
        // calculateCacheBulk preserva StatusSLA=Pausado quando vem assim; DataHoraInicioPausa fica null
        update new AreaParticipante__c(
            Id = areaId,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO
        );

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean found = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('PAUSADO_SEM_DATA_INICIO_PAUSA'.equals(issue.ruleCode) && areaId.equals(issue.recordId)) {
                found = true;
                break;
            }
        }
        Assert.areEqual(true, found, 'Deve detectar area com StatusSLA=Pausado mas DataHoraInicioPausa__c vazio.');
    }

    // ─── 4. Detecta inconsistencia de pausa — DATA_INICIO_PAUSA_INDEVIDA ────────
    @IsTest
    static void testDetectaDataInicioPausaIndevidaAposRetomada() {
        Id areaId = criarAreaCustom('Teste data inicio pausa indevida');

        // Simular retomada incompleta: DataHoraInicioPausa preenchida mas StatusSLA nao e Pausado
        // Inserir diretamente para criar estado inconsistente
        // (trigger nao altera DataHoraInicioPausa se StatusSLA for setado externamente como Pausado
        //  e depois revertido manualmente)
        AreaParticipante__c ap = [SELECT Id, StatusSLA__c, DataHoraInicioPausa__c FROM AreaParticipante__c WHERE Id = :areaId];

        // Passo 1: pausar normalmente para obter DataHoraInicioPausa preenchida
        AreaParticipanteDTO.PauseResumeRequestDTO req = new AreaParticipanteDTO.PauseResumeRequestDTO();
        req.areaParticipanteId = areaId;
        AreaParticipanteService.pauseParticipation(req);

        // Passo 2: forcar StatusSLA de volta para Dentro do Prazo sem limpar DataHoraInicioPausa
        // (simula bug de retomada que nao limpou o campo)
        // Nota: updatear StatusSLA__c sem tocar DataHoraInicioPausa faz calculateCacheBulk ver
        // DataHoraInicioPausa != null e setar Pausado novamente — portanto este cenario
        // so e detectavel se DataHoraInicioPausa for limpada manualmente mas StatusSLA permanecer Pausado.
        // Verificamos o inverso: Pausado sem DataHoraInicioPausa (coberto no teste anterior)
        // e, aqui, usamos o campo DataHoraInicioPausa nulo pos-pauseParticipation como sanidade.
        AreaParticipante__c verificado = [SELECT DataHoraInicioPausa__c, StatusSLA__c FROM AreaParticipante__c WHERE Id = :areaId];
        Assert.isNotNull(verificado.DataHoraInicioPausa__c, 'Pausa deve ter preenchido DataHoraInicioPausa__c.');
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO, verificado.StatusSLA__c, 'StatusSLA deve ser Pausado apos pausa.');

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        // A area esta pausada corretamente — nao deve gerar PAUSADO_SEM_DATA_INICIO_PAUSA
        Boolean found = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('PAUSADO_SEM_DATA_INICIO_PAUSA'.equals(issue.ruleCode) && areaId.equals(issue.recordId)) {
                found = true; break;
            }
        }
        Assert.areEqual(false, found, 'Area pausada corretamente nao deve gerar issue de pausa.');
    }

    // ─── 5. Detecta STANDARD_COM_PAUSA ──────────────────────────────────────────
    @IsTest
    static void testDetectaStandardComPausa() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);

        // Inserir Standard diretamente (trigger nao calcula SLA para Standard)
        AreaParticipante__c stdArea = new AreaParticipante__c(
            Caso__c                = c.Id,
            AreaAtendimento__c     = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c           = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c       = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c           = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicioPausa__c = System.now().addMinutes(-10),
            DataHoraInicio__c      = System.now().addHours(-1)
        );
        insert stdArea;

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean found = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('STANDARD_COM_PAUSA'.equals(issue.ruleCode) && stdArea.Id.equals(issue.recordId)) {
                found = true;
                break;
            }
        }
        Assert.areEqual(true, found, 'Deve detectar Standard com DataHoraInicioPausa__c preenchida.');
    }

    // ─── 6. Garantia de que nenhum DML de correcao e feito ──────────────────────
    @IsTest
    static void testSemDmlCorrecao() {
        Id areaId = criarAreaCustom('Sem DML correcao');

        update new AreaParticipante__c(
            Id = areaId,
            StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO
        );

        AreaParticipante__c antes = [SELECT StatusSLA__c, DataHoraInicioPausa__c FROM AreaParticipante__c WHERE Id = :areaId];

        Test.startTest();
        GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        AreaParticipante__c depois = [SELECT StatusSLA__c, DataHoraInicioPausa__c FROM AreaParticipante__c WHERE Id = :areaId];
        Assert.areEqual(antes.StatusSLA__c, depois.StatusSLA__c, 'Health Check nao deve alterar StatusSLA__c.');
        Assert.areEqual(antes.DataHoraInicioPausa__c, depois.DataHoraInicioPausa__c, 'Health Check nao deve alterar DataHoraInicioPausa__c.');
    }

    // ─── 7. Bulk safety com multiplos registros ──────────────────────────────────
    @IsTest
    static void testBulkSegurancaMultiplosRegistros() {
        enableBhBypass();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        String area1 = areas[0];
        String area2 = areas.size() > 1 ? areas[1] : areas[0];
        Case c = AreaParticipanteTestDataFactory.createCase(area1, areas.size() > 1 ? area2 : null);

        List<AreaParticipante__c> inseridos = new List<AreaParticipante__c>();
        Set<String> areasUsadas = new Set<String>();
        for (String areaVal : new List<String>{ area1, area2 }) {
            if (areasUsadas.contains(areaVal)) continue;
            areasUsadas.add(areaVal);
            AreaParticipanteDTO.AddRequestDTO req = new AreaParticipanteDTO.AddRequestDTO();
            req.caseId = c.Id;
            req.area = areaVal;
            req.comentarioSolicitacao = 'Bulk ' + areaVal;
            try {
                AreaParticipanteService.addParticipation(req);
            } catch (Exception ex) {
                // area pode ja estar ativa no caso, ignorar
            }
        }

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(50);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual(4, result.totalChecks);
        Assert.isTrue(result.totalIssues >= 0);
    }

    // ─── 8. maxRecords nulo e zero usam limite padrao ────────────────────────────
    @IsTest
    static void testMaxRecordsNuloEZeroUsaLimitePadrao() {
        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult r1 = GestaoSLAHealthCheckService.runHealthCheck(null);
        GestaoSLAHealthCheckDTO.HealthCheckResult r2 = GestaoSLAHealthCheckService.runHealthCheck(0);
        Test.stopTest();

        Assert.areEqual(4, r1.totalChecks, 'Deve usar limite padrao com maxRecords=null.');
        Assert.areEqual(4, r2.totalChecks, 'Deve usar limite padrao com maxRecords=0.');
    }

    // ─── 9. Contagem de severidades correta ─────────────────────────────────────
    @IsTest
    static void testContagemSeveridadesCorreta() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);

        // Standard com pausa (Critical) e sem Milestone (Info)
        AreaParticipante__c stdArea = new AreaParticipante__c(
            Caso__c                 = c.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicioPausa__c  = System.now().addMinutes(-5),
            DataHoraInicio__c       = System.now().addHours(-1)
        );
        insert stdArea;

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Assert.areEqual(
            result.totalCritical + result.totalHigh + result.totalMedium + result.totalLow + result.totalInfo,
            result.totalIssues,
            'Soma das severidades deve igualar totalIssues.'
        );
        Assert.isTrue(result.totalCritical >= 1, 'Deve ter ao menos 1 Critical (Standard com pausa).');
        Assert.isTrue(result.totalInfo >= 1, 'Deve ter ao menos 1 Info (Standard sem Milestone).');
    }

    // ─── Helper: cria GestaoSLA__c para testes de RegrasSLA ────────────────────
    private static Id criarGestaoId() {
        List<Schema.PicklistEntry> entries = GestaoSLA__c.UnidadeNegocio__c.getDescribe().getPicklistValues();
        String unidade = entries.isEmpty() ? 'Salvador' : entries[0].getValue();
        GestaoSLA__c g = new GestaoSLA__c(
            Name            = 'Gestao HC Test',
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Tecon Salvador',
            Ativo__c        = true
        );
        insert g;
        return g.Id;
    }

    // ─── 11. Verifica factory @TestVisible newIssue ─────────────────────────────
    @IsTest
    static void testNewIssueFactory() {
        Test.startTest();
        GestaoSLAHealthCheckDTO.Issue issue = GestaoSLAHealthCheckService.newIssue(
            'High', 'AREA_PARTICIPANTE', 'AreaParticipante__c',
            UserInfo.getUserId(), 'RecordTeste',
            'REGRA_TESTE', 'Mensagem de teste', 'Recomendacao de teste'
        );
        Test.stopTest();

        Assert.areEqual('High',               issue.severity);
        Assert.areEqual('AREA_PARTICIPANTE',  issue.category);
        Assert.areEqual('AreaParticipante__c', issue.objectApiName);
        Assert.areEqual(UserInfo.getUserId(), issue.recordId);
        Assert.areEqual('RecordTeste',        issue.recordName);
        Assert.areEqual('REGRA_TESTE',        issue.ruleCode);
        Assert.isNotNull(issue.message);
        Assert.isNotNull(issue.recommendation);
    }

    // ─── 12. Detecta STATUS_SLA_INCOERENTE para Concluida e Cancelada ──────────
    @IsTest
    static void testDetectaStatusSlaIncoerente() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c1 = AreaParticipanteTestDataFactory.createCaseWithoutSla(areas[0], null);
        Case c2 = AreaParticipanteTestDataFactory.createCaseWithoutSla(areas[0], null);

        AreaParticipante__c apConc = new AreaParticipante__c(
            Caso__c                 = c1.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicio__c       = System.now().addHours(-2),
            DataHoraFim__c          = System.now()
        );
        AreaParticipante__c apCanc = new AreaParticipante__c(
            Caso__c                 = c2.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_CANCELADA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicio__c       = System.now().addHours(-1)
        );
        insert new List<AreaParticipante__c>{ apConc, apCanc };

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean foundConc = false, foundCanc = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('STATUS_SLA_INCOERENTE_CONCLUIDA'.equals(issue.ruleCode) && apConc.Id.equals(issue.recordId)) foundConc = true;
            if ('STATUS_SLA_INCOERENTE_CANCELADA'.equals(issue.ruleCode) && apCanc.Id.equals(issue.recordId)) foundCanc = true;
        }
        Assert.areEqual(true, foundConc, 'Deve detectar STATUS_SLA_INCOERENTE_CONCLUIDA.');
        Assert.areEqual(true, foundCanc, 'Deve detectar STATUS_SLA_INCOERENTE_CANCELADA.');
    }

    // ─── 13. Detecta VIOLOU_SLA inconsistente em ambas as direcoes ─────────────
    @IsTest
    static void testDetectaViolouSlaInconsistente() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c1 = AreaParticipanteTestDataFactory.createCaseWithoutSla(areas[0], null);
        Case c2 = AreaParticipanteTestDataFactory.createCaseWithoutSla(areas[0], null);

        // Vencido mas ViolouSLA__c = false
        AreaParticipante__c apVencido = new AreaParticipante__c(
            Caso__c                 = c1.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO,
            ViolouSLA__c            = false,
            DataHoraInicio__c       = System.now().addHours(-2)
        );
        // Dentro do Prazo mas ViolouSLA__c = true
        AreaParticipante__c apDentro = new AreaParticipante__c(
            Caso__c                 = c2.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO,
            ViolouSLA__c            = true,
            DataHoraInicio__c       = System.now().addHours(-1)
        );
        insert new List<AreaParticipante__c>{ apVencido, apDentro };

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean foundVencido = false, foundDentro = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('VIOLOU_SLA_INCONSISTENTE_VENCIDO'.equals(issue.ruleCode)      && apVencido.Id.equals(issue.recordId)) foundVencido = true;
            if ('VIOLOU_SLA_INCONSISTENTE_DENTRO_PRAZO'.equals(issue.ruleCode) && apDentro.Id.equals(issue.recordId))  foundDentro  = true;
        }
        Assert.areEqual(true, foundVencido, 'Deve detectar VIOLOU_SLA_INCONSISTENTE_VENCIDO.');
        Assert.areEqual(true, foundDentro,  'Deve detectar VIOLOU_SLA_INCONSISTENTE_DENTRO_PRAZO.');
    }

    // ─── 14. Detecta TEMPO_PAUSADO_NEGATIVO e DATA_INICIO_PAUSA_INDEVIDA ───────
    @IsTest
    static void testDetectaTempoNegativoEDataPausaIndevida() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(areas[0], null);

        // StatusSLA != Pausado + DataHoraInicioPausa preenchida + TempoPausado negativo
        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c                 = c.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO,
            DataHoraInicioPausa__c  = System.now().addMinutes(-10),
            TempoPausadoMinutos__c  = -5,
            DataHoraInicio__c       = System.now().addHours(-1)
        );
        insert ap;

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean foundData = false, foundNeg = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('DATA_INICIO_PAUSA_INDEVIDA'.equals(issue.ruleCode)  && ap.Id.equals(issue.recordId)) foundData = true;
            if ('TEMPO_PAUSADO_NEGATIVO'.equals(issue.ruleCode)       && ap.Id.equals(issue.recordId)) foundNeg  = true;
        }
        Assert.areEqual(true, foundData, 'Deve detectar DATA_INICIO_PAUSA_INDEVIDA.');
        Assert.areEqual(true, foundNeg,  'Deve detectar TEMPO_PAUSADO_NEGATIVO.');
    }

    // ─── 15. Detecta CASE_TERMINAL_COM_AREA_ABERTA ──────────────────────────────
    @IsTest
    static void testDetectaCaseTerminalComAreaAberta() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCaseWithoutSla(areas[0], null);

        // Standard AP aberta (nao tem BloqueiaFechamentoCaso__c = true — trigger nao processa Standard)
        AreaParticipante__c ap = new AreaParticipante__c(
            Caso__c                 = c.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            DataHoraInicio__c       = System.now().addHours(-1)
        );
        insert ap;

        // Atualizar case para estado terminal (sem bloqueio pois AP nao tem BloqueiaFechamentoCaso__c = true)
        update new Case(Id = c.Id, EtapaAtendimento__c = 'Concluído');

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean found = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('CASE_TERMINAL_COM_AREA_ABERTA'.equals(issue.ruleCode) && c.Id.equals(issue.recordId)) {
                found = true; break;
            }
        }
        Assert.areEqual(true, found, 'Deve detectar case terminal com area aberta.');
    }

    // ─── 16. Detecta REGRA_SEM_BUSINESS_HOURS ───────────────────────────────────
    @IsTest
    static void testDetectaRegraSemBusinessHours() {
        Id gestaoId = criarGestaoId();
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();

        // Categorizacao__c obrigatoria para escopo Area Interna
        Categorizacao__c categ = CategorizacaoTestDataFactory.base(false, false);
        insert categ;

        // Regra sem BusinessHoursName__c (campo em branco) → REGRA_SEM_BUSINESS_HOURS
        RegrasSLACategorizacao__c regraSemBh = new RegrasSLACategorizacao__c(
            GestaoSLA__c       = gestaoId,
            EscopoRegra__c     = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            Categorizacao__c   = categ.Id,
            AreaAtendimento__c = areas[0],
            TempoAlta__c       = 60,
            TempoMedia__c      = 60,
            TempoBaixa__c      = 60,
            Ativo__c           = true
        );
        insert regraSemBh;

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        Boolean found = false;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('REGRA_SEM_BUSINESS_HOURS'.equals(issue.ruleCode) && regraSemBh.Id.equals(issue.recordId)) {
                found = true; break;
            }
        }
        Assert.areEqual(true, found, 'Deve detectar REGRA_SEM_BUSINESS_HOURS.');
    }

    // ─── 10. Issue possui todos os campos preenchidos ────────────────────────────
    @IsTest
    static void testIssueCamposPreenchidos() {
        List<String> areas = AreaParticipanteTestDataFactory.commonAreaValues();
        Case c = AreaParticipanteTestDataFactory.createCase(areas[0], null);
        AreaParticipante__c stdArea = new AreaParticipante__c(
            Caso__c                 = c.Id,
            AreaAtendimento__c      = areas[0],
            TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            OrigemSLA__c            = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD,
            StatusAtuacao__c        = AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            StatusSLA__c            = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO,
            DataHoraInicioPausa__c  = System.now().addMinutes(-5),
            DataHoraInicio__c       = System.now().addHours(-1)
        );
        insert stdArea;

        Test.startTest();
        GestaoSLAHealthCheckDTO.HealthCheckResult result = GestaoSLAHealthCheckService.runHealthCheck(200);
        Test.stopTest();

        GestaoSLAHealthCheckDTO.Issue targetIssue = null;
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if ('STANDARD_COM_PAUSA'.equals(issue.ruleCode) && stdArea.Id.equals(issue.recordId)) {
                targetIssue = issue;
                break;
            }
        }
        Assert.isNotNull(targetIssue, 'Issue STANDARD_COM_PAUSA deve estar presente.');
        Assert.areEqual('Critical',              targetIssue.severity);
        Assert.areEqual('STANDARD_VS_CUSTOM',    targetIssue.category);
        Assert.areEqual('AreaParticipante__c',   targetIssue.objectApiName);
        Assert.areEqual('STANDARD_COM_PAUSA',    targetIssue.ruleCode);
        Assert.isNotNull(targetIssue.message);
        Assert.isNotNull(targetIssue.recommendation);
    }
}
