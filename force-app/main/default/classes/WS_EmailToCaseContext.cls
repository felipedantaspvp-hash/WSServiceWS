/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseContext {
    public Messaging.InboundEmail email;
    public Messaging.InboundEnvelope envelope;
    public WS_EmailToCaseRouteConfig route;
    public String processingKey;
    public String messageIdentifier;
    public String actionTaken;
    public Id caseId;
    public Id originalCaseId;
    public Id threadedRecordId;
    public String errorMessage;
    public Boolean duplicateIgnored;

    public WS_EmailToCaseContext(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        this.email = email;
        this.envelope = envelope;
    }
}