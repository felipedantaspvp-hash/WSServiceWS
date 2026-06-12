/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseDedupService {
    public class ReservationResult {
        public Boolean duplicate;
        public String processingKey;
        public String messageIdentifier;
    }

    public ReservationResult reserve(WS_EmailToCaseContext ctx) {
        ReservationResult result = new ReservationResult();

        String messageId = WS_EmailToCaseUtils.normalizeMessageId(ctx.email == null ? null : ctx.email.messageId);
        if (String.isBlank(messageId)) {
            messageId = WS_EmailToCaseUtils.normalizeMessageId(WS_EmailToCaseUtils.getHeaderValue(ctx.email, 'Message-ID'));
        }

        if (String.isBlank(messageId)) {
            messageId = buildFallbackMessageIdentifier(ctx);
        }

        String routeKey = WS_EmailToCaseUtils.normalize(ctx.route == null ? null : ctx.route.routeKey);
        String processingKey = routeKey + '|' + messageId;
        result.duplicate = isDuplicateForSameRoute(messageId, ctx.route == null ? null : ctx.route.routeKey);

        result.processingKey = processingKey;
        result.messageIdentifier = messageId;
        return result;
    }

    private Boolean isDuplicateForSameRoute(String messageIdentifier, String routeKey) {
        if (String.isBlank(messageIdentifier) || String.isBlank(routeKey)) {
            return false;
        }

        List<EmailMessage> existingEmails = [
            SELECT ParentId
            FROM EmailMessage
            WHERE Incoming = true
              AND MessageIdentifier = :WS_EmailToCaseUtils.safeLeft(messageIdentifier, 255)
              AND ParentId != null
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];

        Set<Id> parentCaseIds = new Set<Id>();
        for (EmailMessage existing : existingEmails) {
            if (existing.ParentId != null && existing.ParentId.getSObjectType() == Case.SObjectType) {
                parentCaseIds.add(existing.ParentId);
            }
        }

        if (parentCaseIds.isEmpty()) {
            return false;
        }

        Integer countForRoute = [
            SELECT count()
            FROM Case
            WHERE Id IN :parentCaseIds
              AND WS_Email_Route_Key__c = :routeKey
        ];
        return countForRoute > 0;
    }

    private String buildFallbackMessageIdentifier(WS_EmailToCaseContext ctx) {
        String fromAddress = WS_EmailToCaseUtils.normalize(ctx.email == null ? null : ctx.email.fromAddress);
        String subject = WS_EmailToCaseUtils.normalize(ctx.email == null ? null : ctx.email.subject);
        String plain = WS_EmailToCaseUtils.safeLeft(ctx.email == null ? null : ctx.email.plainTextBody, WS_EmailToCaseConstants.HASH_BODY_SLICE);
        String html = WS_EmailToCaseUtils.safeLeft(ctx.email == null ? null : ctx.email.htmlBody, WS_EmailToCaseConstants.HASH_BODY_SLICE);
        String routeKey = WS_EmailToCaseUtils.normalize(ctx.route == null ? null : ctx.route.routeKey);

        String seed = String.join(
            new List<String>{
                fromAddress == null ? '' : fromAddress,
                subject == null ? '' : subject,
                plain == null ? '' : plain,
                html == null ? '' : html,
                routeKey == null ? '' : routeKey
            },
            '|'
        );

        return 'hash:' + WS_EmailToCaseUtils.computeSha256(seed);
    }
}