/**
 * @description       : Controller de entrada do Email-to-Case. Recebe o inbound email e delega para a Service.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseInboundHandler implements Messaging.InboundEmailHandler {
    /**
     * @description       : Metodo de entrada do Email Service para processar email recebido.
     * @param email       : Email recebido pelo servico inbound.
     * @param envelope    : Envelope SMTP do email recebido.
     * @return            : Resultado do processamento para o mecanismo de inbound email.
     */
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        WS_EmailToCaseProcessResult processResult = new WS_EmailToCaseInboundService().process(email, envelope);

        Messaging.InboundEmailResult inboundResult = new Messaging.InboundEmailResult();
        inboundResult.success = processResult.success;
        inboundResult.message = processResult.message;
        return inboundResult;
    }
}