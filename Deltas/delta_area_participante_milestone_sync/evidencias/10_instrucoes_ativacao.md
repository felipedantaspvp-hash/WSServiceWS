# Evidência 10 — Instruções de Ativação Pós-Deploy

**Data:** 2026-06-14

## Deploy

```bash
sf project deploy start --manifest Deltas/delta_area_participante_milestone_sync/package.xml \
  --target-org WILSON_SERVICE --test-level RunSpecifiedTests \
  --tests AreaParticipanteMilestoneSyncServiceTest \
  --tests AreaParticipanteMilestoneSyncBatchTest \
  --tests AreaParticipanteSLAServiceTest \
  --tests AreaParticipanteSLAHelperTest \
  --tests AreaParticipanteSLABatchTest
```

## Dry-run (validação sem deploy)

```bash
sf project deploy validate --manifest Deltas/delta_area_participante_milestone_sync/package.xml \
  --target-org WILSON_SERVICE --test-level RunSpecifiedTests \
  --tests AreaParticipanteMilestoneSyncServiceTest \
  --tests AreaParticipanteMilestoneSyncBatchTest \
  --tests AreaParticipanteSLAServiceTest \
  --tests AreaParticipanteSLAHelperTest \
  --tests AreaParticipanteSLABatchTest
```

## Resultado do dry-run executado

**Data:** 2026-06-14
**Deploy ID:** `0Afbe00000AA0H7CAL`
**Org:** `jduarte@wilsonsons.com.br.service` (WILSON_SERVICE)
**Status:** ✅ **Succeeded**
**Duração:** 25.45s

### Testes

| Total | Passing | Failing |
|-------|---------|---------|
| 46 | 46 | 0 |

Classes de teste executadas:
- `AreaParticipanteMilestoneSyncServiceTest` (22 cenários)
- `AreaParticipanteMilestoneSyncBatchTest` (3 cenários)
- `AreaParticipanteSLAServiceTest`
- `AreaParticipanteSLAHelperTest`
- `AreaParticipanteSLABatchTest`

### Componentes validados (15)

| Estado | Componente | Tipo |
|--------|-----------|------|
| Created | AreaParticipanteMilestoneSyncBatch | ApexClass |
| Created | AreaParticipanteMilestoneSyncBatchTest | ApexClass |
| Created | AreaParticipanteMilestoneSyncScheduler | ApexClass |
| Created | AreaParticipanteMilestoneSyncService | ApexClass |
| Created | AreaParticipanteMilestoneSyncServiceTest | ApexClass |
| Changed | AreaParticipanteSLAHelper | ApexClass |
| Changed | AreaParticipanteSLAService | ApexClass |
| Changed | AreaParticipante__c.TipoAreaParticipante__c | CustomField |

> Para deploy imediato aproveitando a validação: `sf project deploy quick --job-id 0Afbe00000AA0H7CAL`

## Executar sincronização inicial (via Anon Apex)

```apex
// Sincronização completa — todos os Cases com SLA ativo
Database.executeBatch(new AreaParticipanteMilestoneSyncBatch(), 200);

// Sincronização de Cases específicos
Set<Id> ids = new Set<Id>{ '5003x000001abcDAAA' };
AreaParticipanteMilestoneSyncService.syncByCaseIds(ids);
```

## Agendar execução periódica

```apex
// Diariamente às 02:00
AreaParticipanteMilestoneSyncScheduler.schedule('0 0 2 * * ?');
```

## Verificação pós-sincronização

```soql
SELECT Caso__c, TipoAreaParticipante__c, NomeMarco__c, StatusSLA__c, OrigemSLA__c, CaseMilestoneId__c
FROM AreaParticipante__c
WHERE OrigemSLA__c = 'Standard'
ORDER BY Caso__c, TipoAreaParticipante__c
LIMIT 200
```

## Cancelar agendamento

```apex
for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AreaParticipanteMilestoneSync%']) {
    System.abortJob(ct.Id);
}
```
