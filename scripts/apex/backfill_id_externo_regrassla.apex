// Backfill de IdExterno__c = Id em RegrasSLACategorizacao__c (chave estável de upsert para data/seed-parametros-atendimento).
List<RegrasSLACategorizacao__c> regras = [SELECT Id FROM RegrasSLACategorizacao__c WHERE IdExterno__c = null];
for (RegrasSLACategorizacao__c r : regras) {
    r.IdExterno__c = r.Id;
}
if (!regras.isEmpty()) {
    update regras;
}
System.debug('RegrasSLACategorizacao__c atualizados: ' + regras.size());
