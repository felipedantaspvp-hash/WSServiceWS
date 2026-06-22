// Recalcula ChaveNatural__c/ChaveNaturalHash__c de todas as Categorizacao__c ativas,
// forcando o trigger->CategorizacaoService.beforeSave a reprocessar com os valores
// atuais dos campos (pos-saneamento das picklists globais PT/EN).
// allOrNone=false: registros que colidirem em hash com outro (duplicidade real
// remanescente) falham individualmente e ficam reportados, sem travar os demais.
List<Categorizacao__c> rows = [
    SELECT Id, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c, Subassunto__c,
           Ativo__c, MotivoInativacao__c, Prioridade__c, RecordTypeId,
           DistribuirParaFila__c, PorCampoCustomizado__c, FilaDeveloperName__c,
           CampoDistribuicao__c, ValorDistribuicao__c, ChaveNaturalHash__c
    FROM Categorizacao__c
    WHERE Ativo__c = true
];

Map<Id, String> oldHashById = new Map<Id, String>();
for (Categorizacao__c r : rows) oldHashById.put(r.Id, r.ChaveNaturalHash__c);

Database.SaveResult[] results = Database.update(rows, false);

Integer okCount = 0;
List<String> failures = new List<String>();
for (Integer i = 0; i < results.size(); i++) {
    Database.SaveResult sr = results[i];
    if (sr.isSuccess()) {
        okCount++;
    } else {
        Categorizacao__c r = rows[i];
        String msg = sr.getErrors().isEmpty() ? 'erro desconhecido' : sr.getErrors()[0].getMessage();
        failures.add(r.Id + ' | hash antigo=' + oldHashById.get(r.Id) + ' | ' + r.UnidadeNegocios__c + '/' + r.TipoCaso__c + '/' + r.Categoria__c + '/' + r.Assunto__c + '/' + r.Subassunto__c + ' | erro: ' + msg);
    }
}

System.debug('RECALC_HASH_TOTAL=' + rows.size());
System.debug('RECALC_HASH_OK=' + okCount);
System.debug('RECALC_HASH_FAIL=' + failures.size());
for (String f : failures) {
    System.debug('RECALC_HASH_FAIL_DETAIL: ' + f);
}
