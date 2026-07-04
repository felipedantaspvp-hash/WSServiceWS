/**
 * @description       : Serviço de gestão de SLA para o módulo AreaParticipante. Gerencia cálculo de prazo, status e atualização de marcos.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteSLAService {
    public class FunctionalException extends Exception {}
    private static final String BYPASS_KEY = 'AreaParticipanteSLAService.bypassBusinessHoursMath';

    public static void beforeSave(List<AreaParticipante__c> newList, Map<Id, AreaParticipante__c> oldMap){
        Set<Id> caseIds = new Set<Id>();
        for (AreaParticipante__c a : newList) if (a.Caso__c != null) caseIds.add(a.Caso__c);
        Map<Id, Case> caseById = new Map<Id, Case>([SELECT Id,Categorizacao__c,Categorizacao__r.GestaoSLA__c,Priority,Origin,EtapaAtendimento__c FROM Case WHERE Id IN :caseIds]);

        Map<Id, Integer> maxSeqByCaseId = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT Caso__c c, MAX(SequenciaAcionamento__c) m FROM AreaParticipante__c WHERE Caso__c IN :caseIds GROUP BY Caso__c]) {
            Decimal mVal = (Decimal) ar.get('m');
            if (mVal != null) maxSeqByCaseId.put((Id) ar.get('c'), mVal.intValue());
        }

        Map<String, RegrasSLACategorizacao__c> ruleByKey = preloadRules(newList, oldMap, caseById);

        for (AreaParticipante__c a : newList){
            if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c)) continue;
            if (AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) continue;
            if (a.Caso__c == null || String.isBlank(a.AreaAtendimento__c)) { a.addError('Caso e Área são obrigatórios para Área Interna.'); continue; }
            Case c = caseById.get(a.Caso__c);
            if (c == null || c.Categorizacao__c == null) { a.addError('Case.Categorizacao__c é obrigatório para SLA N3.'); continue; }

            Boolean changedToOpen = oldMap == null || oldMap.get(a.Id) == null || !AreaParticipanteSLAHelper.isOpenStatus(oldMap.get(a.Id).StatusAtuacao__c);
            if (changedToOpen) {
                RegrasSLACategorizacao__c rule = ruleByKey.get(ruleKey(c, a));
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
                if (String.isBlank(rule.BusinessHoursName__c)) {
                    a.addError('A regra de SLA ativa para essa área não possui Horário Comercial configurado. Configure o campo BusinessHoursName na regra e tente novamente.');
                    continue;
                }
                Id bhId = BusinessHoursResolverService.resolveActiveByName(rule.BusinessHoursName__c);
                Long prazoMs = AreaParticipanteSLAHelper.toMs(resolvedMinutes);
                a.DataHoraPrazo__c = useBypassBusinessHoursInTests()
                    ? a.DataHoraInicio__c.addSeconds(Integer.valueOf(String.valueOf(prazoMs / 1000L)))
                    : BusinessHours.add(bhId, a.DataHoraInicio__c, prazoMs);
                a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO;
                a.ViolouSLA__c = false;
                a.OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM;
                a.BloqueiaFechamentoCaso__c = true;
                Integer seq = maxSeqByCaseId.containsKey(a.Caso__c) ? maxSeqByCaseId.get(a.Caso__c) + 1 : 1;
                a.SequenciaAcionamento__c = seq;
                maxSeqByCaseId.put(a.Caso__c, seq);
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

    private static Map<String, RegrasSLACategorizacao__c> preloadRules(List<AreaParticipante__c> newList, Map<Id, AreaParticipante__c> oldMap, Map<Id, Case> caseById){
        Set<Id> categorizacaoIds = new Set<Id>();
        Set<Id> gestaoIds = new Set<Id>();
        Set<String> areas = new Set<String>();

        for (AreaParticipante__c a : newList){
            if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c)) continue;
            if (AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) continue;
            if (a.Caso__c == null || String.isBlank(a.AreaAtendimento__c)) continue;
            Case c = caseById.get(a.Caso__c);
            if (c == null || c.Categorizacao__c == null) continue;
            Boolean changedToOpen = oldMap == null || oldMap.get(a.Id) == null || !AreaParticipanteSLAHelper.isOpenStatus(oldMap.get(a.Id).StatusAtuacao__c);
            if (!changedToOpen) continue;

            Id gestaoId = gestaoIdOf(c);
            if (gestaoId == null) continue;
            categorizacaoIds.add(c.Categorizacao__c);
            gestaoIds.add(gestaoId);
            areas.add(a.AreaAtendimento__c);
        }

        Map<String, RegrasSLACategorizacao__c> ruleByKey = new Map<String, RegrasSLACategorizacao__c>();
        if (categorizacaoIds.isEmpty()) return ruleByKey;

        for (RegrasSLACategorizacao__c rule : [
            SELECT Id,BusinessHoursName__c,TempoBaixa__c,TempoMedia__c,TempoAlta__c,Categorizacao__c,GestaoSLA__c,AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
                AND Categorizacao__c IN :categorizacaoIds
                AND GestaoSLA__c IN :gestaoIds
                AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
                AND AreaAtendimento__c IN :areas
        ]) {
            String key = rule.Categorizacao__c + '|' + rule.GestaoSLA__c + '|' + rule.AreaAtendimento__c;
            if (!ruleByKey.containsKey(key)) ruleByKey.put(key, rule);
        }
        return ruleByKey;
    }

    private static String ruleKey(Case c, AreaParticipante__c a){
        Id gestaoId = gestaoIdOf(c);
        return c.Categorizacao__c + '|' + gestaoId + '|' + a.AreaAtendimento__c;
    }

    private static Id gestaoIdOf(Case c){
        SObject categRel = c.getSObject('Categorizacao__r');
        return categRel != null ? (Id) categRel.get('GestaoSLA__c') : null;
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
            if (a.DataHoraInicioPausa__c != null) {
                a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
                continue;
            }
            Map<String, Object> populated = a.getPopulatedFieldsAsMap();
            Id ruleId = populated.containsKey('RegraSLACategorizacao__c') ? (Id) populated.get('RegraSLACategorizacao__c') : null;
            RegrasSLACategorizacao__c rule = ruleId == null ? null : ruleById.get(ruleId);
            if (rule == null || String.isBlank(rule.BusinessHoursName__c) || !bhByName.containsKey(rule.BusinessHoursName__c)) continue;

            Id bhId = bhByName.get(rule.BusinessHoursName__c);
            Datetime endRef = a.DataHoraFim__c == null ? nowRef : a.DataHoraFim__c;
            Long usefulMs = useBypassBusinessHoursInTests()
                ? endRef.getTime() - a.DataHoraInicio__c.getTime()
                : BusinessHours.diff(bhId, a.DataHoraInicio__c, endRef);
            Long pausedMs = (a.TempoPausadoMinutos__c == null ? 0L : a.TempoPausadoMinutos__c.longValue()) * 60000L;
            Long consumedMs = Math.max(0, usefulMs - pausedMs);
            Long totalSlaMs = a.TempoSLAMinutos__c.longValue() * 60000L;
            Long remainingMs = Math.max(0, totalSlaMs - consumedMs);

            a.TempoConsumidoMinutos__c = (Decimal.valueOf(consumedMs) / 60000).setScale(6);
            a.TempoRestanteMinutos__c = (Decimal.valueOf(remainingMs) / 60000).setScale(6);

            Decimal pct = (a.TempoConsumidoMinutos__c / a.TempoSLAMinutos__c) * 100;
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
            if (!AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) {
                if (AreaParticipanteSLAHelper.isConcluida(a.StatusAtuacao__c)) a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO;
                if (AreaParticipanteSLAHelper.isCancelada(a.StatusAtuacao__c)) a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_CANCELADO;
            }
            a.BloqueiaFechamentoCaso__c = false;
        }
    }

    private static Boolean useBypassBusinessHoursInTests() {
        return ApexTestSeam.getBoolean(BYPASS_KEY);
    }
}