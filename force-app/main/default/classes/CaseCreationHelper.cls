public inherited sharing class CaseCreationHelper {
    public static String normalizeKey(String value) {
        if (String.isBlank(value)) return '';
        return value.toLowerCase().replaceAll('[^a-z0-9]', '');
    }

    public static Boolean keyMatches(String left, String right) {
        String l = normalizeKey(left);
        String r = normalizeKey(right);
        if (String.isBlank(l) || String.isBlank(r)) return false;
        return l == r || l.contains(r) || r.contains(l);
    }

    public static Boolean sameNormalizedValue(String left, String right) {
        return normalizeText(left) == normalizeText(right);
    }

    public static Boolean isBlank(String value) {
        return String.isBlank(value);
    }

    public static String nv(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    public static Boolean isTrueFlag(String value) {
        String n = String.isBlank(value) ? '' : value.trim().toUpperCase();
        return n == 'SIM' || n == 'TRUE' || n == 'YES' || n == '1';
    }

    public static String normalizeBusinessUnitForCase(String businessUnitName) {
        if (String.isBlank(businessUnitName)) return null;
        String normalizedInput = normalizeText(businessUnitName);
        for (Schema.PicklistEntry pe : Case.UnidadeNegocio__c.getDescribe().getPicklistValues()) {
            String normalizedPe = normalizeText(pe.getValue());
            if (normalizedPe == normalizedInput) return pe.getValue();
            if (!String.isBlank(normalizedInput) && normalizedPe.contains(normalizedInput)) return pe.getValue();
        }
        return businessUnitName.trim();
    }

    public static void putIfNotBlank(Map<String, String> target, String key, String value) {
        if (!String.isBlank(key) && !String.isBlank(value)) target.put(key, value);
    }

    public static CaseCreationDTO.PicklistOptionDTO toOption(String value) {
        CaseCreationDTO.PicklistOptionDTO o = new CaseCreationDTO.PicklistOptionDTO();
        o.value = value;
        o.label = value;
        return o;
    }

    public static Map<String, String> getCasePicklistValueToLabel(String fieldApiName) {
        Map<String, String> out = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldsByApi = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        if (!fieldsByApi.containsKey(fieldApiName)) return out;

        Schema.DescribeFieldResult dfr = fieldsByApi.get(fieldApiName).getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            out.put(pe.getValue(), pe.getLabel());
        }
        return out;
    }

    public static String normalizeText(String value) {
        if (String.isBlank(value)) return '';
        String out = TextNormalizationUtil.stripAccents(value.trim().toLowerCase());
        out = out.replaceAll('[^a-z0-9]', '');
        return out;
    }

    public static List<CaseCreationDTO.PicklistOptionDTO> toSortedOptions(Set<String> values) {
        List<String> sorted = new List<String>();
        for (String v : values) if (!String.isBlank(v)) sorted.add(v);
        sorted.sort();
        List<CaseCreationDTO.PicklistOptionDTO> out = new List<CaseCreationDTO.PicklistOptionDTO>();
        for (String s : sorted) out.add(toOption(s));
        return out;
    }

    public static List<CaseCreationDTO.PicklistOptionDTO> toSortedTranslatedOptions(Set<String> values, String caseFieldApiName) {
        Map<String, String> labelsByValue = getCasePicklistValueToLabel(caseFieldApiName);
        Map<String, Schema.SObjectField> fieldsByApi = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        Map<String, String> valueByNormalized = new Map<String, String>();
        if (fieldsByApi.containsKey(caseFieldApiName)) {
            for (Schema.PicklistEntry pe : fieldsByApi.get(caseFieldApiName).getDescribe().getPicklistValues()) {
                String normalizedValue = normalizeText(pe.getValue());
                String normalizedLabel = normalizeText(pe.getLabel());
                if (!String.isBlank(normalizedValue) && !valueByNormalized.containsKey(normalizedValue)) valueByNormalized.put(normalizedValue, pe.getValue());
                if (!String.isBlank(normalizedLabel) && !valueByNormalized.containsKey(normalizedLabel)) valueByNormalized.put(normalizedLabel, pe.getValue());
            }
        }
        List<String> sortable = new List<String>();
        Map<String, CaseCreationDTO.PicklistOptionDTO> bySortKey = new Map<String, CaseCreationDTO.PicklistOptionDTO>();
        for (String value : values) {
            if (String.isBlank(value)) continue;
            String resolvedValue = value.trim();
            if (!labelsByValue.containsKey(resolvedValue)) {
                String normalizedInput = normalizeText(resolvedValue);
                if (valueByNormalized.containsKey(normalizedInput)) {
                    resolvedValue = valueByNormalized.get(normalizedInput);
                }
            }
            CaseCreationDTO.PicklistOptionDTO o = new CaseCreationDTO.PicklistOptionDTO();
            o.value = resolvedValue;
            o.label = labelsByValue.containsKey(resolvedValue) ? labelsByValue.get(resolvedValue) : value;
            String key = (o.label == null ? '' : o.label) + '||' + resolvedValue;
            sortable.add(key);
            bySortKey.put(key, o);
        }
        sortable.sort();
        List<CaseCreationDTO.PicklistOptionDTO> out = new List<CaseCreationDTO.PicklistOptionDTO>();
        for (String key : sortable) out.add(bySortKey.get(key));
        return out;
    }

    public static List<CaseCreationDTO.PicklistOptionDTO> toSortedOptionsWithLabels(Set<String> values, Map<String, String> labelsByValue, String caseFieldApiName) {
        Map<String, Schema.SObjectField> fieldsByApi = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        Map<String, List<Schema.PicklistEntry>> entriesByNormalizedValue = new Map<String, List<Schema.PicklistEntry>>();
        Map<String, String> canonicalValueByNormalized = new Map<String, String>();
        if (fieldsByApi.containsKey(caseFieldApiName)) {
            for (Schema.PicklistEntry pe : fieldsByApi.get(caseFieldApiName).getDescribe().getPicklistValues()) {
                String keyValue = normalizeText(pe.getValue());
                String keyLabel = normalizeText(pe.getLabel());
                if (!entriesByNormalizedValue.containsKey(keyValue)) entriesByNormalizedValue.put(keyValue, new List<Schema.PicklistEntry>());
                entriesByNormalizedValue.get(keyValue).add(pe);
                if (!canonicalValueByNormalized.containsKey(keyValue)) canonicalValueByNormalized.put(keyValue, pe.getValue());
                if (!String.isBlank(keyLabel) && !canonicalValueByNormalized.containsKey(keyLabel)) canonicalValueByNormalized.put(keyLabel, pe.getValue());
            }
        }

        List<String> sortable = new List<String>();
        Map<String, CaseCreationDTO.PicklistOptionDTO> bySortKey = new Map<String, CaseCreationDTO.PicklistOptionDTO>();
        for (String value : values) {
            if (String.isBlank(value)) continue;
            String clean = value.trim();
            String normalizedClean = normalizeText(clean);
            if (canonicalValueByNormalized.containsKey(normalizedClean)) {
                clean = canonicalValueByNormalized.get(normalizedClean);
            }
            String label = labelsByValue != null && labelsByValue.containsKey(clean) && !String.isBlank(labelsByValue.get(clean))
                ? labelsByValue.get(clean)
                : clean;
            if (normalizeText(label) == normalizeText(clean)) {
                String normalized = normalizeText(clean);
                if (entriesByNormalizedValue.containsKey(normalized)) {
                    for (Schema.PicklistEntry pe : entriesByNormalizedValue.get(normalized)) {
                        if (normalizeText(pe.getLabel()) != normalizeText(pe.getValue())) {
                            label = pe.getLabel();
                            break;
                        }
                    }
                }
            }
            CaseCreationDTO.PicklistOptionDTO o = new CaseCreationDTO.PicklistOptionDTO();
            o.value = clean;
            o.label = label;
            String key = normalizeText(label) + '||' + normalizeText(clean);
            sortable.add(key);
            bySortKey.put(key, o);
        }
        sortable.sort();
        List<CaseCreationDTO.PicklistOptionDTO> out = new List<CaseCreationDTO.PicklistOptionDTO>();
        for (String key : sortable) out.add(bySortKey.get(key));
        return out;
    }
}