// Busca um Case existente com SLA e milestones para testar sync manual
List<Case> cases = [
    SELECT Id, CaseNumber, SlaStartDate, EntitlementId
    FROM Case
    WHERE SlaStartDate != null
    ORDER BY CreatedDate DESC
    LIMIT 3
];

for (Case c : cases) {
    System.debug('CASE=' + c.CaseNumber + ' Id=' + c.Id + ' SlaStart=' + c.SlaStartDate);
}

// Cria caso de teste novo — sem entitlement, só para testar que Queueable não crasha
Case testCase = new Case(
    Subject = '[TESTE 24A v2] Sync sem crash',
    Status  = 'Em Aberto',
    Origin  = 'Web'
);
insert testCase;
System.debug('NEW_CASE_ID=' + testCase.Id);

// Força sync manual via Queueable inline
CaseMilestoneSyncQueueable.bypassEnqueueForTests = true;
CaseMilestoneSyncQueueable.enqueueSync(new Set<Id>{ testCase.Id });

List<AreaParticipante__c> aps = [
    SELECT Id, TipoAreaParticipante__c, StatusSLA__c
    FROM AreaParticipante__c
    WHERE Caso__c = :testCase.Id AND OrigemSLA__c = 'Standard'
];
System.debug('AP_COUNT=' + aps.size() + ' (esperado 0 pois sem milestones)');
System.debug('SYNC_CONCLUIDO_SEM_ERRO=true');
