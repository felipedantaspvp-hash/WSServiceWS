// SCRIPT 03 — Update controlado EscopoRegra__c
// Pacote 15C — Migracao EscopoRegra__c
//
// Mapeamento aprovado:
//   Por Categorizacao  -> Atendimento
//   Por Area Interna   -> Area Interna
//
// Global NAO e atualizado neste script.
// Script e idempotente: registros ja migrados nao sao tocados.
// Executar via: Developer Console > Execute Anonymous
//               ou: sf apex run --file scripts/03_update_escopo_regra.apex -o WILSON_SERVICE

List<RegrasSLACategorizacao__c> rows = [
    SELECT Id, EscopoRegra__c
    FROM RegrasSLACategorizacao__c
    WHERE EscopoRegra__c IN ('Por Categorizacao', 'Por Area Interna')
];

Integer totalEncontrado = rows.size();
Integer totalAtualizado = 0;
Integer totalErro = 0;

System.debug('=== INICIO MIGRACAO EscopoRegra__c ===');
System.debug('Total encontrado para migracao: ' + totalEncontrado);

if (totalEncontrado == 0) {
    System.debug('Nenhum registro pendente de migracao. Script encerrado sem alteracoes.');
} else {
    for (RegrasSLACategorizacao__c row : rows) {
        if (row.EscopoRegra__c == 'Por Categorizacao') {
            row.EscopoRegra__c = 'Atendimento';
        } else if (row.EscopoRegra__c == 'Por Area Interna') {
            row.EscopoRegra__c = 'Area Interna';
        }
    }

    Database.SaveResult[] results = Database.update(rows, false);

    for (Database.SaveResult sr : results) {
        if (sr.isSuccess()) {
            totalAtualizado++;
        } else {
            totalErro++;
            for (Database.Error err : sr.getErrors()) {
                System.debug('ERRO no registro ' + sr.getId() + ': ' + err.getMessage() + ' | Campos: ' + err.getFields());
            }
        }
    }

    System.debug('Total atualizado com sucesso: ' + totalAtualizado);
    System.debug('Total com erro: ' + totalErro);
    System.debug('=== FIM MIGRACAO EscopoRegra__c ===');
}
