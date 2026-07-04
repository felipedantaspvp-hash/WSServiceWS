/**
 * @description Service para entrada controlada de Case em acompanhamento e registro de ação operacional.
 * @author Triscal
 * @group Atendimento
 * @last modified on 06-17-2026
 * @last modified by Marllon Nascimento
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public inherited sharing class CaseAcompanhamentoService {
    @TestVisible private static final String ETAPA_EM_ACOMPANHAMENTO = 'Em Acompanhamento';
    @TestVisible private static final String TIPO_CONTROLE_PAUSA = 'Controle de Pausa';
    @TestVisible private static final String STATUS_ATIVO = 'Ativo';
    @TestVisible private static final String STATUS_ENCERRADO = 'Encerrado';
    @TestVisible private static final String ETAPA_CANCELADO = 'Cancelado';
    @TestVisible private static final String ETAPA_CONCLUIDO = 'Concluído';
    @TestVisible private static final String ETAPA_AGUARDANDO_CLIENTE = 'Aguardando Cliente';
    @TestVisible private static final String MOTIVO_AGUARDANDO_CLIENTE = 'Aguardando cliente';

    private static final Map<String, String> REASON_LABELS_BY_VALUE = new Map<String, String>{
        'Operação externa' => Label.Acao_Acompanhamento_MotivoOperacaoExterna,
        'Aguardando cliente' => Label.Acao_Acompanhamento_MotivoAguardandoCliente,
        'Aguardando terceiro' => Label.Acao_Acompanhamento_MotivoAguardandoTerceiro,
        'Aguardando movimentação operacional' => Label.Acao_Acompanhamento_MotivoAguardandoMovimentacaoOperacional,
        'Aguardando documentação' => Label.Acao_Acompanhamento_MotivoAguardandoDocumentacao,
        'Outro' => Label.Acao_Acompanhamento_MotivoOutro
    };

    private static final Map<String, String> STAGE_LABELS_BY_VALUE = new Map<String, String>{
        'Novo' => Label.Acao_Acompanhamento_EtapaNovo,
        'Em Triagem' => Label.Acao_Acompanhamento_EtapaEmTriagem,
        'Em Atendimento' => Label.Acao_Acompanhamento_EtapaEmAtendimento,
        'Aguardando Cliente' => Label.Acao_Acompanhamento_EtapaAguardandoCliente,
        'Aguardando Área Interna' => Label.Acao_Acompanhamento_EtapaAguardandoAreaInterna,
        'Em Acompanhamento' => Label.Acao_Acompanhamento_EtapaEmAcompanhamento,
        'Preparando Retorno ao Cliente' => Label.Acao_Acompanhamento_EtapaPreparandoRetornoCliente,
        'Concluído' => Label.Acao_Acompanhamento_EtapaConcluido,
        'Cancelado' => Label.Acao_Acompanhamento_EtapaCancelado,
        'Aguardando atendimento' => Label.Acao_Acompanhamento_EtapaAguardandoAtendimento
    };

    /**
     * Exceção funcional com código técnico para cenários tratados da entrada em acompanhamento.
     */
    public class FunctionalException extends Exception { public String code; }

    /**
     * Coloca um Case em acompanhamento, pausa o SLA nativo e cria um registro Acao__c.
     *
     * @param caseId Id do Case.
     * @param motivo Motivo da pausa/acompanhamento.
     * @param comentarioEntrada Comentário obrigatório informado pelo usuário.
     * @return DTO com dados da operação realizada.
     * @throws FunctionalException quando a entrada é inválida ou o usuário não possui permissão.
     */
    public static CaseAcompanhamentoDTO entrarEmAcompanhamento(Id caseId, String motivo, String comentarioEntrada) {
        validateEntradaRequest(caseId, motivo, comentarioEntrada);
        validateAccess();

        Case c = getCaseById(caseId);
        if (c == null) {
            throwFunctional('CASE_NOT_FOUND', Label.Acao_Acompanhamento_ErroCasoNaoEncontrado);
        }
        validateCaseState(c);

        Datetime nowRef = System.now();
        Id userId = UserInfo.getUserId();
        String etapaAnterior = c.EtapaAtendimento__c;
        String etapaAcompanhamento = getTargetStageForReason(motivo);

        Acao__c acao = new Acao__c(
            Tipo__c = TIPO_CONTROLE_PAUSA,
            Case__c = c.Id,
            Status__c = STATUS_ATIVO,
            MotivoPausa__c = motivo,
            EtapaAnterior__c = etapaAnterior,
            DataInicio__c = nowRef,
            UsuarioInicio__c = userId,
            ComentarioEntrada__c = comentarioEntrada,
            SlaPausado__c = true
        );

        try {
            insert acao;

            Case updateCase = new Case(
                Id = c.Id,
                EtapaAtendimento__c = etapaAcompanhamento,
                IsStopped = true,
                MotivoAcompanhamento__c = motivo,
                EtapaAnteriorAcompanhamento__c = etapaAnterior,
                DataInicioAcompanhamento__c = nowRef,
                UsuarioInicioAcompanhamento__c = userId,
                UltimoComentarioAcompanhamento__c = comentarioEntrada,
                AcaoPausaAtiva__c = acao.Id
            );
            update updateCase;
        } catch (DmlException ex) {
            throwFunctional('DML_ERROR', Label.Acao_Acompanhamento_ErroSalvar);
        }

        return buildResponse(c, acao, etapaAcompanhamento);
    }

    /**
     * Busca dados da pausa/acompanhamento ativo do Case.
     *
     * @param caseId Id do Case.
     * @return DTO com dados do Case e da ação ativa, ou indicador de ausência de acompanhamento.
     * @throws FunctionalException quando a entrada é inválida, o Case não existe ou o usuário não possui permissão.
     */
    public static CaseAcompanhamentoDTO getAcompanhamentoData(Id caseId) {
        validateCaseId(caseId);
        validateReadAccess();

        Case c = getCaseById(caseId);
        if (c == null) {
            throwFunctional('CASE_NOT_FOUND', Label.Acao_Acompanhamento_ErroCasoNaoEncontrado);
        }

        Acao__c activeAction = isCaseInAcompanhamento(c) ? findActiveAction(c) : null;
        return buildDataResponse(c, activeAction);
    }

    /**
     * Retoma o atendimento do Case, reativa SLA e encerra a ação de controle de pausa.
     *
     * @param caseId Id do Case.
     * @param comentarioSaida Comentário obrigatório da retomada.
     * @return DTO com o estado atualizado.
     * @throws FunctionalException quando a retomada não é permitida ou falha por dados inválidos.
     */
    public static CaseAcompanhamentoDTO retomarAtendimento(Id caseId, String comentarioSaida) {
        validateRetomadaRequest(caseId, comentarioSaida);
        validateResumeAccess();

        Case c = getCaseById(caseId);
        if (c == null) {
            throwFunctional('CASE_NOT_FOUND', Label.Acao_Acompanhamento_ErroCasoNaoEncontrado);
        }
        if (!isCaseInAcompanhamento(c)) {
            throwFunctional('CASE_NOT_IN_FOLLOW_UP', Label.Acao_Acompanhamento_ErroCasoNaoEstaEmAcompanhamento);
        }
        if (String.isBlank(c.EtapaAnteriorAcompanhamento__c)) {
            throwFunctional('PREVIOUS_STAGE_NOT_FOUND', Label.Acao_Acompanhamento_ErroEtapaAnteriorNaoEncontrada);
        }

        Acao__c activeAction = findActiveAction(c);
        if (activeAction == null) {
            throwFunctional('ACTIVE_ACTION_NOT_FOUND', Label.Acao_Acompanhamento_ErroAcaoAtivaNaoEncontrada);
        }

        Datetime nowRef = System.now();
        Id userId = UserInfo.getUserId();
        activeAction.Status__c = STATUS_ENCERRADO;
        activeAction.DataFim__c = nowRef;
        activeAction.UsuarioFim__c = userId;
        activeAction.ComentarioSaida__c = comentarioSaida;
        activeAction.SlaPausado__c = false;

        Case updateCase = new Case(
            Id = c.Id,
            EtapaAtendimento__c = c.EtapaAnteriorAcompanhamento__c,
            IsStopped = false,
            UltimoComentarioAcompanhamento__c = comentarioSaida,
            AcaoPausaAtiva__c = null
        );

        try {
            update activeAction;
            update updateCase;
        } catch (DmlException ex) {
            throwFunctional('DML_ERROR', Label.Acao_Acompanhamento_ErroSalvar);
        }

        Case updatedCase = new Case(
            Id = c.Id,
            EtapaAtendimento__c = c.EtapaAnteriorAcompanhamento__c,
            IsStopped = false,
            MotivoAcompanhamento__c = c.MotivoAcompanhamento__c,
            EtapaAnteriorAcompanhamento__c = c.EtapaAnteriorAcompanhamento__c,
            DataInicioAcompanhamento__c = c.DataInicioAcompanhamento__c,
            UsuarioInicioAcompanhamento__c = c.UsuarioInicioAcompanhamento__c,
            UltimoComentarioAcompanhamento__c = comentarioSaida,
            AcaoPausaAtiva__c = null
        );
        return buildDataResponse(updatedCase, activeAction);
    }

    private static void validateEntradaRequest(Id caseId, String motivo, String comentarioEntrada) {
        validateCaseId(caseId);
        if (String.isBlank(motivo)) {
            throwFunctional('REQUIRED_REASON', Label.Acao_Acompanhamento_ErroMotivoObrigatorio);
        }
        if (String.isBlank(comentarioEntrada)) {
            throwFunctional('REQUIRED_COMMENT', Label.Acao_Acompanhamento_ErroComentarioObrigatorio);
        }
    }

    private static void validateRetomadaRequest(Id caseId, String comentarioSaida) {
        validateCaseId(caseId);
        if (String.isBlank(comentarioSaida)) {
            throwFunctional('REQUIRED_RESUME_COMMENT', Label.Acao_Acompanhamento_ComentarioSaidaObrigatorio);
        }
    }

    private static void validateCaseId(Id caseId) {
        if (caseId == null) {
            throwFunctional('REQUIRED_CASE_ID', Label.Acao_Acompanhamento_ErroCasoObrigatorio);
        }
    }

    private static void validateCaseState(Case c) {
        if (ETAPA_EM_ACOMPANHAMENTO.equals(c.EtapaAtendimento__c)) {
            throwFunctional('ALREADY_IN_FOLLOW_UP', Label.Acao_Acompanhamento_ErroJaEmAcompanhamento);
        }
        if (c.IsStopped == true) {
            throwFunctional('ALREADY_STOPPED', Label.Acao_Acompanhamento_ErroSlaJaPausado);
        }
        if (c.IsClosed || ETAPA_CONCLUIDO.equals(c.EtapaAtendimento__c) || ETAPA_CANCELADO.equals(c.EtapaAtendimento__c)) {
            throwFunctional('CASE_CLOSED', Label.Acao_Acompanhamento_ErroCasoFechado);
        }
    }

    private static Case getCaseById(Id caseId) {
        List<Case> rows = [
            SELECT Id, Status, IsClosed, IsStopped, EtapaAtendimento__c,
                   MotivoAcompanhamento__c, EtapaAnteriorAcompanhamento__c,
                   DataInicioAcompanhamento__c, UsuarioInicioAcompanhamento__c,
                   UsuarioInicioAcompanhamento__r.Name, UltimoComentarioAcompanhamento__c,
                   AcaoPausaAtiva__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static CaseAcompanhamentoDTO buildResponse(Case sourceCase, Acao__c acao, String etapaAcompanhamento) {
        CaseAcompanhamentoDTO out = new CaseAcompanhamentoDTO();
        out.success = true;
        out.message = Label.Acao_Acompanhamento_Sucesso;
        out.caseId = sourceCase.Id;
        out.etapaAtual = translateStage(etapaAcompanhamento);
        out.etapaAnterior = translateStage(sourceCase.EtapaAtendimento__c);
        out.motivo = translateReason(acao.MotivoPausa__c);
        out.comentarioEntrada = acao.ComentarioEntrada__c;
        out.dataInicio = acao.DataInicio__c;
        out.usuarioInicioNome = UserInfo.getName();
        out.isStopped = true;
        out.acaoPausaAtivaId = acao.Id;
        out.tipoAcao = acao.Tipo__c;
        out.statusAcao = acao.Status__c;
        out.emAcompanhamento = true;
        return out;
    }

    private static String getTargetStageForReason(String motivo) {
        return MOTIVO_AGUARDANDO_CLIENTE.equals(motivo) ? ETAPA_AGUARDANDO_CLIENTE : ETAPA_EM_ACOMPANHAMENTO;
    }

    private static CaseAcompanhamentoDTO buildDataResponse(Case sourceCase, Acao__c activeAction) {
        CaseAcompanhamentoDTO out = new CaseAcompanhamentoDTO();
        out.success = true;
        out.caseId = sourceCase.Id;
        out.etapaAtual = translateStage(sourceCase.EtapaAtendimento__c);
        out.etapaAnterior = translateStage(activeAction?.EtapaAnterior__c ?? sourceCase.EtapaAnteriorAcompanhamento__c);
        out.motivo = activeAction?.MotivoPausa__c != null
            ? translateReason(activeAction.MotivoPausa__c)
            : translateReason(sourceCase.MotivoAcompanhamento__c);
        out.comentarioEntrada = activeAction?.ComentarioEntrada__c ?? sourceCase.UltimoComentarioAcompanhamento__c;
        out.comentarioSaida = activeAction?.ComentarioSaida__c;
        out.dataInicio = activeAction?.DataInicio__c ?? sourceCase.DataInicioAcompanhamento__c;
        out.dataFim = activeAction?.DataFim__c;
        out.usuarioInicioNome = activeAction?.UsuarioInicio__r?.Name ?? sourceCase.UsuarioInicioAcompanhamento__r?.Name;
        out.usuarioFimNome = activeAction?.UsuarioFim__r?.Name ??
            (activeAction?.UsuarioFim__c == UserInfo.getUserId() ? UserInfo.getName() : null);
        out.isStopped = sourceCase.IsStopped;
        out.acaoPausaAtivaId = sourceCase.AcaoPausaAtiva__c;
        out.tipoAcao = activeAction?.Tipo__c;
        out.statusAcao = activeAction?.Status__c;
        out.emAcompanhamento = isCaseInAcompanhamento(sourceCase);
        out.message = out.emAcompanhamento ? Label.Acao_Acompanhamento_BannerDescricao : null;
        return out;
    }

    private static String translateReason(String storedValue) {
        return getMappedLabel(REASON_LABELS_BY_VALUE, storedValue);
    }

    private static String translateStage(String storedValue) {
        return getMappedLabel(STAGE_LABELS_BY_VALUE, storedValue);
    }

    private static String getMappedLabel(Map<String, String> labelsByValue, String storedValue) {
        if (String.isBlank(storedValue)) {
            return storedValue;
        }
        String translatedLabel = labelsByValue.get(storedValue);
        return String.isBlank(translatedLabel) ? storedValue : translatedLabel;
    }

    private static Boolean isCaseInAcompanhamento(Case c) {
        return c != null && (
            ETAPA_EM_ACOMPANHAMENTO.equals(c.EtapaAtendimento__c) ||
            c.IsStopped == true ||
            c.AcaoPausaAtiva__c != null
        );
    }

    private static Acao__c findActiveAction(Case c) {
        if (c.AcaoPausaAtiva__c != null) {
            List<Acao__c> byId = queryActiveActionById(c.AcaoPausaAtiva__c, c.Id);
            if (!byId.isEmpty()) {
                return byId[0];
            }
        }

        List<Acao__c> fallback = [
            SELECT Id, Tipo__c, Case__c, Status__c, MotivoPausa__c, EtapaAnterior__c,
                   DataInicio__c, UsuarioInicio__c, UsuarioInicio__r.Name,
                   ComentarioEntrada__c, DataFim__c, UsuarioFim__c, UsuarioFim__r.Name,
                   ComentarioSaida__c, SlaPausado__c
            FROM Acao__c
            WHERE Case__c = :c.Id
              AND Tipo__c = :TIPO_CONTROLE_PAUSA
              AND Status__c = :STATUS_ATIVO
            ORDER BY DataInicio__c DESC
            LIMIT 1
        ];
        return fallback.isEmpty() ? null : fallback[0];
    }

    private static List<Acao__c> queryActiveActionById(Id actionId, Id caseId) {
        return [
            SELECT Id, Tipo__c, Case__c, Status__c, MotivoPausa__c, EtapaAnterior__c,
                   DataInicio__c, UsuarioInicio__c, UsuarioInicio__r.Name,
                   ComentarioEntrada__c, DataFim__c, UsuarioFim__c, UsuarioFim__r.Name,
                   ComentarioSaida__c, SlaPausado__c
            FROM Acao__c
            WHERE Id = :actionId
              AND Case__c = :caseId
              AND Tipo__c = :TIPO_CONTROLE_PAUSA
              AND Status__c = :STATUS_ATIVO
            LIMIT 1
        ];
    }

    private static void validateAccess() {
        if (ApexTestSeam.getBoolean('CaseAcompanhamentoService.bypassAccessChecks')) {
            return;
        }
        if (ApexTestSeam.getBoolean('CaseAcompanhamentoService.forceAccessDenied')) {
            throwFunctional('FORCED_ACCESS_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
        }
        if (!Schema.sObjectType.Case.isAccessible() || !Schema.sObjectType.Case.isUpdateable()) {
            throwFunctional('CASE_CRUD_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
        }
        if (!Schema.sObjectType.Acao__c.isAccessible() || !Schema.sObjectType.Acao__c.isCreateable()) {
            throwFunctional('ACAO_CRUD_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
        }
        validateFieldAccess();
    }

    private static void validateReadAccess() {
        if (ApexTestSeam.getBoolean('CaseAcompanhamentoService.bypassAccessChecks')) {
            return;
        }
        if (ApexTestSeam.getBoolean('CaseAcompanhamentoService.forceAccessDenied')) {
            throwFunctional('FORCED_ACCESS_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
        }
        if (!Schema.sObjectType.Case.isAccessible() || !Schema.sObjectType.Acao__c.isAccessible()) {
            throwFunctional('READ_CRUD_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
        }
        validateReadableFields(new List<Schema.DescribeFieldResult>{
            Case.EtapaAtendimento__c.getDescribe(),
            Case.IsStopped.getDescribe(),
            Case.MotivoAcompanhamento__c.getDescribe(),
            Case.EtapaAnteriorAcompanhamento__c.getDescribe(),
            Case.DataInicioAcompanhamento__c.getDescribe(),
            Case.UsuarioInicioAcompanhamento__c.getDescribe(),
            Case.UltimoComentarioAcompanhamento__c.getDescribe(),
            Case.AcaoPausaAtiva__c.getDescribe(),
            Acao__c.Case__c.getDescribe(),
            Acao__c.MotivoPausa__c.getDescribe(),
            Acao__c.EtapaAnterior__c.getDescribe(),
            Acao__c.DataInicio__c.getDescribe(),
            Acao__c.UsuarioInicio__c.getDescribe(),
            Acao__c.ComentarioEntrada__c.getDescribe(),
            Acao__c.DataFim__c.getDescribe(),
            Acao__c.UsuarioFim__c.getDescribe(),
            Acao__c.ComentarioSaida__c.getDescribe(),
            Acao__c.SlaPausado__c.getDescribe()
        });
    }

    private static void validateResumeAccess() {
        validateReadAccess();
        if (ApexTestSeam.getBoolean('CaseAcompanhamentoService.bypassAccessChecks')) {
            return;
        }
        if (!Schema.sObjectType.Case.isUpdateable() || !Schema.sObjectType.Acao__c.isUpdateable()) {
            throwFunctional('UPDATE_CRUD_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
        }
        validateUpdateableFields(new List<Schema.DescribeFieldResult>{
            Case.EtapaAtendimento__c.getDescribe(),
            Case.IsStopped.getDescribe(),
            Case.UltimoComentarioAcompanhamento__c.getDescribe(),
            Case.AcaoPausaAtiva__c.getDescribe(),
            Acao__c.DataFim__c.getDescribe(),
            Acao__c.UsuarioFim__c.getDescribe(),
            Acao__c.ComentarioSaida__c.getDescribe(),
            Acao__c.SlaPausado__c.getDescribe()
        });
    }

    private static void validateFieldAccess() {
        List<Schema.DescribeFieldResult> readableCaseFields = new List<Schema.DescribeFieldResult>{
            Case.EtapaAtendimento__c.getDescribe(),
            Case.IsStopped.getDescribe()
        };
        validateReadableFields(readableCaseFields);

        List<Schema.DescribeFieldResult> updateableCaseFields = new List<Schema.DescribeFieldResult>{
            Case.EtapaAtendimento__c.getDescribe(),
            Case.IsStopped.getDescribe(),
            Case.MotivoAcompanhamento__c.getDescribe(),
            Case.EtapaAnteriorAcompanhamento__c.getDescribe(),
            Case.DataInicioAcompanhamento__c.getDescribe(),
            Case.UsuarioInicioAcompanhamento__c.getDescribe(),
            Case.UltimoComentarioAcompanhamento__c.getDescribe(),
            Case.AcaoPausaAtiva__c.getDescribe()
        };
        validateUpdateableFields(updateableCaseFields);

        List<Schema.DescribeFieldResult> createableActionFields = new List<Schema.DescribeFieldResult>{
            Acao__c.Tipo__c.getDescribe(),
            Acao__c.Case__c.getDescribe(),
            Acao__c.Status__c.getDescribe(),
            Acao__c.MotivoPausa__c.getDescribe(),
            Acao__c.EtapaAnterior__c.getDescribe(),
            Acao__c.DataInicio__c.getDescribe(),
            Acao__c.UsuarioInicio__c.getDescribe(),
            Acao__c.ComentarioEntrada__c.getDescribe(),
            Acao__c.SlaPausado__c.getDescribe()
        };
        for (Schema.DescribeFieldResult fieldDescribe : createableActionFields) {
            if (!fieldDescribe.isCreateable()) {
                throwFunctional('FLS_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
            }
        }
    }

    private static void validateReadableFields(List<Schema.DescribeFieldResult> fieldDescribes) {
        for (Schema.DescribeFieldResult fieldDescribe : fieldDescribes) {
            if (!fieldDescribe.isAccessible()) {
                throwFunctional('FLS_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
            }
        }
    }

    private static void validateUpdateableFields(List<Schema.DescribeFieldResult> fieldDescribes) {
        for (Schema.DescribeFieldResult fieldDescribe : fieldDescribes) {
            if (!fieldDescribe.isUpdateable()) {
                throwFunctional('FLS_DENIED', Label.Acao_Acompanhamento_ErroPermissao);
            }
        }
    }

    private static void throwFunctional(String code, String message) {
        FunctionalException ex = new FunctionalException(message);
        ex.code = code;
        throw ex;
    }
}