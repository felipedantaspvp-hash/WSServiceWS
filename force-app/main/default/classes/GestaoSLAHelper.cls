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

    // ------------------------------------------------------------------
    // Helpers cross-domínio (movidos de GestaoSLAService.cls — usados pelos
    // serviços de Gestão, Categoria, Marco e Regra de SLA).
    // ------------------------------------------------------------------

    public static GestaoSLADTO.PermissionInfo buildPermissionInfo() {
        GestaoSLADTO.PermissionInfo perms = new GestaoSLADTO.PermissionInfo();
        perms.canAccessGestaoSLA = canAccessGestaoSLA();
        perms.canManageCategories = canManageCategories();
        perms.canManageRules = canManageRules();
        perms.canAdminTechnicalSettings = canAdminTechnicalSettings();
        return perms;
    }

    public static void ensureCanAccess(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canAccessGestaoSLA != true) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão para acessar a Gestão de SLA.');
        }
    }

    public static void ensureCanManageCategories(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canManageCategories != true) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão para gerenciar categorias.');
        }
    }

    public static void ensureCanManageRules(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canManageRules != true) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão para gerenciar regras de SLA.');
        }
    }

    public static void ensureCanDelete(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canAdminTechnicalSettings != true) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão para excluir registros de Gestão de SLA.');
        }
    }

    public static void ensureCanAdminTechnicalSettings(GestaoSLADTO.PermissionInfo perms) {
        if (perms == null || perms.canAdminTechnicalSettings != true) {
            throw new GestaoSLAService.FunctionalException('Você não possui permissão para administrar Marcos SLA.');
        }
    }

    /**
     * @description Resolve as Unidades de Negócio que o usuário corrente pode acessar na Gestão de SLA.
     * Admin Técnico (canAdminTechnicalSettings) tem acesso irrestrito (retorna null).
     * Demais usuários são restritos às unidades derivadas do Record Type de Case disponível para eles.
     * @param perms Permissões já resolvidas do usuário corrente.
     * @return Set de Unidades de Negócio permitidas, ou null se irrestrito.
     */
    public static Set<String> resolveAllowedUnidades(GestaoSLADTO.PermissionInfo perms) {
        if (perms != null && perms.canAdminTechnicalSettings == true) {
            return null;
        }
        return getAllowedUnidadesNegocio();
    }

    /**
     * @description Garante que a Unidade de Negócio de um registro está dentro do conjunto permitido
     * para o usuário corrente. Não faz nada quando allowedUnidades é null (acesso irrestrito).
     * @param unidadeNegocio Unidade de Negócio do registro sendo acessado/alterado.
     * @param allowedUnidades Unidades permitidas para o usuário, ou null se irrestrito.
     */
    public static void ensureUnidadeAllowed(String unidadeNegocio, Set<String> allowedUnidades) {
        if (allowedUnidades == null) {
            return;
        }
        if (String.isBlank(unidadeNegocio) || !allowedUnidades.contains(unidadeNegocio)) {
            throw new GestaoSLAService.FunctionalException('Você não possui Record Type disponível para a Unidade de Negócio "' + unidadeNegocio + '".');
        }
    }

    public static GestaoSLA__c loadGestaoOrThrow(Id gestaoSLAId) {
        if (gestaoSLAId == null) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não informada.');
        }
        List<GestaoSLA__c> rows = GestaoSLASelector.selectUnidadeById(gestaoSLAId);
        if (rows.isEmpty()) {
            throw new GestaoSLAService.FunctionalException('Gestão de SLA não encontrada.');
        }
        return rows[0];
    }

    public static String normalizeOptionalText(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    public static String normalizeOptionalFilter(String value) {
        if (String.isBlank(value) || value == 'Todos' || value == 'Todas') {
            return null;
        }
        return normalizeText(value);
    }

    public static void validatePicklistValue(String label, Schema.SObjectField fieldRef, String value) {
        if (String.isBlank(value)) {
            return;
        }
        Schema.DescribeFieldResult describeResult = fieldRef.getDescribe();
        if (!describeResult.isRestrictedPicklist()) {
            return;
        }
        Set<String> allowedValues = new Set<String>();
        for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
            if (entry != null && entry.isActive()) {
                allowedValues.add(entry.getValue());
            }
        }
        if (!allowedValues.isEmpty() && !allowedValues.contains(value)) {
            throw new GestaoSLAService.FunctionalException(label + ' inválida.');
        }
    }

    public static List<String> getActivePicklistValues(Schema.SObjectField fieldRef) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
            if (entry != null && entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    public static List<GestaoSLADTO.PicklistOptionDTO> getActivePicklistOptions(Schema.SObjectField fieldRef) {
        List<GestaoSLADTO.PicklistOptionDTO> options = new List<GestaoSLADTO.PicklistOptionDTO>();
        for (Schema.PicklistEntry entry : fieldRef.getDescribe().getPicklistValues()) {
            if (entry == null || !entry.isActive()) continue;
            GestaoSLADTO.PicklistOptionDTO opt = new GestaoSLADTO.PicklistOptionDTO();
            opt.label = entry.getLabel();
            opt.value = entry.getValue();
            options.add(opt);
        }
        return options;
    }

    public static Integer toInteger(Decimal value) {
        return value == null ? null : value.intValue();
    }
}