/**
 * @description       : Classe de suporte para o módulo Case Milestone.
 * @author            : Triscal
 * @group             : Case Milestone
 * @last modified on  : 06-16-2026
 * @last modified by  : Jean Duarte
 **/
/**
 * CaseMilestoneSyncQueueable
 *
 * Queueable job that syncs CaseMilestone records to AreaParticipante__c Standard
 * records for a given set of Case IDs.
 *
 * Rationale: CaseMilestone does not support Apex triggers in this org.
 * This queueable is enqueued from CaseAfterInsertTriggerHandler after Case
 * insertion, allowing Salesforce time to create the EntitlementProcess
 * CaseMilestone records before the sync executes.
 */
public inherited sharing class CaseMilestoneSyncQueueable implements Queueable {

    @TestVisible private static Boolean bypassEnqueueForTests = false;

    private final Set<Id> caseIds;

    public CaseMilestoneSyncQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext ctx) {
        if (caseIds == null || caseIds.isEmpty()) return;
        AreaParticipanteMilestoneSyncService.syncByCaseIds(caseIds);
    }

    /**
     * Enqueues the sync job for the given Case IDs.
     * Skipped in test context via bypassEnqueueForTests to allow direct execution.
     */
    public static void enqueueSync(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        if (bypassEnqueueForTests) {
            // In tests: execute synchronously instead of enqueuing
            new CaseMilestoneSyncQueueable(caseIds).execute(null);
            return;
        }
        System.enqueueJob(new CaseMilestoneSyncQueueable(caseIds));
    }
}
