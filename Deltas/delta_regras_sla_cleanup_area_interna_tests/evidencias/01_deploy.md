# Evidência 01 — Deploy

**Deploy ID (final):** 0Afbe00000A9xEPCAZ — Succeeded — 47/47 testes (incl. correção vMarco em HelperTest)
**Deploy ID (patch):** 0Afbe00000A9xCnCAJ — Succeeded — 47/47 testes (incl. CategorizacaoServiceTest)
**Deploy ID (inicial):** 0Afbe00000A9x37CAB — Succeeded — 33/33 testes
**Data:** 2026-06-14
**Org:** jduarte@wilsonsons.com.br.service
**Status:** Succeeded
**Componentes:** 6/6 (100%)

## Classes implantadas

| Classe | Tipo | Status |
|--------|------|--------|
| RegrasSLACompatibilidadeServiceTest | ApexClass | Deployed |
| SLACoverageCoreTest | ApexClass | Deployed |
| RegrasSLACategorizacaoSelectorTest | ApexClass | Deployed |
| RegrasSLACategorizacaoHelperTest | ApexClass | Deployed |
| CaseMilestoneTriggerTimeCalculatorTest | ApexClass | Deployed |

## Mudanças por arquivo

### RegrasSLACompatibilidadeServiceTest
- Removido helper `createMarco(Id gestaoId)` (dead code pós-cleanup)
- Removido parâmetro `marcoSlaId` de `createRegra`; removido `MarcoSLA__c = marcoSlaId`
- `testSelectorCompatibilidadeComCamposNovos`: removida variável `marco`; assertion `found.MarcoSLA__c == marco.Id` → `found.MarcoSLA__c == null`
- `testBulkCompatibilidadeSemSoqlEmLoop`: removida variável `marco`; removido `MarcoSLA__c = marco.Id`; filtro `r.MarcoSLA__c == marco.Id` → `r.GestaoSLA__c == gestao.Id`
- `testSelectorLegacyMethodsCoverage`: removida variável `marco`; atualizada chamada `createRegra`

### SLACoverageCoreTest
- Removido helper `createMarco(Id gestaoId)` (dead code pós-cleanup)
- Removido parâmetro `marcoId` de `createRule`; removido `MarcoSLA__c = marcoId`
- `testRegrasValidationAndSelectorHelper`: removida variável `m`; removido `MarcoSLA__c = m.Id` de `dup` e `inactiveDup`
- `testAreaLifecyclePauseResumeCloseAndBlockCaseClose`: removida variável `m`; adicionado `categ.GestaoSLA__c = g.Id; update categ;` (bug fix: findRule() agora requer GestaoSLA__c)
- `testBatchAndSchedulerAndGuard`: removida variável `mBatch`; adicionado `categ.GestaoSLA__c = gBatch.Id; update categ;`

### RegrasSLACategorizacaoSelectorTest
- `testFindAllActiveForCompatibilityReturnsExpectedFields`: removida variável `marco`; removido `MarcoSLA__c = marco.Id`; assertion `found.MarcoSLA__c == marco.Id` → `found.MarcoSLA__c == null`
- `testFindActiveRulesAndByMarcoAndByHash`: removida variável `marco`; removido `MarcoSLA__c = marco.Id` das 2 regras inline
- `testFindActiveRulesNovoN3Coverage`: removido `MarcoSLA__c = marco.Id` da regra; assertion `rows.size() == 1` → `rows.size() == 0` (regras Area Interna sem MarcoSLA não são encontradas por findActiveRulesNovoN3)

### RegrasSLACategorizacaoHelperTest (final)
- `testBuildKeyNovoMudaComCamposDaChave`: removida variação `vMarco` que clonava `base` (AREA_INTERNA) e definia `MarcoSLA__c = m2.Id`. Substituída por par dedicado `baseAtendimento` (ESCOPO_ATENDIMENTO, null marco) + `vMarco` (ESCOPO_ATENDIMENTO, marco = m2.Id). Nenhum registro Area Interna com MarcoSLA__c criado, nem em memória.

### CategorizacaoServiceTest (patch)
- `testGetRegrasSlaByCategorizacaoReturnsRows`: removido bloco `MarcoSLA__c marco = new MarcoSLA__c(...)` + `insert marco`; removido `MarcoSLA__c = marco.Id` da regra
- `testSaveDeletesExistingRegrasWhenRequestListIsEmpty`: removido bloco `MarcoSLA__c marco2 = new MarcoSLA__c(...)` + `insert marco2`; removido `MarcoSLA__c = marco2.Id` do insert inline

### RegrasSLACategorizacaoHelperTest
- `testBuildKeyNovoMudaComCamposDaChave`: removida variável `m1`; removido `MarcoSLA__c = m1.Id` de `base` (Area Interna — correto sem MarcoSLA__c)

### CaseMilestoneTriggerTimeCalculatorTest
- `testAtendimentoN3MacroNaoUsaRegraAreaInterna`: chamada `createRegra` com ESCOPO_AREA_INTERNA alterada de `marco.Id` → `null` no parâmetro marcoSlaId
