# 01 - Inventario de Objetos e Campos

## AreaParticipante__c — campos relevantes ao health check

| Campo | Tipo | Uso |
|-------|------|-----|
| `Id` | Id | Identificacao |
| `Name` | String | Label no Issue |
| `TipoAreaParticipante__c` | Picklist | Filtro: 'Área Interna' |
| `OrigemSLA__c` | Picklist | Distingue Standard vs Custom |
| `StatusAtuacao__c` | Picklist | Aberta/Andamento/Concluida/Cancelada |
| `StatusSLA__c` | Picklist | Dentro do Prazo/Pausado/Vencido/Concluido/Cancelado |
| `DataHoraPrazo__c` | Datetime | Prazo calculado (Custom) |
| `DataHoraInicio__c` | Datetime | Inicio da participacao |
| `DataHoraInicioPausa__c` | Datetime | Null se nao pausado |
| `TempoPausadoMinutos__c` | Decimal | Acumulado de pausa |
| `ViolouSLA__c` | Boolean | True se venceu SLA |
| `CaseMilestoneId__c` | Id | Vinculo com Standard (null para Custom) |
| `Caso__c` | Lookup | Caso relacionado |

**Campos removidos no Pacote 16B (NAO usar):** `Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`, `TipoAtuacao__c`

## RegrasSLACategorizacao__c — campos relevantes

| Campo | Uso |
|-------|-----|
| `Id`, `Name` | Identificacao |
| `Ativo__c` | Status |
| `EscopoRegra__c` | Validos: 'Atendimento', 'Area Interna'. Legados: 'Global', 'Por Categorizacao', 'Por Area Interna' |
| `BusinessHoursName__c` | Nome do BH para calculo de prazo |
| `ChaveUnica__c` | Chave funcional para deteccao de duplicatas |
| `TempoAlta__c`, `TempoMedia__c`, `TempoBaixa__c` | Prazos por prioridade |

## Case — campos relevantes

| Campo | Uso |
|-------|-----|
| `Id`, `CaseNumber` | Identificacao |
| `EtapaAtendimento__c` | Picklist: 'Concluído', 'Cancelado' sao valores terminais |
| `Status` | Status padrao |
