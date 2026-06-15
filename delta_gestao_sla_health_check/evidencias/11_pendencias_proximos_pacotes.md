# 11 - Pendencias e Proximos Pacotes

## O que este pacote NAO faz (por restricao explicita)

- Nao corrige dados inconsistentes automaticamente.
- Nao expoe o health check via LWC ou Experience Cloud.
- Nao cria agendamento automatico (Batch/Scheduler).
- Nao envia notificacoes ou emails ao detectar issues.

## Sugestoes para proximos pacotes

| # | Descricao | Tipo |
|---|-----------|------|
| 25 | Controller + LWC para visualizacao do Health Check no console do agente | Feature |
| 26 | Batch semanal que executa `runHealthCheck(500)` e armazena resultado em Custom Metadata ou arquivo de log | Feature |
| 27 | Notificacao automatica via Custom Notification quando `totalCritical > 0` | Feature |
| 28 | Correcao em lote de `VIOLOU_SLA_INCONSISTENTE_VENCIDO` via recalculo do calculateCacheBulk | Correcao de dados |

## Issues que podem ser falso-positivo

| Codigo | Motivo possivel de falso-positivo |
|--------|----------------------------------|
| `STANDARD_SEM_MILESTONE` | Sincronizacao via AreaParticipanteMilestoneSyncService ainda em progresso |
| `REGRA_SEM_BUSINESS_HOURS` | Regra configurada para calculo de prazo fixo sem BH (raro) |
| `CUSTOM_ABERTA_SEM_PRAZO` | Area recem-criada antes do beforeSave calcular o prazo |
