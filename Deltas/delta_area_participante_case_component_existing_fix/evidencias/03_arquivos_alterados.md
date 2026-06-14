# Evidência 03 — Arquivos alterados do componente existente

**Data:** 2026-06-14

## Arquivos modificados

| Arquivo | Operação | Detalhe da mudança |
|---------|----------|--------------------|
| `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.js` | Modificado | Adicionado label `refresh` (PT+EN), getter `canManage`, método `handleRefresh` |
| `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.html` | Modificado | Botão refresh adicionado; botão Adicionar gateado por `canManage` |
| `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.js-meta.xml` | Modificado | Adicionado `<masterLabel>Áreas Participantes SLA</masterLabel>` |
| `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.css` | Não alterado | Preservado integralmente |

## Arquivo excluído (artefato descartado)

| Arquivo | Operação |
|---------|----------|
| `force-app/main/default/lwc/caseAreaParticipantePanel/` (4 arquivos) | `git rm -r` — removido do source e do staging |

## Nenhum outro arquivo alterado

- Sem alterações em Apex, Flow, Trigger, objetos, campos, RecordTypes ou Permission Sets.
- Sem alterações na FlexiPage `LP_Atendimento_Salvador`.
- Sem `destructiveChanges`.
