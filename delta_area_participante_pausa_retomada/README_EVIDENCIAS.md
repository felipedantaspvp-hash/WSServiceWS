# Pacote 22 - Pausa e retomada operacional de Area Interna

## Objetivo

Implementar controle backend de pausa e retomada operacional do SLA de Area Interna manual, afetando somente `AreaParticipante__c` com `TipoAreaParticipante__c = Area Interna` e `OrigemSLA__c = Custom`.

## Arquivos alterados/criados

- `classes/AreaParticipanteController.cls`
- `classes/AreaParticipanteControllerTest.cls`
- `classes/AreaParticipanteDTO.cls`
- `classes/AreaParticipanteSelector.cls`
- `classes/AreaParticipanteService.cls`
- `classes/AreaParticipanteServiceTest.cls`
- `classes/AreaParticipanteSLAService.cls`
- `package.xml`
- `evidencias/*.md`

## Flows analisados

- `Case_EntitlementAutoAssignment.flow-meta.xml`
- `Route_from_Will.flow-meta.xml`
- `Route_to_Will_Smoke.flow-meta.xml`

Nenhum Flow local controla pausa/retomada operacional de `AreaParticipante__c`.

## Services/classes analisados

- `AreaParticipanteService`
- `AreaParticipanteController`
- `AreaParticipanteSelector`
- `AreaParticipanteDTO`
- `AreaParticipanteSLAService`
- `AreaParticipanteSLAHelper`
- `CaseAreaParticipantePauseService`
- `AreaParticipanteTriggerHandler`
- `caseAreasParticipantesPanel`

## Campos encontrados

- `DataHoraInicioPausa__c`
- `TempoPausadoMinutos__c`
- `StatusAtuacaoAnteriorPausa__c`
- `StatusAtuacao__c`
- `StatusSLA__c`
- `DataHoraPrazo__c`
- `TempoConsumidoMinutos__c`
- `TempoRestanteMinutos__c`
- `PercentualDecorrido__c`
- `ViolouSLA__c`

Nao existe `DataHoraFimPausa__c` nem `MotivoPausa__c` no source/org analisado.

## Decisao arquitetural

Service Apex existente. A regra fica no ciclo oficial de `AreaParticipanteService`, com exposicao por `AreaParticipanteController`. Nao foi criado Flow, Trigger, campo, Permission Set, layout ou LWC.

## Criterio de pausa

Pausa permitida somente para Area Interna Custom aberta/em andamento/vencida e nao terminal, desde que `DataHoraInicioPausa__c` esteja vazio e `StatusSLA__c` nao esteja `Pausado`.

## Criterio de retomada

Retomada permitida somente para Area Interna Custom com `DataHoraInicioPausa__c` preenchido. O tempo entre inicio da pausa e retomada e acumulado em `TempoPausadoMinutos__c`; `DataHoraPrazo__c` e estendido pelo mesmo intervalo usando Business Hours quando aplicavel.

## Standard nao afetado

Registros `OrigemSLA__c = Standard` sao rejeitados por validacao funcional antes de qualquer DML.

## Area Interna Custom afetada

Somente registros com `TipoAreaParticipante__c = Area Interna` e `OrigemSLA__c = Custom` passam pelas acoes de pausa/retomada.

## Campos removidos no 16B

Nao foram usados nem recriados: `Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c`.

## Testes executados

Dry-run anterior (Codex) `0Afbe00000AA5NGCA1`: `Succeeded`, 39/39 testes.

Apos ajustes pos-Codex (Claude) `0Afbe00000AA2h8CAD`: `Succeeded`, 40/40 testes (hardcoded Id removido, +1 teste overdue, package.xml 66.0).

## Code Analyzer

Tentado via `sf code-analyzer run`; bloqueado por dependencia local ausente de Python para o engine `flow` e caminhos `.claude/skills` inexistentes no workspace.

## UTF-8 e mojibake

Arquivos criados em UTF-8 sem BOM. Validacao de mojibake executada contra o delta sem ocorrencias.

## Proximo pacote recomendado

Avaliar, em pacote separado, se o painel `caseAreasParticipantesPanel` deve exibir botoes de pausa/retomada e se deve existir `MotivoPausa__c`/historico operacional.
