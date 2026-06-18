/**
 * @description       : Serviço de negócio para o módulo CaseMilestoneMacro. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : Case Milestone
 * @last modified on  : 06-13-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseMilestoneMacroService {
    private static final String ETAPA_CONCLUIDO = 'Concluído';
    private static final String ETAPA_CANCELADO = 'Cancelado';
    private static final String M_TOTAL = 'SLA Total';

    @TestVisible private static Set<Id> lastCatchAllCaseIds = new Set<Id>();
    @TestVisible private static Set<Id> lastSLATotalCaseIds = new Set<Id>();
    @TestVisible private static Boolean bypassCaseMilestoneDmlInTests = false;

    public static void completeByStageTransition(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        if (newMap == null || newMap.isEmpty() || oldMap == null) return;

        Set<Id> catchAllCaseIds = new Set<Id>();
        Set<Id> slaTotalCaseIds = new Set<Id>();

        for (Id caseId : newMap.keySet()) {
            Case n = newMap.get(caseId);
            Case o = oldMap.get(caseId);
            if (n == null || o == null) continue;

            if (n.EtapaAtendimento__c != o.EtapaAtendimento__c) {
                catchAllCaseIds.add(caseId);
            }
            if ((o.IsClosed == false && n.IsClosed == true)
                    || isIn(n.EtapaAtendimento__c, new Set<String>{ ETAPA_CONCLUIDO, ETAPA_CANCELADO })) {
                slaTotalCaseIds.add(caseId);
            }
        }

        lastCatchAllCaseIds = new Set<Id>(catchAllCaseIds);
        lastSLATotalCaseIds = new Set<Id>(slaTotalCaseIds);

        if (catchAllCaseIds.isEmpty() && slaTotalCaseIds.isEmpty()) return;
        if (Test.isRunningTest() && bypassCaseMilestoneDmlInTests) return;

        Set<Id> allCaseIds = new Set<Id>();
        allCaseIds.addAll(catchAllCaseIds);
        allCaseIds.addAll(slaTotalCaseIds);

        Datetime nowRef = System.now();
        List<CaseMilestone> toUpdate = new List<CaseMilestone>();
        for (CaseMilestone cm : [
            SELECT Id, CaseId, CompletionDate, MilestoneType.Name
            FROM CaseMilestone
            WHERE CaseId IN :allCaseIds
              AND CompletionDate = null
        ]) {
            Boolean isSLATotal = cm.MilestoneType.Name == M_TOTAL;
            if (!isSLATotal && catchAllCaseIds.contains(cm.CaseId)) {
                cm.CompletionDate = nowRef;
                toUpdate.add(cm);
            } else if (isSLATotal && slaTotalCaseIds.contains(cm.CaseId)) {
                cm.CompletionDate = nowRef;
                toUpdate.add(cm);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        // Sincroniza todos os Milestones do Case mesmo sem ter completado nenhum:
        // o próprio critério de entrada da transição de etapa pode iniciar um novo
        // Milestone diretamente no motor do Entitlement Process, sem depender de uma
        // conclusão explícita feita por este código.
        AreaParticipanteMilestoneSyncService.syncByCaseIds(allCaseIds);
    }

    private static Boolean isIn(String value, Set<String> allowed) {
        return value != null && allowed != null && allowed.contains(value);
    }
}