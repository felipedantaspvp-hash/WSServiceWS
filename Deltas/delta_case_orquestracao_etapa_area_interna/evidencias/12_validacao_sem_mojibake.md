# 12 - Validação de Ausência de Mojibake

## O que é mojibake

Mojibake é corrupção de caracteres especiais ao salvar/abrir arquivo com encoding incorreto. Exemplo: 'Área' → 'Ãrea' ou 'Ãrea'.

## Caracteres especiais nos arquivos alterados

### AreaParticipanteService.cls

| Ocorrência | Valor correto | Status |
|---|---|---|
| `'Aguardando Área Interna'` | 'Á' (U+00C1) | ✅ OK |
| `'Preparando Retorno ao Cliente'` | sem especiais | ✅ OK |
| `AreaParticipanteSLAHelper.TIPO_AREA_INTERNA` | constante referenciada | ✅ OK |

### AreaParticipanteServiceTest.cls

| Ocorrência | Valor correto | Status |
|---|---|---|
| `'Aguardando Área Interna'` | 'Á' (U+00C1) | ✅ OK |
| `'Cancelado'` | sem especiais | ✅ OK |
| `'Em Atendimento'` | sem especiais | ✅ OK |
| `'Preparando Retorno ao Cliente'` | sem especiais | ✅ OK |
| `'Área 1'`, `'Área 2'` (comentários) | 'Á' (U+00C1) | ✅ OK |

## Resultado

Nenhum caractere corrompido detectado em nenhum dos arquivos modificados. ✅
