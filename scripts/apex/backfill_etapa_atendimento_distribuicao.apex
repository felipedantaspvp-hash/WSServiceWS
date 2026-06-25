// Backfill de Categorizacao__c.EtapaAtendimentoDistribuicao__c para as Categorizacoes que ja
// distribuem para fila (DistribuirParaFila__c='Sim') e foram criadas antes deste campo existir.
// Diferente do backfill de PermiteAssumirComFilaParametrizada__c, este campo passou a ser
// OBRIGATORIO quando DistribuirParaFila__c='Sim' (validateAndNormalize bloqueia save em branco) —
// por isso o valor precisa ser setado explicitamente aqui, e nao por um update vazio.
// 'Em Triagem' preserva o comportamento hardcoded que o motor usava antes desta mudanca.
// allOrNone=false: qualquer falha pontual fica reportada sem travar o backfill dos demais.
List<Categorizacao__c> rows = [
    SELECT Id, EtapaAtendimentoDistribuicao__c
    FROM Categorizacao__c
    WHERE DistribuirParaFila__c = 'Sim'
      AND EtapaAtendimentoDistribuicao__c = null
];

System.debug('BACKFILL_ETAPA_ATENDIMENTO_TOTAL=' + rows.size());

for (Categorizacao__c r : rows) {
    r.EtapaAtendimentoDistribuicao__c = 'Em Triagem';
}

Database.SaveResult[] results = Database.update(rows, false);

Integer okCount = 0;
List<String> failures = new List<String>();
for (Integer i = 0; i < results.size(); i++) {
    Database.SaveResult sr = results[i];
    if (sr.isSuccess()) {
        okCount++;
    } else {
        String msg = sr.getErrors().isEmpty() ? 'erro desconhecido' : sr.getErrors()[0].getMessage();
        failures.add(rows[i].Id + ' | erro: ' + msg);
    }
}

System.debug('BACKFILL_ETAPA_ATENDIMENTO_OK=' + okCount);
System.debug('BACKFILL_ETAPA_ATENDIMENTO_FAIL=' + failures.size());
for (String f : failures) {
    System.debug('BACKFILL_ETAPA_ATENDIMENTO_FAIL_DETAIL: ' + f);
}
