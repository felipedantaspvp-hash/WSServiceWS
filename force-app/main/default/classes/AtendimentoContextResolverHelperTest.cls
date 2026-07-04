@IsTest
private class AtendimentoContextResolverHelperTest {
    @IsTest
    static void shouldReturnNullWhenNoRowsProvided() {
        Test.startTest();
        String result = AtendimentoContextResolverHelper.resolveBusinessUnitFromConfigs('CHAT', 'algum-canal', null);
        Test.stopTest();

        Assert.areEqual(null, result, 'Sem configs, deve retornar null.');
    }

    @IsTest
    static void shouldMatchByChannelIdentifier() {
        AtendimentoConfigDTO config = buildConfig('Tecon Salvador', 'WS_TSV_WebChat', 'CHAT');

        Test.startTest();
        String result = AtendimentoContextResolverHelper.resolveBusinessUnitFromConfigs('CHAT', 'WS_TSV_WebChat', new List<AtendimentoConfigDTO>{ config });
        Test.stopTest();

        Assert.areEqual('Tecon Salvador', result, 'Deve casar pelo identificador exato do canal.');
    }

    @IsTest
    static void shouldMatchByChannelTypeWhenIdentifierIsUnknown() {
        AtendimentoConfigDTO config = buildConfig('Centro Logístico', 'WS_CL_WebChat', 'CHAT');

        Test.startTest();
        String result = AtendimentoContextResolverHelper.resolveBusinessUnitFromConfigs('CHAT', 'canal-desconhecido', new List<AtendimentoConfigDTO>{ config });
        Test.stopTest();

        Assert.areEqual('Centro Logístico', result, 'Sem identificador exato, deve casar pelo tipo de canal (messagingChannelType).');
    }

    @IsTest
    static void shouldReturnNullWhenNothingMatchesInsteadOfFallingBackToFirstActiveConfig() {
        List<AtendimentoConfigDTO> configs = new List<AtendimentoConfigDTO>{
            buildConfig('Centro Logístico', 'WS_CL_WebChat', 'CHAT'),
            buildConfig('Tecon Salvador', 'WS_TSV_WebChat', 'CHAT')
        };

        Test.startTest();
        String result = AtendimentoContextResolverHelper.resolveBusinessUnitFromConfigs('MESSAGING', 'canal-totalmente-desconhecido', configs);
        Test.stopTest();

        Assert.areEqual(null, result, 'Canal sem match algum não deve cair na primeira config ativa da lista de forma arbitrária.');
    }

    @IsTest
    static void shouldReturnNullForUnmappedWhatsAppChannel() {
        AtendimentoConfigDTO config = buildConfig('Tecon Salvador', 'WS_TSV_WebChat', 'CHAT');

        Test.startTest();
        String result = AtendimentoContextResolverHelper.resolveBusinessUnitFromConfigs('WHATSAPP', 'whatsapp-nao-mapeado', new List<AtendimentoConfigDTO>{ config });
        Test.stopTest();

        Assert.areEqual(null, result, 'WhatsApp não mapeado não deve cair em nenhuma config ativa.');
    }

    private static AtendimentoConfigDTO buildConfig(String businessUnit, String channelDeveloperName, String channelType) {
        AtendimentoConfigDTO config = new AtendimentoConfigDTO();
        config.businessUnit = businessUnit;
        config.masterLabel = businessUnit;
        config.developerName = channelDeveloperName;
        config.messagingChannelDeveloperName = channelDeveloperName;
        config.messagingChannelType = channelType;
        config.isActive = true;
        return config;
    }
}
