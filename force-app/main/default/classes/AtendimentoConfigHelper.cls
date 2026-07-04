/**
 * @description       : Helper de normalização para configurações do domínio de Atendimento.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-12-2026
 * @last modified by  : Marllon Nascimento
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
        String out = TextNormalizationUtil.stripAccents(value.trim().toLowerCase());
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

    /**
     * @description Entrada de fallback hardcoded de Unidade de Negócio por Record Type, usada quando
     * `AtendimentoConfigService.getActiveConfigs()` vem vazio (ex.: Custom Metadata não carregado/vazio).
     * Fonte única compartilhada por `CaseCreationSelector`/`CategorizacaoSelector` (ver CR-017 do CodeReview.md).
     */
    public class UnidadeFallbackEntry {
        public String recordTypeDeveloperName;
        public String unidadeNegocio;
        public String queuePrefix;
    }

    /**
     * @description Retorna o fallback hardcoded de Unidades de Negócio conhecidas, usado quando não há
     * nenhuma configuração ativa de `AtendimentoConfigService`. Mantém as duas telas (Novo Caso e
     * Categorização) protegidas do mesmo jeito nesse cenário de falha de configuração.
     * @return Lista de fallback (Salvador/Rio Grande/Centro Logístico/Rebocadores).
     */
    public static List<UnidadeFallbackEntry> getHardcodedUnidadeFallback() {
        List<UnidadeFallbackEntry> out = new List<UnidadeFallbackEntry>();
        out.add(fallbackEntry('Salvador', 'Atendimento Salvador', 'TSV'));
        out.add(fallbackEntry('TeconSalvador', 'Atendimento Salvador', 'TSV'));
        out.add(fallbackEntry('RioGrande', 'Atendimento Rio Grande', 'TRG'));
        out.add(fallbackEntry('TeconRioGrande', 'Atendimento Rio Grande', 'TRG'));
        out.add(fallbackEntry('CentroLogistico', 'Centro Logístico', 'CL'));
        out.add(fallbackEntry('Rebocadores', 'Rebocadores', 'REB'));
        return out;
    }

    private static UnidadeFallbackEntry fallbackEntry(String recordTypeDeveloperName, String unidadeNegocio, String queuePrefix) {
        UnidadeFallbackEntry entry = new UnidadeFallbackEntry();
        entry.recordTypeDeveloperName = recordTypeDeveloperName;
        entry.unidadeNegocio = unidadeNegocio;
        entry.queuePrefix = queuePrefix;
        return entry;
    }
}