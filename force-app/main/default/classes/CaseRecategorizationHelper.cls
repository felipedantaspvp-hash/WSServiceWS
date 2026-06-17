/**
 * @description       : Funções utilitárias e helpers para o módulo CaseRecategorization.
 * @author            : Triscal
 * @group             : Case Recategorização
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseRecategorizationHelper {
    public static Boolean isBlank(String value) {
        return String.isBlank(value);
    }

    public static String normalizeText(String value) {
        return CaseCreationHelper.normalizeText(value);
    }

    public static Boolean sameNormalizedValue(String left, String right) {
        return CaseCreationHelper.sameNormalizedValue(left, right);
    }

    public static Boolean isCaseBlocked(Case c) {
        if (c == null) return true;
        if (c.IsClosed) return true;
        return normalizeText(c.Status) == normalizeText('Cancelado') || normalizeText(c.Status) == normalizeText('Canceled');
    }

    public static CaseRecategorizationDTO.PicklistOptionDTO toOption(String label, String value) {
        CaseRecategorizationDTO.PicklistOptionDTO out = new CaseRecategorizationDTO.PicklistOptionDTO();
        out.label = label;
        out.value = value;
        return out;
    }

    public static List<CaseRecategorizationDTO.PicklistOptionDTO> toSortedOptionsWithLabels(
        Set<String> values,
        Map<String, String> labelsByValue,
        String caseFieldApiName
    ) {
        List<CaseCreationDTO.PicklistOptionDTO> base = CaseCreationHelper.toSortedOptionsWithLabels(values, labelsByValue, caseFieldApiName);
        List<CaseRecategorizationDTO.PicklistOptionDTO> out = new List<CaseRecategorizationDTO.PicklistOptionDTO>();
        for (CaseCreationDTO.PicklistOptionDTO item : base) {
            out.add(toOption(item.label, item.value));
        }
        return out;
    }

    public static String safeAliasValue(SObject row, String aliasFieldName, String fallback) {
        try {
            String value = (String) row.get(aliasFieldName);
            return String.isBlank(value) ? fallback : value;
        } catch (Exception ex) {
            return fallback;
        }
    }

    public static String resolveCasePicklistLabel(String fieldApiName, String value) {
        if (String.isBlank(value)) return null;
        Map<String, String> valueToLabel = CaseCreationHelper.getCasePicklistValueToLabel(fieldApiName);
        return valueToLabel.containsKey(value) ? valueToLabel.get(value) : value;
    }
}