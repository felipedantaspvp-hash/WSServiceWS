# Pacote 20 — Bloqueio de Fechamento/Cancelamento de Case com Área Interna Aberta

## 1. Objetivo

Impedir que um Case seja fechado ou cancelado enquanto existir `AreaParticipante__c` do tipo Área Interna (`OrigemSLA__c = 'Custom'`) com `BloqueiaFechamentoCaso__c = true` e `DataHoraFim__c = null` vinculada ao caso.

## 2. Arquivos criados/alterados

| Arquivo | Operação | Descrição |
|---|---|---|
| `force-app/main/default/classes/CaseTriggerHandler.cls` | Alterado | + Detecção de cancelamento via `EtapaAtendimento__c = 'Cancelado'`; + filtro `OrigemSLA__c = 'Custom'` na query; + mensagem funcional atualizada |
| `force-app/main/default/classes/CaseTriggerHandlerTest.cls` | Alterado | 7 cenários de teste implementados (1 existente revisado + 6 novos) |

## 3. Flows de Case analisados

| Flow | Adequado para este fim? |
|---|---|
| `Case_EntitlementAutoAssignment` | Não — before-save, on-create, atribui Entitlement |
| `Route_from_Will` | Não — RoutingFlow de Messaging |
| `Route_to_Will_Smoke` | Não — RoutingFlow de Messaging |

Nenhum Flow de Case para fechamento/cancelamento/validação encontrado.

## 4. Triggers/Classes de Case encontradas

| Artefato | Tipo |
|---|---|
| `CaseTrigger` | Apex Trigger (before insert, before update, after update) |
| `CaseTriggerHandler` | Trigger Handler — lógica de bloqueio parcialmente implementada |
| `CaseClosureSurveyService` | Service — fecha Case via UI, `CLOSED_STATUS = 'Fechado'` |
| `CaseMilestoneMacroService` | Service — fecha milestones; referencia `ETAPA_CANCELADO = 'Cancelado'` |

## 5. Decisão arquitetural

**Estender o `CaseTriggerHandler` existente.**

O projeto já tem Trigger + Handler como padrão oficial para Case. O bloqueio de fechamento estava parcialmente implementado no `beforeUpdate`. Flow seria automação paralela desnecessária. A regra é simples o suficiente para o Handler, sem necessidade de Apex Invocable separado.

Ver detalhes: `evidencias/04_decisao_arquitetural_flow_apex.md`

## 6. Justificativa: por que Handler e não Flow + Invocable

- Trigger Handler já existia e já tinha a lógica parcial
- Nenhum Flow de before-update adequado encontrado
- A query é simples (1 SOQL aggregate, 1 GROUP BY)
- Criar Flow + Invocable apenas para substituir 12 linhas de Handler seria over-engineering
- Não existe necessidade de reutilização externa da regra

## 7. Onde a regra está implementada

`CaseTriggerHandler.beforeUpdate()` — linhas de detecção e bloqueio:

```apex
// Detecção de fechamento
if (!oldC.IsClosed && newC.IsClosed) closing.add(idCase);

// Detecção de cancelamento via EtapaAtendimento__c (Pacote 20)
if (ETAPA_CANCELADO.equals(newC.EtapaAtendimento__c) && !ETAPA_CANCELADO.equals(oldC.EtapaAtendimento__c)) {
    closing.add(idCase);
}

// Query com filtro OrigemSLA__c = 'Custom' (Pacote 20)
AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM

// Mensagem atualizada (Pacote 20)
'Existem áreas internas abertas. Conclua ou cancele as áreas participantes antes de fechar ou cancelar o caso.'
```

## 8. Status de Case considerados fechamento/cancelamento

| Status | Como detectado |
|---|---|
| Fechado (`Status = 'Fechado'` → `IsClosed = true`) | `!oldC.IsClosed && newC.IsClosed` |
| Cancelado (`EtapaAtendimento__c = 'Cancelado'`) | Transição da etapa operacional |

Fonte: `CaseClosureSurveyService.CLOSED_STATUS = 'Fechado'`; `CaseMilestoneMacroService.ETAPA_CANCELADO = 'Cancelado'`.

