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
    public static final String ORIGEM_SLA_CUSTOM    = 'Custom';
    public static final String ORIGEM_SLA_STANDARD  = 'Standard';
    public static final String ORIGEM_REGRA_QUALQUER = 'Qualquer';
    public static final String MARCO_ATENDIMENTO_N3 = 'Atendimento N3';

    public static String n(String v){ return v == null ? '' : v.trim().toLowerCase(); }
    public static Boolean isTipoInterna(String v){ return n(v).contains('interna'); }
    public static Boolean isOpenStatus(String v){ String x=n(v); return x.contains('aberta') || x.contains('andamento') || x.contains('pausada') || x.contains('vencida'); }
    public static Boolean isConcluida(String v){ return n(v).contains('conclu'); }
    public static Boolean isCancelada(String v){ return n(v).contains('cancel'); }
    public static String statusPausada(){ return STATUS_ATUACAO_PAUSADA; }
    public static String statusSlaPausado(){ return STATUS_SLA_PAUSADO; }
    public static String statusSlaConcluido(){ return STATUS_SLA_CONCLUIDO; }
    public static String statusSlaCancelado(){ return STATUS_SLA_CANCELADO; }
    public static String statusSlaVencido(){ return STATUS_SLA_VENCIDO; }
    public static String statusSlaDentroPrazo(){ return STATUS_SLA_DENTRO_PRAZO; }
    public static String etapaAguardandoCliente(){ return ETAPA_AGUARDANDO_CLIENTE; }
    public static String tipoAreaInternaApiValue(){ return TIPO_AREA_INTERNA; }
    public static String origemQualquerApiValue(){ return ORIGEM_REGRA_QUALQUER; }
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
        String s = input.toLowerCase();
        s = s.replace('á','a').replace('à','a').replace('â','a').replace('ã','a').replace('ä','a');
        s = s.replace('é','e').replace('è','e').replace('ê','e').replace('ë','e');
        s = s.replace('í','i').replace('ì','i').replace('î','i').replace('ï','i');
        s = s.replace('ó','o').replace('ò','o').replace('ô','o').replace('õ','o').replace('ö','o');
        s = s.replace('ú','u').replace('ù','u').replace('û','u').replace('ü','u');
        s = s.replace('ç','c');
        return s;
    }
}