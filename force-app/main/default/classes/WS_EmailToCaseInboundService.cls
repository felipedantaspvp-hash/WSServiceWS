/**
 * @description       : Service principal do fluxo de Email-to-Case.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseInboundService {
    private final WS_EmailToCaseRouteService routeService;
    private final WS_EmailToCaseDedupService dedupService;
    private final WS_EmailToCaseThreadingService threadingService;
    private final WS_EmailToCaseCaseService caseService;
    private final WS_EmailToCaseOwnerService ownerService;
    private final WS_EmailToCaseAttachmentService attachmentService;
    private final WS_EmailToCaseEmailMessageService emailMessageService;
    private final WS_EmailToCaseLogService logService;
    private final WS_EmailToCaseClock clock;

    /**
     * @description       : Construtor padrao com injecao das dependencias concretas do fluxo.
     */
    public WS_EmailToCaseInboundService() {
        this(
            new WS_EmailToCaseRouteService(),
            new WS_EmailToCaseDedupService(),
            new WS_EmailToCaseThreadingService(),
            new WS_EmailToCaseCaseService(),
            new WS_EmailToCaseOwnerService(),
            new WS_EmailToCaseAttachmentService(),
            new WS_EmailToCaseEmailMessageService(),
            new WS_EmailToCaseLogService(),
            WS_EmailToCaseClock.get()
        );
    }

    /**
     * @description       : Construtor para injecao de dependencias (testes e cenarios controlados).
     * @param routeService : Service de resolucao de rota.
     * @param dedupService : Service de deduplicacao por identificador da mensagem.
     * @param threadingService : Service de resolucao de thread para Case existente.
     * @param caseService  : Service de manipulacao de Case.
     * @param ownerService : Service de resolucao de owner.
     * @param attachmentService : Service de publicacao de anexos.
     * @param emailMessageService : Service de criacao de EmailMessage.
     * @param logService   : Service de log tecnico/auditoria.
     * @param clock        : Relogio utilizado para regras de janela de reabertura.
     */
    public WS_EmailToCaseInboundService(
        WS_EmailToCaseRouteService routeService,
        WS_EmailToCaseDedupService dedupService,
        WS_EmailToCaseThreadingService threadingService,
        WS_EmailToCaseCaseService caseService,
        WS_EmailToCaseOwnerService ownerService,
        WS_EmailToCaseAttachmentService attachmentService,
        WS_EmailToCaseEmailMessageService emailMessageService,
        WS_EmailToCaseLogService logService,
        WS_EmailToCaseClock clock
    ) {
        this.routeService = routeService;
        this.dedupService = dedupService;
        this.threadingService = threadingService;
        this.caseService = caseService;
        this.ownerService = ownerService;
        this.attachmentService = attachmentService;
        this.emailMessageService = emailMessageService;
        this.logService = logService;
        this.clock = clock;
    }

    /**
     * @description       : Processa o email inbound conforme regras de rota e ciclo do Case.
     * @param email       : Email recebido pelo servico inbound.
     * @param envelope    : Envelope SMTP do email recebido.
     * @return            : Resultado padronizado do processamento.
     */
    public WS_EmailToCaseProcessResult process(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        WS_EmailToCaseContext ctx = new WS_EmailToCaseContext(email, envelope);
        WS_EmailToCaseProcessResult result = new WS_EmailToCaseProcessResult(true, 'Email processado com sucesso.');

        try {
            ctx.route = routeService.resolveRoute(email, envelope);
            if (ctx.route == null) {
                String message = 'Nenhuma rota ativa encontrada para o e-mail recebido.';
                logService.logError(ctx, message, true);
                result.message = message;
                result.action = WS_EmailToCaseConstants.ACTION_ERROR;
                return result;
            }

            WS_EmailToCaseDedupService.ReservationResult reservation = dedupService.reserve(ctx);
            ctx.processingKey = reservation.processingKey;
            ctx.messageIdentifier = reservation.messageIdentifier;

            if (reservation.duplicate) {
                ctx.duplicateIgnored = true;
                ctx.actionTaken = WS_EmailToCaseConstants.ACTION_DUPLICATE_IGNORED;
                result.message = 'E-mail duplicado para a mesma rota. Processamento ignorado.';
                result.action = ctx.actionTaken;
                return result;
            }

            Id threadedCaseId = threadingService.resolveThreadCaseId(email);
            ctx.threadedRecordId = threadedCaseId;

            Case targetCase;
            if (threadedCaseId == null) {
                targetCase = createNewCase(email, ctx.route, null);
                ctx.caseId = targetCase.Id;
                ctx.actionTaken = WS_EmailToCaseConstants.ACTION_NEW_CASE;
            } else {
                targetCase = [
                    SELECT Id, IsClosed, ClosedDate, OwnerId, Status
                    FROM Case
                    WHERE Id = :threadedCaseId
                    LIMIT 1
                ];

                if (!caseService.isClosedCase(targetCase)) {
                    caseService.appendToOpenCase(targetCase);
                    ctx.caseId = targetCase.Id;
                    ctx.actionTaken = WS_EmailToCaseConstants.ACTION_APPEND_OPEN_CASE;
                } else {
                    handleClosedCase(ctx, targetCase);
                }
            }

            if (ctx.caseId != null) {
                try {
                    emailMessageService.createInboundEmailMessage(email, ctx.caseId, ctx.messageIdentifier);
                } catch (Exception emailMessageEx) {
                    ctx.errorMessage = appendError(ctx.errorMessage, 'Falha ao criar EmailMessage: ' + emailMessageEx.getMessage());
                }
            }

            if (ctx.route.createContentFiles == true && ctx.caseId != null) {
                try {
                    attachmentService.publishAttachmentsToCase(email, ctx.caseId);
                } catch (Exception attachEx) {
                    ctx.errorMessage = appendError(ctx.errorMessage, 'Falha ao publicar anexos: ' + attachEx.getMessage());
                }
            }

            if (!String.isBlank(ctx.errorMessage)) {
                logService.logError(ctx, ctx.errorMessage, ctx.route.persistEmailAudit == true);
            }

            result.action = ctx.actionTaken;
            result.caseId = ctx.caseId;
            if (!String.isBlank(ctx.errorMessage)) {
                result.message = 'Processamento concluido com alertas: ' + ctx.errorMessage;
            }
            return result;
        } catch (Exception ex) {
            ctx.errorMessage = ex.getMessage();
            Boolean persistAudit = ctx.route == null ? true : (ctx.route.persistEmailAudit == true);
            try {
                logService.logError(ctx, ex.getMessage(), persistAudit);
            } catch (Exception ignoredLogEx) {
                System.debug(LoggingLevel.WARN, 'Log service unavailable; swallowed to protect main flow: ' + ignoredLogEx.getMessage());
            }
            result.success = true;
            result.message = 'Falha controlada no processamento: ' + ex.getMessage();
            result.action = WS_EmailToCaseConstants.ACTION_ERROR;
            return result;
        }
    }

    /**
     * @description       : Executa a estrategia para case fechado (reabrir ou criar novo).
     * @param ctx         : Contexto de processamento do email.
     * @param threadedCase : Case localizado por threading.
     */
    private void handleClosedCase(WS_EmailToCaseContext ctx, Case threadedCase) {
        String behavior = ctx.route.closedCaseBehavior;
        if (behavior == WS_EmailToCaseConstants.BEHAVIOR_CREATE_NEW) {
            Case created = createNewCase(ctx.email, ctx.route, threadedCase.Id);
            ctx.caseId = created.Id;
            ctx.originalCaseId = threadedCase.Id;
            ctx.actionTaken = WS_EmailToCaseConstants.ACTION_NEW_CASE;
            return;
        }

        if (behavior != WS_EmailToCaseConstants.BEHAVIOR_REOPEN) {
            throw new WS_EmailToCaseConfigException('Closed_Case_Behavior__c invalido: ' + behavior);
        }

        Datetime nowDt = clock.now();
        if (caseService.isWithinReopenWindow(threadedCase, ctx.route.reopenWindowMinutes, nowDt)) {
            Case reopened = caseService.reopenCase(threadedCase, ctx.route);
            ctx.caseId = reopened.Id;
            ctx.originalCaseId = threadedCase.Id;
            ctx.actionTaken = WS_EmailToCaseConstants.ACTION_REOPEN_CLOSED_CASE;
            return;
        }

        Case createdAfterWindow = createNewCase(ctx.email, ctx.route, threadedCase.Id);
        ctx.caseId = createdAfterWindow.Id;
        ctx.originalCaseId = threadedCase.Id;
        ctx.actionTaken = WS_EmailToCaseConstants.ACTION_NEW_AFTER_REOPEN_WINDOW;
    }

    /**
     * @description       : Cria um novo Case com owner resolvido pela regra da rota.
     * @param email       : Email recebido.
     * @param route       : Configuracao de rota aplicada.
     * @param originalCaseId : Id do case original quando houver relacionamento.
     * @return            : Case criado.
     */
    private Case createNewCase(Messaging.InboundEmail email, WS_EmailToCaseRouteConfig route, Id originalCaseId) {
        Id ownerId = ownerService.resolveOwnerId(route);
        return caseService.createNewCase(email, route, ownerId, originalCaseId);
    }

    /**
     * @description       : Concatena mensagens de erro preservando erros anteriores.
     * @param base        : Mensagem base ja acumulada.
     * @param extra       : Nova mensagem de erro.
     * @return            : Mensagem consolidada.
     */
    private String appendError(String base, String extra) {
        if (String.isBlank(base)) {
            return extra;
        }
        return base + ' | ' + extra;
    }
}