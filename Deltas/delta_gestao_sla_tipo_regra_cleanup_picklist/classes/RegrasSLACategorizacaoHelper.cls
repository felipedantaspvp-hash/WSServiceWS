public inherited sharing class RegrasSLACategorizacaoHelper {
    public static String normalize(String v){ return String.isBlank(v) ? 'null' : v.trim().toLowerCase(); }

    public static String buildKey(RegrasSLACategorizacao__c r){
        String areaAplicavel = isEscopoAreaInterna(r) ? r.AreaAtendimento__c : null;
        return RegrasSLACompatibilidadeService.buildKeyNovo(
            r.GestaoSLA__c,
            r.MarcoSLA__c,
            r.EscopoRegra__c,
            r.Categorizacao__c,
            areaAplicavel,
            r.Origem__c
        );
    }

    public static Boolean isEscopoAtendimento(RegrasSLACategorizacao__c r) {
        return r != null && r.EscopoRegra__c == RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO;
    }

    public static Boolean isEscopoAreaInterna(RegrasSLACategorizacao__c r) {
        return r != null && r.EscopoRegra__c == RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA;
    }

    public static Boolean hasAnyTempoNovoPositivo(RegrasSLACategorizacao__c r) {
        if (r == null) return false;
        return isTempoPositivo(r.TempoBaixa__c)
            || isTempoPositivo(r.TempoMedia__c)
            || isTempoPositivo(r.TempoAlta__c);
    }

    public static Boolean isVigenciaValida(RegrasSLACategorizacao__c r) {
        if (r == null) return true;
        if (r.VigenciaInicio__c == null || r.VigenciaFim__c == null) return true;
        return r.VigenciaFim__c >= r.VigenciaInicio__c;
    }

    private static Boolean isTempoPositivo(Decimal tempo) {
        return tempo != null && tempo > 0;
    }

    public static String hash(String source){
        Blob b = Blob.valueOf(source == null ? '' : source);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', b));
    }
}