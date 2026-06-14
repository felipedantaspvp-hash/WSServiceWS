# README — Evidências Pacote 19: Sincronização CaseMilestone → AreaParticipante__c

**Data:** 2026-06-14
**Branch:** feat/claude/area-participante-milestone-sync

## Índice de evidências

| Arquivo | Conteúdo |
|---------|----------|
| [01_objetivo_e_escopo.md](evidencias/01_objetivo_e_escopo.md) | Objetivo, problema resolvido, artefatos do pacote, restrições respeitadas |
| [02_arquitetura.md](evidencias/02_arquitetura.md) | Diagrama de fluxo, pontos de entrada, descrição de idempotência |
| [03_mapeamento_milestones.md](evidencias/03_mapeamento_milestones.md) | Tabela MilestoneType.Name → TipoAreaParticipante__c, normalização, limitação SLA Total |
| [04_campos_mapeados.md](evidencias/04_campos_mapeados.md) | Mapeamento completo de campos CaseMilestone → AreaParticipante__c, lógica StatusSLA |
| [05_seguranca_trigger.md](evidencias/05_seguranca_trigger.md) | Análise de segurança do trigger para registros Standard (beforeSave, closeSLA, etc.) |
| [06_modificacoes_helper_service.md](evidencias/06_modificacoes_helper_service.md) | Diffs das modificações em AreaParticipanteSLAHelper e AreaParticipanteSLAService |
| [07_cenarios_de_teste.md](evidencias/07_cenarios_de_teste.md) | 21 cenários de teste documentados (17 ServiceTest + 3 BatchTest + 1 Scheduler) |
| [08_idempotencia_e_preservacao_custom.md](evidencias/08_idempotencia_e_preservacao_custom.md) | Detalhamento da chave CaseMilestoneId__c e preservação de registros Custom |
| [09_bulk_safety.md](evidencias/09_bulk_safety.md) | Análise de queries, DML e limites de governor |
| [10_instrucoes_ativacao.md](evidencias/10_instrucoes_ativacao.md) | Comandos de deploy, dry-run, ativação inicial e agendamento |
| [11_utf8_sem_bom.md](evidencias/11_utf8_sem_bom.md) | Verificação binária de encoding — sem BOM, sem mojibake |

## Estrutura do delta

```
delta_area_participante_milestone_sync/
├── package.xml
├── README_EVIDENCIAS.md
├── classes/
│   ├── AreaParticipanteMilestoneSyncService.cls + -meta.xml   ← NOVO
│   ├── AreaParticipanteMilestoneSyncBatch.cls + -meta.xml     ← NOVO
│   ├── AreaParticipanteMilestoneSyncScheduler.cls + -meta.xml ← NOVO
│   ├── AreaParticipanteMilestoneSyncServiceTest.cls + -meta.xml ← NOVO
│   ├── AreaParticipanteMilestoneSyncBatchTest.cls + -meta.xml ← NOVO
│   ├── AreaParticipanteSLAHelper.cls + -meta.xml              ← MODIFICADO
│   └── AreaParticipanteSLAService.cls + -meta.xml             ← MODIFICADO
└── evidencias/
    └── 01 a 11 *.md
```
