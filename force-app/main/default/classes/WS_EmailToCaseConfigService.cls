/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseConfigService {
    @TestVisible
    private static List<WS_EmailToCaseRouteConfig> testRoutes;

    @TestVisible
    static void setTestRoutes(List<WS_EmailToCaseRouteConfig> routes) {
        testRoutes = routes;
    }

    @TestVisible
    static void clearTestRoutes() {
        testRoutes = null;
    }

    public static List<WS_EmailToCaseRouteConfig> getActiveRoutes() {
        if (Test.isRunningTest() && testRoutes != null) {
            List<WS_EmailToCaseRouteConfig> onlyActive = new List<WS_EmailToCaseRouteConfig>();
            for (WS_EmailToCaseRouteConfig route : testRoutes) {
                if (route != null && route.active == true) {
                    onlyActive.add(route);
                }
            }
            return cloneRoutes(onlyActive);
        }

        List<WS_EmailToCaseRouteConfig> routes = new List<WS_EmailToCaseRouteConfig>();
        Map<String, ParametrosAtendimento__mdt> allRoutes = ParametrosAtendimento__mdt.getAll();
        for (ParametrosAtendimento__mdt row : allRoutes.values()) {
            if (row.Ativo__c && !String.isBlank(row.RouteKey__c)) {
                routes.add(toConfig(row));
            }
        }
        return routes;
    }

    private static WS_EmailToCaseRouteConfig toConfig(ParametrosAtendimento__mdt row) {
        WS_EmailToCaseRouteConfig c = new WS_EmailToCaseRouteConfig();
        c.developerName = row.DeveloperName;
        c.active = row.Ativo__c;
        c.routeKey = row.RouteKey__c;
        c.businessEmail = row.BusinessEmail__c;
        c.salesforceServiceAddress = row.SalesforceServiceAddress__c;
        c.matchMode = row.MatchMode__c;
        c.caseRecordTypeDeveloperName = row.CaseRecordTypeDeveloperName__c;
        c.caseOrigin = row.CaseOrigin__c;
        c.casePriority = row.Prioridade__c;
        c.ownerType = row.RouteOwnerType__c;
        c.ownerKey = 'USER'.equals(row.RouteOwnerType__c) ? row.RouteOwnerUsername__c : row.RouteOwnerDeveloperName__c;
        c.closedCaseBehavior = row.ClosedCaseBehavior__c;
        c.reopenWindowMinutes = row.ReopenWindowMinutes__c == null ? 0 : Integer.valueOf(row.ReopenWindowMinutes__c);
        c.reopenStatus = row.ReopenStatus__c;
        c.relateNewCaseToOriginal = row.RelateNewCaseToOriginal__c;
        c.isDefaultRoute = row.IsDefaultEmailRoute__c;
        c.createContentFiles = row.CreateContentFiles__c;
        c.persistEmailAudit = row.PersistEmailAudit__c;
        c.allowedFromDomains = row.AllowedFromDomains__c;
        c.description = row.Descricao__c;
        return c;
    }

    private static List<WS_EmailToCaseRouteConfig> cloneRoutes(List<WS_EmailToCaseRouteConfig> source) {
        List<WS_EmailToCaseRouteConfig> result = new List<WS_EmailToCaseRouteConfig>();
        for (WS_EmailToCaseRouteConfig c : source) {
            WS_EmailToCaseRouteConfig x = new WS_EmailToCaseRouteConfig();
            x.developerName = c.developerName;
            x.active = c.active;
            x.routeKey = c.routeKey;
            x.businessEmail = c.businessEmail;
            x.salesforceServiceAddress = c.salesforceServiceAddress;
            x.matchMode = c.matchMode;
            x.caseRecordTypeDeveloperName = c.caseRecordTypeDeveloperName;
            x.caseOrigin = c.caseOrigin;
            x.casePriority = c.casePriority;
            x.ownerType = c.ownerType;
            x.ownerKey = c.ownerKey;
            x.closedCaseBehavior = c.closedCaseBehavior;
            x.reopenWindowMinutes = c.reopenWindowMinutes;
            x.reopenStatus = c.reopenStatus;
            x.relateNewCaseToOriginal = c.relateNewCaseToOriginal;
            x.isDefaultRoute = c.isDefaultRoute;
            x.createContentFiles = c.createContentFiles;
            x.persistEmailAudit = c.persistEmailAudit;
            x.allowedFromDomains = c.allowedFromDomains;
            x.description = c.description;
            result.add(x);
        }
        return result;
    }
}