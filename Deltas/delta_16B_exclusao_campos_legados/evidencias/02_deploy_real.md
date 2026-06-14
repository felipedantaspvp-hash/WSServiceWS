# Evidência 02 — Deploy Real

## Comando

```bash
sf project deploy start \
  --manifest "Deltas/delta_16B_exclusao_campos_legados/package.xml" \
  --post-destructive-changes "Deltas/delta_16B_exclusao_campos_legados/destructiveChanges.xml" \
  -o WILSON_SERVICE \
  --ignore-conflicts
```

## Resultado

| Item | Valor |
|------|-------|
| Deploy ID | `0Afbe00000A9vAzCAJ` |
| Status | **Succeeded** |
| Componentes deletados | 4/4 (100%) |
| Source Tracking atualizado | 4/4 (100%) |
| Data | 2026-06-13 |

## Campos excluídos da org

| Campo | Objeto | Estado |
|-------|--------|--------|
| `TipoAtuacao__c` | `AreaParticipante__c` | **Deleted** |
| `Origem__c` | `RegrasSLACategorizacao__c` | **Deleted** |
| `VigenciaFim__c` | `RegrasSLACategorizacao__c` | **Deleted** |
| `VigenciaInicio__c` | `RegrasSLACategorizacao__c` | **Deleted** |

## Confirmação

Os campos foram fisicamente removidos do schema da org WILSON_SERVICE.
Não existem mais referências ativas em código (removidas no Pacote 16A).
Pacote 16B concluído.
