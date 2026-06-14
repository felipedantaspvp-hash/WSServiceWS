// SCRIPT 07 — Delete regras com EscopoRegra__c = null
// Solicitado em 2026-06-13 apos diagnostico confirmar dados perdidos

List<RegrasSLACategorizacao__c> rows = [
    SELECT Id
    FROM RegrasSLACategorizacao__c
    WHERE EscopoRegra__c = null
];

Integer totalEncontrado = rows.size();
Integer totalExcluido = 0;
Integer totalErro = 0;

System.debug('=== INICIO DELETE RegrasSLACategorizacao__c sem EscopoRegra__c ===');
System.debug('Total encontrado: ' + totalEncontrado);

Database.DeleteResult[] results = Database.delete(rows, false);

for (Database.DeleteResult dr : results) {
    if (dr.isSuccess()) {
        totalExcluido++;
    } else {
        totalErro++;
        for (Database.Error err : dr.getErrors()) {
            System.debug('ERRO no registro ' + dr.getId() + ': ' + err.getMessage());
        }
    }
}

System.debug('Total excluido com sucesso: ' + totalExcluido);
System.debug('Total com erro: ' + totalErro);
System.debug('=== FIM DELETE ===');
