// SCRIPT 06 — Update registros com EscopoRegra__c = null para Atendimento
// Pacote 15C complemento — solicitado em 2026-06-13

List<RegrasSLACategorizacao__c> rows = [
    SELECT Id, EscopoRegra__c
    FROM RegrasSLACategorizacao__c
    WHERE EscopoRegra__c = null
];

Integer totalEncontrado = rows.size();
Integer totalAtualizado = 0;
Integer totalErro = 0;

System.debug('=== INICIO UPDATE NULL -> Atendimento ===');
System.debug('Total encontrado: ' + totalEncontrado);

for (RegrasSLACategorizacao__c r : rows) {
    r.EscopoRegra__c = 'Atendimento';
}

Database.SaveResult[] results = Database.update(rows, false);

for (Database.SaveResult sr : results) {
    if (sr.isSuccess()) {
        totalAtualizado++;
    } else {
        totalErro++;
        for (Database.Error err : sr.getErrors()) {
            System.debug('ERRO no registro ' + sr.getId() + ': ' + err.getMessage());
        }
    }
}

System.debug('Total atualizado com sucesso: ' + totalAtualizado);
System.debug('Total com erro: ' + totalErro);
System.debug('=== FIM UPDATE NULL -> Atendimento ===');
