public inherited sharing class AreaParticipanteSLAService {
    public class FunctionalException extends Exception {}
    @TestVisible public static Boolean bypassBusinessHoursMathForTests = false;

    public static void beforeSave(List<AreaParticipante__c> newList, Map<Id, AreaParticipante__c> oldMap){
        Set<Id> caseIds = new Set<Id>();
        for (AreaParticipante__c a : newList) if (a.Caso__c != null) caseIds.add(a.Caso__c);
        Map<Id, Case> caseById = new Map<Id, Case>([SELECT Id,Categorizacao__c,Priority,Origin,EtapaAtendimento__c FROM Case WHERE Id IN :caseIds]);

        Map<String, Integer> maxSeqByKey = new Map<String, Integer>();
        for (AggregateResult ar : [SELECT Caso__c c, AreaAtendimento__c a, MAX(SequenciaAcionamento__c) m FROM AreaParticipante__c WHERE Caso__c IN :caseIds GROUP BY Caso__c, AreaAtendimento__c]) {
            maxSeqByKey.put(String.valueOf(ar.get('c')) + '|' + String.valueOf(ar.get('a')), ((Decimal) ar.get('m')).intValue());
        }

        for (AreaParticipante__c a : newList){
            if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c)) continue;
            if (a.Caso__c == null || String.isBlank(a.AreaAtendimento__c)) { a.addError('Caso e Área são obrigatórios para Área Interna.'); continue; }
            Case c = caseById.get(a.Caso__c);
            if (c == null || c.Categorizacao__c == null) { a.addError('Case.Categorizacao__c é obrigatório para SLA N3.'); continue; }

            Boolean changedToOpen = oldMap == null || oldMap.get(a.Id) == null || !AreaParticipanteSLAHelper.isOpenStatus(oldMap.get(a.Id).StatusAtuacao__c);
            if (changedToOpen) {
                RegrasSLACategorizacao__c rule = findRule(c, a);
                if (rule == null) { a.addError('Não existe regra de SLA ativa para a categorização, área participante e prioridade informadas.'); continue; }
                Integer resolvedMinutes;
                try {
                    resolvedMinutes = RegrasSLACompatibilidadeService.resolveTempoCompativel(rule, c.Priority);
                } catch (Exception ex) {
                    String errMsg = ex.getMessage();
                    a.addError(errMsg != null && errMsg.contains('não suportada')
                        ? 'Prioridade do caso inválida para cálculo de SLA da área participante.'
                        : 'Regra de SLA não possui tempo configurado para a prioridade do caso.');
                    continue;
                }
                a.RegraSLACategorizacao__c = rule.Id;
                a.TempoSLAMinutos__c = resolvedMinutes;
                if (a.DataHoraInicio__c == null) a.DataHoraInicio__c = System.now();
                Id bhId = BusinessHoursResolverService.resolveActiveByName(rule.BusinessHoursName__c);
                Long prazoMs = AreaParticipanteSLAHelper.toMs(resolvedMinutes);
                a.DataHoraPrazo__c = useBypassBusinessHoursInTests()
                    ? a.DataHoraInicio__c.addSeconds(Integer.valueOf(String.valueOf(prazoMs / 1000L)))
                    : BusinessHours.add(bhId, a.DataHoraInicio__c, prazoMs);
                a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO;
                a.ViolouSLA__c = false;
                a.OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM;
                a.BloqueiaFechamentoCaso__c = true;
                String seqKey = String.valueOf(a.Caso__c) + '|' + String.valueOf(a.AreaAtendimento__c);
                Integer seq = maxSeqByKey.containsKey(seqKey) ? maxSeqByKey.get(seqKey) + 1 : 1;
                a.SequenciaAcionamento__c = seq;
                maxSeqByKey.put(seqKey, seq);
            }
        }

        calculateCacheBulk(newList, System.now());
        validateNoOpenDuplicate(newList);
    }

    private static void validateNoOpenDuplicate(List<AreaParticipante__c> newList){
        Set<Id> caseIds = new Set<Id>();
        Set<String> areas = new Set<String>();
        for (AreaParticipante__c a : newList){
            if (a.Caso__c != null && AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c) && AreaParticipanteSLAHelper.isOpenStatus(a.StatusAtuacao__c)) {
                caseIds.add(a.Caso__c);
                areas.add(a.AreaAtendimento__c);
            }
        }
        if (caseIds.isEmpty()) return;

        Map<String, Id> existingByKey = new Map<String, Id>();
        for (AreaParticipante__c a : [
            SELECT Id,Caso__c,AreaAtendimento__c,TipoAreaParticipante__c,StatusAtuacao__c,DataHoraFim__c
            FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds AND AreaAtendimento__c IN :areas AND DataHoraFim__c = null
        ]) {
            if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c) || !AreaParticipanteSLAHelper.isOpenStatus(a.StatusAtuacao__c)) continue;
            existingByKey.put(String.valueOf(a.Caso__c) + '|' + a.AreaAtendimento__c, a.Id);
        }

        Set<String> seen = new Set<String>();
        for (AreaParticipante__c a : newList){
            if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c) || !AreaParticipanteSLAHelper.isOpenStatus(a.StatusAtuacao__c)) continue;
            String key = String.valueOf(a.Caso__c) + '|' + a.AreaAtendimento__c;
            if (existingByKey.containsKey(key) && existingByKey.get(key) != a.Id) a.addError('Já existe ciclo aberto da mesma área para o Case.');
            if (seen.contains(key)) a.addError('Duplicidade aberta dentro do mesmo lote.');
            seen.add(key);
        }
    }

    private static RegrasSLACategorizacao__c findRule(Case c, AreaParticipante__c a){
        List<RegrasSLACategorizacao__c> rows = [
            SELECT Id,BusinessHoursName__c,TempoBaixa__c,TempoMedia__c,TempoAlta__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
                AND Categorizacao__c = :c.Categorizacao__c
                AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
                AND AreaAtendimento__c = :a.AreaAtendimento__c
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    public static void calculateCache(AreaParticipante__c a){
        calculateCacheBulk(new List<AreaParticipante__c>{ a }, System.now());
    }

    public static void calculateCacheBulk(List<AreaParticipante__c> rows, Datetime nowRef){
        if (rows == null || rows.isEmpty()) return;

        Set<Id> ruleIds = new Set<Id>();
        for (AreaParticipante__c a : rows) {
            Map<String, Object> populated = a.getPopulatedFieldsAsMap();
            Id ruleId = populated.containsKey('RegraSLACategorizacao__c') ? (Id) populated.get('RegraSLACategorizacao__c') : null;
            if (ruleId != null) ruleIds.add(ruleId);
        }

        Map<Id, RegrasSLACategorizacao__c> ruleById = new Map<Id, RegrasSLACategorizacao__c>();
        if (!ruleIds.isEmpty()) {
            ruleById = new Map<Id, RegrasSLACategorizacao__c>([
                SELECT Id, BusinessHoursName__c
                FROM RegrasSLACategorizacao__c
                WHERE Id IN :ruleIds
            ]);
        }

        Map<String, Id> bhByName = new Map<String, Id>();
        for (RegrasSLACategorizacao__c r : ruleById.values()) {
            if (String.isBlank(r.BusinessHoursName__c)) continue;
            if (!bhByName.containsKey(r.BusinessHoursName__c)) {
                bhByName.put(r.BusinessHoursName__c, BusinessHoursResolverService.resolveActiveByName(r.BusinessHoursName__c));
            }
        }

        for (AreaParticipante__c a : rows){
            if (a.DataHoraInicio__c == null || a.TempoSLAMinutos__c == null || a.TempoSLAMinutos__c <= 0) continue;
            Map<String, Object> populated = a.getPopulatedFieldsAsMap();
            Id ruleId = populated.containsKey('RegraSLACategorizacao__c') ? (Id) populated.get('RegraSLACategorizacao__c') : null;
            RegrasSLACategorizacao__c rule = ruleId == null ? null : ruleById.get(ruleId);
            if (rule == null || String.isBlank(rule.BusinessHoursName__c) || !bhByName.containsKey(rule.BusinessHoursName__c)) continue;

            Id bhId = bhByName.get(rule.BusinessHoursName__c);
            Datetime endRef = a.DataHoraFim__c == null ? nowRef : a.DataHoraFim__c;
            Long usefulMs = useBypassBusinessHoursInTests()
                ? endRef.getTime() - a.DataHoraInicio__c.getTime()
                : BusinessHours.diff(bhId, a.DataHoraInicio__c, endRef);
            Long usefulMin = Math.max(0, usefulMs / (60L * 1000L));
            Long pausedMin = a.TempoPausadoMinutos__c == null ? 0L : a.TempoPausadoMinutos__c.longValue();
            Long consumedMin = Math.max(0, usefulMin - pausedMin);

            a.TempoConsumidoMinutos__c = Decimal.valueOf(consumedMin);
            Long totalSla = a.TempoSLAMinutos__c.longValue();
            a.TempoRestanteMinutos__c = Decimal.valueOf(totalSla - consumedMin);

            Decimal pct = (Decimal.valueOf(consumedMin) / a.TempoSLAMinutos__c) * 100;
            if (pct < 0) pct = 0;
            if (pct > 100) pct = 100;
            a.PercentualDecorrido__c = pct.setScale(2);

            if (a.DataHoraFim__c == null && a.DataHoraPrazo__c != null && nowRef.getTime() > a.DataHoraPrazo__c.getTime()) {
                a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO;
                a.ViolouSLA__c = true;
            }
        }
    }

    public static void closeSLA(List<AreaParticipante__c> rows){
        calculateCacheBulk(rows, System.now());
        for (AreaParticipante__c a : rows){
            if (AreaParticipanteSLAHelper.isConcluida(a.StatusAtuacao__c)) a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO;
            if (AreaParticipanteSLAHelper.isCancelada(a.StatusAtuacao__c)) a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_CANCELADO;
            a.BloqueiaFechamentoCaso__c = false;
        }
    }

    private static Boolean useBypassBusinessHoursInTests() {
        return Test.isRunningTest() && bypassBusinessHoursMathForTests == true;
    }
}