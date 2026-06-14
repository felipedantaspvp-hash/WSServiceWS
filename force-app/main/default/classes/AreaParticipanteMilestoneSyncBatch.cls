public inherited sharing class AreaParticipanteMilestoneSyncBatch implements Database.Batchable<SObject> {

    private final Set<Id> caseIds;

    public AreaParticipanteMilestoneSyncBatch() {
        this.caseIds = null;
    }

    public AreaParticipanteMilestoneSyncBatch(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (caseIds != null && !caseIds.isEmpty()) {
            return Database.getQueryLocator([
                SELECT Id FROM Case WHERE Id IN :caseIds
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id FROM Case
            WHERE SlaStartDate != null
            AND Status != 'Fechado'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        Set<Id> ids = new Set<Id>();
        for (Case c : scope) ids.add(c.Id);
        AreaParticipanteMilestoneSyncService.syncByCaseIds(ids);
    }

    public void finish(Database.BatchableContext bc) {}
}
