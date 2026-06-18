@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.CyclomaticComplexity')
private class CaseAcompanhamentoServiceTest {
    private static final String MOTIVO = 'Aguardando terceiro';
    private static final String MOTIVO_OPERACAO_EXTERNA = 'Operação externa';
    private static final String MOTIVO_AGUARDANDO_CLIENTE = 'Aguardando cliente';
    private static final String COMENTARIO = 'Dependência operacional externa para continuidade do atendimento.';

    @IsTest
    static void shouldEnterFollowUpAndCreatePauseActionWhenRequestIsValid() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
        Test.stopTest();

        Case savedCase = [
            SELECT Id, EtapaAtendimento__c, IsStopped, MotivoAcompanhamento__c, EtapaAnteriorAcompanhamento__c,
                   DataInicioAcompanhamento__c, UsuarioInicioAcompanhamento__c, UltimoComentarioAcompanhamento__c,
                   AcaoPausaAtiva__c
            FROM Case
            WHERE Id = :c.Id
        ];
        Acao__c savedAction = [
            SELECT Id, Tipo__c, Case__c, Status__c, MotivoPausa__c, DataInicio__c, UsuarioInicio__c,
                   ComentarioEntrada__c, EtapaAnterior__c, SlaPausado__c
            FROM Acao__c
            WHERE Id = :savedCase.AcaoPausaAtiva__c
        ];

        Assert.areEqual(true, result.success, 'DTO deve indicar sucesso.');
        Assert.areEqual(Label.Acao_Acompanhamento_Sucesso, result.message, 'DTO deve retornar mensagem de sucesso.');
        Assert.areEqual(c.Id, result.caseId, 'DTO deve retornar o Case processado.');
        Assert.areEqual(Label.Acao_Acompanhamento_EtapaEmAcompanhamento, result.etapaAtual, 'DTO deve retornar etapa atual.');
        Assert.areEqual(Label.Acao_Acompanhamento_EtapaEmAtendimento, result.etapaAnterior, 'DTO deve retornar etapa anterior.');
        Assert.areEqual(Label.Acao_Acompanhamento_MotivoAguardandoTerceiro, result.motivo, 'DTO deve retornar motivo.');
        Assert.areEqual(COMENTARIO, result.comentarioEntrada, 'DTO deve retornar comentário.');
        Assert.areNotEqual(null, result.dataInicio, 'DTO deve retornar data de início.');
        Assert.areEqual(UserInfo.getName(), result.usuarioInicioNome, 'DTO deve retornar nome do usuário.');
        Assert.areEqual(true, result.isStopped, 'DTO deve indicar SLA pausado.');
        Assert.areEqual(savedAction.Id, result.acaoPausaAtivaId, 'DTO deve retornar ação ativa.');
        Assert.areEqual(true, result.emAcompanhamento, 'DTO deve indicar acompanhamento.');

        Assert.areEqual('Em Acompanhamento', savedCase.EtapaAtendimento__c, 'Case deve entrar em acompanhamento.');
        Assert.areEqual(true, savedCase.IsStopped, 'Case deve ter SLA pausado.');
        Assert.areEqual(MOTIVO, savedCase.MotivoAcompanhamento__c, 'Case deve guardar motivo.');
        Assert.areEqual('Em Atendimento', savedCase.EtapaAnteriorAcompanhamento__c, 'Case deve preservar etapa anterior.');
        Assert.areNotEqual(null, savedCase.DataInicioAcompanhamento__c, 'Case deve guardar data de início.');
        Assert.areEqual(UserInfo.getUserId(), savedCase.UsuarioInicioAcompanhamento__c, 'Case deve guardar usuário de início.');
        Assert.areEqual(COMENTARIO, savedCase.UltimoComentarioAcompanhamento__c, 'Case deve guardar comentário.');
        Assert.areEqual(savedAction.Id, savedCase.AcaoPausaAtiva__c, 'Case deve guardar ação ativa.');

