/**
 * @description       : Funções auxiliares de cálculo e validação de SLA para o módulo AreaParticipante.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-14-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteSLAHelper {
    public static final String TIPO_AREA_INTERNA = 'Área Interna';
    public static final String STATUS_ATUACAO_ABERTA = 'Aberta';
    public static final String STATUS_ATUACAO_ANDAMENTO = 'Em Andamento';
    public static final String STATUS_ATUACAO_PAUSADA = 'Pausada';
    public static final String STATUS_ATUACAO_VENCIDA = 'Vencida';
    public static final String STATUS_ATUACAO_CONCLUIDA = 'Concluída';
    public static final String STATUS_ATUACAO_CANCELADA = 'Cancelada';
    public static final String STATUS_SLA_DENTRO_PRAZO = 'Dentro do Prazo';
    public static final String STATUS_SLA_PAUSADO = 'Pausado';
    public static final String STATUS_SLA_VENCIDO = 'Vencido';
    public static final String STATUS_SLA_CONCLUIDO = 'Concluído';
    public static final String STATUS_SLA_CANCELADO = 'Cancelado';
    public static final String ETAPA_AGUARDANDO_CLIENTE = 'Aguardando Cliente';
    public static final String ETAPA_EM_ACOMPANHAMENTO = 'Em Acompanhamento';
    public static final Set<String> ETAPAS_PAUSA_SLA = new Set<String>{ ETAPA_AGUARDANDO_CLIENTE, ETAPA_EM_ACOMPANHAMENTO };
    public static final String ORIGEM_SLA_CUSTOM    = 'Custom';
    public static final String ORIGEM_SLA_STANDARD  = 'Standard';
    public static final String ORIGEM_REGRA_QUALQUER = 'Qualquer';
    public static final String MARCO_ATENDIMENTO_N3 = 'Atendimento N3';

    public static String n(String v){ return v == null ? '' : v.trim().toLowerCase(); }
    public static Boolean isTipoInterna(String v){ return n(v).contains('interna'); }
    public static Boolean isOpenStatus(String v){ String x=n(v); return x.contains('aberta') || x.contains('andamento') || x.contains('pausada') || x.contains('vencida'); }
    public static Boolean isConcluida(String v){ return n(v).contains('conclu'); }
    public static Boolean isCancelada(String v){ return n(v).contains('cancel'); }
    public static Long toMs(Integer minutes){ return (minutes == null ? 0L : Long.valueOf(String.valueOf(minutes))) * 60L * 1000L; }

    public static String marcoAtendimentoN3ApiValue(){
        return MARCO_ATENDIMENTO_N3;
    }

    public static Boolean isAtendimentoN3MarcoName(String value){
        String n = normalizeText(value);
        return n.contains('atendimento n3');
    }

    private static String normalizeText(String input){
        if (input == null) return '';
        return TextNormalizationUtil.stripAccents(input.toLowerCase());
    }
}