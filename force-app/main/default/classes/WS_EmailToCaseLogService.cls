/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseLogService {
    public void logError(WS_EmailToCaseContext ctx, String errorMessage, Boolean persistAudit) {
        if (persistAudit != true || !Schema.sObjectType.LogIntegracao__c.isCreateable()) {
            return;
        }

        LogIntegracao__c row = new LogIntegracao__c();
        row.Name = WS_EmailToCaseUtils.safeLeft('WS EmailToCase', 80);
        row.MetodoCallout__c = 'EMAIL';
        row.DescritivoErroLog__c = WS_EmailToCaseUtils.safeLeft(errorMessage, 255);
        row.RequestBody__c = WS_EmailToCaseUtils.safeLeft(buildEmailBodySnapshot(ctx), 131072);
        row.ComentariosObservacoes__c = WS_EmailToCaseUtils.safeLeft(buildDetailedError(ctx, errorMessage), 131072);
        row.Endpoint__c = WS_EmailToCaseUtils.safeLeft(buildEndpointHint(ctx), 255);

        if (ctx != null && ctx.caseId != null) {
            row.ObjetoRelacionamento__c = 'Case';
            row.IdRelacionamento__c = String.valueOf(ctx.caseId);
        }

        insert row;
    }

    private String buildEndpointHint(WS_EmailToCaseContext ctx) {
        List<String> parts = new List<String>();
        parts.add('route=' + (ctx == null || ctx.route == null ? WS_EmailToCaseConstants.NO_ROUTE_KEY : String.valueOf(ctx.route.routeKey)));
        parts.add('action=' + (ctx == null ? null : String.valueOf(ctx.actionTaken)));
        return String.join(parts, ';');
    }

    private String buildDetailedError(WS_EmailToCaseContext ctx, String errorMessage) {
        Messaging.InboundEmail email = ctx == null ? null : ctx.email;
        Messaging.InboundEnvelope envelope = ctx == null ? null : ctx.envelope;

        List<String> lines = new List<String>{
            'Erro: ' + (String.isBlank(errorMessage) ? 'Não informado' : errorMessage),
            'Ação: ' + (ctx == null ? null : String.valueOf(ctx.actionTaken)),
            'Route Key: ' + (ctx == null || ctx.route == null ? WS_EmailToCaseConstants.NO_ROUTE_KEY : String.valueOf(ctx.route.routeKey)),
            'Processing Key: ' + (ctx == null ? null : String.valueOf(ctx.processingKey)),
            'Message Identifier: ' + (ctx == null ? null : String.valueOf(ctx.messageIdentifier)),
            'From: ' + (email == null ? null : email.fromAddress),
            'Envelope To: ' + (envelope == null ? null : envelope.toAddress),
            'To: ' + WS_EmailToCaseUtils.joinAddresses(email == null ? null : email.toAddresses),
            'Cc: ' + WS_EmailToCaseUtils.joinAddresses(email == null ? null : email.ccAddresses),
            'Subject: ' + (email == null ? null : email.subject),
            'Thread Record Id: ' + (ctx == null || ctx.threadedRecordId == null ? null : String.valueOf(ctx.threadedRecordId)),
            'Case Id: ' + (ctx == null || ctx.caseId == null ? null : String.valueOf(ctx.caseId)),
            'Original Case Id: ' + (ctx == null || ctx.originalCaseId == null ? null : String.valueOf(ctx.originalCaseId)),
            'In-Reply-To: ' + WS_EmailToCaseUtils.getHeaderValue(email, 'In-Reply-To'),
            'References: ' + WS_EmailToCaseUtils.getHeaderValue(email, 'References')
        };

        return String.join(lines, '\n');
    }

    private String buildEmailBodySnapshot(WS_EmailToCaseContext ctx) {
        Messaging.InboundEmail email = ctx == null ? null : ctx.email;
        String plainBody = email == null ? null : email.plainTextBody;
        String htmlBody = email == null ? null : email.htmlBody;
        String htmlAsText = WS_EmailToCaseUtils.htmlToText(htmlBody);

        List<String> parts = new List<String>{
            'Subject: ' + (email == null ? null : email.subject),
            'From: ' + (email == null ? null : email.fromAddress),
            'To: ' + WS_EmailToCaseUtils.joinAddresses(email == null ? null : email.toAddresses),
            'Cc: ' + WS_EmailToCaseUtils.joinAddresses(email == null ? null : email.ccAddresses),
            '',
            'PlainTextBody:',
            String.isBlank(plainBody) ? '(vazio)' : plainBody,
            '',
            'HtmlBodyAsText:',
            String.isBlank(htmlAsText) ? '(vazio)' : htmlAsText
        };

        return String.join(parts, '\n');
    }
}
