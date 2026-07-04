/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseEmailMessageService {
    public Id createInboundEmailMessage(Messaging.InboundEmail email, Id caseId, String messageIdentifier) {
        if (email == null || caseId == null) {
            return null;
        }
        if (!Schema.sObjectType.EmailMessage.isCreateable()) {
            throw new WS_EmailToCaseConfigException('Sem permissão para criar EmailMessage.');
        }

        EmailMessage em = new EmailMessage();
        em.ParentId = caseId;
        em.RelatedToId = caseId;
        em.Incoming = true;
        em.Status = WS_EmailToCaseConstants.EMAIL_MESSAGE_STATUS_INBOUND;
        em.FromAddress = email.fromAddress;
        em.ToAddress = WS_EmailToCaseUtils.joinAddresses(email.toAddresses);
        em.CcAddress = WS_EmailToCaseUtils.joinAddresses(email.ccAddresses);
        em.Subject = WS_EmailToCaseUtils.safeLeft(
            String.isBlank(email.subject) ? WS_EmailToCaseConstants.NO_SUBJECT_FALLBACK : email.subject,
            1000
        );
        em.TextBody = email.plainTextBody;
        em.HtmlBody = email.htmlBody;
        em.MessageIdentifier = WS_EmailToCaseUtils.safeLeft(messageIdentifier, 255);
        em.ThreadIdentifier = WS_EmailToCaseUtils.safeLeft(messageIdentifier, 255);

        insert em;
        return em.Id;
    }
}
