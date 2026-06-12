/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseThreadingService {
    @TestVisible
    private static Id testTokenRecordId;
    @TestVisible
    private static Id testHeaderCaseId;

    public Id resolveThreadCaseId(Messaging.InboundEmail email) {
        Id tokenId;
        try {
            if (Test.isRunningTest() && testTokenRecordId != null) {
                tokenId = testTokenRecordId;
            } else {
                tokenId = System.EmailMessages.getRecordIdFromEmail(
                    email == null ? null : email.subject,
                    email == null ? null : email.plainTextBody,
                    email == null ? null : email.htmlBody
                );
            }
        } catch (Exception ignoredTokenEx) {
            tokenId = null;
        }

        Id validatedFromToken = validateCaseId(tokenId);
        if (validatedFromToken != null) {
            return validatedFromToken;
        }

        Id headerId;
        try {
            if (Test.isRunningTest() && testHeaderCaseId != null) {
                headerId = testHeaderCaseId;
            } else {
                headerId = System.Cases.getCaseIdFromEmailHeaders(email == null ? null : email.headers);
            }
        } catch (Exception ignoredHeaderEx) {
            headerId = null;
        }
        return validateCaseId(headerId);
    }

    private Id validateCaseId(Id candidate) {
        if (candidate == null) {
            return null;
        }
        Schema.SObjectType typeRef = candidate.getSObjectType();
        return typeRef == Case.SObjectType ? candidate : null;
    }

    @TestVisible
    static void setTestThreadingIds(Id tokenRecordId, Id headerCaseId) {
        testTokenRecordId = tokenRecordId;
        testHeaderCaseId = headerCaseId;
    }

    @TestVisible
    static void clearTestThreadingIds() {
        testTokenRecordId = null;
        testHeaderCaseId = null;
    }
}