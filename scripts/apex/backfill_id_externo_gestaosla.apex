// Backfill de IdExterno__c = Id em GestaoSLA__c (chave estável de upsert para data/seed-parametros-atendimento).
List<GestaoSLA__c> gestoes = [SELECT Id FROM GestaoSLA__c WHERE IdExterno__c = null];
for (GestaoSLA__c g : gestoes) {
    g.IdExterno__c = g.Id;
}
if (!gestoes.isEmpty()) {
    update gestoes;
}
System.debug('GestaoSLA__c atualizados: ' + gestoes.size());
