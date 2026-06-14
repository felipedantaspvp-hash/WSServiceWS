# 12 - Validação de Ausência de Mojibake

## O que é mojibake

Mojibake é corrupção de caracteres especiais ao salvar ou abrir arquivo com encoding incorreto. Resulta em caracteres ilegíveis no lugar de acentos e símbolos.

## Caracteres especiais nos arquivos alterados

### AreaParticipanteSelector.cls

| Ocorrência | Status |
|---|---|
| Sem literais com acentos | ✅ OK |

### AreaParticipanteService.cls

| Ocorrência | Valor correto | Status |
|---|---|---|
| `'Aguardando Area Interna'` (constante API via TIPO_AREA_INTERNA) | referencia constante | ✅ OK |
| `'Aguardando Área Interna'` (literal) | U+00C1 = A com acento agudo | ✅ OK |
| `'Preparando Retorno ao Cliente'` | sem especiais | ✅ OK |
| mensagens de erro PT/EN | sem especiais problemáticos | ✅ OK |

### AreaParticipanteServiceTest.cls

| Ocorrência | Valor correto | Status |
|---|---|---|
| `'Aguardando Área Interna'` | U+00C1 = A com acento agudo | ✅ OK |
| `'Cancelado'`, `'Em Atendimento'` | sem especiais | ✅ OK |
| `'Preparando Retorno ao Cliente'` | sem especiais | ✅ OK |
| `'Solução IsClosed'` → atualizado para `'Solução Status Fechado'` | U+00E7 = c com cedilha | ✅ OK |

## Resultado

Nenhum caractere corrompido detectado em nenhum dos arquivos modificados. ✅
