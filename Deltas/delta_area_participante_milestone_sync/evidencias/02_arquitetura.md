# Evidência 02 — Arquitetura e Fluxo de Sincronização

**Data:** 2026-06-14

## Diagrama de fluxo

```
[Scheduler / Chamada manual]
        │
        ▼
AreaParticipanteMilestoneSyncBatch.start()
  └─ QueryLocator: Case WHERE SlaStartDate != null AND Status != 'Fechado'
        │  (ou Set<Id> de Cases específicos)
        ▼
AreaParticipanteMilestoneSyncBatch.execute(scope)
  └─ Set<Id> caseIds ← scope
        │
        ▼
AreaParticipanteMilestoneSyncService.syncByCaseIds(caseIds)
        │
        ├─ SOQL: CaseMilestone WHERE CaseId IN :caseIds
        │   └─ campos: Id, CaseId, MilestoneType.Name, StartDate, TargetDate,
        │              CompletionDate, IsCompleted, IsViolated,
        │              ElapsedTimeInMins, TimeRemainingInMins
        │
        ├─ SOQL: AreaParticipante__c WHERE CaseMilestoneId__c IN :cmIdStrings
        │   └─ mapa existingByMilestoneId
        │
        └─ Para cada CaseMilestone:
              ├─ [Custom existente] → skip (preserva)
              ├─ [Standard existente] → buildRecord → toUpdate
              └─ [Novo] → buildRecord → toInsert
                    │
                    ▼
              insert toInsert / update toUpdate
```

## Pontos de entrada

| Método | Uso |
|--------|-----|
| `syncByCaseIds(Set<Id>)` | Sincroniza milestones de um conjunto de Cases |
| `syncByCaseMilestoneIds(Set<Id>)` | Sincroniza milestones por ID direto |

## Idempotência

A chave `CaseMilestoneId__c` garante que uma segunda execução atualiza o registro existente em vez de criar um novo. Registros Custom (OrigemSLA__c = 'Custom') são identificados antes do insert/update e ignorados.
