/**
 * @description       : Testes unitários de GestaoSLAHelper.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
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
    static void testNormalizeTextAndLikePattern() {
        Assert.areEqual('', GestaoSLAHelper.normalizeText(null));
        Assert.areEqual('', GestaoSLAHelper.normalizeText('   '));
        Assert.areEqual('abc', GestaoSLAHelper.normalizeText('  AbC '));
        Assert.areEqual(null, GestaoSLAHelper.toLikePattern(null));
        Assert.areEqual('%abc%', GestaoSLAHelper.toLikePattern(' abc '));
    }
}