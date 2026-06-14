# Evidência 11 — UTF-8 sem BOM e ausência de mojibake

**Data:** 2026-06-14

## Verificação de encoding (binário)

| Arquivo | BOM | Bytes iniciais (hex) | Interpretação |
|---------|-----|----------------------|---------------|
| `AreaParticipanteMilestoneSyncService.cls` | Sem BOM ✓ | `70 75 62` | `pub` — início de `public` |
| `AreaParticipanteMilestoneSyncBatch.cls` | Sem BOM ✓ | `70 75 62` | `pub` |
| `AreaParticipanteMilestoneSyncScheduler.cls` | Sem BOM ✓ | `70 75 62` | `pub` |
| `AreaParticipanteMilestoneSyncServiceTest.cls` | Sem BOM ✓ | `40 49 73` | `@Is` — início de `@IsTest` |
| `AreaParticipanteMilestoneSyncBatchTest.cls` | Sem BOM ✓ | `40 49 73` | `@Is` |
| `AreaParticipanteSLAHelper.cls` | Sem BOM ✓ | `70 75 62` | `pub` |
| `AreaParticipanteSLAService.cls` | Sem BOM ✓ | `70 75 62` | `pub` |

Verificado via `[System.IO.File]::ReadAllBytes` (PowerShell) antes de zipar.

## Caracteres com acento verificados

| String | Arquivo | Status |
|--------|---------|--------|
| `'Categorização Inicial'` | Service | UTF-8 correto ✓ |
| `'Tratamento Primário'` | Service | UTF-8 correto ✓ |
| `'Área Interna'` | Service | UTF-8 correto ✓ |
| `'Retorno ao Cliente'` | Service | UTF-8 correto ✓ |
| `'Tempo Total de Atendimento'` | Service | UTF-8 correto ✓ |
| `'Concluída'` | Service / Tests | UTF-8 correto ✓ |
| `'Concluído'` | Service / Tests | UTF-8 correto ✓ |
| `ORIGEM_SLA_STANDARD = 'Standard'` | Helper | ASCII — sem acento |

## Mojibake

Nenhum caractere corrompido por re-encoding. Arquivos gerados diretamente por Claude Code em UTF-8 puro (sem BOM).
