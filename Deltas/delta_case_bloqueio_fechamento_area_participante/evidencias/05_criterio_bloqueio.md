# 05 - Critério de Bloqueio

## Regra funcional

Um Case NÃO pode ser fechado ou cancelado quando existir ao menos um registro `AreaParticipante__c` vinculado que atenda TODOS os seguintes critérios:

| Campo | Critério | Razão |
|---|---|---|
| `Caso__c` | `IN :closingCaseIds` | Vinculado ao Case que está sendo fechado/cancelado |
| `TipoAreaParticipante__c` | `= 'Área Interna'` | Apenas Áreas Internas bloqueiam |
| `OrigemSLA__c` | `= 'Custom'` | Apenas registros manuais/Custom bloqueiam; Standard (espelhos de Milestone) nunca bloqueiam |
| `BloqueiaFechamentoCaso__c` | `= true` | Flag explícita de bloqueio, setada pelo AreaParticipanteSLAService ao abrir o acionamento |
| `DataHoraFim__c` | `= null` | Registros concluídos/cancelados têm DataHoraFim preenchido e não bloqueiam |

## Query SOQL de verificação

```apex
SELECT Caso__c c, COUNT(Id) cnt
FROM AreaParticipante__c
WHERE Caso__c IN :closing
  AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
  AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM
  AND BloqueiaFechamentoCaso__c = true
  AND DataHoraFim__c = null
GROUP BY Caso__c
```

## Quando o bloqueio é acionado

| Transição no Case | Detectado por | Bloqueia? |
|---|---|---|
| `IsClosed = false → true` (Status='Fechado') | `!oldC.IsClosed && newC.IsClosed` | Sim, se existir AP Custom Interna aberta |
| `EtapaAtendimento__c → 'Cancelado'` | `ETAPA_CANCELADO.equals(newC.EtapaAtendimento__c) && !ETAPA_CANCELADO.equals(oldC.EtapaAtendimento__c)` | Sim, se existir AP Custom Interna aberta |
| Qualquer outro update (etapa, comentário, etc.) | Não detectado | Não — método retorna cedo |

## Mensagem de erro funcional

```
Existem áreas internas abertas. Conclua ou cancele as áreas participantes antes de fechar ou cancelar o caso.
```

## Bulk safety

A query é executada UMA VEZ para todos os Cases do batch (via `WHERE Caso__c IN :closing`). Nenhuma query em loop. O resultado é mapeado em `Map<Id, Integer>` e percorrido sequencialmente. Padrão bulk-safe.
