@IsTest
private class WS_EmailToCaseConfigServiceTest {
    @IsTest
    static void testGetActiveRoutesUsesInjectedRoutesAndReturnsClones() {
        WS_EmailToCaseRouteConfig activeRoute = new WS_EmailToCaseRouteConfig();
        activeRoute.developerName = 'InjectedActive';
        activeRoute.active = true;
        activeRoute.routeKey = 'active@company.com';
        activeRoute.caseRecordTypeDeveloperName = 'AtendimentoTeconSalvador';
        activeRoute.ownerType = 'QUEUE';
        activeRoute.ownerKey = 'TSV_AtendimentoN1';
        activeRoute.reopenWindowMinutes = 30;
        activeRoute.persistEmailAudit = true;

        WS_EmailToCaseRouteConfig inactiveRoute = new WS_EmailToCaseRouteConfig();
        inactiveRoute.developerName = 'InjectedInactive';
        inactiveRoute.active = false;
        inactiveRoute.routeKey = 'inactive@company.com';

        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ activeRoute, inactiveRoute });

        List<WS_EmailToCaseRouteConfig> result = WS_EmailToCaseConfigService.getActiveRoutes();
        Assert.areEqual(1, result.size());
        Assert.areEqual('InjectedActive', result[0].developerName);
        Assert.areEqual('active@company.com', result[0].routeKey);
        Assert.areEqual(true, result[0].persistEmailAudit);

        result[0].routeKey = 'changed@company.com';
        List<WS_EmailToCaseRouteConfig> secondRead = WS_EmailToCaseConfigService.getActiveRoutes();
        Assert.areEqual('active@company.com', secondRead[0].routeKey);

        WS_EmailToCaseConfigService.clearTestRoutes();
    }

    @IsTest
    static void testGetActiveRoutesReadsMetadataAndMapsFields() {
        WS_EmailToCaseConfigService.clearTestRoutes();

        List<WS_EmailToCaseRouteConfig> routes = WS_EmailToCaseConfigService.getActiveRoutes();
        Assert.areEqual(true, routes.isEmpty() == false);

        WS_EmailToCaseRouteConfig configuredRoute;
        for (WS_EmailToCaseRouteConfig route : routes) {
            if (!String.isBlank(route.routeKey)) {
                configuredRoute = route;
                break;
            }
        }

        Assert.isNotNull(configuredRoute);
        Assert.areEqual(true, String.isBlank(configuredRoute.developerName) == false);
        Assert.areEqual(true, String.isBlank(configuredRoute.routeKey) == false);
        Assert.areEqual(true, String.isBlank(configuredRoute.caseRecordTypeDeveloperName) == false);
        Assert.areEqual(true, String.isBlank(configuredRoute.ownerType) == false);
        Assert.isNotNull(configuredRoute.reopenWindowMinutes);
    }

    @IsTest
    static void testGetActiveRoutesReadsDedicatedMetadataRowsOnly() {
        WS_EmailRoute__mdt activeRow = new WS_EmailRoute__mdt();
        activeRow.DeveloperName = 'DedicatedActive';
        activeRow.Ativo__c = true;
        activeRow.RouteKey__c = 'dedicated@company.com';
        activeRow.BusinessEmail__c = 'inbox@company.com';
        activeRow.SalesforceServiceAddress__c = 'service@company.com';
        activeRow.MatchMode__c = 'ANY_RECIPIENT';
        activeRow.CaseRecordTypeDeveloperName__c = 'AtendimentoTeconSalvador';
        activeRow.CaseOrigin__c = 'Email';
        activeRow.Prioridade__c = 'High';
        activeRow.RouteOwnerType__c = 'QUEUE';
        activeRow.RouteOwnerDeveloperName__c = 'TSV_AtendimentoN1';
        activeRow.ClosedCaseBehavior__c = 'REOPEN';
        activeRow.ReopenWindowMinutes__c = 45;
        activeRow.ReopenStatus__c = 'Novo';
        activeRow.RelateNewCaseToOriginal__c = true;
        activeRow.IsDefaultEmailRoute__c = true;
        activeRow.CreateContentFiles__c = false;
        activeRow.PersistEmailAudit__c = true;
        activeRow.AllowedFromDomains__c = 'example.com';
        activeRow.Descricao__c = 'Rota dedicada';

        WS_EmailRoute__mdt inactiveRow = new WS_EmailRoute__mdt();
        inactiveRow.DeveloperName = 'DedicatedInactive';
        inactiveRow.Ativo__c = false;
        inactiveRow.RouteKey__c = 'inactive@company.com';

        WS_EmailToCaseConfigService.setTestMetadataRows(new List<WS_EmailRoute__mdt>{ activeRow, inactiveRow });

        List<WS_EmailToCaseRouteConfig> routes = WS_EmailToCaseConfigService.getActiveRoutes();

        Assert.areEqual(1, routes.size());
        Assert.areEqual('DedicatedActive', routes[0].developerName);
        Assert.areEqual('dedicated@company.com', routes[0].routeKey);
        Assert.areEqual('inbox@company.com', routes[0].businessEmail);
        Assert.areEqual('service@company.com', routes[0].salesforceServiceAddress);
        Assert.areEqual('QUEUE', routes[0].ownerType);
        Assert.areEqual('TSV_AtendimentoN1', routes[0].ownerKey);
        Assert.areEqual(true, routes[0].isDefaultRoute);
        Assert.areEqual(false, routes[0].createContentFiles);
        Assert.areEqual(true, routes[0].persistEmailAudit);
        Assert.areEqual('example.com', routes[0].allowedFromDomains);
        Assert.areEqual('Rota dedicada', routes[0].description);

        WS_EmailToCaseConfigService.clearTestRoutes();
    }
}