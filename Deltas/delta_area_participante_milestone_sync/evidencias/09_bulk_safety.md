# Evidência 09 — Bulk Safety e Limites de Governor

**Data:** 2026-06-14

## Análise de queries por execução de syncInternal

| Query | Localização | Padrão |
|-------|-------------|--------|
| `CaseMilestone WHERE CaseId IN :caseIds` | syncByCaseIds | 1 query bulk |
| `CaseMilestone WHERE Id IN :milestoneIds` | syncByCaseMilestoneIds | 1 query bulk |
| `AreaParticipante__c WHERE CaseMilestoneId__c IN :cmIdStrings` | syncInternal | 1 query bulk |
| `Case WHERE Id IN :caseIds` (Batch.start) | Batch QueryLocator | QueryLocator (não conta) |

**Total por execução de syncInternal:** 2 queries SOQL.

## DML

| DML | Condição |
|-----|----------|
| `insert toInsert` | Apenas se há novos milestones |
| `update toUpdate` | Apenas se há milestones existentes para atualizar |

Máximo 2 statements DML. Seguro dentro do limite de 150.

## Tamanho de lote do Batch

`Database.executeBatch(new AreaParticipanteMilestoneSyncBatch(), 200)` — lote de 200 Cases.
Para 200 Cases com ~8 milestones cada: ~1600 CaseMilestones por execução, bem abaixo dos 50.000 de query.

## Sem queries em loops

Toda lógica de lookup usa Maps populados antes do loop principal.
Não há queries dentro de `for` em `syncInternal` ou `buildRecord`.
