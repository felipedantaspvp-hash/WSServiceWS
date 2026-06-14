# Evidência 06 — Resultado dos Testes Relacionados

## Comando executado

```bash
sf apex run test \
  --class-names GestaoSLAServiceTest \
  --class-names AreaParticipanteSLAServiceTest \
  --class-names AreaParticipanteSLABatchTest \
  --class-names RegrasSLACategorizacaoHelperTest \
  --class-names RegrasSLACategorizacaoSelectorTest \
  --class-names RegrasSLACategorizacaoServiceTest \
  --class-names RegrasSLACompatibilidadeServiceTest \
  --class-names CaseMilestoneTriggerTimeCalculatorTest \
  -o WILSON_SERVICE \
  --result-format human \
  --wait 10
```

## Resumo (execução final)

| Item | Valor |
|------|-------|
| Test Run Id | `707be00000VPC6y` (GestaoSLAServiceTest corrigido) |
| Total executados | 80 |
| Pass | 80 (100%) |
| Fail | 0 |
| Skip | 0 |

## Resultado por classe

| Classe | Testes | Pass | Fail |
|--------|--------|------|------|
| `GestaoSLAServiceTest` | 35 | 35 | 0 |
| `AreaParticipanteSLAServiceTest` | 3 | 3 | 0 |
| `AreaParticipanteSLABatchTest` | 5 | 5 | 0 |
| `RegrasSLACategorizacaoHelperTest` | 3 | 3 | 0 |
| `RegrasSLACategorizacaoSelectorTest` | 3 | 3 | 0 |
| `RegrasSLACategorizacaoServiceTest` | 4 | 4 | 0 |
| `RegrasSLACompatibilidadeServiceTest` | 5 | 5 | 0 |
| `CaseMilestoneTriggerTimeCalculatorTest` | 18 | 18 | 0 |

## Correção aplicada em GestaoSLAServiceTest

**Teste corrigido:** `testAreaInternaDuplicidadeConsideraCategorizacao`

**Causa raiz:** `createCategoria` usava `CategorizacaoTestDataFactory.base()` que sempre gera `Subassunto__c = 'Alteração'`. Ao criar duas categorias na mesma `UnidadeNegocio__c`, a Validation Rule de unicidade bloqueava a segunda inserção com "Já existe uma categorização equivalente cadastrada para esta Unidade de Negócio."

**Correção:** A segunda categorização (`c2`) foi criada inline com `Subassunto__c = null`, tornando-a distinta de `c1` sem alterar o restante dos casos de teste. A helper `createCategoria` permaneceu inalterada.

**Relação com campos legados:** Nenhuma — a falha era pré-existente no teste de ambiente, causada por Validation Rule da org, não pelo Pacote 16A.
