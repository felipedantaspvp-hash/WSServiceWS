# 07 - Proxy: BloqueiaFechamentoCaso__c como indicador de Custom Interna aberta

## Fundamento

`BloqueiaFechamentoCaso__c` é definido pelo ciclo de vida SLA:

| Evento | Quem define | Valor |
|---|---|---|
| Insert de AP Custom Área Interna (status aberto) | `AreaParticipanteSLAService.beforeSave()` linha 48 | `true` |
| Close de AP Custom (`closeSLA()`) | `AreaParticipanteSLAService.closeSLA()` | `false` |
| Sync de Milestone → AP Standard | `AreaParticipanteMilestoneSyncService.buildRecord()` | `false` (sempre) |

## Garantia de exclusão de Standard

Standard APs têm `BloqueiaFechamentoCaso__c = false` por definição (`buildRecord()` linha explícita). Portanto, o filtro:

```apex
if (!other.BloqueiaFechamentoCaso__c) continue;
```

Exclui **todos** os registros Standard corretamente, independentemente de `TipoAreaParticipante__c`.

## Dupla proteção

O filtro usa dois critérios independentes:
1. `TipoAreaParticipante__c = 'Área Interna'` — exclui marcos SLA e outros tipos (TipoAreaParticipante__c='Marco SLA', etc.)
2. `BloqueiaFechamentoCaso__c = true` — exclui Standard e APs concluídas/canceladas

Qualquer AP que passe pelos dois filtros E tenha status aberto/overdue é uma Custom Interna genuinamente aberta.

## Consistência com Pacote 20

O Pacote 20 usa a mesma abordagem no SOQL do `CaseTriggerHandler`:
```apex
AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM
AND BloqueiaFechamentoCaso__c = true
AND DataHoraFim__c = null
```

O Pacote 21 usa a mesma lógica no loop in-memory (pois `remainingRows` já foi carregado), substituindo `OrigemSLA__c` por `BloqueiaFechamentoCaso__c` como proxy (campo já disponível no SOQL de `getAreasByCase()`).
