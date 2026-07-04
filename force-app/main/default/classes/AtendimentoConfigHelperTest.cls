@IsTest
private class AtendimentoConfigHelperTest {
    @IsTest
    static void shouldNormalizeBusinessUnitKey() {
        Test.startTest();
        String key = AtendimentoConfigHelper.normalizeBusinessUnitKey('Atendimento Tecon Salvador');
        String blank = AtendimentoConfigHelper.normalizeBusinessUnitKey(null);
        Test.stopTest();

        Assert.areEqual('teconsalvador', key);
        Assert.areEqual('', blank);
    }

    @IsTest
    static void shouldNormalizeSurveyMode() {
        Test.startTest();
        String always = AtendimentoConfigHelper.normalizeSurveyMode('always');
        String invalid = AtendimentoConfigHelper.normalizeSurveyMode('unknown');
        String blank = AtendimentoConfigHelper.normalizeSurveyMode(null);
        Test.stopTest();

        Assert.areEqual(AtendimentoConfigHelper.SURVEY_MODE_ALWAYS, always);
        Assert.areEqual(AtendimentoConfigHelper.SURVEY_MODE_NEVER, invalid);
        Assert.areEqual(AtendimentoConfigHelper.SURVEY_MODE_NEVER, blank);
    }

    @IsTest
    static void shouldReturnHardcodedUnidadeFallback() {
        Test.startTest();
        List<AtendimentoConfigHelper.UnidadeFallbackEntry> fallback = AtendimentoConfigHelper.getHardcodedUnidadeFallback();
        Test.stopTest();

        Assert.areEqual(6, fallback.size(), 'Fallback deve ter as 6 entradas conhecidas (Salvador/TeconSalvador/RioGrande/TeconRioGrande/CentroLogistico/Rebocadores).');
        Set<String> recordTypes = new Set<String>();
        for (AtendimentoConfigHelper.UnidadeFallbackEntry entry : fallback) {
            recordTypes.add(entry.recordTypeDeveloperName);
            Assert.isFalse(String.isBlank(entry.unidadeNegocio), 'Toda entrada de fallback deve ter Unidade de Negócio preenchida.');
            Assert.isFalse(String.isBlank(entry.queuePrefix), 'Toda entrada de fallback deve ter prefixo de fila preenchido.');
        }
        Assert.isTrue(recordTypes.contains('TeconSalvador'));
        Assert.isTrue(recordTypes.contains('TeconRioGrande'));
        Assert.isTrue(recordTypes.contains('CentroLogistico'));
        Assert.isTrue(recordTypes.contains('Rebocadores'));
    }
}
