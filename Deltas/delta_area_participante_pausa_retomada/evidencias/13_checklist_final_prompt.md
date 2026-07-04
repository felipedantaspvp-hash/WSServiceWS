# 13 - Checklist final do prompt

- [x] Objetivo do pacote atendido.
- [x] Arquitetura Flow-first avaliada.
- [x] Flows existentes analisados.
- [x] Services existentes analisados.
- [x] Decisao entre Flow, Flow + Apex Invocable, Service existente ou Trigger documentada.
- [x] Fora do escopo respeitado.
- [x] Nenhum campo removido no 16B foi usado/recriado.
- [x] Nenhum valor antigo de `EscopoRegra__c` foi usado.
- [x] Regra implementada somente para Area Interna Custom.
- [x] Registros Standard nao sao pausados/retomados.
- [x] Campos novos nao foram criados.
- [x] Testes obrigatorios foram executados.
- [x] `package.xml` minimo e sem wildcard.
- [x] UTF-8 sem BOM.
- [x] Sem mojibake.
- [x] Nenhum artefato extra foi incluido no delta.
- [x] O prompt foi relido antes da finalizacao.

## Ajustes pos-Codex (Claude)

- [x] Hardcoded Id removido (3 ocorrencias substituidas por SOQL real).
- [x] Novo teste de retomada de area vencida adicionado (`testResumeOverdueAreaKeepsVencidoStatus`).
- [x] `package.xml` versao corrigida para `66.0`.
- [x] Novo dry-run executado: Job `0Afbe00000AAAJhCAP`, Succeeded, 40/40 testes (delta sincronizado com force-app, todos hardcoded Ids removidos).
