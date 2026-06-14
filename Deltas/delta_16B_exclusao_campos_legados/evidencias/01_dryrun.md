# Evidência 01 — Dry-run

## Comando

```bash
sf project deploy start \
  --manifest "Deltas/delta_16B_exclusao_campos_legados/package.xml" \
  --post-destructive-changes "Deltas/delta_16B_exclusao_campos_legados/destructiveChanges.xml" \
  -o WILSON_SERVICE \
  --dry-run \
  --ignore-conflicts
```

## Resultado

| Item | Valor |
|------|-------|
| Deploy ID | `0Afbe00000A9v9NCAR` |
| Status | **Succeeded** |
| Componentes validados | 4/4 (100%) |
| Data | 2026-06-13 |

## Campos validados para exclusão

| Campo | Objeto | Estado |
|-------|--------|--------|
| `TipoAtuacao__c` | `AreaParticipante__c` | Deleted |
| `Origem__c` | `RegrasSLACategorizacao__c` | Deleted |
| `VigenciaFim__c` | `RegrasSLACategorizacao__c` | Deleted |
| `VigenciaInicio__c` | `RegrasSLACategorizacao__c` | Deleted |
