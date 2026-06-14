# 02 - Inventário do Trigger e Handler de AreaParticipante__c

## AreaParticipanteTrigger

Eventos: `before insert, before update, after insert, after update`

```apex
trigger AreaParticipanteTrigger on AreaParticipante__c (...) {
    if (Trigger.isBefore && Trigger.isInsert) AreaParticipanteTriggerHandler.beforeInsert(Trigger.new);
    if (Trigger.isBefore && Trigger.isUpdate) AreaParticipanteTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    if (Trigger.isAfter && Trigger.isInsert) AreaParticipanteTriggerHandler.afterInsert(Trigger.new);
    if (Trigger.isAfter && Trigger.isUpdate) AreaParticipanteTriggerHandler.afterUpdate(Trigger.new);
}
```

## AreaParticipanteTriggerHandler

```apex
beforeInsert → AreaParticipanteSLAService.beforeSave(newList, null)
beforeUpdate → AreaParticipanteSLAService.beforeSave(newList, oldMap)
             → AreaParticipanteSLAService.closeSLA(newList)
afterInsert  → CaseAreaParticipanteAggregationService.refreshForCases(caseIds)
afterUpdate  → CaseAreaParticipanteAggregationService.refreshForCases(caseIds)
```

## Conclusão

O Trigger e Handler são responsáveis por SLA e aggregation, **não por EtapaAtendimento__c**. A orquestração de etapa é responsabilidade do Service, conforme lógica parcial já existente em `closeParticipation()`.
