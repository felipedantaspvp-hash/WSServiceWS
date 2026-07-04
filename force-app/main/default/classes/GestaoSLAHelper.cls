public inherited sharing class GestaoSLAHelper {
    public static final String CP_ACESSAR_GESTAO_SLA = 'AcessarGestaoSLA';
    public static final String CP_GERENCIAR_CATEGORIAS = 'GerenciarCategoriasGestaoSLA';
    public static final String CP_GERENCIAR_REGRAS = 'GerenciarRegrasSLA';
    public static final String CP_ADMIN_CONFIG_TECNICA = 'AdministrarConfiguracoesGestaoSLA';

    public static final String TIPO_REGRA_ATENDIMENTO = 'Atendimento';
    public static final String TIPO_REGRA_AREA_INTERNA = 'Area Interna';

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

    /**
     * @description Unidades de Negócio que o usuário corrente pode ver/gerenciar na Gestão de SLA.
     * Delega para `AtendimentoConfigService`, que centraliza essa resolução para todo o domínio de
     * Atendimento (ex.: também consumida por `ContactWhatsappMessageService`).
     * @return Conjunto de valores de Unidade de Negócio permitidos para o usuário corrente.
     */
    public static Set<String> getAllowedUnidadesNegocio() {
        return AtendimentoConfigService.getAllowedUnidadesNegocio();
    }

    /**
     * @description Permite injetar em testes o conjunto de Unidades de Negócio permitidas,
     * sem depender de Record Type/Profile reais. Passe null para simular acesso irrestrito (ex.: Admin).
     * @param unidades Unidades permitidas, ou null para irrestrito.
     */
    @TestVisible
    public static void setAllowedUnidadesOverride(Set<String> unidades) {
        AtendimentoConfigService.setAllowedUnidadesOverride(unidades);
    }

    @TestVisible
    public static void clearAllowedUnidadesOverride() {
        AtendimentoConfigService.clearAllowedUnidadesOverride();
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

    /**
     * @description Monta o label de exibição de uma Categorização (Categoria / Assunto / Subassunto),
     * reutilizável entre os serviços de Categoria e Regra de SLA sem acoplamento cross-service.
     * @param row Categorizacao__c (ou relacionamento Categorizacao__r de uma regra).
     * @return Label combinado, ou o Name do registro se nenhuma parte estiver preenchida.
     */
    public static String buildCategorizacaoLabel(Categorizacao__c row) {
        if (row == null) {
            return null;
        }
        List<String> parts = new List<String>();
        if (!String.isBlank(row.Categoria__c)) parts.add(row.Categoria__c);
        if (!String.isBlank(row.Assunto__c)) parts.add(row.Assunto__c);
        if (!String.isBlank(row.Subassunto__c)) parts.add(row.Subassunto__c);
        return parts.isEmpty() ? row.Name : String.join(parts, ' / ');
    }

    public static SObject sanitizeForCreate(SObject record, String errorMessage) {
        List<SObject> sanitized = sanitizeForAccess(System.AccessType.CREATABLE, new List<SObject>{ record }, errorMessage);
        return sanitized.isEmpty() ? null : sanitized[0];
    }

    public static SObject sanitizeForUpdate(SObject record, String errorMessage) {
        List<SObject> sanitized = sanitizeForAccess(System.AccessType.UPDATABLE, new List<SObject>{ record }, errorMessage);
        return sanitized.isEmpty() ? null : sanitized[0];
    }

    public static List<SObject> sanitizeForCreate(List<SObject> records, String errorMessage) {
        return sanitizeForAccess(System.AccessType.CREATABLE, records, errorMessage);
    }

    public static List<SObject> sanitizeForUpdate(List<SObject> records, String errorMessage) {
        return sanitizeForAccess(System.AccessType.UPDATABLE, records, errorMessage);
    }

    private static List<SObject> sanitizeForAccess(System.AccessType accessType, List<SObject> records, String errorMessage) {
        if (records == null || records.isEmpty()) {
            return new List<SObject>();
        }
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(accessType, records);
            return decision.getRecords();
        } catch (Exception ex) {
            throw new GestaoSLAService.FunctionalException(errorMessage);
        }
    }
}