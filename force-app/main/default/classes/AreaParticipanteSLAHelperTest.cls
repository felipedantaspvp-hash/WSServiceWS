/**
 * @description       : Testes unitários de AreaParticipanteSLAHelper.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteSLAHelperTest {
    @IsTest
    static void testConstantsAndNormalization() {
        Assert.areEqual(AreaParticipanteSLAHelper.tipoAreaInternaApiValue(), AreaParticipanteSLAHelper.TIPO_AREA_INTERNA);
        Assert.areEqual(true, AreaParticipanteSLAHelper.isTipoInterna(AreaParticipanteSLAHelper.tipoAreaInternaApiValue()));
        Assert.areEqual(true, AreaParticipanteSLAHelper.isOpenStatus('Em Andamento'));
        Assert.areEqual(false, AreaParticipanteSLAHelper.isOpenStatus(AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA));
        Assert.areEqual(60000L, AreaParticipanteSLAHelper.toMs(1));
        Assert.areEqual(0L, AreaParticipanteSLAHelper.toMs(null));
        Assert.areEqual('', AreaParticipanteSLAHelper.n(null));
        Assert.areEqual('abc', AreaParticipanteSLAHelper.n('  AbC  '));
        Assert.areEqual('Pausada', AreaParticipanteSLAHelper.statusPausada());
        Assert.areEqual('Pausado', AreaParticipanteSLAHelper.statusSlaPausado());
        Assert.areEqual(AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO, AreaParticipanteSLAHelper.statusSlaConcluido());
        Assert.areEqual('Cancelado', AreaParticipanteSLAHelper.statusSlaCancelado());
        Assert.areEqual('Vencido', AreaParticipanteSLAHelper.statusSlaVencido());
        Assert.areEqual('Dentro do Prazo', AreaParticipanteSLAHelper.statusSlaDentroPrazo());
        Assert.areEqual('Aguardando Cliente', AreaParticipanteSLAHelper.etapaAguardandoCliente());
        Assert.areEqual(true, !String.isBlank(AreaParticipanteSLAHelper.tipoAreaInternaApiValue()));
        Assert.areEqual(true, !String.isBlank(AreaParticipanteSLAHelper.origemQualquerApiValue()));
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