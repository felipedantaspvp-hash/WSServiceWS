# Evidência 08 — Idempotência e Preservação de Registros Custom

**Data:** 2026-06-14

## Idempotência via CaseMilestoneId__c

O campo `CaseMilestoneId__c` (Text 18) armazena o Id do CaseMilestone como string.
Em `syncInternal`, antes de qualquer DML:

```apex
Map<String, AreaParticipante__c> existingByMilestoneId = ...
    WHERE CaseMilestoneId__c IN :cmIdStrings
```

Decisão:
- Registro encontrado → `buildRecord(cm, existing)` → `toUpdate`
- Registro não encontrado → `buildRecord(cm, null)` → `toInsert`

Segunda execução com o mesmo milestone: `existingByMilestoneId` já contém o registro → update path.
Resultado: **nunca dois registros para o mesmo CaseMilestone**.

## Preservação de registros Custom

Ao encontrar um registro existente com `OrigemSLA__c = 'Custom'`:

```apex
if (existing != null && ORIGEM_CUSTOM.equals(existing.OrigemSLA__c)) continue;
```

O loop pula sem criar registro algum. O Custom não é sobrescrito e não é criado um novo Standard.

## Cenários cobertos

| Cenário | Resultado |
|---------|-----------|
| Nenhum registro com CaseMilestoneId__c | Insert do espelho Standard |
| Registro Standard existente | Update do espelho Standard |
| Registro Custom existente | Skip — Custom preservado |
| Mesma chamada repetida (idempotência) | Update na segunda vez, mesmo resultado final |
