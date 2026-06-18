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
}