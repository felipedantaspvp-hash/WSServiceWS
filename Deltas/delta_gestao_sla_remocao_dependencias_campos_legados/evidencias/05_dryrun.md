# Evidência 05 — Dry-run do Pacote 16A (Ajuste)

## Comando executado

```bash
sf project deploy start \
  --manifest "Deltas/delta_gestao_sla_remocao_dependencias_campos_legados/package.xml" \
  -o WILSON_SERVICE \
  --dry-run \
  --ignore-conflicts
```

## Resultado

| Item | Valor |
|------|-------|
| **Status** | **Succeeded** |
| Deploy ID | `0Afbe00000A9u3dCAB` |
| Org | `jduarte@wilsonsons.com.br.service` |
| Erros | 0 |
| Componentes Changed | `AreaParticipanteSLAService`, `GestaoSLAService`, `gestaoSLAWorkspace`, `Admin`, 4 RecordTypes |
| Componentes Unchanged | 48 (já implantados no deploy real `0Afbe00000A9tXNCAZ`) |

## Componentes Changed no ajuste (novas alterações)

| Componente | Tipo | Mudança |
|------------|------|---------|
| `AreaParticipanteSLAService` | ApexClass | Mensagem de erro corrigida (removida menção a "origem") |
| `GestaoSLAService` | ApexClass | Removidos constante `ORIGEM_QUALQUER` e método `normalizeOrigem` (código morto) |

## Observação sobre Unchanged

Os demais 28 componentes aparecem como `Unchanged` porque o deploy real do 16A (`0Afbe00000A9tXNCAZ`, Status: Succeeded, 2026-06-12) já os implantou na org. O dry-run confirma que o delta continua coerente com a org.
