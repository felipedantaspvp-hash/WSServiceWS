# 01 - Inventário de Automação de Case

## Flows de Case encontrados

| Flow | Objeto | Trigger | Evento | Finalidade |
|---|---|---|---|---|
| Case_EntitlementAutoAssignment | Case | Record-Triggered | Before Save — Create only | Atribui EntitlementId automaticamente por UnidadeNegocio__c |
| Route_from_Will | Messaging | RoutingFlow | — | Roteamento de mensagens (não relacionado) |
| Route_to_Will_Smoke | Messaging | RoutingFlow | — | Roteamento de mensagens (não relacionado) |

**Nenhum Flow de Case para fechamento, cancelamento, validação de status ou orquestração de participações encontrado.**

## Triggers de Case encontradas

| Trigger | Eventos | Handler |
|---|---|---|
| CaseTrigger | before insert, before update, after update | CaseTriggerHandler |

## Handler de Case existente — CaseTriggerHandler.cls

| Método | Finalidade |
|---|---|
| `beforeInsert` | Placeholder vazio |
| `beforeUpdate` | **Bloqueia fechamento** (`IsClosed = false → true`) quando existir AreaParticipante__c Interna aberta — lógica parcialmente implementada |
| `afterUpdate` | Chama `CaseAreaParticipantePauseService.handleEtapaChanges` e `CaseMilestoneMacroService.completeByStageTransition` |

## Classes de Case relacionadas ao fechamento/cancelamento

| Classe | Finalidade |
|---|---|
| `CaseClosureSurveyService` | Fecha o Case via UI; define `CLOSED_STATUS = 'Fechado'` |
| `CaseClosureSurveyController` | Controller AuraEnabled da tela de encerramento |
| `CaseMilestoneMacroService` | Fecha milestones ao detectar `IsClosed = true` ou `EtapaAtendimento__c = 'Cancelado'` |
| `CaseAreaParticipantePauseService` | Pausa/retoma AreaParticipante ao mudar `EtapaAtendimento__c` |

## Invocable Actions existentes

| Classe | Label | Finalidade |
|---|---|---|
| `CaseSurveyDispatchFlowAction` | "Atendimento - Enviar Survey do Case" | Disparo de survey pós-fechamento via Flow |

## Validação Rules e Process Builder

Nenhuma Validation Rule ou Process Builder encontrado relacionado ao bloqueio de fechamento.

## Conclusão do inventário

- **Trigger Handler oficial para Case já existe**: `CaseTriggerHandler`
- O bloqueio de fechamento já estava **parcialmente implementado** (apenas `IsClosed = false → true`)
- **Gaps identificados**: cancelamento via `EtapaAtendimento__c = 'Cancelado'` não coberto; filtro `OrigemSLA__c = 'Custom'` ausente; mensagem desatualizada
- Nenhuma automação paralela encontrada para este fim
