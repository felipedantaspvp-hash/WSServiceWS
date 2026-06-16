# Pacote 24A — CaseMilestone → AreaParticipante Sync (Auto-Wire)

## 1. Causa raiz

Ao criar um Case com `EtapaAtendimento__c = 'Em Atendimento'`, o Salesforce
gera registros `CaseMilestone` via EntitlementProcess. Entretanto, o serviço
`AreaParticipanteMilestoneSyncService.syncByCaseMilestoneIds()` nunca era chamado
automaticamente: ele só existia no batch `AreaParticipanteMilestoneSyncBatch`.
Resultado: nenhum registro `AreaParticipante__c` Standard era criado após a
criação do Case.

## 2. Por que AP Standard não era criada automaticamente

Não havia nenhum gatilho ou hook que chamasse o serviço de sync no momento em que
os `CaseMilestone` eram gerados pelo EntitlementProcess. O batch existe para
backfill, mas não é executado automaticamente em cada inserção de Case.

## 3. CaseMilestone suporta Trigger no projeto?

**Não.** Verificado via dry-run:

```
problem: "SObject type does not allow triggers: CaseMilestone"
```

A API do Salesforce confirmou a existência do objeto (`EntityDefinition`
retornou `CaseMilestone`), mas este org específico não suporta Apex Triggers
nesse objeto.

## 4. Estratégia escolhida

**Opção B — Queueable a partir de Case `after insert`**

- Nova trigger `CaseAfterInsertTrigger` em `Case (after insert)` — **não altera**
  a `CaseTrigger` existente (Salesforce suporta múltiplas triggers no mesmo objeto).
- `CaseAfterInsertTriggerHandler.afterInsert()` coleta os IDs dos Cases inseridos
  e chama `CaseMilestoneSyncQueueable.enqueueSync()`.
- `CaseMilestoneSyncQueueable` implementa `Queueable` e chama
  `AreaParticipanteMilestoneSyncService.syncByCaseIds()` assincronamente.
- A execução assíncrona é necessária: os `CaseMilestone` são gerados pelo
  EntitlementProcess **após** o commit da transação do Case.

## 5. Arquivos criados/alterados

### Criados (delta e force-app/main/default)

| Arquivo | Tipo | Descrição |
|---|---|---|
| `CaseAfterInsertTriggerHandler.cls` | ApexClass | Handler para after insert do Case |
| `CaseMilestoneSyncQueueable.cls` | ApexClass | Queueable que chama o sync service |
| `CaseMilestoneSyncQueueableTest.cls` | ApexClass | 6 testes de cobertura |
| `CaseAfterInsertTrigger.trigger` | ApexTrigger | Trigger `Case (after insert)` |
| `package.xml` | Manifest | Package 24A |

### Não alterados

- `CaseTrigger.trigger` — não modificado
- `CaseTriggerHandler.cls` — não modificado
- `AreaParticipanteMilestoneSyncService.cls` — não modificado (reaproveitado)
- Nenhum LWC, Flow, EntitlementProcess ou objeto existente alterado

## 6. Confirmação: serviço existente foi reaproveitado

`CaseMilestoneSyncQueueable.execute()` chama diretamente
`AreaParticipanteMilestoneSyncService.syncByCaseIds(caseIds)` — o mesmo serviço
usado pelo `AreaParticipanteMilestoneSyncBatch`. Nenhuma lógica de negócio foi
duplicada.

## 7. Confirmação de idempotência

`AreaParticipanteMilestoneSyncService.syncInternal()` já implementa idempotência:
busca registros existentes por `CaseMilestoneId__c` e faz update em vez de insert
quando já existe. O teste `testAfterInsertIdempotente` confirma que duas execuções
consecutivas com o mesmo milestone resultam em exatamente 1 registro.

## 8. Confirmação: Custom manual não afetado

`syncInternal()` respeita `OrigemSLA__c = 'Custom'`: quando um AP Custom já existe
para aquele `CaseMilestoneId__c`, o registro é pulado (`continue`) e nenhum
Standard é criado ou atualiza o Custom. Confirmado pelo teste `testCustomManualNaoAfetado`.

## 9. Testes (CaseMilestoneSyncQueueableTest)

| Método | Cobertura |
|---|---|
| `testAfterInsertCriaMilestoneSync` | afterInsert cria 1 AP Standard com campos corretos |
| `testAfterInsertIdempotente` | Segunda execução não duplica registros |
| `testQueueableExecuteSyncByCaseIds` | Queueable.execute() direto cria AP via SLA Total |
| `testAfterInsertSetVazioNaoFazNada` | Lista vazia não lança exceção |
| `testBulkMultiplosCases` | 3 milestones de 3 Cases distintos criam 3 APs (bulk safe) |
| `testCustomManualNaoAfetado` | AP Custom existente não é substituído nem duplicado |

## 10. Resultado do dry-run

- **Job ID:** `0Afbe00000AApptCAD` (primeira tentativa, Option A — falhou por CaseMilestone não suportar trigger)
- **Job ID Option B:** `0Afbe00000AApqBCAR` (sucesso)
- **Status:** `Succeeded`
- **Testes executados:** 6/6
- **Falhas:** 0
- **Cobertura:**
  - `CaseAfterInsertTrigger` (trigger): 1/1 locations — **100%**
  - `CaseMilestoneSyncQueueable` (class): 12/12 locations — **100%**
  - `CaseAfterInsertTriggerHandler` (class): 7/7 locations — **100%**
- **Erros de componente:** 0
