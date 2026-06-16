// Testa sync direto para o case com milestones conhecidos
Id caseId = '500be00000GJefhAAD';

System.debug('ANTES - APs Standard:');
for (AreaParticipante__c a : [
    SELECT Id, TipoAreaParticipante__c, StatusSLA__c, TempoSLAMinutos__c, CaseMilestoneId__c
    FROM AreaParticipante__c
    WHERE Caso__c = :caseId AND OrigemSLA__c = 'Standard'
]) { System.debug('AP=' + a); }

AreaParticipanteMilestoneSyncService.syncByCaseIds(new Set<Id>{ caseId });

System.debug('DEPOIS - APs Standard:');
List<AreaParticipante__c> aps = [
    SELECT Id, TipoAreaParticipante__c, StatusSLA__c, TempoSLAMinutos__c, CaseMilestoneId__c, StatusAtuacao__c
    FROM AreaParticipante__c
    WHERE Caso__c = :caseId AND OrigemSLA__c = 'Standard'
];
System.debug('AP_COUNT=' + aps.size());
for (AreaParticipante__c a : aps) { System.debug('AP=' + a); }
