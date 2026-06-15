# Pacote 23 - UX de pausa e retomada de Area Participante

## Objetivo

Expor no LWC `caseAreasParticipantesPanel` as acoes de pausar e retomar Area Interna manual/Custom, reutilizando os metodos Apex criados no Pacote 22.

## Arquivos alterados

- `force-app/main/default/classes/AreaParticipanteDTO.cls`
- `force-app/main/default/classes/AreaParticipanteService.cls`
- `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.js`
- `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.html`
- `force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.css`
- `delta_area_participante_pausa_retomada_ux/tests/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.test.js`

## Metodos Apex reutilizados

- `AreaParticipanteController.pauseParticipation(request)`
- `AreaParticipanteController.resumeParticipation(request)`

Assinatura real usada pelo LWC: `{ request: { areaParticipanteId } }`.

## Campos e flags usados pelo LWC

- `canPause`
- `canResume`
- `canManage`

O DTO foi alterado neste pacote para expor `canPause` e `canResume`. Essas flags sao calculadas no backend a partir de `TipoAreaParticipante__c`, `OrigemSLA__c`, status terminal e estado de pausa. O LWC apenas renderiza as acoes.

## Regra de exibicao

- `Pausar`: exibido quando `item.canPause = true`.
- `Retomar`: exibido quando `item.canResume = true`.

## Confirmacoes de escopo

- Standard nao exibe acoes de pausa/retomada.
- Nenhuma regra de SLA foi alterada.
- Nao houve alteracao em `AreaParticipanteSLAService`, CaseMilestone, Entitlement Process, Flow, Trigger, campos ou Permission Sets.
- Nao foi criada regra de negocio no frontend; o LWC apenas controla renderizacao e chama o backend.

## Testes executados

- `node --check force-app/main/default/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.js`: passou.
- `node --check delta_area_participante_pausa_retomada_ux/tests/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.test.js`: passou.
- Jest LWC: criado, mas nao executado localmente porque `node_modules` nao existe e `sfdx-lwc-jest` nao esta instalado/cacheado.

O arquivo Jest foi incluido no delta como artefato de apoio em `tests/lwc/caseAreasParticipantesPanel/caseAreasParticipantesPanel.test.js`.

## Dry-run

- Org: `WILSON_SERVICE`
- Job: `0Afbe00000AAAd3CAH`
- Status: `Succeeded`
- Test level: `RunSpecifiedTests`
- Testes: `AreaParticipanteServiceTest`, `AreaParticipanteControllerTest`
- Resultado: 40/40 testes, 0 falhas
- Componentes: 2 `ApexClass` + 1 `LightningComponentBundle`

## Pendencias

- Executar Jest apos `npm install`/restauracao de dependencias locais.
