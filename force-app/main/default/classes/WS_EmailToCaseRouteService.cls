/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseRouteService {
    public WS_EmailToCaseRouteConfig resolveRoute(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        List<WS_EmailToCaseRouteConfig> activeRoutes = WS_EmailToCaseConfigService.getActiveRoutes();
        if (activeRoutes.isEmpty()) {
            return null;
        }

        Set<String> toAddresses = WS_EmailToCaseUtils.normalizeAddressSet(email == null ? null : email.toAddresses);
        Set<String> ccAddresses = WS_EmailToCaseUtils.normalizeAddressSet(email == null ? null : email.ccAddresses);
        String envelopeTo = WS_EmailToCaseUtils.normalize(envelope == null ? null : envelope.toAddress);

        Set<String> anyRecipients = new Set<String>();
        anyRecipients.addAll(toAddresses);
        anyRecipients.addAll(ccAddresses);
        if (!String.isBlank(envelopeTo)) {
            anyRecipients.add(envelopeTo);
        }

        List<WS_EmailToCaseRouteConfig> matches = new List<WS_EmailToCaseRouteConfig>();
        for (WS_EmailToCaseRouteConfig route : activeRoutes) {
            if (matchesRoute(route, envelopeTo, toAddresses, ccAddresses, anyRecipients)) {
                matches.add(route);
            }
        }

        if (matches.size() == 1) {
            return matches[0];
        }
        if (matches.size() > 1) {
            throw new WS_EmailToCaseConfigException('ConfiguraÃ§Ã£o ambÃ­gua: mÃºltiplas rotas ativas correspondem ao mesmo e-mail.');
        }

        List<WS_EmailToCaseRouteConfig> defaults = new List<WS_EmailToCaseRouteConfig>();
        for (WS_EmailToCaseRouteConfig route : activeRoutes) {
            if (route.isDefaultRoute == true) {
                defaults.add(route);
            }
        }

        if (defaults.size() > 1) {
            throw new WS_EmailToCaseConfigException('ConfiguraÃ§Ã£o invÃ¡lida: existe mais de uma rota padrÃ£o ativa.');
        }
        return defaults.isEmpty() ? null : defaults[0];
    }

    private Boolean matchesRoute(
        WS_EmailToCaseRouteConfig route,
        String envelopeTo,
        Set<String> toAddresses,
        Set<String> ccAddresses,
        Set<String> anyRecipients
    ) {
        Set<String> candidates = new Set<String>();
        String routeKey = WS_EmailToCaseUtils.normalize(route.routeKey);
        String businessEmail = WS_EmailToCaseUtils.normalize(route.businessEmail);
        String serviceAddress = WS_EmailToCaseUtils.normalize(route.salesforceServiceAddress);

        if (!String.isBlank(routeKey)) candidates.add(routeKey);
        if (!String.isBlank(businessEmail)) candidates.add(businessEmail);
        if (!String.isBlank(serviceAddress)) candidates.add(serviceAddress);

        String mode = String.isBlank(route.matchMode) ? WS_EmailToCaseConstants.MATCH_ANY_RECIPIENT : route.matchMode;
        if (mode == WS_EmailToCaseConstants.MATCH_ENVELOPE_TO) {
            return !String.isBlank(envelopeTo) && candidates.contains(envelopeTo);
        }
        if (mode == WS_EmailToCaseConstants.MATCH_TO_ADDRESSES) {
            return intersects(candidates, toAddresses);
        }
        if (mode == WS_EmailToCaseConstants.MATCH_CC_ADDRESSES) {
            return intersects(candidates, ccAddresses);
        }
        return intersects(candidates, anyRecipients);
    }

    private Boolean intersects(Set<String> left, Set<String> right) {
        if (left == null || right == null || left.isEmpty() || right.isEmpty()) {
            return false;
        }
        for (String value : left) {
            if (right.contains(value)) {
                return true;
            }
        }
        return false;
    }
}