# 06 - Testes

## Criados

- `force-app/main/default/lwc/caseAreasParticipantesPanel/__tests__/caseAreasParticipantesPanel.test.js`
- `delta_area_participante_pausa_retomada_ux/tests/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.test.js` (artefato de apoio no delta)

Cobertura prevista:

- Exibicao de `Pausar` para Area Interna Custom aberta.
- Exibicao de `Retomar` para Area Interna Custom pausada.
- Ausencia de botoes para Standard.
- Chamada do Apex de pausa.
- Chamada do Apex de retomada.
- Tratamento de erro.

## Executados

- `node --check force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.js`: passou.
- `node --check force-app/main/default/lwc/caseAreasParticipantesPanel/__tests__/caseAreasParticipantesPanel.test.js`: passou.
- Dry-run `0Afbe00000AAAd3CAH`: `Succeeded`, `RunSpecifiedTests`, 40/40 testes, 0 falhas.

## Limitacao local

`npm run test:unit` e `npx --no-install sfdx-lwc-jest` nao executaram porque `node_modules` nao existe e `sfdx-lwc-jest` nao esta instalado/cacheado no workspace.