        Assert.areEqual('Controle de Pausa', savedAction.Tipo__c, 'Ação deve ter tipo de controle de pausa.');
        Assert.areEqual('Ativo', savedAction.Status__c, 'Ação deve iniciar ativa.');
        Assert.areEqual(c.Id, savedAction.Case__c, 'Ação deve vincular o Case correto.');
        Assert.areEqual(MOTIVO, savedAction.MotivoPausa__c, 'Ação deve guardar motivo.');
        Assert.areNotEqual(null, savedAction.DataInicio__c, 'Ação deve guardar data de início.');
        Assert.areEqual(UserInfo.getUserId(), savedAction.UsuarioInicio__c, 'Ação deve guardar usuário.');
        Assert.areEqual(COMENTARIO, savedAction.ComentarioEntrada__c, 'Ação deve guardar comentário.');
        Assert.areEqual('Em Atendimento', savedAction.EtapaAnterior__c, 'Ação deve preservar etapa anterior.');
        Assert.areEqual(true, savedAction.SlaPausado__c, 'Ação deve marcar SLA pausado.');
    }

    @IsTest
    static void shouldMoveCaseToWaitingCustomerWhenReasonIsWaitingCustomer() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.entrarEmAcompanhamento(
            c.Id,
            MOTIVO_AGUARDANDO_CLIENTE,
            COMENTARIO
        );
        Test.stopTest();

        Case savedCase = [
            SELECT Id, EtapaAtendimento__c, IsStopped, MotivoAcompanhamento__c, EtapaAnteriorAcompanhamento__c,
                   AcaoPausaAtiva__c
            FROM Case
            WHERE Id = :c.Id
        ];
        Acao__c savedAction = [
            SELECT Id, MotivoPausa__c, EtapaAnterior__c, Status__c, SlaPausado__c
            FROM Acao__c
            WHERE Id = :savedCase.AcaoPausaAtiva__c
        ];

        Assert.areEqual(
            Label.Acao_Acompanhamento_EtapaAguardandoCliente,
            result.etapaAtual,
            'DTO deve retornar a etapa atual de aguardando cliente.'
        );
        Assert.areEqual('Aguardando Cliente', savedCase.EtapaAtendimento__c, 'Case deve ir para Aguardando Cliente.');
        Assert.areEqual(true, savedCase.IsStopped, 'Case deve manter SLA pausado.');
        Assert.areEqual(MOTIVO_AGUARDANDO_CLIENTE, savedCase.MotivoAcompanhamento__c, 'Case deve guardar motivo selecionado.');
        Assert.areEqual('Em Atendimento', savedCase.EtapaAnteriorAcompanhamento__c, 'Case deve preservar etapa anterior.');
        Assert.areEqual(MOTIVO_AGUARDANDO_CLIENTE, savedAction.MotivoPausa__c, 'Ação deve guardar motivo selecionado.');
        Assert.areEqual('Em Atendimento', savedAction.EtapaAnterior__c, 'Ação deve preservar etapa anterior.');
        Assert.areEqual('Ativo', savedAction.Status__c, 'Ação deve continuar ativa.');
        Assert.areEqual(true, savedAction.SlaPausado__c, 'Ação deve marcar SLA pausado.');
    }

    @IsTest
    static void shouldThrowWhenCaseAlreadyInFollowUp() {
        Case c = createCase('Em Acompanhamento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
            Assert.fail('Deveria bloquear Case já em acompanhamento.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroJaEmAcompanhamento, ex.getMessage(), 'Mensagem deve indicar acompanhamento ativo.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenCaseIdIsNull() {
        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(null, MOTIVO, COMENTARIO);
            Assert.fail('Deveria exigir CaseId.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroCasoObrigatorio, ex.getMessage(), 'Mensagem deve indicar Case obrigatório.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenCaseDoesNotExist() {
        Case deletedCase = createCase('Em Atendimento');
        Id missingCaseId = deletedCase.Id;
        delete deletedCase;
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(missingCaseId, MOTIVO, COMENTARIO);
            Assert.fail('Deveria bloquear Case inexistente.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroCasoNaoEncontrado, ex.getMessage(), 'Mensagem deve indicar Case não encontrado.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenReasonIsBlank() {
        Case c = createCase('Em Atendimento');

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, ' ', COMENTARIO);
            Assert.fail('Deveria exigir motivo.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroMotivoObrigatorio, ex.getMessage(), 'Mensagem deve indicar motivo obrigatório.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenCommentIsBlank() {
        Case c = createCase('Em Atendimento');

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, '');
            Assert.fail('Deveria exigir comentário.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroComentarioObrigatorio, ex.getMessage(), 'Mensagem deve indicar comentário obrigatório.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenUserDoesNotHaveRequiredAccess() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.forceAccessDeniedForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
            Assert.fail('Deveria bloquear usuário sem acesso suficiente.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroPermissao, ex.getMessage(), 'Mensagem deve indicar falta de permissão.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenGetDataUserDoesNotHaveRequiredAccess() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.forceAccessDeniedForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
            Assert.fail('Deveria bloquear consulta sem acesso suficiente.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroPermissao, ex.getMessage(), 'Mensagem deve indicar falta de permissão na consulta.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRunAccessChecksWhenUserHasRequiredPermissions() {
        Case c = createCase('Em Atendimento');

        Test.startTest();
        CaseAcompanhamentoDTO created = CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
        CaseAcompanhamentoDTO loaded = CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
        CaseAcompanhamentoDTO resumed = CaseAcompanhamentoService.retomarAtendimento(c.Id, 'Retomada com acesso validado.');
        Test.stopTest();

        Assert.areEqual(true, created.success, 'Entrada deve passar com permissões reais.');
        Assert.areEqual(true, loaded.emAcompanhamento, 'Consulta deve passar com permissões reais.');
        Assert.areEqual(false, resumed.isStopped, 'Retomada deve passar com permissões reais.');
    }

    @IsTest
    static void shouldThrowAuraHandledExceptionWhenControllerReceivesServiceError() {
        Test.startTest();
        try {
            CaseAcompanhamentoController.entrarEmAcompanhamento(null, MOTIVO, COMENTARIO);
            Assert.fail('Controller deveria devolver AuraHandledException.');
        } catch (AuraHandledException ex) {
            Assert.areNotEqual(null, ex.getMessage(), 'Controller deve retornar mensagem tratada.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldEnterFollowUpThroughControllerWhenRequestIsValid() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoController.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Controller deve retornar sucesso.');
        Assert.areEqual(c.Id, result.caseId, 'Controller deve retornar Case processado.');
        Assert.areEqual(true, result.emAcompanhamento, 'Controller deve indicar acompanhamento.');
        Assert.areNotEqual(null, result.acaoPausaAtivaId, 'Controller deve retornar ação ativa.');
    }

    @IsTest
    static void shouldGetFollowUpDataWhenCaseIsInFollowUp() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;
        CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Consulta deve retornar sucesso.');
        Assert.areEqual(true, result.emAcompanhamento, 'Banner deve ser exibido.');
        Assert.areEqual(true, result.isStopped, 'DTO deve indicar SLA pausado.');
        Assert.areEqual(Label.Acao_Acompanhamento_MotivoAguardandoTerceiro, result.motivo, 'DTO deve retornar motivo da ação.');
        Assert.areEqual(COMENTARIO, result.comentarioEntrada, 'DTO deve retornar comentário de entrada.');
        Assert.areEqual('Controle de Pausa', result.tipoAcao, 'DTO deve retornar tipo da ação.');
        Assert.areEqual('Ativo', result.statusAcao, 'DTO deve retornar status da ação.');
    }

    @IsTest
    static void shouldTranslateExternalOperationReasonWithoutChangingStoredValue() {
        Case c = createCase('Novo');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;
        CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO_OPERACAO_EXTERNA, COMENTARIO);

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
        Test.stopTest();

        Case savedCase = [
            SELECT Id, MotivoAcompanhamento__c, EtapaAtendimento__c
            FROM Case
            WHERE Id = :c.Id
        ];
        Acao__c savedAction = [
            SELECT Id, MotivoPausa__c
            FROM Acao__c
            WHERE Id = :result.acaoPausaAtivaId
        ];

        Assert.areEqual(Label.Acao_Acompanhamento_MotivoOperacaoExterna, result.motivo, 'DTO deve exibir o label correto do motivo externo.');
        Assert.areEqual(Label.Acao_Acompanhamento_EtapaNovo, result.etapaAnterior, 'DTO deve traduzir a etapa anterior pelo valor correto.');
        Assert.areEqual(MOTIVO_OPERACAO_EXTERNA, savedCase.MotivoAcompanhamento__c, 'Case deve preservar o valor gravado do motivo.');
        Assert.areEqual('Em Acompanhamento', savedCase.EtapaAtendimento__c, 'Case deve ir para acompanhamento no motivo externo.');
        Assert.areEqual(MOTIVO_OPERACAO_EXTERNA, savedAction.MotivoPausa__c, 'Ação deve preservar o valor gravado do motivo.');
    }

    @IsTest
    static void shouldGetFollowUpDataWhenOnlySlaIsStopped() {
        Case c = createCase('Em Atendimento');
        Acao__c action = createActiveAction(c.Id, 'Em Atendimento');
        update new Case(
            Id = c.Id,
            IsStopped = true,
            MotivoAcompanhamento__c = MOTIVO,
            EtapaAnteriorAcompanhamento__c = 'Em Atendimento',
            DataInicioAcompanhamento__c = action.DataInicio__c,
            UsuarioInicioAcompanhamento__c = UserInfo.getUserId(),
            UltimoComentarioAcompanhamento__c = COMENTARIO
        );
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
        Test.stopTest();

        Assert.areEqual(true, result.emAcompanhamento, 'SLA pausado deve exibir banner.');
        Assert.areEqual('Ativo', result.statusAcao, 'Fallback deve encontrar ação ativa.');
        Assert.areEqual(action.Id, [SELECT Id FROM Acao__c WHERE Id = :action.Id].Id, 'Ação usada no cenário deve existir.');
    }

    @IsTest
    static void shouldGetFollowUpDataWhenActiveActionLookupIsFilled() {
        Case c = createCase('Em Atendimento');
        Acao__c action = createActiveAction(c.Id, 'Em Atendimento');
        update new Case(
            Id = c.Id,
            AcaoPausaAtiva__c = action.Id,
            MotivoAcompanhamento__c = MOTIVO,
            EtapaAnteriorAcompanhamento__c = 'Em Atendimento',
            DataInicioAcompanhamento__c = action.DataInicio__c,
            UsuarioInicioAcompanhamento__c = UserInfo.getUserId(),
            UltimoComentarioAcompanhamento__c = COMENTARIO
        );
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
        Test.stopTest();

        Assert.areEqual(true, result.emAcompanhamento, 'Lookup de ação ativa deve exibir banner.');
        Assert.areEqual(action.Id, result.acaoPausaAtivaId, 'DTO deve retornar ação ativa salva no Case.');
        Assert.areEqual('Controle de Pausa', result.tipoAcao, 'DTO deve validar tipo da ação.');
    }

    @IsTest
    static void shouldGetFollowUpDataUsingFallbackWhenActiveLookupIsEmpty() {
        Case c = createCase('Em Acompanhamento');
        Acao__c action = createActiveAction(c.Id, 'Em Atendimento');
        update new Case(
            Id = c.Id,
            MotivoAcompanhamento__c = MOTIVO,
            EtapaAnteriorAcompanhamento__c = 'Em Atendimento',
            DataInicioAcompanhamento__c = action.DataInicio__c,
            UsuarioInicioAcompanhamento__c = UserInfo.getUserId(),
            UltimoComentarioAcompanhamento__c = COMENTARIO
        );
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.getAcompanhamentoData(c.Id);
        Test.stopTest();

        Assert.areEqual(true, result.emAcompanhamento, 'Etapa em acompanhamento deve exibir banner.');
        Assert.areEqual(null, result.acaoPausaAtivaId, 'Case sem lookup ativo deve permanecer sem lookup no DTO.');
        Assert.areEqual('Ativo', result.statusAcao, 'Fallback deve retornar ação ativa.');
    }

    @IsTest
    static void shouldResumeFollowUpAndCloseActiveActionWhenRequestIsValid() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;
        CaseAcompanhamentoDTO startResult = CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoService.retomarAtendimento(c.Id, 'Retomada autorizada.');
        Test.stopTest();

        Case savedCase = [
            SELECT Id, EtapaAtendimento__c, IsStopped, UltimoComentarioAcompanhamento__c, AcaoPausaAtiva__c
            FROM Case
            WHERE Id = :c.Id
        ];
        Acao__c savedAction = [
            SELECT Id, Status__c, DataFim__c, UsuarioFim__c, ComentarioSaida__c, SlaPausado__c
            FROM Acao__c
            WHERE Id = :startResult.acaoPausaAtivaId
        ];

        Assert.areEqual(true, result.success, 'Retomada deve retornar sucesso.');
        Assert.areEqual(false, result.emAcompanhamento, 'DTO atualizado não deve indicar acompanhamento ativo.');
        Assert.areEqual('Encerrado', result.statusAcao, 'DTO deve retornar ação encerrada.');
        Assert.areEqual('Em Atendimento', savedCase.EtapaAtendimento__c, 'Case deve retornar para etapa anterior.');
        Assert.areEqual(false, savedCase.IsStopped, 'SLA deve ser retomado.');
        Assert.areEqual('Retomada autorizada.', savedCase.UltimoComentarioAcompanhamento__c, 'Case deve guardar comentário de retomada.');
        Assert.areEqual(null, savedCase.AcaoPausaAtiva__c, 'Case deve limpar ação ativa.');
        Assert.areEqual('Encerrado', savedAction.Status__c, 'Ação deve ser encerrada.');
        Assert.areNotEqual(null, savedAction.DataFim__c, 'Ação deve guardar data fim.');
        Assert.areEqual(UserInfo.getUserId(), savedAction.UsuarioFim__c, 'Ação deve guardar usuário fim.');
        Assert.areEqual('Retomada autorizada.', savedAction.ComentarioSaida__c, 'Ação deve guardar comentário de saída.');
        Assert.areEqual(false, savedAction.SlaPausado__c, 'Ação deve indicar SLA retomado.');
    }

    @IsTest
    static void shouldResumeFollowUpThroughControllerWhenRequestIsValid() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;
        CaseAcompanhamentoController.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoController.retomarAtendimento(c.Id, 'Retomada via controller.');
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Controller deve retornar sucesso na retomada.');
        Assert.areEqual(false, result.emAcompanhamento, 'Controller deve retornar estado retomado.');
        Assert.areEqual('Encerrado', result.statusAcao, 'Controller deve retornar ação encerrada.');
    }

    @IsTest
    static void shouldGetFollowUpDataThroughControllerWhenRequestIsValid() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;
        CaseAcompanhamentoController.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);

        Test.startTest();
        CaseAcompanhamentoDTO result = CaseAcompanhamentoController.getAcompanhamentoData(c.Id);
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Controller deve retornar sucesso na consulta.');
        Assert.areEqual(true, result.emAcompanhamento, 'Controller deve retornar acompanhamento ativo.');
        Assert.areEqual('Ativo', result.statusAcao, 'Controller deve retornar ação ativa.');
    }

    @IsTest
    static void shouldThrowAuraHandledExceptionWhenControllerGetReceivesServiceError() {
        Test.startTest();
        try {
            CaseAcompanhamentoController.getAcompanhamentoData(null);
            Assert.fail('Controller deveria tratar erro funcional da consulta.');
        } catch (AuraHandledException ex) {
            Assert.areNotEqual(null, ex.getMessage(), 'Controller deve encapsular erro funcional da consulta.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowAuraHandledExceptionWhenControllerResumeReceivesServiceError() {
        Test.startTest();
        try {
            CaseAcompanhamentoController.retomarAtendimento(null, 'Comentário.');
            Assert.fail('Controller deveria tratar erro funcional da retomada.');
        } catch (AuraHandledException ex) {
            Assert.areNotEqual(null, ex.getMessage(), 'Controller deve encapsular erro funcional da retomada.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenResumeCaseIsNotInFollowUp() {
        Case c = createCase('Em Atendimento');
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.retomarAtendimento(c.Id, 'Tentativa inválida.');
            Assert.fail('Deveria bloquear retomada sem acompanhamento.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroCasoNaoEstaEmAcompanhamento, ex.getMessage(), 'Mensagem deve indicar ausência de acompanhamento.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenPreviousStageIsMissingOnResume() {
        Case c = createCase('Em Acompanhamento');
        Acao__c action = createActiveAction(c.Id, 'Em Atendimento');
        update new Case(Id = c.Id, IsStopped = true, AcaoPausaAtiva__c = action.Id);
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.retomarAtendimento(c.Id, 'Sem etapa anterior.');
            Assert.fail('Deveria bloquear retomada sem etapa anterior.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroEtapaAnteriorNaoEncontrada, ex.getMessage(), 'Mensagem deve indicar etapa anterior ausente.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenResumeCommentIsBlank() {
        Case c = createCase('Em Acompanhamento');

        Test.startTest();
        try {
            CaseAcompanhamentoService.retomarAtendimento(c.Id, ' ');
            Assert.fail('Deveria exigir comentário de retomada.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ComentarioSaidaObrigatorio, ex.getMessage(), 'Mensagem deve indicar comentário obrigatório.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenResumeCaseIdIsNull() {
        Test.startTest();
        try {
            CaseAcompanhamentoService.retomarAtendimento(null, 'Comentário.');
            Assert.fail('Deveria exigir CaseId na retomada.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroCasoObrigatorio, ex.getMessage(), 'Mensagem deve indicar Case obrigatório.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenResumeCaseDoesNotExist() {
        Case deletedCase = createCase('Em Atendimento');
        Id missingCaseId = deletedCase.Id;
        delete deletedCase;
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.retomarAtendimento(missingCaseId, 'Comentário.');
            Assert.fail('Deveria bloquear retomada de Case inexistente.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroCasoNaoEncontrado, ex.getMessage(), 'Mensagem deve indicar Case não encontrado na retomada.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenStartingFollowUpAndSlaIsAlreadyStopped() {
        Case c = createCase('Em Atendimento');
        update new Case(Id = c.Id, IsStopped = true);
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
            Assert.fail('Deveria bloquear entrada quando SLA já está pausado.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroSlaJaPausado, ex.getMessage(), 'Mensagem deve indicar SLA já pausado.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenStartingFollowUpAndCaseIsTerminal() {
        Case c = createCase(CaseAcompanhamentoService.ETAPA_CONCLUIDO);
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.entrarEmAcompanhamento(c.Id, MOTIVO, COMENTARIO);
            Assert.fail('Deveria bloquear entrada de Case em etapa terminal.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroCasoFechado, ex.getMessage(), 'Mensagem deve indicar Case terminal.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenNoActiveActionExistsOnResume() {
        Case c = createCase('Em Acompanhamento');
        update new Case(
            Id = c.Id,
            IsStopped = true,
            EtapaAnteriorAcompanhamento__c = 'Em Atendimento'
        );
        CaseAcompanhamentoService.bypassAccessChecksForTests = true;

        Test.startTest();
        try {
            CaseAcompanhamentoService.retomarAtendimento(c.Id, 'Sem ação ativa.');
            Assert.fail('Deveria exigir ação ativa.');
        } catch (CaseAcompanhamentoService.FunctionalException ex) {
            Assert.areEqual(Label.Acao_Acompanhamento_ErroAcaoAtivaNaoEncontrada, ex.getMessage(), 'Mensagem deve indicar ação ativa ausente.');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldReturnFriendlyMessageWhenControllerReceivesUnexpectedError() {
        CaseAcompanhamentoController.forceUnexpectedErrorForTest = true;

        Test.startTest();
        try {
            CaseAcompanhamentoController.entrarEmAcompanhamento(null, MOTIVO, COMENTARIO);
            Assert.fail('Controller deveria tratar erro inesperado.');
        } catch (AuraHandledException ex) {
            Assert.areNotEqual(null, ex.getMessage(), 'Controller deve encapsular erro inesperado.');
        }
        Test.stopTest();
    }

    private static Case createCase(String etapa) {
        Case c = new Case(
            Subject = 'Teste acompanhamento',
            Status = 'Aberto',
            Origin = 'Email',
            EtapaAtendimento__c = etapa,
            UnidadeNegocio__c = 'Centro Logístico'
        );
        insert c;
        return c;
    }

    private static Acao__c createActiveAction(Id caseId, String etapaAnterior) {
        Acao__c action = new Acao__c(
            Tipo__c = CaseAcompanhamentoService.TIPO_CONTROLE_PAUSA,
            Case__c = caseId,
            Status__c = CaseAcompanhamentoService.STATUS_ATIVO,
            MotivoPausa__c = MOTIVO,
            EtapaAnterior__c = etapaAnterior,
            DataInicio__c = System.now(),
            UsuarioInicio__c = UserInfo.getUserId(),
            ComentarioEntrada__c = COMENTARIO,
            SlaPausado__c = true
        );
        insert action;
        return action;
    }
}