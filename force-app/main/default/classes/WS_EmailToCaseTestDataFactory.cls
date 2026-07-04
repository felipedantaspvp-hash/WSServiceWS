/**
 * @description       : Classe de teste do modulo Email-to-Case.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
 * createQueue/createUser/createCase delegam para TestDataFactory (Pacote 40) — wrapper fino,
 * lógica de montagem do SObject centralizada lá.
**/
@IsTest
public inherited sharing class WS_EmailToCaseTestDataFactory {
    public static WS_EmailToCaseRouteConfig buildRoute(String routeKey, String ownerType, String ownerKey, String behavior, Integer reopenWindow) {
        WS_EmailToCaseRouteConfig route = new WS_EmailToCaseRouteConfig();
        route.active = true;
        route.routeKey = routeKey;
        route.businessEmail = routeKey;
        route.salesforceServiceAddress = routeKey;
        route.matchMode = WS_EmailToCaseConstants.MATCH_ANY_RECIPIENT;
        route.caseRecordTypeDeveloperName = getAnyCaseRecordTypeDeveloperName();
        route.caseOrigin = 'Email';
        route.casePriority = 'Medium';
        route.ownerType = ownerType;
        route.ownerKey = ownerKey;
        route.closedCaseBehavior = behavior;
        route.reopenWindowMinutes = reopenWindow;
        route.reopenStatus = getAnyOpenStatus();
        route.relateNewCaseToOriginal = true;
        route.isDefaultRoute = false;
        route.createContentFiles = true;
        route.persistEmailAudit = true;
        return route;
    }

    public static Messaging.InboundEmail buildEmail(
        String messageId,
        String toAddress,
        String fromAddress,
        String subject,
        String plainTextBody,
        String htmlBody
    ) {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.messageId = messageId;
        email.fromAddress = fromAddress;
        email.subject = subject;
        email.plainTextBody = plainTextBody;
        email.htmlBody = htmlBody;
        email.toAddresses = new String[] { toAddress };
        email.ccAddresses = new String[] {};
        return email;
    }

    public static Messaging.InboundEnvelope buildEnvelope(String toAddress, String fromAddress) {
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.toAddress = toAddress;
        env.fromAddress = fromAddress;
        return env;
    }

    public static Group createQueue(String developerName) {
        return TestDataFactory.createQueue(developerName);
    }

    public static User createUser(String aliasSeed) {
        return TestDataFactory.createUser(aliasSeed, null);
    }

    // RecordTypeId propositalmente null: replica o comportamento original de deixar o
    // RecordType default da org resolver (ver TestDataFactory.buildCase).
    public static Case createCase(Id ownerId, String status, Datetime closedDateLike) {
        Case c = TestDataFactory.createCase(new Map<String, Object>{
            'RecordTypeId' => null,
            'Subject' => 'Case teste',
            'Origin' => 'Email',
            'Priority' => 'Medium',
            'OwnerId' => ownerId,
            'Status' => status
        });
        if (closedDateLike != null) {
            Test.setCreatedDate(c.Id, closedDateLike.addDays(-1));
        }
        return c;
    }

    public static String getAnyCaseRecordTypeDeveloperName() {
        for (Schema.RecordTypeInfo info : Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getRecordTypeInfos()) {
            if (info.isAvailable()) {
                return info.getDeveloperName();
            }
        }
        List<RecordType> rts = [
            SELECT DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
            ORDER BY IsActive DESC, DeveloperName
            LIMIT 1
        ];
        if (!rts.isEmpty()) {
            return rts[0].DeveloperName;
        }
        return 'Master';
    }

    public static String getAnyOpenStatus() {
        List<CaseStatus> openStatuses = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = false LIMIT 1];
        return openStatuses[0].MasterLabel;
    }

    public static String getAnyClosedStatus() {
        List<CaseStatus> closedStatuses = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true LIMIT 1];
        return closedStatuses[0].MasterLabel;
    }

    public static Messaging.InboundEmail.Header buildHeader(String name, String value) {
        Messaging.InboundEmail.Header h = new Messaging.InboundEmail.Header();
        h.name = name;
        h.value = value;
        return h;
    }
}