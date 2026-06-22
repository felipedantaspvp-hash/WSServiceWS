@IsTest
private class WS_EmailToCaseRouteServiceTest {
    @IsTest
    static void shouldResolveEnvelopeRoute_WhenMatchModeIsEnvelopeTo() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'envelope@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        route.matchMode = WS_EmailToCaseConstants.MATCH_ENVELOPE_TO;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseRouteConfig resolved = new WS_EmailToCaseRouteService().resolveRoute(
            WS_EmailToCaseTestDataFactory.buildEmail('<env@id>', 'other@company.com', 'sender@example.com', 'Envelope', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('envelope@company.com', 'sender@example.com')
        );

        Assert.areEqual('envelope@company.com', resolved.routeKey, 'A rota deve ser resolvida pelo envelope.');
        cleanupStatics();
    }

    @IsTest
    static void shouldResolveToRoute_WhenMatchModeIsToAddresses() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'to@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        route.matchMode = WS_EmailToCaseConstants.MATCH_TO_ADDRESSES;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseRouteConfig resolved = new WS_EmailToCaseRouteService().resolveRoute(
            WS_EmailToCaseTestDataFactory.buildEmail('<to@id>', 'to@company.com', 'sender@example.com', 'To', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('other@company.com', 'sender@example.com')
        );

        Assert.areEqual('to@company.com', resolved.routeKey, 'A rota deve ser resolvida pelo destinatário To.');
        cleanupStatics();
    }

    @IsTest
    static void shouldResolveCcRoute_WhenMatchModeIsCcAddresses() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'cc@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        route.matchMode = WS_EmailToCaseConstants.MATCH_CC_ADDRESSES;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        Messaging.InboundEmail email = WS_EmailToCaseTestDataFactory.buildEmail(
            '<cc@id>',
            'other@company.com',
            'sender@example.com',
            'Cc',
            'Body',
            null
        );
        email.ccAddresses = new String[]{ 'cc@company.com' };

        WS_EmailToCaseRouteConfig resolved = new WS_EmailToCaseRouteService().resolveRoute(
            email,
            WS_EmailToCaseTestDataFactory.buildEnvelope('other@company.com', 'sender@example.com')
        );

        Assert.areEqual('cc@company.com', resolved.routeKey, 'A rota deve ser resolvida pelo destinatário Cc.');
        cleanupStatics();
    }

    @IsTest
    static void shouldReturnDefaultRoute_WhenNoDirectMatchExists() {
        WS_EmailToCaseRouteConfig defaultRoute = WS_EmailToCaseTestDataFactory.buildRoute(
            'default@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        defaultRoute.isDefaultRoute = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ defaultRoute });

        WS_EmailToCaseRouteConfig resolved = new WS_EmailToCaseRouteService().resolveRoute(
            WS_EmailToCaseTestDataFactory.buildEmail('<default@id>', 'unknown@company.com', 'sender@example.com', 'Default', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('unknown@company.com', 'sender@example.com')
        );

        Assert.areEqual('default@company.com', resolved.routeKey, 'A rota default deve ser usada como fallback.');
        cleanupStatics();
    }

    @IsTest
    static void shouldReturnNull_WhenNoDirectMatchAndNoDefaultExist() {
        WS_EmailToCaseRouteConfig route = WS_EmailToCaseTestDataFactory.buildRoute(
            'known@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ route });

        WS_EmailToCaseRouteConfig resolved = new WS_EmailToCaseRouteService().resolveRoute(
            WS_EmailToCaseTestDataFactory.buildEmail('<null@id>', 'unknown@company.com', 'sender@example.com', 'None', 'Body', null),
            WS_EmailToCaseTestDataFactory.buildEnvelope('unknown@company.com', 'sender@example.com')
        );

        Assert.areEqual(null, resolved, 'Sem match e sem default, a resolução deve retornar nulo.');
        cleanupStatics();
    }

    @IsTest
    static void shouldThrow_WhenMultipleActiveRoutesMatchSameEmail() {
        WS_EmailToCaseRouteConfig routeA = WS_EmailToCaseTestDataFactory.buildRoute(
            'shared@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        WS_EmailToCaseRouteConfig routeB = WS_EmailToCaseTestDataFactory.buildRoute(
            'shared@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        routeB.businessEmail = 'shared-business@company.com';
        routeB.salesforceServiceAddress = 'shared-service@company.com';
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ routeA, routeB });

        try {
            new WS_EmailToCaseRouteService().resolveRoute(
                WS_EmailToCaseTestDataFactory.buildEmail('<amb@id>', 'shared@company.com', 'sender@example.com', 'Ambiguous', 'Body', null),
                WS_EmailToCaseTestDataFactory.buildEnvelope('shared@company.com', 'sender@example.com')
            );
            Assert.fail('Era esperado erro de ambiguidade de rota.');
        } catch (WS_EmailToCaseConfigException ex) {
            Assert.areEqual(true, ex.getMessage().contains('m') && ex.getMessage().contains('rotas ativas'), 'A mensagem deve indicar ambiguidade.');
        } finally {
            cleanupStatics();
        }
    }

    @IsTest
    static void shouldThrow_WhenMultipleDefaultRoutesAreActive() {
        WS_EmailToCaseRouteConfig defaultA = WS_EmailToCaseTestDataFactory.buildRoute(
            'default-a@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        WS_EmailToCaseRouteConfig defaultB = WS_EmailToCaseTestDataFactory.buildRoute(
            'default-b@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_USER,
            UserInfo.getUserName(),
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        defaultA.isDefaultRoute = true;
        defaultB.isDefaultRoute = true;
        WS_EmailToCaseConfigService.setTestRoutes(new List<WS_EmailToCaseRouteConfig>{ defaultA, defaultB });

        try {
            new WS_EmailToCaseRouteService().resolveRoute(
                WS_EmailToCaseTestDataFactory.buildEmail('<multidefault@id>', 'unknown@company.com', 'sender@example.com', 'Defaults', 'Body', null),
                WS_EmailToCaseTestDataFactory.buildEnvelope('unknown@company.com', 'sender@example.com')
            );
            Assert.fail('Era esperado erro por múltiplas rotas default.');
        } catch (WS_EmailToCaseConfigException ex) {
            Assert.areEqual(true, ex.getMessage().contains('mais de uma rota') && ex.getMessage().contains('ativa'), 'A mensagem deve apontar conflito de default.');
        } finally {
            cleanupStatics();
        }
    }

    private static void cleanupStatics() {
        WS_EmailToCaseConfigService.clearTestRoutes();
    }
}