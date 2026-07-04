# 01 - Inventario de automacoes Case/AreaParticipante

## Flows locais analisados

- `Case_EntitlementAutoAssignment.flow-meta.xml`: atribui Entitlement no Case antes da criacao.
- `Route_from_Will.flow-meta.xml`: roteamento Will/Messaging.
- `Route_to_Will_Smoke.flow-meta.xml`: roteamento/smoke Will/Messaging.

## Apex/trigger analisados

- `AreaParticipanteTriggerHandler`: before insert/update chama `AreaParticipanteSLAService`; after insert/update atualiza agregados no Case.
- `CaseTriggerHandler`: bloqueio de fechamento/cancelamento e chamada de `CaseAreaParticipantePauseService` por mudanca de etapa.
- `CaseAreaParticipantePauseService`: pausa/retoma areas internas a partir da etapa do Case `Aguardando Cliente`.

## Conclusao

Nao existe Flow local adequado para pausa/retomada manual de `AreaParticipante__c`. O ciclo de vida operacional ja esta centralizado em Apex Service.
