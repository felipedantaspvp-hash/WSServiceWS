# 10 - Resultado do Dry-Run (v2 — pós-ajustes)

## Deploy ID

`0Afbe00000AA3rhCAD`

## Status

**Succeeded** (dry-run) — 3 componentes

## Componentes

| Componente | Tipo | Status |
|---|---|---|
| AreaParticipanteSelector | ApexClass | ✅ Deployed |
| AreaParticipanteService | ApexClass | ✅ Deployed |
| AreaParticipanteServiceTest | ApexClass | ✅ Deployed |

## Testes

**20/20 passando — 0 falhas**

| Teste | Resultado | Tempo |
|---|---|---|
| AreaParticipanteServiceTest.testAddParticipationCriaCamposCorretos | ✅ PASS | 4133ms |
| AreaParticipanteServiceTest.testAddParticipationDoesNotChangeEtapaForCancelledCase | ✅ PASS | 1531ms |
| AreaParticipanteServiceTest.testAddParticipationRequiresSlaRule | ✅ PASS | 494ms |
| AreaParticipanteServiceTest.testAddParticipationSetsEtapaAguardandoAreaInterna | ✅ PASS | 1406ms |
| AreaParticipanteServiceTest.testCloseDoesNotUpdateEtapaForTerminalCase | ✅ PASS | 1823ms |
| AreaParticipanteServiceTest.testCloseDoesNotUpdateEtapaWhenCaseIsClosed | ✅ PASS | 1680ms |
| AreaParticipanteServiceTest.testCloseLastCustomInternaMovesEtapaToPreparandoRetorno | ✅ PASS | 1627ms |
| AreaParticipanteServiceTest.testCloseLastParticipationUpdatesEtapa | ✅ PASS | 1692ms |
| AreaParticipanteServiceTest.testCloseParticipationRequiresFields | ✅ PASS | 1394ms |
| AreaParticipanteServiceTest.testCloseParticipationSyncsCase | ✅ PASS | 1779ms |
| AreaParticipanteServiceTest.testCloseStandardApDoesNotUpdateEtapa | ✅ PASS | 1839ms |
| AreaParticipanteServiceTest.testCloseWithOtherOpenCustomInternaKeepsEtapa | ✅ PASS | 1994ms |
| AreaParticipanteServiceTest.testCloseWithStandardOnlyRemainingMovesEtapa | ✅ PASS | 1802ms |
| AreaParticipanteServiceTest.testGetPanelDataWithOpenAndOverdue | ✅ PASS | 1932ms |
| AreaParticipanteServiceTest.testGetPanelDataWithoutAreas | ✅ PASS | 931ms |
| AreaParticipanteServiceTest.testHelperMultipicklist | ✅ PASS | 140ms |
| SLACoverageCoreTest.testAreaLifecyclePauseResumeCloseAndBlockCaseClose | ✅ PASS | 2790ms |
| SLACoverageCoreTest.testBatchAndSchedulerAndGuard | ✅ PASS | 2600ms |
| SLACoverageCoreTest.testBusinessHoursResolverErrorBranch | ✅ PASS | 178ms |
| SLACoverageCoreTest.testRegrasValidationAndSelectorHelper | ✅ PASS | 719ms |

## Cobertura

| Classe | Cobertura |
|---|---|
| AreaParticipanteSelector | **97%** (33/34 linhas) |
| AreaParticipanteService | **85%** (240/283 linhas) |

## Quick Deploy

```
sf project deploy quick --job-id 0Afbe00000AA3rhCAD --target-org WILSON_SERVICE
```

## Histórico de dry-runs

| Versão | Deploy ID | Resultado | Testes |
|---|---|---|---|
| v1 (inicial) | 0Afbe00000AA2ysCAD | Succeeded | 18/18 |
| v2 (pós-ajustes) | 0Afbe00000AA3rhCAD | Succeeded | 20/20 |
