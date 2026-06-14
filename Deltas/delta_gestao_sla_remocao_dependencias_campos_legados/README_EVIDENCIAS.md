# Pacote 16A — Remoção de Dependências de Campos Legados

## Objetivo

Remover todas as referências de código e metadados aos campos que serão excluídos no Pacote 16B via destructiveChanges:

- `RegrasSLACategorizacao__c.Origem__c`
- `RegrasSLACategorizacao__c.VigenciaInicio__c`
- `RegrasSLACategorizacao__c.VigenciaFim__c`
- `AreaParticipante__c.TipoAtuacao__c`

**IMPORTANTE:** Os campos NÃO foram deletados neste pacote. Apenas referências de código foram removidas.

---

## Deploys realizados

| Deploy | ID | Status | Data | Descrição |
|--------|-----|--------|------|-----------|
| Deploy real 16A | `0Afbe00000A9tXNCAZ` | **Succeeded** | 2026-06-12 | 30 componentes — remoção de dependências |
| Deploy real cabeçalhos | `0Afbe00000A9th3CAB` | **Succeeded** | 2026-06-13 | 16 classes — correção de @last modified by |
| Dry-run ajuste 16A | `0Afbe00000A9u3dCAB` | **Succeeded** | 2026-06-13 | Ajuste mensagem + remoção de código morto |

---

## Escopo de mudanças

### Classes Apex (produção)

| Arquivo | Mudança |
|---------|---------|
| `RegrasSLACompatibilidadeService.cls` | Removidos: `isVigente`, `resolveByOrigemFallback`, `resolveByOrigemFallbackNovo`. `buildKeyNovo` 6→5 parâmetros (removido `origem`). |
| `RegrasSLACategorizacaoHelper.cls` | `buildKey`: removido `r.Origem__c`. Removido `isVigenciaValida`. |
| `RegrasSLACategorizacaoService.cls` | Removido bloco de validação `isVigenciaValida`. |
| `RegrasSLACategorizacaoSelector.cls` | Removidos campos legados de SELECT/WHERE em 4 métodos. `findActiveRules` e `findActiveRulesNovoN3`: assinaturas simplificadas (sem `origens`). |
| `GestaoSLADTO.cls` | Removidos `origem`, `vigenciaInicio`, `vigenciaFim` de `RegraSLAResumo` e `RegraSLARequest`. |
| `GestaoSLAService.cls` | `getRegrasSLA` 7→6 parâmetros (removido `origem`). Removidos campos legados de SELECT/ORDER BY. Removidos constante `ORIGEM_QUALQUER` e método `normalizeOrigem` (código morto — nunca chamado). |
| `GestaoSLAController.cls` | Atualizada chamada a `GestaoSLAService.getRegrasSLA` de 7 para 6 params. |
| `AreaParticipanteSelector.cls` | Removido `AND Origem__c IN :origins` do WHERE. |
| `AreaParticipanteSLAService.cls` | `findRule`: removidos campos legados, simplificado para LIMIT 1. Mensagem de erro corrigida: removida menção a "origem informada". |
| `CategorizacaoSelector.cls` | `getRegrasSlaByCategorizacao`: removidos campos legados de SELECT/ORDER BY. |
| `CategorizacaoService.cls` | Removidas referências a `Origem__c` em `getInitialState`, `toRegraViews`, `saveRegrasSla`. |
| `CaseMilestoneTriggerTimeCalculator.cls` | `resolveTempoRegra`: reescrito para usar `ESCOPO_ATENDIMENTO` (constantes `ESCOPO_GLOBAL`/`ESCOPO_POR_CATEGORIZACAO` foram removidas no Pacote 15D). |

### LWC

| Arquivo | Mudança |
|---------|---------|
| `gestaoSLAWorkspace.js` | Removidas 11 importações de labels legados (`ruleColOrigin`, `ruleColValidity`, `ruleScopeGlobal`, `ruleScopeByCategory`, `ruleScopeByInternalArea`, `ruleFilterOriginAll`, `validityOpen`, `validityNoStart`, `validityNoEnd`, `validityUntil`, `errorRuleValidityEndBeforeStart`). |

### Metadados

| Arquivo | Mudança |
|---------|---------|
| `Admin.profile-meta.xml` | Removidas `<fieldPermissions>` de: `AreaParticipante__c.TipoAtuacao__c`, `RegrasSLACategorizacao__c.Origem__c`, `RegrasSLACategorizacao__c.VigenciaFim__c`, `RegrasSLACategorizacao__c.VigenciaInicio__c`. |
| `CentroLogistico.recordType-meta.xml` | Removido bloco `<picklistValues>` de `TipoAtuacao__c`. |
| `Rebocadores.recordType-meta.xml` | Removido bloco `<picklistValues>` de `TipoAtuacao__c`. |
| `TeconRioGrande.recordType-meta.xml` | Removido bloco `<picklistValues>` de `TipoAtuacao__c`. |
| `TeconSalvador.recordType-meta.xml` | Removido bloco `<picklistValues>` de `TipoAtuacao__c`. |

### Classes de Teste

