# 10 - Resultado do Dry-Run

## Deploy ID

`0Afbe00000AA2ysCAD`

## Status

**Succeeded** (dry-run) — 24.0s

## Componentes

| Componente | Tipo | Status |
|---|---|---|
| AreaParticipanteService | ApexClass | ✅ Deployed |
| AreaParticipanteServiceTest | ApexClass | ✅ Deployed |

## Testes

**18/18 passando — 0 falhas**

| Teste | Resultado | Tempo |
|---|---|---|
| AreaParticipanteServiceTest.testAddParticipationCriaCamposCorretos | ✅ PASS | 1938ms |
| AreaParticipanteServiceTest.testAddParticipationDoesNotChangeEtapaForCancelledCase | ✅ PASS | 504ms |
| AreaParticipanteServiceTest.testAddParticipationRequiresSlaRule | ✅ PASS | 194ms |
| AreaParticipanteServiceTest.testAddParticipationSetsEtapaAguardandoAreaInterna | ✅ PASS | 459ms |
| AreaParticipanteServiceTest.testCloseDoesNotUpdateEtapaForTerminalCase | ✅ PASS | 601ms |
| AreaParticipanteServiceTest.testCloseLastCustomInternaMovesEtapaToPreparandoRetorno | ✅ PASS | 560ms |
| AreaParticipanteServiceTest.testCloseLastParticipationUpdatesEtapa | ✅ PASS | 587ms |
| AreaParticipanteServiceTest.testCloseParticipationRequiresFields | ✅ PASS | 468ms |
| AreaParticipanteServiceTest.testCloseParticipationSyncsCase | ✅ PASS | 596ms |
| AreaParticipanteServiceTest.testCloseWithOtherOpenCustomInternaKeepsEtapa | ✅ PASS | 696ms |
| AreaParticipanteServiceTest.testCloseWithStandardOnlyRemainingMovesEtapa | ✅ PASS | 630ms |
| AreaParticipanteServiceTest.testGetPanelDataWithOpenAndOverdue | ✅ PASS | 645ms |
| AreaParticipanteServiceTest.testGetPanelDataWithoutAreas | ✅ PASS | 343ms |
| AreaParticipanteServiceTest.testHelperMultipicklist | ✅ PASS | 54ms |
| SLACoverageCoreTest.testAreaLifecyclePauseResumeCloseAndBlockCaseClose | ✅ PASS | 1017ms |
| SLACoverageCoreTest.testBatchAndSchedulerAndGuard | ✅ PASS | 883ms |
| SLACoverageCoreTest.testBusinessHoursResolverErrorBranch | ✅ PASS | 68ms |
| SLACoverageCoreTest.testRegrasValidationAndSelectorHelper | ✅ PASS | 263ms |

## Cobertura

| Classe | Cobertura |
|---|---|
| AreaParticipanteService | **85%** (237/280 linhas) |

## Quick Deploy

```
sf project deploy quick --job-id 0Afbe00000AA2ysCAD --target-org WILSON_SERVICE
```
