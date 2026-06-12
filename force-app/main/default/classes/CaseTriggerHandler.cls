public inherited sharing class CaseTriggerHandler {
    @TestVisible private static Map<Id, Integer> injectedBlockersByCase = new Map<Id, Integer>();

    public static void beforeInsert(List<Case> newRows) {
        CaseEntitlementAssignmentService.assignForSalvador(newRows);
    }

    public static void beforeUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        List<Case> rows = new List<Case>();
        rows.addAll(newMap.values());
        CaseEntitlementAssignmentService.assignForSalvador(rows);

        Set<Id> closing = new Set<Id>();
        for (Id idCase : newMap.keySet()) {
            if (oldMap.get(idCase).IsClosed == false && newMap.get(idCase).IsClosed == true) closing.add(idCase);
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
                  AND BloqueiaFechamentoCaso__c = true
                  AND DataHoraFim__c = null
                GROUP BY Caso__c
            ]) blockers.put((Id) ar.get('c'), (Integer) ar.get('cnt'));
        }

        for (Id idCase : closing) {
            if (blockers.containsKey(idCase) && blockers.get(idCase) > 0) {
                newMap.get(idCase).addError('Não é possível encerrar o Caso enquanto houver Área Participante interna aberta ou bloqueante.');
            }
        }
    }

    public static void afterUpdate(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        CaseAreaParticipantePauseService.handleEtapaChanges(newMap, oldMap);
        CaseMilestoneMacroService.completeByStageTransition(newMap, oldMap);
    }
}