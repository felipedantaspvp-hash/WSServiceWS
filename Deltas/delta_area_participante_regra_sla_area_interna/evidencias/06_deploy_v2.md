# Evidência 06 — Deploy v2 (Sequência Global + GestaoSLA Explícito)

**Deploy ID:** 0Afbe00000A9wAHCAZ
**Data:** 2026-06-14
**Org:** jduarte@wilsonsons.com.br.service
**Tipo:** Deploy Real (Quick Deploy após Dry Run aprovado)

## Resultado do Deploy

- **Status:** Succeeded
- **Classes implantadas:** 8

## Resultado dos Testes

**Test Run ID:** 707be00000VPT8y

| Métrica | Valor |
|---------|-------|
| Tests Ran | 43 |
| Pass Rate | 100% |
| Fail Rate | 0% |

## Classes implantadas neste deploy (v2)

| Classe | Mudança principal |
|--------|------------------|
| AreaParticipanteSLAService | Sequência global por Case; filtro GestaoSLA__c explícito em findRule() |
| AreaParticipanteSelector | getCaseById agora inclui Categorizacao__r.GestaoSLA__c; getEligibleAreaValuesForCase filtra por GestaoSLA__c |
| AreaParticipanteService | Sem mudanças adicionais em v2 |
| AreaParticipanteSLAServiceTest | createRegraNova sem MarcoSLA__c; novo teste testSequenciaGlobalPorCaseNaoPorArea |
| AreaParticipanteServiceTest | Sem mudanças adicionais em v2 |
| AreaParticipanteControllerTest | Sem mudanças adicionais em v2 |
| AreaParticipanteTestDataFactory | createSharedGestao(); createSlaRule aceita gestaoId; todos os registros de um Case usam a mesma GestaoSLA__c |
| AreaParticipanteSLABatchTest | createRule atualiza Categorizacao__c.GestaoSLA__c = g.Id após criar a regra; removido MarcoSLA__c |

## Histórico de rounds de deploy v2

| Round | Deploy ID | Testes | Resultado |
|-------|-----------|--------|-----------|
| v2-r1 | 0Afbe00000A9vnhCAB → tentativa v2 | 38/43 | 5 falhas |
| v2-r2 | getSObject fix + batch fix | 42/43 | 1 falha restante |
| v2-r3 | Factory shared GestaoSLA fix | 43/43 | **100%** |
| v2-final | 0Afbe00000A9wAHCAZ | 43/43 | **Succeeded** |

## Novo teste adicionado

`testSequenciaGlobalPorCaseNaoPorArea` — verifica que SequenciaAcionamento__c é global por Case:
- Área1 inserida → SequenciaAcionamento__c = 1
- Área2 diferente inserida no mesmo Case → SequenciaAcionamento__c = 2 (não reinicia em 1)
