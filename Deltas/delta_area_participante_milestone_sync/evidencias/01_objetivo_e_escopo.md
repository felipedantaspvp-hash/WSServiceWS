# Evidência 01 — Objetivo e Escopo do Pacote 19

**Data:** 2026-06-14
**Branch:** feat/claude/area-participante-milestone-sync
**Pacote:** 19 — Sincronização de CaseMilestones para AreaParticipante__c

## Objetivo

Criar um mecanismo que espelha CaseMilestones padrão do Salesforce para registros `AreaParticipante__c`, consolidando SLA Standard e Custom em um único objeto para relatórios.

## Problema resolvido

O objeto `AreaParticipante__c` já registra participações manuais de Área Interna (OrigemSLA__c = 'Custom'). O SLA Standard (CaseMilestone gerenciado por EntitlementProcess) estava visível apenas no objeto nativo, sem consolidação.

## Solução

Registros espelho com `OrigemSLA__c = 'Standard'` criados/atualizados via serviço batch. `CaseMilestoneId__c` (Text 18) é a chave de idempotência — nunca duplica o mesmo milestone.

## Escopo de artefatos

| Artefato | Tipo | Papel |
|----------|------|-------|
| `AreaParticipanteMilestoneSyncService` | Classe Apex | Lógica de sincronização (insert/update) |
| `AreaParticipanteMilestoneSyncBatch` | Apex Batch | Processa Cases em lotes de 200 |
| `AreaParticipanteMilestoneSyncScheduler` | Apex Schedulable | Agendamento periódico |
| `AreaParticipanteMilestoneSyncServiceTest` | Teste Apex | Cobertura do serviço (17 cenários) |
| `AreaParticipanteMilestoneSyncBatchTest` | Teste Apex | Cobertura do batch e scheduler |
| `AreaParticipanteSLAHelper` | Modificada | + constante `ORIGEM_SLA_STANDARD` |
| `AreaParticipanteSLAService` | Modificada | Guards para registros Standard |

## Restrições respeitadas

- Sem novos campos criados
- Sem alteração de FlexiPage, Permission Sets, LWC ou metadata
- Sem alterar lógica produtiva existente (apenas guards adicionados)
- Sem destructiveChanges
- Sem campos removidos no 16B (`Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c`)
