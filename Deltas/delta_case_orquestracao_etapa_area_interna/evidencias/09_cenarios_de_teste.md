# 09 - Cenários de Teste — Package 21

## Classe: AreaParticipanteServiceTest

### Novos testes (Pacote 21)

| # | Método | Cenário | Critério de aceite |
|---|---|---|---|
| 1 | `testAddParticipationSetsEtapaAguardandoAreaInterna` | Case em 'Em Atendimento' → addParticipation → etapa muda para 'Aguardando Área Interna' | `EtapaAtendimento__c = 'Aguardando Área Interna'` |
| 2 | `testAddParticipationDoesNotChangeEtapaForCancelledCase` | Case em 'Cancelado' → addParticipation → etapa NÃO muda | `EtapaAtendimento__c = 'Cancelado'` (sem alteração) |
| 3 | `testCloseLastCustomInternaMovesEtapaToPreparandoRetorno` | addParticipation + closeParticipation (única AP) → etapa vai para 'Preparando Retorno ao Cliente' | `EtapaAtendimento__c = 'Preparando Retorno ao Cliente'`, `etapaAtualizada = true` |
| 4 | `testCloseWithOtherOpenCustomInternaKeepsEtapa` | 2 APs abertas → close 1ª → etapa permanece 'Aguardando Área Interna' | `EtapaAtendimento__c = 'Aguardando Área Interna'`, `etapaAtualizada = false` |
| 5 | `testCloseWithStandardOnlyRemainingMovesEtapa` | 1 Custom + 1 Standard → close Custom → Standard não conta → 'Preparando Retorno ao Cliente' | `EtapaAtendimento__c = 'Preparando Retorno ao Cliente'` |
| 6 | `testCloseDoesNotUpdateEtapaForTerminalCase` | Case 'Cancelado' → addParticipation + closeParticipation → etapa NÃO muda | `EtapaAtendimento__c = 'Cancelado'`, `etapaAtualizada = false` |

### Testes existentes (regressão)

| Método | Status |
|---|---|
| `testGetPanelDataWithoutAreas` | ✅ PASS |
| `testGetPanelDataWithOpenAndOverdue` | ✅ PASS |
| `testCloseParticipationSyncsCase` | ✅ PASS |
| `testCloseLastParticipationUpdatesEtapa` | ✅ PASS |
| `testCloseParticipationRequiresFields` | ✅ PASS |
| `testAddParticipationRequiresSlaRule` | ✅ PASS |
| `testAddParticipationCriaCamposCorretos` | ✅ PASS |
| `testHelperMultipicklist` | ✅ PASS |

### Testes SLACoverageCore (regressão)

| Método | Status |
|---|---|
| `testAreaLifecyclePauseResumeCloseAndBlockCaseClose` | ✅ PASS |
| `testBatchAndSchedulerAndGuard` | ✅ PASS |
| `testBusinessHoursResolverErrorBranch` | ✅ PASS |
| `testRegrasValidationAndSelectorHelper` | ✅ PASS |

### Cobertura de requisitos funcionais

| Requisito | Teste cobrindo |
|---|---|
| addParticipation move Case para 'Aguardando Área Interna' | #1 |
| addParticipation não altera Case terminal | #2 |
| close última Custom Interna → 'Preparando Retorno ao Cliente' | #3 |
| close com outra Custom Interna aberta → sem mudança de etapa | #4 |
| Standard não conta como "aberta" | #5 |
| Case terminal não tem etapa alterada por close | #6 |
| Sem SeeAllData=true | Todos ✅ |
| Sem System.assert | Todos ✅ (usam Assert.areEqual) |
| Sem hardcoded Id | Todos ✅ |
| Campos removidos no 16B não usados | Todos ✅ |
