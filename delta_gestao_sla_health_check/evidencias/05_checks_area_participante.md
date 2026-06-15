# 05 - Checks: Area Participante

## SOQL utilizado

```soql
SELECT Id, Name, TipoAreaParticipante__c, OrigemSLA__c,
       StatusAtuacao__c, StatusSLA__c,
       DataHoraPrazo__c, DataHoraFim__c, DataHoraInicio__c,
       DataHoraInicioPausa__c, TempoPausadoMinutos__c, ViolouSLA__c
FROM AreaParticipante__c
WHERE TipoAreaParticipante__c = 'Área Interna'
LIMIT :lim
```

## Regras detectadas

| Codigo | Severidade | Condicao |
|--------|-----------|----------|
| `CUSTOM_ABERTA_SEM_PRAZO` | High | Custom + isAbertaOuAndamento + DataHoraPrazo__c null |
| `SEM_STATUS_ATUACAO` | Critical | StatusAtuacao__c em branco |
| `SEM_STATUS_SLA` | High | StatusSLA__c em branco |
| `STATUS_SLA_INCOERENTE_CONCLUIDA` | Medium | isConcluida + StatusSLA nao e Concluido nem Vencido |
| `STATUS_SLA_INCOERENTE_CANCELADA` | Low | isCancelada + StatusSLA nao e Cancelado |
| `VIOLOU_SLA_INCONSISTENTE_VENCIDO` | Medium | StatusSLA = Vencido + ViolouSLA__c = false |
| `VIOLOU_SLA_INCONSISTENTE_DENTRO_PRAZO` | Low | StatusSLA = Dentro do Prazo + ViolouSLA__c = true |
| `PAUSADO_SEM_DATA_INICIO_PAUSA` | High | StatusSLA = Pausado + DataHoraInicioPausa__c null |
| `DATA_INICIO_PAUSA_INDEVIDA` | Medium | StatusSLA != Pausado + DataHoraInicioPausa__c preenchida + nao terminal |
| `TEMPO_PAUSADO_NEGATIVO` | High | TempoPausadoMinutos__c < 0 |

## Escopo

Apenas `TipoAreaParticipante__c = 'Área Interna'`. APs de outros tipos nao sao avaliados.
