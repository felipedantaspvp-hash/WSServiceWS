public inherited sharing class RegrasSLACompatibilidadeService {
    public class CompatibilidadeException extends Exception {}

    public static final String ESCOPO_GLOBAL = 'Global';
    public static final String ESCOPO_POR_CATEGORIZACAO = 'Por Categorizacao';
    public static final String ESCOPO_POR_AREA_INTERNA = 'Por Area Interna';

    private static final String PRIORIDADE_BAIXA = 'BAIXA';
    private static final String PRIORIDADE_MEDIA = 'MEDIA';
    private static final String PRIORIDADE_ALTA = 'ALTA';

    public static Integer resolveTempoCompativel(RegrasSLACategorizacao__c regra, String prioridade) {
        return resolveTempoNovoPorPrioridade(regra, prioridade);
    }

    public static Integer resolveTempoNovoPorPrioridade(RegrasSLACategorizacao__c regra, String prioridade) {
        if (regra == null) {
            throw new CompatibilidadeException('Regra de SLA inválida para cálculo.');
        }
        String chave = canonicalPrioridade(prioridade);
        Decimal tempo;
        if (chave == PRIORIDADE_BAIXA) tempo = regra.TempoBaixa__c;
        else if (chave == PRIORIDADE_MEDIA) tempo = regra.TempoMedia__c;
        else if (chave == PRIORIDADE_ALTA) tempo = regra.TempoAlta__c;
        else throw new CompatibilidadeException('Prioridade não suportada para cálculo de SLA.');

        if (tempo == null) {
            throw new CompatibilidadeException('Regra de SLA não possui tempo configurado para a prioridade informada.');
        }
        return Integer.valueOf(String.valueOf(tempo.setScale(0)));
    }

    public static Boolean isVigente(RegrasSLACategorizacao__c regra) {
        return isVigente(regra, System.today());
    }

    public static Boolean isVigente(RegrasSLACategorizacao__c regra, Date dataReferencia) {
        if (regra == null) return false;
        if (regra.Ativo__c != true) return false;
        Date ref = dataReferencia == null ? System.today() : dataReferencia;
        if (regra.VigenciaInicio__c != null && regra.VigenciaInicio__c > ref) return false;
        if (regra.VigenciaFim__c != null && regra.VigenciaFim__c < ref) return false;
        return true;
    }

    public static String buildKeyNovo(
        Id gestaoSlaId,
        Id marcoSlaId,
        String escopoRegra,
        Id categorizacaoId,
        String areaAtendimento,
        String origem
    ) {
        return String.join(new List<String>{
            normalizeId(gestaoSlaId),
            normalizeId(marcoSlaId),
            normalizeText(escopoRegra),
            normalizeId(categorizacaoId),
            normalizeText(areaAtendimento),
            normalizeText(origem)
        }, '|');
    }

    public static RegrasSLACategorizacao__c resolveByOrigemFallbackNovo(
        Map<String, RegrasSLACategorizacao__c> rulesByKey,
        Id gestaoSlaId,
        Id marcoSlaId,
        String escopoRegra,
        Id categorizacaoId,
        String areaAtendimento,
        String origemEspecifica
    ) {
        String keyEspecifica = buildKeyNovo(gestaoSlaId, marcoSlaId, escopoRegra, categorizacaoId, areaAtendimento, origemEspecifica);
        String keyQualquer = buildKeyNovo(gestaoSlaId, marcoSlaId, escopoRegra, categorizacaoId, areaAtendimento, AreaParticipanteSLAHelper.origemQualquerApiValue());
        return resolveByOrigemFallback(rulesByKey, keyEspecifica, keyQualquer);
    }

    public static RegrasSLACategorizacao__c resolveByOrigemFallback(
        Map<String, RegrasSLACategorizacao__c> rulesByKey,
        String keyEspecifica,
        String keyQualquer
    ) {
        if (rulesByKey == null || rulesByKey.isEmpty()) return null;
        if (rulesByKey.containsKey(keyEspecifica)) return rulesByKey.get(keyEspecifica);
        return rulesByKey.get(keyQualquer);
    }

    public static List<RegrasSLACategorizacao__c> loadActiveRulesForCompatibility() {
        return RegrasSLACategorizacaoSelector.findAllActiveForCompatibility();
    }

    private static String canonicalPrioridade(String prioridade) {
        String p = normalizeForCompare(prioridade);
        if (p == 'baixa' || p == 'low') return PRIORIDADE_BAIXA;
        if (p == 'media' || p == 'medium') return PRIORIDADE_MEDIA;
        if (p == 'alta' || p == 'high') return PRIORIDADE_ALTA;
        return null;
    }

    private static String normalizeId(Id value) {
        return value == null ? 'null' : String.valueOf(value);
    }

    private static String normalizeText(String value) {
        return String.isBlank(value) ? 'null' : value.trim().toLowerCase();
    }

    private static String normalizeForCompare(String value) {
        String v = normalizeText(value);
        if (v == 'null') return '';
        v = v.replace('á', 'a').replace('à', 'a').replace('â', 'a').replace('ã', 'a').replace('ä', 'a');
        v = v.replace('é', 'e').replace('è', 'e').replace('ê', 'e').replace('ë', 'e');
        v = v.replace('í', 'i').replace('ì', 'i').replace('î', 'i').replace('ï', 'i');
        v = v.replace('ó', 'o').replace('ò', 'o').replace('ô', 'o').replace('õ', 'o').replace('ö', 'o');
        v = v.replace('ú', 'u').replace('ù', 'u').replace('û', 'u').replace('ü', 'u');
        v = v.replace('ç', 'c');
        return v;
    }
}