// Backfill de Categorizacao__c.PermiteAssumirComFilaParametrizada__c para os registros
// existentes (criados antes deste campo existir). Nao seta o valor diretamente aqui:
// dispara um update vazio para forcar CategorizacaoTrigger -> CategorizacaoService.beforeSave
// a aplicar o default "Sim" (preserva o comportamento atual de "Assumir" sempre disponivel
// em todas as Categorizacoes ja configuradas, conforme decisao do usuario).
// allOrNone=false: qualquer falha pontual fica reportada sem travar o backfill dos demais.
List<Categorizacao__c> rows = [
    SELECT Id, PermiteAssumirComFilaParametrizada__c
    FROM Categorizacao__c
    WHERE PermiteAssumirComFilaParametrizada__c = null
];

System.debug('BACKFILL_PERMITE_ASSUMIR_TOTAL=' + rows.size());

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

System.debug('BACKFILL_PERMITE_ASSUMIR_OK=' + okCount);
System.debug('BACKFILL_PERMITE_ASSUMIR_FAIL=' + failures.size());
for (String f : failures) {
    System.debug('BACKFILL_PERMITE_ASSUMIR_FAIL_DETAIL: ' + f);
}