## 9. Status de Área Participante considerados abertos

Detectados indiretamente via `BloqueiaFechamentoCaso__c = true AND DataHoraFim__c = null` (equivalente a Aberta + Em Andamento + Vencida, mas mais robusto).

## 10. Critério para bloquear

`TipoAreaParticipante__c = 'Área Interna'` AND `OrigemSLA__c = 'Custom'` AND `BloqueiaFechamentoCaso__c = true` AND `DataHoraFim__c = null`.

## 11. Standard não bloqueia

Confirmado por dupla proteção:
1. `buildRecord()` sempre define `BloqueiaFechamentoCaso__c = false` em registros Standard
2. Query agora inclui `OrigemSLA__c = 'Custom'` explicitamente

Testado em `testStandardOrigemDoesNotBlockClosure`.

## 12. Custom Área Interna aberta bloqueia

Confirmado por `testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen` e `testBeforeUpdateBlocksCancelViaEtapaCancelado`.

## 13. Campos removidos no 16B

Nenhum dos campos removidos (`Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c`) foi usado ou recriado.

## 14. Testes executados

| # | Cenário | Resultado |
|---|---|---|
| 1 | Fechamento com Área Interna aberta → bloqueado | A preencher |
| 2 | Fechamento sem bloqueadores → permitido | A preencher |
| 3 | Cancelamento com Área Interna aberta → bloqueado | A preencher |
| 4 | Cancelamento sem bloqueadores → permitido | A preencher |
| 5 | Update sem fechamento/cancelamento → sem verificação | A preencher |
| 6 | Bulk: apenas Cases fechando são verificados | A preencher |
| 7 | Standard AP com BloqueiaFechamento=false → sem bloqueio | A preencher |
| 8 | Múltiplos bloqueadores → 1 erro por Case | A preencher |

## 15. Resultado do dry-run

**Deploy ID:** `0Afbe00000AA0fJCAT`  
**Status:** Succeeded (34.67s)  
**Testes:** 12/12 passando — 0 falhas  
**Cobertura:** CaseTriggerHandler 96% (linha 36 não coberta)  
**Quick Deploy:** `sf project deploy quick --job-id 0Afbe00000AA0fJCAT --target-org WILSON_SERVICE`

| Teste | Status |
|---|---|
| CaseTriggerHandlerTest.testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen | ✅ PASS |
| CaseTriggerHandlerTest.testBeforeUpdateNoErrorWhenNoBlockersOnClose | ✅ PASS |
| CaseTriggerHandlerTest.testBeforeUpdateBlocksCancelViaEtapaCancelado | ✅ PASS |
| CaseTriggerHandlerTest.testBeforeUpdateNoErrorWhenNoBlockersOnCancel | ✅ PASS |
| CaseTriggerHandlerTest.testBeforeUpdateNoCheckOnNonClosingUpdate | ✅ PASS |
| CaseTriggerHandlerTest.testBeforeUpdateBulkBlocksOnlyClosingCases | ✅ PASS |
| CaseTriggerHandlerTest.testStandardOrigemDoesNotBlockClosure | ✅ PASS |
| CaseTriggerHandlerTest.testBeforeUpdateMultipleBlockersStillBlocks | ✅ PASS |
| SLACoverageCoreTest.testAreaLifecyclePauseResumeCloseAndBlockCaseClose | ✅ PASS |
| SLACoverageCoreTest.testBatchAndSchedulerAndGuard | ✅ PASS |
| SLACoverageCoreTest.testBusinessHoursResolverErrorBranch | ✅ PASS |
| SLACoverageCoreTest.testRegrasValidationAndSelectorHelper | ✅ PASS |

## 16. UTF-8 sem BOM

Confirmado — ver `evidencias/10_validacao_utf8_sem_bom.md`.

## 17. Ausência de mojibake

Confirmado — ver `evidencias/11_validacao_sem_mojibake.md`.

## 18. Próximo pacote recomendado

Pacote 21 — Orquestração de `EtapaAtendimento__c` ao acionar/concluir Área Interna.
