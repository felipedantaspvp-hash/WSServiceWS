# Patch para AI_HANDLERS.md — Encoding Handler

Adicionar este Handler antes do `Quality Gate Handler`.

---

# Encoding / UTF-8 Handler

## Objetivo

Garantir que nomes, labels, descriptions, mensagens e textos de metadados Salesforce não quebrem acentuação no deploy do Codex para a org de destino.

## Regras

Antes de salvar ou deployar metadados com texto:

```text
Confirmar que o arquivo está em UTF-8.
Confirmar que XML Salesforce mantém encoding="UTF-8".
Validar labels, plural labels, descriptions e mensagens.
Buscar padrões de mojibake.
Não remover acentos.
Não converter para ANSI/Latin-1/Windows-1252.
```

## Bloqueios

Bloquear entrega se encontrar:

```text
Ã
Â
�
â€™
â€œ
â€
Ã§
Ã£
Ã¡
Ã©
Ãª
Ã³
Ãº
```

## Checklist

```text
O texto aparece correto no source?
O XML tem UTF-8?
O diff não contém mojibake?
Foi feita busca por caracteres quebrados?
Se houve deploy, o retrieve da org confirma acentuação correta?
```

## Comando sugerido

```bash
grep -RInE "Ã|Â|�|â€™|â€œ|â€|Ã§|Ã£|Ã¡|Ã©|Ãª|Ã³|Ãº" force-app manifest docs .agents AGENTS.md AI_HANDLERS.md 2>/dev/null
```

Se retornar ocorrência em metadata Salesforce, corrigir antes de finalizar.
