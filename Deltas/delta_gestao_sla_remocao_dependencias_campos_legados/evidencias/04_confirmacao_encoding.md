# Evidência 04 — Confirmação de UTF-8 sem BOM e Ausência de Mojibake

## Método de verificação

Verificação dos primeiros 3 bytes de cada arquivo modificado:
- UTF-8 sem BOM: arquivo inicia com bytes de conteúdo real (ex: `70 75 62` = "pub")
- UTF-8 com BOM: arquivo iniciaria com `EF BB BF` antes do conteúdo

Verificação de mojibake: busca de bytes `\x80-\xFF` fora do contexto esperado de acentuação portuguesa.

## Resultado por arquivo (ajuste adicional 16A)

| Arquivo | Primeiros bytes (hex) | Interpretação | BOM | Mojibake |
|---------|----------------------|---------------|-----|----------|
| `AreaParticipanteSLAService.cls` | `70 75 62` ("pub") | UTF-8 sem BOM | Não | Não |
| `GestaoSLAService.cls` | `70 75 62` ("pub") | UTF-8 sem BOM | Não | Não |

## Caracteres não-ASCII detectados (esperados)

Os bytes `\x80-\xFF` encontrados nos arquivos são acentuação portuguesa legítima em UTF-8:
- `'Não existe regra...'` — acento em "Não"
- `'Caso e Área são obrigatórios...'` — acentos em "Área" e "são"
- `'Case.Categorizacao__c é obrigatório...'` — acento em "é" e "obrigatório"
- Mensagens de exceção em `GestaoSLAService.cls` com acentuação normal

**Conclusão: todos os arquivos do delta estão em UTF-8 sem BOM, sem mojibake.**
