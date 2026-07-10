// Backfill de ExternalId__c = Id em Categorizacao__c (chave estável de upsert para data/seed-parametros-atendimento).
List<Categorizacao__c> categorizacoes = [SELECT Id FROM Categorizacao__c WHERE ExternalId__c = null];
for (Categorizacao__c c : categorizacoes) {
    c.ExternalId__c = c.Id;
}
if (!categorizacoes.isEmpty()) {
    update categorizacoes;
}
System.debug('Categorizacao__c atualizados: ' + categorizacoes.size());
