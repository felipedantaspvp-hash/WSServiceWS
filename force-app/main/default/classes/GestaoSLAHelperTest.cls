@IsTest
private class GestaoSLAHelperTest {
    @IsTest
    static void testPermissionOverrides() {
        GestaoSLAHelper.clearPermissionOverrides();
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ACESSAR_GESTAO_SLA, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_CATEGORIAS, true);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_GERENCIAR_REGRAS, false);
        GestaoSLAHelper.setPermissionOverride(GestaoSLAHelper.CP_ADMIN_CONFIG_TECNICA, false);

        Assert.areEqual(true, GestaoSLAHelper.canAccessGestaoSLA());
        Assert.areEqual(true, GestaoSLAHelper.canManageCategories());
        Assert.areEqual(false, GestaoSLAHelper.canManageRules());
        Assert.areEqual(false, GestaoSLAHelper.canAdminTechnicalSettings());
    }

    @IsTest
    static void testAllowedUnidadesOverrideSeam() {
        GestaoSLAHelper.clearAllowedUnidadesOverride();
        GestaoSLAHelper.setAllowedUnidadesOverride(new Set<String>{ 'Atendimento Tecon Salvador' });
        Assert.areEqual(1, GestaoSLAHelper.getAllowedUnidadesNegocio().size());
        Assert.areEqual(true, GestaoSLAHelper.getAllowedUnidadesNegocio().contains('Atendimento Tecon Salvador'));

        GestaoSLAHelper.setAllowedUnidadesOverride(null);
        Assert.areEqual(null, GestaoSLAHelper.getAllowedUnidadesNegocio());

        GestaoSLAHelper.clearAllowedUnidadesOverride();
    }

    @IsTest
    static void testGetAllowedUnidadesNegocioSemOverrideUsaRecordTypeReal() {
        GestaoSLAHelper.clearAllowedUnidadesOverride();
        Set<String> result = GestaoSLAHelper.getAllowedUnidadesNegocio();
        Assert.areNotEqual(null, result, 'Sem override, o método deve computar a partir do Record Type real do usuário (pode ser vazio, mas não null).');
    }

    @IsTest
    static void testNormalizeTextAndLikePattern() {
        Assert.areEqual('', GestaoSLAHelper.normalizeText(null));
        Assert.areEqual('', GestaoSLAHelper.normalizeText('   '));
        Assert.areEqual('abc', GestaoSLAHelper.normalizeText('  AbC '));
        Assert.areEqual(null, GestaoSLAHelper.toLikePattern(null));
        Assert.areEqual('%abc%', GestaoSLAHelper.toLikePattern(' abc '));
    }
}