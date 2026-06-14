# Evidência 03 — Validações

**Data:** 2026-06-14

## Validação 1 — Nenhuma referência a createRegraLegada

Busca em `force-app/` por `createRegraLegada`: **0 resultados**

## Validação 2 — Nenhum teste cria Area Interna com MarcoSLA__c (pacote)

Nos 4 arquivos do pacote AreaParticipante:
- `AreaParticipanteSLAServiceTest.cls` — `createRegraLegada` removido; `createRegraNova` sem `MarcoSLA__c` ✓
- `AreaParticipanteTestDataFactory.cls` — `createSlaRule` sem `MarcoSLA__c` ✓
- `AreaParticipanteSLABatchTest.cls` — `createRule` sem `MarcoSLA__c` ✓
- `CaseAreaParticipantePauseServiceTest.cls` — bloco `MarcoSLA__c m = new MarcoSLA__c(...)` e `MarcoSLA__c = m.Id` removidos ✓

## Validação 3 — Nenhuma referência a campos legados

Busca por `Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c` em `*Test*.cls`: **0 resultados**

## Validação 4 — Campos legados 16B

Campos excluídos no Pacote 16B (`Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c`) não foram recriados.

## Validação 5 — UTF-8 sem BOM / sem mojibake

Arquivos editados são Apex puro (ASCII/UTF-8). Nenhum caractere especial adicionado.

## Validação 6 — Package.xml mínimo e sem wildcard

```xml
<types>
    <members>AreaParticipanteSLAServiceTest</members>
    <members>AreaParticipanteTestDataFactory</members>
    <members>AreaParticipanteSLABatchTest</members>
    <members>CaseAreaParticipantePauseServiceTest</members>
    <name>ApexClass</name>
</types>
```
4 membros explícitos. Sem wildcard. ✓

## Validação 7 — Sem alteração funcional

Nenhuma classe de produção foi alterada. Mudanças exclusivas em 4 classes de teste.

---

## Referência fora do escopo

Os arquivos abaixo também têm `ESCOPO_AREA_INTERNA + MarcoSLA__c` mas são de **domínios diferentes** do pacote AreaParticipante e estão fora do escopo deste cleanup:

| Arquivo | Domínio | Observação |
|---------|---------|------------|
| `RegrasSLACompatibilidadeServiceTest.cls` | RegrasSLACompatibilidade | MarcoSLA__c intencional para testes de compatibilidade |
| `SLACoverageCoreTest.cls` | SLACoverage | MarcoSLA__c intencional para cobertura SLA |
| `RegrasSLACategorizacaoSelectorTest.cls` | RegrasSLACategorizacaoSelector | MarcoSLA__c intencional para testes de seleção |
| `RegrasSLACategorizacaoHelperTest.cls` | RegrasSLACategorizacaoHelper | MarcoSLA__c intencional para testes de helper |
| `CaseMilestoneTriggerTimeCalculatorTest.cls` | CaseMilestoneTriggerTimeCalculator | `testAtendimentoN3MacroNaoUsaRegraAreaInterna` verifica que calculador ignora regras de Area Interna |

Esses arquivos podem ser limpos em um pacote dedicado se o escopo for ampliado.
