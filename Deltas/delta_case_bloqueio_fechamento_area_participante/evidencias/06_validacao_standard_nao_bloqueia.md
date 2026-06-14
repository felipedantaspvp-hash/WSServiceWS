# 06 - Validação: Standard Não Bloqueia

## Confirmação por design

Registros `AreaParticipante__c` com `OrigemSLA__c = 'Standard'` (espelhos de CaseMilestone criados pelo Pacote 19) são excluídos do bloqueio por dois mecanismos independentes:

### Mecanismo 1 — Flag BloqueiaFechamentoCaso__c

Em `AreaParticipanteMilestoneSyncService.buildRecord()`:
```apex
record.BloqueiaFechamentoCaso__c = false;  // always false for Standard mirrors
```

Standard records sempre têm `BloqueiaFechamentoCaso__c = false`. A query filtra `BloqueiaFechamentoCaso__c = true`, então Standard records nunca são encontrados.

### Mecanismo 2 — Filtro OrigemSLA__c = 'Custom' (Pacote 20)

A query agora inclui explicitamente:
```sql
AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM
```

Mesmo que um registro Standard tivesse `BloqueiaFechamentoCaso__c = true` (impossível pelo design atual), o filtro de `OrigemSLA__c` o excluiria.

## Teste automatizado

`CaseTriggerHandlerTest.testStandardOrigemDoesNotBlockClosure`:
- Insere Case real
- Insere AreaParticipante__c com `OrigemSLA__c = 'Standard'` e `BloqueiaFechamentoCaso__c = false`
- Executa `beforeUpdate` com transição `IsClosed = false → true`
- SOQL roda contra banco real
- Verifica `Assert.areEqual(false, newCase.hasErrors())` — sem erro

## Confirmação

Standard records de Milestone (Pacote 19) não bloqueiam o fechamento do Case. Confirmado por design (dupla proteção) e por teste automatizado.
