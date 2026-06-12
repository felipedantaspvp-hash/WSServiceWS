/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseCaseService {
    private static Map<String, Id> recordTypeByDevName;

    public Case createNewCase(Messaging.InboundEmail email, WS_EmailToCaseRouteConfig route, Id ownerId, Id originalCaseId) {
        WS_EmailToCaseUtils.ensureCaseCreateAccess();

        Case c = new Case();
        c.RecordTypeId = resolveCaseRecordTypeId(route.caseRecordTypeDeveloperName);
        c.Origin = route.caseOrigin;
        c.Priority = route.casePriority;
        c.OwnerId = ownerId;
        c.Subject = buildSubject(email);
        c.Description = buildDescription(email);
        if (!String.isBlank(email == null ? null : email.fromAddress)) {
            c.SuppliedEmail = email.fromAddress;
        }
        c.WS_Email_Route_Key__c = route.routeKey;
        if (originalCaseId != null && route.relateNewCaseToOriginal == true) {
            c.WS_Original_Case__c = originalCaseId;
        }

        insert c;
        return c;
    }

    public Case appendToOpenCase(Case existingCase) {
        if (existingCase == null) {
            throw new WS_EmailToCaseConfigException('Case aberto nÃ£o encontrado para append.');
        }
        return existingCase;
    }

    public Case reopenCase(Case closedCase, WS_EmailToCaseRouteConfig route) {
        if (closedCase == null) {
            throw new WS_EmailToCaseConfigException('Case fechado nÃ£o encontrado para reabertura.');
        }
        if (String.isBlank(route.reopenStatus)) {
            throw new WS_EmailToCaseConfigException('Reopen_Status__c obrigatÃ³rio quando Closed_Case_Behavior__c = REOPEN.');
        }
        validateReopenStatus(route.reopenStatus);
        WS_EmailToCaseUtils.ensureCaseUpdateAccess();

        closedCase.Status = route.reopenStatus;
        update closedCase;
        return closedCase;
    }

    public Id resolveCaseRecordTypeId(String developerName) {
        if (String.isBlank(developerName)) {
            throw new WS_EmailToCaseConfigException('Case_RecordType_DeveloperName__c Ã© obrigatÃ³rio.');
        }
        if (recordTypeByDevName == null) {
            recordTypeByDevName = new Map<String, Id>();
            for (Schema.RecordTypeInfo info : Case.SObjectType.getDescribe().getRecordTypeInfos()) {
                recordTypeByDevName.put(info.getDeveloperName(), info.getRecordTypeId());
            }
        }
        if (!recordTypeByDevName.containsKey(developerName)) {
            throw new WS_EmailToCaseConfigException('Record Type de Case nÃ£o encontrado para DeveloperName: ' + developerName);
        }
        return recordTypeByDevName.get(developerName);
    }

    public String buildSubject(Messaging.InboundEmail email) {
        String subject = email == null ? null : email.subject;
        return String.isBlank(subject) ? WS_EmailToCaseConstants.NO_SUBJECT_FALLBACK : subject;
    }

    public String buildDescription(Messaging.InboundEmail email) {
        String plainText = email == null ? null : email.plainTextBody;
        if (!String.isBlank(plainText)) {
            return plainText;
        }

        String htmlBody = email == null ? null : email.htmlBody;
        String htmlAsText = WS_EmailToCaseUtils.htmlToText(htmlBody);
        if (!String.isBlank(htmlAsText)) {
            return htmlAsText;
        }
        return WS_EmailToCaseConstants.NO_BODY_FALLBACK;
    }

    public Boolean isClosedCase(Case c) {
        return c != null && c.IsClosed;
    }

    public Boolean isWithinReopenWindow(Case closedCase, Integer reopenWindowMinutes, Datetime nowDt) {
        Integer minutes = reopenWindowMinutes == null ? 0 : reopenWindowMinutes;
        if (closedCase == null || closedCase.ClosedDate == null) {
            return false;
        }
        Datetime closeLimit = closedCase.ClosedDate.addMinutes(minutes);
        return nowDt.getTime() <= closeLimit.getTime();
    }

    private void validateReopenStatus(String statusValue) {
        Schema.DescribeFieldResult statusDescribe = Case.Status.getDescribe();
        Boolean exists = false;
        for (Schema.PicklistEntry entry : statusDescribe.getPicklistValues()) {
            if (entry.getValue() == statusValue) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            throw new WS_EmailToCaseConfigException('Reopen_Status__c invÃ¡lido para Case: ' + statusValue);
        }

        List<CaseStatus> openStatuses = [
            SELECT MasterLabel
            FROM CaseStatus
            WHERE IsClosed = false
        ];
        Set<String> openValues = new Set<String>();
        for (CaseStatus cs : openStatuses) {
            openValues.add(cs.MasterLabel);
        }
        if (!openValues.contains(statusValue)) {
            throw new WS_EmailToCaseConfigException('Reopen_Status__c deve ser um status aberto de Case: ' + statusValue);
        }
    }
}