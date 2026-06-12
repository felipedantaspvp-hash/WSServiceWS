/**
 * @description       : Helper de normalização para configurações do domínio de Atendimento.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-12-2026
 * @last modified by  : Codex
 **/
public inherited sharing class AtendimentoConfigHelper {
    public static final String SURVEY_MODE_ALWAYS = 'ALWAYS';
    public static final String SURVEY_MODE_OPTIONAL = 'OPTIONAL';
    public static final String SURVEY_MODE_NEVER = 'NEVER';

    /**
     * @description Normaliza chaves funcionais de unidade para comparação sem depender de Id.
     * @param value Valor da unidade de negócio.
     * @return Chave normalizada.
     */
    public static String normalizeBusinessUnitKey(String value) {
        if (String.isBlank(value)) return '';
        String out = value.trim().toLowerCase();
        out = out.replace('á', 'a').replace('à', 'a').replace('ã', 'a').replace('â', 'a');
        out = out.replace('é', 'e').replace('ê', 'e');
        out = out.replace('í', 'i');
        out = out.replace('ó', 'o').replace('ô', 'o').replace('õ', 'o');
        out = out.replace('ú', 'u');
        out = out.replace('ç', 'c');
        out = out.replaceAll('[^a-z0-9]+', '');
        if (out.startsWith('atendimento') && out.length() > 'atendimento'.length()) {
            out = out.substring('atendimento'.length());
        }
        return out;
    }

    /**
     * @description Garante modo válido de Survey.
     * @param mode Modo configurado.
     * @return Modo válido, usando NEVER como fallback seguro.
     */
    public static String normalizeSurveyMode(String mode) {
        String normalized = String.isBlank(mode) ? SURVEY_MODE_NEVER : mode.trim().toUpperCase();
        if (normalized == SURVEY_MODE_ALWAYS || normalized == SURVEY_MODE_OPTIONAL || normalized == SURVEY_MODE_NEVER) {
            return normalized;
        }
        return SURVEY_MODE_NEVER;
    }
}