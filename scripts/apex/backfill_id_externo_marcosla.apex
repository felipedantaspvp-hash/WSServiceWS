// Backfill de IdExterno__c = Id em MarcoSLA__c (chave estável de upsert para data/seed-parametros-atendimento).
List<MarcoSLA__c> marcos = [SELECT Id FROM MarcoSLA__c WHERE IdExterno__c = null];
for (MarcoSLA__c m : marcos) {
    m.IdExterno__c = m.Id;
}
if (!marcos.isEmpty()) {
    update marcos;
}
System.debug('MarcoSLA__c atualizados: ' + marcos.size());
