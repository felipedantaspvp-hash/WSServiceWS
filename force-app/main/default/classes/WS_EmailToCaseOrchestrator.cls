/**
 * @description       : Fachada de compatibilidade do modulo Email-to-Case.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseOrchestrator {
    private final WS_EmailToCaseInboundService inboundService;

    /**
     * @description       : Construtor padrao com Service concreta.
     */
    public WS_EmailToCaseOrchestrator() {
        this(new WS_EmailToCaseInboundService());
    }

    /**
     * @description       : Construtor com injecao direta da Service principal.
     * @param inboundService : Service principal do fluxo de inbound email.
     */
    public WS_EmailToCaseOrchestrator(WS_EmailToCaseInboundService inboundService) {
        this.inboundService = inboundService;
    }

    /**
     * @description       : Construtor legado com injecao por dependencias granulares.
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
    public WS_EmailToCaseOrchestrator(
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
        this.inboundService = new WS_EmailToCaseInboundService(
            routeService,
            dedupService,
            threadingService,
            caseService,
            ownerService,
            attachmentService,
            emailMessageService,
            logService,
            clock
        );
    }

    /**
     * @description       : Processa o inbound email delegando para a Service principal.
     * @param email       : Email recebido pelo servico inbound.
     * @param envelope    : Envelope SMTP do email recebido.
     * @return            : Resultado padronizado do processamento.
     */
    public WS_EmailToCaseProcessResult process(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        return inboundService.process(email, envelope);
    }
}