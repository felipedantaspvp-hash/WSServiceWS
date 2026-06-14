# Evidência 03 — Validações

**Data:** 2026-06-14

## Validação 1 — Nenhum teste (nos 6 arquivos alvo) cria Area Interna com MarcoSLA__c

| Arquivo | Status |
|---------|--------|
| `RegrasSLACompatibilidadeServiceTest.cls` | `createRegra` sem `MarcoSLA__c`; todos os 3 testes atualizados ✓ |
| `SLACoverageCoreTest.cls` | `createRule` sem `MarcoSLA__c`; `dup` e `inactiveDup` sem `MarcoSLA__c` ✓ |
| `RegrasSLACategorizacaoSelectorTest.cls` | regras inline sem `MarcoSLA__c` nos 3 testes ✓ |
| `RegrasSLACategorizacaoHelperTest.cls` | `base` (AREA_INTERNA) sem `MarcoSLA__c`; `vMarco` usa ESCOPO_ATENDIMENTO ✓ |
| `CaseMilestoneTriggerTimeCalculatorTest.cls` | chamada AREA_INTERNA com `null` marcoSlaId ✓ |
| `CategorizacaoServiceTest.cls` | 2 regras AREA_INTERNA sem `MarcoSLA__c` ✓ |

## Validação 2 — Nenhuma classe de produção alterada

Mudanças exclusivas em 6 classes de teste. Zero alterações em classes sem sufixo `Test`. ✓

## Validação 3 — Nenhuma referência a campos legados 16B

Campos `Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c` não introduzidos. ✓

## Validação 4 — LWC, metadata, Permission Sets intactos

Nenhuma alteração em LWC, metadata, fluxos ou Permission Sets. ✓

## Validação 5 — Package.xml mínimo e sem wildcard

```xml
<types>
    <members>RegrasSLACompatibilidadeServiceTest</members>
    <members>SLACoverageCoreTest</members>
    <members>RegrasSLACategorizacaoSelectorTest</members>
    <members>RegrasSLACategorizacaoHelperTest</members>
    <members>CaseMilestoneTriggerTimeCalculatorTest</members>
    <name>ApexClass</name>
</types>
```
6 membros explícitos. Sem wildcard. ✓

## Validação 6 — UTF-8 sem BOM

Arquivos Apex puro (ASCII/UTF-8). Nenhum caractere especial adicionado. ✓

## Validação 7 — Atendimento mantém MarcoSLA__c

| Teste | Escopo | MarcoSLA__c |
|-------|--------|-------------|
| `testBuildKeyNovoNaoIncluiPrioridade` | ESCOPO_ATENDIMENTO | marco.Id ✓ |
| `testBuildKeyEscopo` | ESCOPO_ATENDIMENTO | marco.Id ✓ |
| `testBuildKeyNovoMudaComCamposDaChave` → `baseAtendimento`/`vMarco` | ESCOPO_ATENDIMENTO | null / m2.Id ✓ |
| `assertMarcoRegraSla` (CaseMilestone) | ESCOPO_ATENDIMENTO | marco.Id ✓ |
| `testAtendimentoN3MacroNaoUsaRegraAreaInterna` — ATENDIMENTO | ESCOPO_ATENDIMENTO | marco.Id ✓ |

## Validação 8 — RegrasSLACategorizacaoHelperTest: sem Area Interna + MarcoSLA__c nem em memória

`testBuildKeyNovoMudaComCamposDaChave`:
- `base` → ESCOPO_AREA_INTERNA, MarcoSLA__c = null ✓
- `vMarco` → clone de `baseAtendimento` (ESCOPO_ATENDIMENTO), MarcoSLA__c = m2.Id ✓
- Nenhum clone de `base` recebe MarcoSLA__c preenchido ✓

Testes que continuam usando ATENDIMENTO + MarcoSLA__c (corretos, sem alteração):
| Teste | Escopo | MarcoSLA__c |
|-------|--------|-------------|
| `testBuildKeyNovoNaoIncluiPrioridade` | ESCOPO_ATENDIMENTO | marco.Id ✓ |
| `testBuildKeyEscopo` | ESCOPO_ATENDIMENTO | marco.Id ✓ |
| `testBuildKeyNovoMudaComCamposDaChave` → `baseAtendimento`/`vMarco` | ESCOPO_ATENDIMENTO | null / m2.Id ✓ |

## Validação 9 — CategorizacaoServiceTest

| Método | Antes | Depois |
|--------|-------|--------|
| `testGetRegrasSlaByCategorizacaoReturnsRows` | AREA_INTERNA + `MarcoSLA__c = marco.Id` | AREA_INTERNA, `MarcoSLA__c` null ✓ |
| `testSaveDeletesExistingRegrasWhenRequestListIsEmpty` | AREA_INTERNA + `MarcoSLA__c = marco2.Id` | AREA_INTERNA, `MarcoSLA__c` null ✓ |

Deploy patch `0Afbe00000A9xCnCAJ` Succeeded. 47/47 testes.
