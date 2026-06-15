# 02 - Inventario de campos de pausa/retomada

## Campos existentes usados

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
- `RegraSLACategorizacao__c`

## Campos nao encontrados

- `DataHoraFimPausa__c`
- `MotivoPausa__c`

## Decisao

Nenhum campo novo foi criado. A retomada acumula tempo em `TempoPausadoMinutos__c` e limpa `DataHoraInicioPausa__c`.
