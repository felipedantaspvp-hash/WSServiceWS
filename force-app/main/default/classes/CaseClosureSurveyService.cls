/**
 * @description       : Service de encerramento de Case e elegibilidade de Survey no padrão Triscal.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseClosureSurveyService {
    public class FunctionalException extends Exception { public String code; }

    private static final String CLOSED_STATUS = 'Fechado';
    private static final String REQUIRED_CATEGORIZATION_MESSAGE = 'Categorize o caso antes de encerrá-lo.';

    /**
     * @description Retorna contexto da tela de encerramento.
     * @param caseId Id do Case.
     * @return DTO com contexto de encerramento e Survey.
     */
    public static CaseClosureSurveyDTO getClosureContext(Id caseId) {
        validateReadAccess();
        if (caseId == null) throwFunctional('REQUIRED_CASE_ID', 'Caso não informado.');

        Case c = getCaseById(caseId);
        if (c == null) throwFunctional('CASE_NOT_FOUND', 'Caso não encontrado.');

        AtendimentoConfigDTO config = AtendimentoConfigService.getSurveyConfigByBusinessUnit(c.UnidadeNegocio__c);
        return buildContext(c, config);
    }

    /**
     * @description Fecha o Case e marca a elegibilidade de envio de Survey.
     * @param request Dados informados pela tela.
     * @return DTO com resultado de sucesso.
     */
    public static CaseClosureSurveyDTO closeCase(CaseClosureSurveyDTO request) {
        validateUpdateAccess();
        if (request == null || request.caseId == null) throwFunctional('REQUIRED_CASE_ID', 'Caso não informado.');

        Case c = getCaseById(request.caseId);
        if (c == null) throwFunctional('CASE_NOT_FOUND', 'Caso não encontrado.');
        if (c.IsClosed) throwFunctional('CASE_ALREADY_CLOSED', 'Este caso já está fechado.');
        validateCaseCategorization(c);

        AtendimentoConfigDTO config = AtendimentoConfigService.getSurveyConfigByBusinessUnit(c.UnidadeNegocio__c);
        CaseClosureSurveyDTO context = buildContext(c, config);
        validateClosureRequest(request);

        Boolean sendSurvey = resolveSendSurvey(request, context, config, c);
        Boolean reclamacaoEligible = context.showGerarReclamacaoQuestion == true;
        Boolean gerarReclamacao = reclamacaoEligible && request.selectedGerarReclamacao == true;

        Case updateCase = new Case(Id = c.Id);
        updateCase.Status = String.isBlank(request.closureStatus) ? CLOSED_STATUS : request.closureStatus;
        updateCase.MotivoEncerramento__c = request.closureReason;
        updateCase.ComentarioEncerramento__c = request.closureComment;
        updateCase.SolucaoCaso__c = request.closureSolution;
        updateCase.EnviarPesquisaSatisfacao__c = sendSurvey;
        updateCase.AcaoPosCategorizacao__c = 'Encerrar';
        updateCase.EtapaAtendimento__c = 'Concluído';
        if (reclamacaoEligible) {
            // Registra que a decisão (gerar ou não) já foi capturada nesta tela, para que o
            // motor automático (ReclamacaoService, disparado pelo trigger de Case) não decida de
            // novo nesta mesma transação - inclusive quando o usuário escolhe não gerar.
            updateCase.ReclamacaoDecisaoManual__c = true;
            if (gerarReclamacao) {
                updateCase.ReclamacaoGerada__c = true;
                updateCase.DtGeracaoReclamacao__c = System.now();
            }
        }
        update updateCase;

        if (gerarReclamacao) {
            insert ReclamacaoService.buildReclamacao(c, config);
        }

        CaseClosureSurveyDTO out = buildContext(getCaseById(c.Id), config);
        out.selectedSendSurvey = sendSurvey;
        out.selectedGerarReclamacao = gerarReclamacao;
        out.successMessage = 'Caso encerrado com sucesso.';
        return out;
    }

    private static CaseClosureSurveyDTO buildContext(Case c, AtendimentoConfigDTO config) {
        String surveyMode = config != null && config.isActive == true
            ? AtendimentoConfigHelper.normalizeSurveyMode(config.surveyMode)
            : AtendimentoConfigHelper.SURVEY_MODE_NEVER;
        Boolean optionalMode = surveyMode == AtendimentoConfigHelper.SURVEY_MODE_OPTIONAL;
        Boolean alwaysMode = surveyMode == AtendimentoConfigHelper.SURVEY_MODE_ALWAYS;
        Boolean showDaily = optionalMode && config != null && config.showDailySurveyIndicator == true;
        Boolean receivedToday = showDaily && config.verifyDailySurvey == true
            ? CaseClosureSurveyHelper.customerReceivedSurveyToday(c)
            : false;

        CaseClosureSurveyDTO dto = new CaseClosureSurveyDTO();
        dto.caseId = c.Id;
        dto.caseNumber = c.CaseNumber;
        dto.businessUnit = c.UnidadeNegocio__c;
        dto.channel = c.Origin;
        dto.surveyMode = surveyMode;
        dto.showSurveyQuestion = optionalMode;
        dto.defaultSendSurvey = alwaysMode;
        dto.selectedSendSurvey = alwaysMode;
        dto.showDailySurveyIndicator = showDaily;
        dto.customerAlreadyReceivedSurveyToday = receivedToday;
        dto.allowSameDaySurvey = config != null && config.allowSameDaySurvey == true;
        dto.surveyAlreadySentMessage = showDaily
            ? CaseClosureSurveyHelper.buildDailySurveyMessage(receivedToday, dto.allowSameDaySurvey)
            : null;
        dto.isCategorized = c.Categorizacao__c != null;
        dto.categorizationBlockMessage = dto.isCategorized == true ? null : REQUIRED_CATEGORIZATION_MESSAGE;
        dto.closureStatus = CLOSED_STATUS;
        dto.closureReason = c.MotivoEncerramento__c;
        dto.closureComment = c.ComentarioEncerramento__c;
        dto.closureSolution = c.SolucaoCaso__c;
        dto.showGerarReclamacaoQuestion = ReclamacaoService.isEligibleForManualDecision(c, config);
        dto.selectedGerarReclamacao = dto.showGerarReclamacaoQuestion;
        return dto;
    }

    private static Boolean resolveSendSurvey(CaseClosureSurveyDTO request, CaseClosureSurveyDTO context, AtendimentoConfigDTO config, Case c) {
        if (context.surveyMode == AtendimentoConfigHelper.SURVEY_MODE_NEVER) return false;

        String recipientEmail = CaseClosureSurveyHelper.resolveRecipientEmail(c);
        if (CaseClosureSurveyHelper.isBlockedInternalDomain(recipientEmail, config != null ? config.blockedInternalDomain : null)) {
            return false;
        }

        if (context.surveyMode == AtendimentoConfigHelper.SURVEY_MODE_ALWAYS) return true;

        Boolean selected = request.selectedSendSurvey == true;
        if (!selected) return false;
        if (context.customerAlreadyReceivedSurveyToday == true && context.allowSameDaySurvey != true) {
            throwFunctional('SAME_DAY_SURVEY_BLOCKED', 'Este cliente já recebeu pesquisa hoje.');
        }
        return true;
    }

    private static void validateClosureRequest(CaseClosureSurveyDTO request) {
        if (String.isBlank(request.closureReason)) throwFunctional('REQUIRED_CLOSURE_REASON', 'Motivo de encerramento é obrigatório.');
        if (String.isBlank(request.closureSolution)) throwFunctional('REQUIRED_CLOSURE_SOLUTION', 'Solução do caso é obrigatória.');
    }

    private static void validateCaseCategorization(Case c) {
        if (c.Categorizacao__c == null) {
            throwFunctional('REQUIRED_CASE_CATEGORIZATION', REQUIRED_CATEGORIZATION_MESSAGE);
        }
    }

    private static Case getCaseById(Id caseId) {
        List<Case> rows = [
            SELECT Id, CaseNumber, Status, IsClosed, UnidadeNegocio__c, Origin, ContactId, Contact.Email,
                   ContactEmail, SuppliedEmail, MotivoEncerramento__c, ComentarioEncerramento__c,
                   SolucaoCaso__c, EnviarPesquisaSatisfacao__c, PesquisaEnviada__c, DataHoraEnvioPesquisa__c,
                   Categorizacao__c, TipoCaso__c, Categoria__c, Assunto__c, Subassunto__c, ReclamacaoGerada__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static void validateReadAccess() {
        if (!Schema.sObjectType.Case.isAccessible()) {
            throwFunctional('CRUD_DENIED', 'Você não possui permissão para acessar este Caso.');
        }
    }

    private static void validateUpdateAccess() {
        validateReadAccess();
        if (!Schema.sObjectType.Case.isUpdateable()) {
            throwFunctional('CRUD_DENIED', 'Você não possui permissão para encerrar este Caso.');
        }
        if (!Case.Status.getDescribe().isUpdateable()
            || !Case.MotivoEncerramento__c.getDescribe().isUpdateable()
            || !Case.ComentarioEncerramento__c.getDescribe().isUpdateable()
            || !Case.SolucaoCaso__c.getDescribe().isUpdateable()
            || !Case.EnviarPesquisaSatisfacao__c.getDescribe().isUpdateable()) {
            throwFunctional('FLS_DENIED', 'Você não possui permissão para atualizar campos de encerramento deste Caso.');
        }
    }

    private static void throwFunctional(String code, String message) {
        FunctionalException ex = new FunctionalException(message);
        ex.code = code;
        throw ex;
    }
}