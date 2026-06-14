// SCRIPT 05 — Rollback opcional (TEMPLATE — NAO executar diretamente)
// Pacote 15C — Migracao EscopoRegra__c
//
// ATENCAO: Este script e um template comentado.
// NAO deve ser executado diretamente sem revisao manual.
//
// O rollback correto deve ser feito usando o backup CSV gerado pelo script 02.
// O CSV contem os Ids originais com seus valores antigos de EscopoRegra__c.
//
// Procedimento de rollback:
//   1. Abrir o arquivo backup_regras_sla_escopo_regra_pre_update.csv
//   2. Filtrar apenas os Ids que tinham 'Por Categorizacao' ou 'Por Area Interna'
//   3. Substituir a lista de Ids abaixo pelos Ids reais do backup
//   4. Revisar e executar via Developer Console > Execute Anonymous
//
// NUNCA usar WHERE EscopoRegra__c IN ('Atendimento', 'Area Interna') como filtro
// de rollback, pois isso reverteria registros que JA existiam com esses valores
// antes da migracao.

/*

// ===== TEMPLATE DE ROLLBACK — SUBSTITUIR IDs ANTES DE USAR =====

// Ids dos registros que foram migrados de 'Por Categorizacao' para 'Atendimento'
List<Id> idsPorCategorizacao = new List<Id>{
    // Substituir pelos Ids reais do backup CSV
    // Exemplo: '001xx000003GYn5AAG', '001xx000003GYn6AAG'
};

// Ids dos registros que foram migrados de 'Por Area Interna' para 'Area Interna'
List<Id> idsPorAreaInterna = new List<Id>{
    // Substituir pelos Ids reais do backup CSV
    // Exemplo: '001xx000003GYn7AAG'
};

List<RegrasSLACategorizacao__c> rollbackRows = new List<RegrasSLACategorizacao__c>();

for (Id recordId : idsPorCategorizacao) {
    rollbackRows.add(new RegrasSLACategorizacao__c(
        Id = recordId,
        EscopoRegra__c = 'Por Categorizacao'
    ));
}

for (Id recordId : idsPorAreaInterna) {
    rollbackRows.add(new RegrasSLACategorizacao__c(
        Id = recordId,
        EscopoRegra__c = 'Por Area Interna'
    ));
}

if (!rollbackRows.isEmpty()) {
    Database.SaveResult[] results = Database.update(rollbackRows, false);
    Integer ok = 0;
    Integer err = 0;
    for (Database.SaveResult sr : results) {
        if (sr.isSuccess()) { ok++; } else { err++; }
    }
    System.debug('Rollback: ' + ok + ' revertidos, ' + err + ' com erro.');
}

// ===== FIM DO TEMPLATE =====

*/
