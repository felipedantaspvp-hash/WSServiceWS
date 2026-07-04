@IsTest
private class AreaParticipanteSLAHelperTest {
    @IsTest
    static void testConstantsAndNormalization() {
        Assert.areEqual(AreaParticipanteSLAHelper.TIPO_AREA_INTERNA, AreaParticipanteSLAHelper.TIPO_AREA_INTERNA);
        Assert.areEqual(true, AreaParticipanteSLAHelper.isTipoInterna(AreaParticipanteSLAHelper.TIPO_AREA_INTERNA));
        Assert.areEqual(true, AreaParticipanteSLAHelper.isOpenStatus('Em Andamento'));
        Assert.areEqual(false, AreaParticipanteSLAHelper.isOpenStatus(AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA));
        Assert.areEqual(60000L, AreaParticipanteSLAHelper.toMs(1));
        Assert.areEqual(0L, AreaParticipanteSLAHelper.toMs(null));
        Assert.areEqual('', AreaParticipanteSLAHelper.n(null));
        Assert.areEqual('abc', AreaParticipanteSLAHelper.n('  AbC  '));
        Assert.areEqual('Pausada', AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA);
        Assert.areEqual('Pausado', AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO);
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO, AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO);
        Assert.areEqual('Cancelado', AreaParticipanteSLAHelper.STATUS_SLA_CANCELADO);
        Assert.areEqual('Vencido', AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO);
        Assert.areEqual('Dentro do Prazo', AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO);
        Assert.areEqual('Aguardando Cliente', AreaParticipanteSLAHelper.ETAPA_AGUARDANDO_CLIENTE);
        Assert.areEqual(true, !String.isBlank(AreaParticipanteSLAHelper.TIPO_AREA_INTERNA));
        Assert.areEqual(true, !String.isBlank(AreaParticipanteSLAHelper.ORIGEM_REGRA_QUALQUER));
        Assert.areEqual(true, !String.isBlank(AreaParticipanteSLAHelper.marcoAtendimentoN3ApiValue()));
        Assert.areEqual(true, AreaParticipanteSLAHelper.isAtendimentoN3MarcoName('Atendimento N3'));
        Assert.areEqual(false, AreaParticipanteSLAHelper.isAtendimentoN3MarcoName('Atendimento'));
        Assert.areEqual(true, AreaParticipanteSLAHelper.isConcluida(AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA));
        Assert.areEqual(false, AreaParticipanteSLAHelper.isConcluida('Aberta'));
        Assert.areEqual(true, AreaParticipanteSLAHelper.isCancelada(AreaParticipanteSLAHelper.STATUS_ATUACAO_CANCELADA));
        Assert.areEqual(false, AreaParticipanteSLAHelper.isCancelada('Aberta'));
    }

    @IsTest
    static void testMarcoAtendimentoN3ReturnsNonBlank() {
        String value = AreaParticipanteSLAHelper.marcoAtendimentoN3ApiValue();
        Assert.areEqual(true, String.isNotBlank(value));
        Assert.areEqual(AreaParticipanteSLAHelper.MARCO_ATENDIMENTO_N3, value);
    }
}