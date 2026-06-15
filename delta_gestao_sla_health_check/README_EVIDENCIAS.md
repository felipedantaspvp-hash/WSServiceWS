# Pacote 24 — GestaoSLA Health Check

## Objetivo

Servico de auditoria read-only que detecta inconsistencias nos dados de SLA sem alterar nenhum registro.

## Artefatos

| Arquivo | Tipo | Descricao |
|---------|------|-----------|
| `classes/GestaoSLAHealthCheckDTO.cls` | Apex Class | DTO de resultado (HealthCheckResult + Issue) |
| `classes/GestaoSLAHealthCheckService.cls` | Apex Class | Servico com 4 categorias de check, 7 SOQL, zero DML |
| `classes/GestaoSLAHealthCheckServiceTest.cls` | Apex Test | 10 testes, sem SeeAllData, sem hardcoded Id |

## Categorias de check

| # | Categoria | SOQL | Regras |
|---|-----------|------|--------|
| 1 | REGRAS_SLA | 1 | REGRA_SEM_PRAZO, ESCOPO_LEGADO, REGRA_DUPLICADA, REGRA_SEM_BUSINESS_HOURS |
| 2 | AREA_PARTICIPANTE | 1 | CUSTOM_ABERTA_SEM_PRAZO, SEM_STATUS_ATUACAO, SEM_STATUS_SLA, STATUS_SLA_INCOERENTE_*, VIOLOU_SLA_INCONSISTENTE_*, PAUSADO_SEM_DATA_INICIO_PAUSA, DATA_INICIO_PAUSA_INDEVIDA, TEMPO_PAUSADO_NEGATIVO |
| 3 | STANDARD_VS_CUSTOM | 3 | STANDARD_COM_PAUSA, STANDARD_SEM_MILESTONE, CUSTOM_COM_MILESTONE |
| 4 | CASE_ETAPA | 2 | CASE_TERMINAL_COM_AREA_ABERTA |

## Severidades

`Critical` > `High` > `Medium` > `Low` > `Info`

## Restricoes respeitadas

- Zero DML (sem insert, update, upsert, delete)
- Sem Flow, Trigger, Batch, Scheduler
- Sem campos removidos no Pacote 16B
- Sem hardcoded Id
- Sem SOQL em loop
- package.xml minimo sem wildcard
- API version 66.0

## Evidencias

Ver pasta `evidencias/` para detalhes de cada check e validacao.
