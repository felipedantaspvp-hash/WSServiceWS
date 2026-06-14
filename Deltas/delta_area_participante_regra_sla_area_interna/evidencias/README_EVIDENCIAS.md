# README Evidências — Delta: AreaParticipante Regra SLA Area Interna

**Pacote:** 17A  
**Branch:** feat/claude/entitlement-rio-grande-centro-logistico-rebocadores  
**Última atualização:** 2026-06-14

## Resumo

Implementação de regra de SLA para Area Interna via `AreaParticipante__c`, com lookups de `RegrasSLACategorizacao__c` filtrados por `EscopoRegra__c = 'Area Interna'` e `GestaoSLA__c` explícito. Sequência de acionamento global por Case.

## Deploy Final

| Tipo | ID |
|------|----|
| Deploy Real (v1 — baseline) | 0Afbe00000A9vnhCAB |
| Deploy Real (v2 — GestaoSLA + Seq Global) | 0Afbe00000A9wAHCAZ |

## Testes

| Run | ID | Testes | Resultado |
|-----|----|--------|-----------|
| v1 | 707be00000VPGnc | 42/42 | 100% Pass |
| v2 | 707be00000VPT8y | 43/43 | 100% Pass |

## Índice de Evidências

| Arquivo | Conteúdo |
|---------|----------|
| `01_dryrun.md` | Dry run do deploy v1 (Deploy ID 0Afbe00000A9vm5CAB) |
| `02_deploy_real.md` | Deploy real v1 (Deploy ID 0Afbe00000A9vnhCAB) |
| `03_testes.md` | Test Run v1 — 42/42 passes (Run 707be00000VPGnc) |
| `04_mudancas_apex.md` | Mudanças Apex v1 (findRule EscopoRegra__c, addParticipation campos) |
| `05_inventario_componente_visual.md` | Inventário LWC/Aura — nenhum componente visual existe ainda; Pacote 18 |
| `06_deploy_v2.md` | Deploy v2 (Deploy ID 0Afbe00000A9wAHCAZ) — 43/43 passes |
| `07_mudancas_apex_v2.md` | Mudanças Apex v2 (Seq Global, GestaoSLA explícito, Factory shared gestao) |

## Classes no Delta (8 classes)

| Classe | Tipo | Escopo |
|--------|------|--------|
| AreaParticipanteSLAService | Produção | Serviço principal: findRule, addParticipation, SequenciaAcionamento |
| AreaParticipanteSelector | Produção | Selector: getCaseById com GestaoSLA__c, getEligibleAreaValuesForCase |
| AreaParticipanteService | Produção | Serviço de entrada: addParticipation, mensagem de erro |
| AreaParticipanteSLAServiceTest | Teste | 14 testes (1 novo v2: testSequenciaGlobalPorCaseNaoPorArea) |
| AreaParticipanteServiceTest | Teste | Testes de serviço com BH bypass |
| AreaParticipanteControllerTest | Teste | Testes de controller com BH bypass |
| AreaParticipanteTestDataFactory | Teste | Factory com shared GestaoSLA__c |
| AreaParticipanteSLABatchTest | Teste | Batch tests com GestaoSLA__c corrigido |
