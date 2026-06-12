public inherited sharing class CaseAreaParticipantePauseService {
    @TestVisible public static Boolean bypassBusinessHoursMathForTests = false;

    public static void handleEtapaChanges(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        if (!AreaParticipanteSLARecursionGuard.enter('CASE_PAUSE_RESUME')) return;
        try {
            Set<Id> entered = new Set<Id>();
            Set<Id> exited = new Set<Id>();
            for (Id idCase : newMap.keySet()){
                Case n = newMap.get(idCase);
                Case o = oldMap.get(idCase);
                Boolean nowWait = n.EtapaAtendimento__c == AreaParticipanteSLAHelper.ETAPA_AGUARDANDO_CLIENTE;
                Boolean wasWait = o != null && o.EtapaAtendimento__c == AreaParticipanteSLAHelper.ETAPA_AGUARDANDO_CLIENTE;
                if (nowWait && !wasWait) entered.add(idCase);
                if (!nowWait && wasWait) exited.add(idCase);
            }

            List<AreaParticipante__c> updates = new List<AreaParticipante__c>();

            if (!entered.isEmpty()){
                for (AreaParticipante__c a : [
                    SELECT Id,StatusAtuacao__c,StatusSLA__c,TipoAreaParticipante__c,DataHoraInicioPausa__c,DataHoraFim__c,StatusAtuacaoAnteriorPausa__c,DataHoraInicio__c,DataHoraPrazo__c,TempoSLAMinutos__c,RegraSLACategorizacao__c,TempoPausadoMinutos__c
                    FROM AreaParticipante__c
                    WHERE Caso__c IN :entered AND DataHoraFim__c = null
                ]){
                    if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c)
                        || !AreaParticipanteSLAHelper.isOpenStatus(a.StatusAtuacao__c)
                        || a.StatusAtuacao__c == AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA) continue;

                    a.StatusAtuacaoAnteriorPausa__c = a.StatusAtuacao__c;
                    a.DataHoraInicioPausa__c = System.now();
                    a.StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA;
                    a.StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO;
                    updates.add(a);
                }
            }

            if (!exited.isEmpty()){
                List<AreaParticipante__c> pausedRows = [
                    SELECT Id,StatusAtuacao__c,StatusSLA__c,TipoAreaParticipante__c,DataHoraInicioPausa__c,DataHoraPrazo__c,
                           RegraSLACategorizacao__r.BusinessHoursName__c,TempoPausadoMinutos__c,StatusAtuacaoAnteriorPausa__c,
                           DataHoraInicio__c,TempoSLAMinutos__c,RegraSLACategorizacao__c,DataHoraFim__c
                    FROM AreaParticipante__c
                    WHERE Caso__c IN :exited AND DataHoraFim__c = null AND DataHoraInicioPausa__c != null
                ];

                Map<String, Id> bhByName = new Map<String, Id>();
                for (AreaParticipante__c a : pausedRows) {
                    String bhName = a.RegraSLACategorizacao__r == null ? null : a.RegraSLACategorizacao__r.BusinessHoursName__c;
                    if (String.isBlank(bhName)) continue;
                    if (!bhByName.containsKey(bhName)) bhByName.put(bhName, BusinessHoursResolverService.resolveActiveByName(bhName));
                }

                Datetime nowRef = System.now();
                for (AreaParticipante__c a : pausedRows){
                    if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c)) continue;
                    String bhName = a.RegraSLACategorizacao__r == null ? null : a.RegraSLACategorizacao__r.BusinessHoursName__c;
                    if (String.isBlank(bhName) || !bhByName.containsKey(bhName)) continue;

                    Id bhId = bhByName.get(bhName);
                    Long pausedMs = useBypassBusinessHoursInTests()
                        ? nowRef.getTime() - a.DataHoraInicioPausa__c.getTime()
                        : BusinessHours.diff(bhId, a.DataHoraInicioPausa__c, nowRef);
                    Long pausedMin = Math.max(0, pausedMs / (60L * 1000L));
                    a.TempoPausadoMinutos__c = (a.TempoPausadoMinutos__c == null ? 0 : a.TempoPausadoMinutos__c) + pausedMin;

                    if (a.DataHoraPrazo__c != null) {
                        a.DataHoraPrazo__c = useBypassBusinessHoursInTests()
                            ? a.DataHoraPrazo__c.addSeconds(Integer.valueOf(String.valueOf(pausedMs / 1000L)))
                            : BusinessHours.add(bhId, a.DataHoraPrazo__c, pausedMs);
                    }

                    a.DataHoraInicioPausa__c = null;
                    a.StatusAtuacao__c = String.isBlank(a.StatusAtuacaoAnteriorPausa__c)
                        ? AreaParticipanteSLAHelper.STATUS_ATUACAO_ANDAMENTO
                        : a.StatusAtuacaoAnteriorPausa__c;
                    a.StatusAtuacaoAnteriorPausa__c = null;
                    updates.add(a);
                }
            }

            if (!updates.isEmpty()) {
                AreaParticipanteSLAService.calculateCacheBulk(updates, System.now());
                update updates;
            }
        } finally {
            AreaParticipanteSLARecursionGuard.leave('CASE_PAUSE_RESUME');
        }
    }

    private static Boolean useBypassBusinessHoursInTests() {
        return Test.isRunningTest() && bypassBusinessHoursMathForTests == true;
    }
}