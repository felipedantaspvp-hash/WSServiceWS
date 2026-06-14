# 07 - Validação: Custom Área Interna Aberta Bloqueia

## Como o registro Custom de Área Interna chega ao estado bloqueante

Em `AreaParticipanteSLAService.beforeSave()`, quando um acionamento de Área Interna é criado/aberto:

```apex
a.OrigemSLA__c = AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM;  // 'Custom'
a.BloqueiaFechamentoCaso__c = true;  // flag de bloqueio
```

E em `AreaParticipanteSLAService.closeSLA()`:
```apex
a.BloqueiaFechamentoCaso__c = false;  // limpo ao concluir/cancelar
```

Ciclo de vida do bloqueio:
1. Área Interna criada → `BloqueiaFechamentoCaso__c = true`, `DataHoraFim__c = null`
2. Área Interna concluída → `BloqueiaFechamentoCaso__c = false`, `DataHoraFim__c = now()`
3. Enquanto no estado 1: Case NÃO pode ser fechado/cancelado

## Query de bloqueio

```sql
WHERE TipoAreaParticipante__c = 'Área Interna'
  AND OrigemSLA__c = 'Custom'
  AND BloqueiaFechamentoCaso__c = true
  AND DataHoraFim__c = null
```

Todos os 4 filtros devem ser `true` simultaneamente para bloquear.

## Testes automatizados

| Cenário | Método de teste |
|---|---|
| Fechamento bloqueado por 1 AP Interna Custom aberta | `testBeforeUpdateBlocksCloseWhenHasInternalAreaOpen` |
| Cancelamento bloqueado por 1 AP Interna Custom aberta | `testBeforeUpdateBlocksCancelViaEtapaCancelado` |
| Múltiplas APs bloqueadoras ainda bloqueiam | `testBeforeUpdateMultipleBlockersStillBlocks` |

Padrão de injeção: `CaseTriggerHandler.injectedBlockersByCase` com contagem > 0 simula o resultado da query.

## Confirmação

Registros Custom de Área Interna com `BloqueiaFechamentoCaso__c = true` e `DataHoraFim__c = null` bloqueiam o fechamento e o cancelamento do Case. Confirmado por design e por testes automatizados.
