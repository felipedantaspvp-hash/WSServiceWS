# 09 - Validação de Testes

## Classe de teste: CaseTriggerHandlerTest.cls

### Cenários implementados

| # | Método | Cenário | Resultado esperado |
|---|---|---|---|
| 1 | `testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen` | Fechamento (`IsClosed = false → true`) com 1 bloqueador injetado | `hasErrors() = true`, 1 erro, mensagem contém "áreas internas abertas" |
| 2 | `testBeforeUpdateNoErrorWhenNoBlockersOnClose` | Fechamento sem bloqueadores (SOQL com ID fictício → 0 registros) | `hasErrors() = false` |
| 3 | `testBeforeUpdateBlocksCancelViaEtapaCancelado` | Cancelamento (`EtapaAtendimento__c → 'Cancelado'`) com bloqueador | `hasErrors() = true`, mensagem contém "áreas internas abertas" |
| 4 | `testBeforeUpdateNoErrorWhenNoBlockersOnCancel` | Cancelamento sem bloqueadores | `hasErrors() = false` |
| 5 | `testBeforeUpdateNoCheckOnNonClosingUpdate` | Update sem transição de fechamento/cancelamento | `hasErrors() = false` (retorno antecipado) |
| 6 | `testBeforeUpdateBulkBlocksOnlyClosingCases` | Bulk: 1 Case fechando (com bloqueador) + 1 Case atualizando etapa | Case1 com erro, Case2 sem erro |
| 7 | `testStandardOrigemDoesNotBlockClosure` | Registro Standard real inserido; SOQL roda | `hasErrors() = false` (Standard excluído pela query) |
| 8 | `testBeforeUpdateMultipleBlockersStillBlocks` | 3 bloqueadores para 1 Case | `hasErrors() = true`, exatamente 1 erro por Case |

### Cobertura dos requisitos funcionais

| Requisito do prompt | Teste cobrindo |
|---|---|
| Case com Área Interna aberta não pode ser fechado | #1 |
| Case com Área Interna aberta não pode ser cancelado | #3 |
| Case com Área Interna concluída pode ser fechado | #2 (sem bloqueadores = concluída/inexistente) |
| Case com apenas registros Standard pode ser fechado | #7 |
| Case com OrigemSLA__c = Standard não bloqueia | #7 |
| Case com múltiplas áreas abertas bloqueia | #8 |
| Bulk update de múltiplos Cases | #6 |
| Mensagem funcional correta | #1, #3 |
| Nenhum teste usa campos removidos no 16B | Todos os testes ✅ |
| Sem SeeAllData=true | Todos os testes ✅ |
| Sem System.assert | Todos os testes ✅ (usam Assert.areEqual / Assert.isTrue) |
| Sem hardcoded Id | Todos usam `makeFakeCaseId(n)` via `Schema.SObjectType.Case.getKeyPrefix()` |

### Resultado do dry-run

Deploy ID: `0Afbe00000AA0fJCAT` — **Dry-run Succeeded** (34.67s)

| Teste | Resultado | Tempo |
|---|---|---|
| CaseTriggerHandlerTest.testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen | ✅ PASS | 90ms |
| CaseTriggerHandlerTest.testBeforeUpdateNoErrorWhenNoBlockersOnClose | ✅ PASS | 113ms |
| CaseTriggerHandlerTest.testBeforeUpdateBlocksCancelViaEtapaCancelado | ✅ PASS | 235ms |
| CaseTriggerHandlerTest.testBeforeUpdateNoErrorWhenNoBlockersOnCancel | ✅ PASS | 145ms |
| CaseTriggerHandlerTest.testBeforeUpdateNoCheckOnNonClosingUpdate | ✅ PASS | 100ms |
| CaseTriggerHandlerTest.testBeforeUpdateBulkBlocksOnlyClosingCases | ✅ PASS | 92ms |
| CaseTriggerHandlerTest.testStandardOrigemDoesNotBlockClosure | ✅ PASS | 1037ms |
| CaseTriggerHandlerTest.testBeforeUpdateMultipleBlockersStillBlocks | ✅ PASS | 96ms |
| SLACoverageCoreTest.testAreaLifecyclePauseResumeCloseAndBlockCaseClose | ✅ PASS | 2795ms |
| SLACoverageCoreTest.testBatchAndSchedulerAndGuard | ✅ PASS | 1591ms |
| SLACoverageCoreTest.testBusinessHoursResolverErrorBranch | ✅ PASS | 114ms |
| SLACoverageCoreTest.testRegrasValidationAndSelectorHelper | ✅ PASS | 604ms |

**Total: 12/12 passando — 0 falhas**

**Cobertura: CaseTriggerHandler 96%**
