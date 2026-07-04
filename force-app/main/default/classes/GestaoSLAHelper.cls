public inherited sharing class GestaoSLAHelper {
    public static final String CP_ACESSAR_GESTAO_SLA = 'AcessarGestaoSLA';
    public static final String CP_GERENCIAR_CATEGORIAS = 'GerenciarCategoriasGestaoSLA';
    public static final String CP_GERENCIAR_REGRAS = 'GerenciarRegrasSLA';
    public static final String CP_ADMIN_CONFIG_TECNICA = 'AdministrarConfiguracoesGestaoSLA';

    public static final String TIPO_REGRA_ATENDIMENTO = 'Atendimento';
    public static final String TIPO_REGRA_AREA_INTERNA = 'Area Interna';

    @TestVisible private static Map<String, Boolean> permissionOverrideByName = new Map<String, Boolean>();
    @TestVisible private static Set<String> allowedUnidadesOverride;
    @TestVisible private static Boolean allowedUnidadesOverrideSet = false;

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

    /**
     * @description Unidades de Negócio que o usuário corrente pode ver/gerenciar na Gestão de SLA,
     * derivadas dos Record Types de Case disponíveis para o usuário (Schema.RecordTypeInfo.isAvailable())
     * mapeados via ParametrosAtendimento__mdt.CaseRecordTypeDeveloperName__c -> UnidadeNegocio__c.
     * Um Set vazio significa "nenhuma unidade disponível" (usuário sem Record Type de Case atribuído).
     * @return Conjunto de valores de Unidade de Negócio permitidos para o usuário corrente.
     */
    public static Set<String> getAllowedUnidadesNegocio() {
        if (allowedUnidadesOverrideSet) {
            return allowedUnidadesOverride;
        }

        Map<String, String> unidadeByRtDevName = new Map<String, String>();
        for (AtendimentoConfigDTO cfg : AtendimentoConfigService.getActiveConfigs()) {
            if (!String.isBlank(cfg.caseRecordTypeDeveloperName) && !String.isBlank(cfg.businessUnit)) {
                unidadeByRtDevName.put(cfg.caseRecordTypeDeveloperName, cfg.businessUnit);
            }
        }

        Set<String> out = new Set<String>();
        Map<String, Schema.RecordTypeInfo> rtInfos = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getRecordTypeInfosByDeveloperName();
        for (String devName : unidadeByRtDevName.keySet()) {
            Schema.RecordTypeInfo info = rtInfos.get(devName);
            if (info != null && info.isAvailable()) {
                out.add(unidadeByRtDevName.get(devName));
            }
        }
        return out;
    }

    /**
     * @description Permite injetar em testes o conjunto de Unidades de Negócio permitidas,
     * sem depender de Record Type/Profile reais. Passe null para simular acesso irrestrito (ex.: Admin).
     * @param unidades Unidades permitidas, ou null para irrestrito.
     */
    @TestVisible
    public static void setAllowedUnidadesOverride(Set<String> unidades) {
        allowedUnidadesOverride = unidades;
        allowedUnidadesOverrideSet = true;
    }

    @TestVisible
    public static void clearAllowedUnidadesOverride() {
        allowedUnidadesOverride = null;
        allowedUnidadesOverrideSet = false;
    }
}