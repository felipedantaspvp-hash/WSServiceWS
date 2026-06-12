public inherited sharing class GestaoSLAHelper {
    public static final String CP_ACESSAR_GESTAO_SLA = 'AcessarGestaoSLA';
    public static final String CP_GERENCIAR_CATEGORIAS = 'GerenciarCategoriasGestaoSLA';
    public static final String CP_GERENCIAR_REGRAS = 'GerenciarRegrasSLA';
    public static final String CP_ADMIN_CONFIG_TECNICA = 'AdministrarConfiguracoesGestaoSLA';

    @TestVisible private static Map<String, Boolean> permissionOverrideByName = new Map<String, Boolean>();

    public static Boolean canAccessGestaoSLA() {
        return hasPermission(CP_ACESSAR_GESTAO_SLA);
    }

    public static Boolean canManageCategories() {
        return hasPermission(CP_GERENCIAR_CATEGORIAS);
    }

    public static Boolean canManageRules() {
        return hasPermission(CP_GERENCIAR_REGRAS);
    }

    public static Boolean canAdminTechnicalSettings() {
        return hasPermission(CP_ADMIN_CONFIG_TECNICA);
    }

    public static String normalizeText(String value) {
        return String.isBlank(value) ? '' : value.trim().toLowerCase();
    }

    public static String toLikePattern(String value) {
        if (String.isBlank(value)) return null;
        return '%' + value.trim() + '%';
    }

    @TestVisible
    public static void setPermissionOverride(String permissionName, Boolean value) {
        permissionOverrideByName.put(permissionName, value == true);
    }

    @TestVisible
    public static void clearPermissionOverrides() {
        permissionOverrideByName.clear();
    }

    private static Boolean hasPermission(String permissionName) {
        if (permissionOverrideByName.containsKey(permissionName)) {
            return permissionOverrideByName.get(permissionName);
        }
        return FeatureManagement.checkPermission(permissionName);
    }
}