public inherited sharing class AreaParticipanteHelper {
    private static Boolean isEnglish() {
        String lang = UserInfo.getLanguage();
        return !String.isBlank(lang) && lang.toLowerCase().startsWith('en');
    }

    public static String normalizeText(String value) {
        if (String.isBlank(value)) return '';
        String out = TextNormalizationUtil.stripAccents(value.trim().toLowerCase());
        out = out.replaceAll('[^a-z0-9 ]', ' ');
        out = out.replaceAll('\\s+', ' ').trim();
        return out;
    }

    public static Set<String> parseMultiPicklist(String value) {
        Set<String> out = new Set<String>();
        if (String.isBlank(value)) return out;
        for (String token : value.split(';')) {
            if (!String.isBlank(token)) out.add(token.trim());
        }
        return out;
    }

    public static String joinMultiPicklist(Set<String> values) {
        if (values == null || values.isEmpty()) return null;
        List<String> sorted = new List<String>();
        for (String item : values) if (!String.isBlank(item)) sorted.add(item.trim());
        sorted.sort();
        return sorted.isEmpty() ? null : String.join(sorted, ';');
    }

    public static String removeValue(String currentValue, String valueToRemove) {
        Set<String> tokens = parseMultiPicklist(currentValue);
        if (tokens.isEmpty() || String.isBlank(valueToRemove)) return joinMultiPicklist(tokens);
        String n = normalizeText(valueToRemove);
        for (String token : new List<String>(tokens)) {
            if (normalizeText(token) == n) tokens.remove(token);
        }
        return joinMultiPicklist(tokens);
    }

    public static String addValue(String currentValue, String valueToAdd) {
        Set<String> tokens = parseMultiPicklist(currentValue);
        if (String.isBlank(valueToAdd)) return joinMultiPicklist(tokens);
        Boolean found = false;
        String n = normalizeText(valueToAdd);
        for (String token : tokens) {
            if (normalizeText(token) == n) {
                found = true;
                break;
            }
        }
        if (!found) tokens.add(valueToAdd.trim());
        return joinMultiPicklist(tokens);
    }

    public static Boolean containsValue(String currentValue, String value) {
        if (String.isBlank(currentValue) || String.isBlank(value)) return false;
        String n = normalizeText(value);
        for (String token : parseMultiPicklist(currentValue)) {
            if (normalizeText(token) == n) return true;
        }
        return false;
    }

    public static Decimal calculatePercent(Datetime inicio, Datetime prazo, Datetime referenceNow) {
        if (inicio == null || prazo == null) return null;
        Long total = prazo.getTime() - inicio.getTime();
        if (total <= 0) return 100;
        Long elapsed = referenceNow.getTime() - inicio.getTime();
        Decimal pct = (Decimal.valueOf(elapsed) / Decimal.valueOf(total)) * 100;
        if (pct < 0) return 0;
        if (pct > 100) return 100;
        return pct.setScale(2);
    }

    public static Boolean isOverdue(Datetime prazo, Datetime referenceNow, String statusValue) {
        if (prazo == null) return false;
        if (isConcluida(statusValue) || isCancelada(statusValue)) return false;
        return referenceNow.getTime() > prazo.getTime();
    }

    public static Boolean isConcluida(String statusValue) {
        String n = normalizeText(statusValue);
        return n.contains('conclu') || n.contains('completed') || n.contains('finaliz');
    }

    public static Boolean isCancelada(String statusValue) {
        String n = normalizeText(statusValue);
        return n.contains('cancel');
    }

    public static Boolean isAbertaOuAndamento(String statusValue) {
        String n = normalizeText(statusValue);
        if (String.isBlank(n)) return true;
        if (isConcluida(statusValue) || isCancelada(statusValue)) return false;
        return n.contains('aberta') || n.contains('aberto') || n.contains('andamento') || n.contains('em andamento') || n.contains('open') || n.contains('progress') || n.contains('pendente');
    }

    public static String resolveConcluidaStatusValue() {
        List<Schema.PicklistEntry> entries = AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pe : entries) {
            if (isConcluida(pe.getValue()) || isConcluida(pe.getLabel())) return pe.getValue();
        }
        return entries.isEmpty() ? 'Concluída' : entries[0].getValue();
    }

    public static String resolveOpenStatusValue() {
        List<Schema.PicklistEntry> entries = AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pe : entries) {
            String n = normalizeText(pe.getValue() + ' ' + pe.getLabel());
            if (n.contains('abert') || n.contains('andamento') || n.contains('open') || n.contains('progress')) return pe.getValue();
        }
        return entries.isEmpty() ? 'Aberta' : entries[0].getValue();
    }

    public static String buildTempoTexto(Datetime nowRef, Datetime prazo, Datetime fim) {
        if (prazo == null) return isEnglish() ? 'No deadline informed' : 'Prazo não informado';
        Datetime ref = fim == null ? nowRef : fim;
        Long diffMs = prazo.getTime() - ref.getTime();
        Long mins = Math.abs(diffMs) / (60 * 1000);
        Long hours = mins / 60;
        Long remMins = Math.mod(mins, 60);
        String pretty = String.valueOf(hours) + 'h ' + String.valueOf(remMins) + 'm';
        if (diffMs >= 0) return (isEnglish() ? 'Remaining: ' : 'Restante: ') + pretty;
        return (isEnglish() ? 'Overdue: ' : 'Atraso: ') + pretty;
    }

}
