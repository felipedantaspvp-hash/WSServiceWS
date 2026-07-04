@IsTest
private class TextNormalizationUtilTest {
    @IsTest
    static void shouldReturnNullWhenInputIsNull() {
        Test.startTest();
        String result = TextNormalizationUtil.stripAccents(null);
        Test.stopTest();

        Assert.areEqual(null, result, 'stripAccents deve retornar null para entrada null.');
    }

    @IsTest
    static void shouldReturnUnchangedWhenNoAccents() {
        Test.startTest();
        String result = TextNormalizationUtil.stripAccents('Sem Acentos 123');
        Test.stopTest();

        Assert.areEqual('Sem Acentos 123', result, 'String sem acentos deve permanecer inalterada.');
    }

    @IsTest
    static void shouldStripLowercaseAccents() {
        Test.startTest();
        String result = TextNormalizationUtil.stripAccents('áàâãäéèêëíìîïóòôõöúùûüçñ');
        Test.stopTest();

        Assert.areEqual('aaaaaeeeeiiiiooooouuuucn', result, 'Todos os acentos minúsculos mapeados devem ser removidos.');
    }

    @IsTest
    static void shouldStripUppercaseAccents() {
        Test.startTest();
        String result = TextNormalizationUtil.stripAccents('ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ');
        Test.stopTest();

        Assert.areEqual('AAAAAEEEEIIIIOOOOOUUUUCN', result, 'Todos os acentos maiúsculos mapeados devem ser removidos.');
    }

    @IsTest
    static void shouldStripAccentsInMixedRealWorldString() {
        Test.startTest();
        String result = TextNormalizationUtil.stripAccents('Atendimento Tecon Rio Grande - Não é possível: código João');
        Test.stopTest();

        Assert.areEqual('Atendimento Tecon Rio Grande - Nao e possivel: codigo Joao', result, 'Frase real com acentuação mista deve ser normalizada corretamente.');
    }
}