| Arquivo | Mudança |
|---------|---------|
| `RegrasSLACompatibilidadeServiceTest.cls` | `createRegra` 3 params; removido `testVigenciaAtivaEInativa`; substituídos testes de fallback de origem. |
| `RegrasSLACategorizacaoHelperTest.cls` | Constantes atualizadas (`ESCOPO_ATENDIMENTO`/`ESCOPO_AREA_INTERNA`), removido `Origem__c`. |
| `RegrasSLACategorizacaoSelectorTest.cls` | Assinaturas de chamada atualizadas, removidos campos legados de dados de teste. |
| `RegrasSLACategorizacaoServiceTest.cls` | `novoBase` sem campos legados; removidos testes de escopo global e vigência inválida. |
| `CaseMilestoneTriggerTimeCalculatorTest.cls` | `createRegra` 7 params, testes reescritos para novos escopos. |
| `AreaParticipanteSLAServiceTest.cls` | `createRegraNova` e `createRegraLegada` sem campos legados; testes renomeados. |
| `AreaParticipanteSLABatchTest.cls` | `createRule` sem `origin`. |
| `CaseAreaParticipantePauseServiceTest.cls` | Removido `Origem__c`, `ESCOPO_POR_AREA_INTERNA` → `ESCOPO_AREA_INTERNA`. |
| `SLACoverageCoreTest.cls` | `createRule` e dados inline sem campos legados; `ESCOPO_POR_AREA_INTERNA` → `ESCOPO_AREA_INTERNA`. |
| `GestaoSLAServiceTest.cls` | `createRegraDetalhada` 6 params (sem `origem`); todas chamadas `getRegrasSLA` de 7→6 params. |
| `CategorizacaoServiceTest.cls` | `Origem__c = 'Qualquer'` e `ESCOPO_GLOBAL` substituídos por campos válidos. |
| `AreaParticipanteTestDataFactory.cls` | Removido `Origem__c = ORIGEM_REGRA_QUALQUER`. |

---

## Evidências

| Arquivo | Conteúdo |
|---------|----------|
| `evidencias/01_inventario_referencias_legadas.md` | Inventário completo — 0 referências funcionais aos campos legados |
| `evidencias/02_confirmacao_sem_uso_funcional.md` | Confirmação por campo da ausência de uso funcional |
| `evidencias/03_confirmacao_campos_preservados.md` | Confirmação de que OrigemSLA__c e TipoAreaParticipante__c não foram alterados |
| `evidencias/04_confirmacao_encoding.md` | UTF-8 sem BOM e ausência de mojibake em todos os arquivos |
| `evidencias/05_dryrun.md` | Dry-run Succeeded — Deploy ID `0Afbe00000A9u3dCAB` |
| `evidencias/06_resultado_testes.md` | 79/80 testes passou (99%) — 1 falha de ambiente pré-existente, sem relação com o pacote |
| `evidencias/07_pendencias_16B.md` | Campos prontos para exclusão física + lista de campos que NÃO devem entrar no 16B |

---

## Resultado dos testes

| Classe | Testes | Pass | Falhas relacionadas ao pacote |
|--------|--------|------|-------------------------------|
| `GestaoSLAServiceTest` | 39 | 38 | 0 (1 falha de ambiente — dados conflitantes na org) |
| `AreaParticipanteSLAServiceTest` | 3 | 3 | 0 |
| `AreaParticipanteSLABatchTest` | 5 | 5 | 0 |
| `RegrasSLACategorizacaoHelperTest` | 3 | 3 | 0 |
| `RegrasSLACategorizacaoSelectorTest` | 3 | 3 | 0 |
| `RegrasSLACategorizacaoServiceTest` | 4 | 4 | 0 |
| `RegrasSLACompatibilidadeServiceTest` | 5 | 5 | 0 |
| `CaseMilestoneTriggerTimeCalculatorTest` | 18 | 18 | 0 |
| **Total** | **80** | **79** | **0** |

---

## Campos preservados (NÃO legados)

- `AreaParticipante__c.OrigemSLA__c` — NÃO tocado
- `AreaParticipante__c.TipoAreaParticipante__c` — campo oficial, NÃO tocado
- `AreaParticipante__c.OrigemAtuacao__c` — NÃO tocado
- `MarcoSLA__c.UsaOrigem__c` — NÃO tocado
- `ParametrosAtendimento__mdt.CanalOrigem__c` — NÃO tocado

---

## Confirmação de escopo

Este pacote **apenas remove dependências** de código e metadados de configuração. Ele:

- NÃO exclui campos fisicamente
- NÃO cria destructiveChanges
- NÃO altera dados
- NÃO altera `AreaParticipante__c.OrigemSLA__c`
- NÃO altera a lógica funcional de Área Participante (apenas corrige mensagem de erro residual)
- Prepara o terreno para o **Pacote 16B** (exclusão física dos 4 campos via destructiveChanges)

---

## Próximo passo (Pacote 16B)

Executar destructiveChanges para deletar os campos:
- `RegrasSLACategorizacao__c.Origem__c`
- `RegrasSLACategorizacao__c.VigenciaInicio__c`
- `RegrasSLACategorizacao__c.VigenciaFim__c`
- `AreaParticipante__c.TipoAtuacao__c`
