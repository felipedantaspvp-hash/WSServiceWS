public inherited sharing class CaseTriggerHandler {
    @TestVisible private static Map<Id, Integer> injectedBlockersByCase = new Map<Id, Integer>();

    private static final String ETAPA_CANCELADO = 'Cancelado';
    private static final String MSG_AREA_INTERNA_ABERTA =
        'Existem áreas internas abertas. Conclua ou cancele as áreas participantes antes de fechar ou cancelar o caso.';

    public static void beforeInsert(List<Case> newRows) {
    }

    public static void beforeUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        Set<Id> closing = new Set<Id>();
        for (Id idCase : newMap.keySet()) {
            Case newC = newMap.get(idCase);
            Case oldC = oldMap.get(idCase);
            if (!oldC.IsClosed && newC.IsClosed) closing.add(idCase);
            if (ETAPA_CANCELADO.equals(newC.EtapaAtendimento__c) && !ETAPA_CANCELADO.equals(oldC.EtapaAtendimento__c)) {
                closing.add(idCase);
            }
        }
        if (closing.isEmpty()) return;

        Map<Id, Integer> blockers = new Map<Id, Integer>();
        if (Test.isRunningTest() && !injectedBlockersByCase.isEmpty()) {
            blockers.putAll(injectedBlockersByCase);
        } else {
            for (AggregateResult ar : [
                SELECT Caso__c c, COUNT(Id) cnt
                FROM AreaParticipante__c
                WHERE Caso__c IN :closing
                  AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
                  AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM
                  AND BloqueiaFechamentoCaso__c = true
                  AND DataHoraFim__c = null
                GROUP BY Caso__c
            ]) blockers.put((Id) ar.get('c'), (Integer) ar.get('cnt'));
        }

        for (Id idCase : closing) {
            if (blockers.containsKey(idCase) && blockers.get(idCase) > 0) {
                newMap.get(idCase).addError(MSG_AREA_INTERNA_ABERTA);
            }
        }
    }

    public static void afterUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        CaseAreaParticipantePauseService.handleEtapaChanges(newMap, oldMap);
        CaseMilestoneMacroService.completeByStageTransition(newMap, oldMap);
    }
}