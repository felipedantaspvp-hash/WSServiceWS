# README Evidências — Delta: RegrasSLA Cleanup Area Interna Tests

**Pacote:** Cleanup RegrasSLA
**Branch:** feat/codex/retrieve-entitlement-atendimento-salvador
**Data:** 2026-06-14

## Resumo

Cleanup transversal de 6 classes de teste:
- Removido `MarcoSLA__c` de regras `Area Interna` em todos os testes alvo
- Removido helper `createMarco` de `RegrasSLACompatibilidadeServiceTest` e `SLACoverageCoreTest` (dead code pós-cleanup)
- Corrigido `SLACoverageCoreTest` para definir `Categorizacao.GestaoSLA__c` antes de inserir `AreaParticipante__c` (bug latente pós-17A v2)
- Ajustado `testFindActiveRulesNovoN3Coverage` para refletir nova realidade: regras Area Interna sem MarcoSLA__c retornam 0 via `findActiveRulesNovoN3` (método legado)
- Corrigido `RegrasSLACategorizacaoHelperTest.testBuildKeyNovoMudaComCamposDaChave`: variação `vMarco` reescrita com ESCOPO_ATENDIMENTO, eliminando a última ocorrência de Area Interna + MarcoSLA__c mesmo em memória
- Removido `MarcoSLA__c` de 2 regras Area Interna em `CategorizacaoServiceTest`

## Deploy

| Deploy ID | Resultado |
|-----------|-----------|
| 0Afbe00000A9xEPCAZ (final) | Succeeded |
| 0Afbe00000A9xCnCAJ (patch) | Succeeded |
| 0Afbe00000A9x37CAB (inicial) | Succeeded |

## Testes

| Deploy | Testes | Resultado |
|--------|--------|-----------|
| 0Afbe00000A9xEPCAZ (final) | 47/47 | 100% Pass |
| 0Afbe00000A9xCnCAJ (patch) | 47/47 | 100% Pass |
| 0Afbe00000A9x37CAB (inicial) | 33/33 | 100% Pass |

## Índice de Evidências

| Arquivo | Conteúdo |
|---------|----------|
| `01_deploy.md` | Deploy IDs, 6 classes implantadas, mudanças |
| `02_testes.md` | 47 testes, 100% pass |
| `03_validacoes.md` | Todas as validações |
