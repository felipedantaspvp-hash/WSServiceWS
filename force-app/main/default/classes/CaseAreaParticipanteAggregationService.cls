public inherited sharing class CaseAreaParticipanteAggregationService {
    public static void refreshForCases(Set<Id> caseIds){
        if (caseIds == null || caseIds.isEmpty()) return;
        if (!AreaParticipanteSLARecursionGuard.enter('CASE_AGGREGATION')) return;
        try {
            Map<Id, Integer> openByCase = new Map<Id, Integer>();
            Map<Id, Integer> dueByCase = new Map<Id, Integer>();

            for (AggregateResult ar : [
                SELECT Caso__c c, COUNT(Id) cnt
                FROM AreaParticipante__c
                WHERE Caso__c IN :caseIds
                  AND DataHoraFim__c = null
                  AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
                  AND StatusAtuacao__c IN :new Set<String>{AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA, AreaParticipanteSLAHelper.STATUS_ATUACAO_ANDAMENTO, AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA, AreaParticipanteSLAHelper.STATUS_ATUACAO_VENCIDA}
                GROUP BY Caso__c
            ]) openByCase.put((Id) ar.get('c'), (Integer) ar.get('cnt'));

            for (AggregateResult ar : [
                SELECT Caso__c c, COUNT(Id) cnt
                FROM AreaParticipante__c
                WHERE Caso__c IN :caseIds
                  AND DataHoraFim__c = null
                  AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
                  AND StatusSLA__c = :AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
                GROUP BY Caso__c
            ]) dueByCase.put((Id) ar.get('c'), (Integer) ar.get('cnt'));

            List<Case> updates = new List<Case>();
            for (Id cId : caseIds) {
                updates.add(new Case(
                    Id = cId,
                    QtdAreasParticipantesAbertas__c = openByCase.containsKey(cId) ? openByCase.get(cId) : 0,
                    QtdAreasParticipantesVencidas__c = dueByCase.containsKey(cId) ? dueByCase.get(cId) : 0
                ));
            }
            if (!updates.isEmpty()) update updates;
        } finally {
            AreaParticipanteSLARecursionGuard.leave('CASE_AGGREGATION');
        }
    }
}