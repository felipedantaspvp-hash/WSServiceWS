/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseRouteConfig {
    public String developerName;
    public Boolean active;
    public String routeKey;
    public String businessEmail;
    public String salesforceServiceAddress;
    public String matchMode;
    public String caseRecordTypeDeveloperName;
    public String caseOrigin;
    public String casePriority;
    public String ownerType;
    public String ownerKey;
    public String closedCaseBehavior;
    public Integer reopenWindowMinutes;
    public String reopenStatus;
    public Boolean relateNewCaseToOriginal;
    public Boolean isDefaultRoute;
    public Boolean createContentFiles;
    public Boolean persistEmailAudit;
    public String allowedFromDomains;
    public String description;
}