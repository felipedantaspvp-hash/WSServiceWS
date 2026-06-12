# Patch para AGENTS.md — Regra de Encoding UTF-8

Adicionar esta seção no `AGENTS.md`, nas regras principais do projeto.

---

## Encoding UTF-8 obrigatório

Antes de qualquer deploy, retrieve, geração ou alteração de metadados Salesforce, o agente deve garantir que os arquivos estejam em UTF-8.

Regras:

- Preservar `encoding="UTF-8"` nos XML Salesforce.
- Não salvar arquivos como ANSI, Latin-1, ISO-8859-1 ou Windows-1252.
- Não aceitar labels/descriptions quebrados como `CategorizaÃ§Ã£o`.
- Não remover acentos como solução.
- Validar objetos, campos, labels, descriptions, validation messages, flows, custom labels e help texts.
- Executar checagem de mojibake antes de deploy.
- Em caso de caracteres quebrados, corrigir o source antes de publicar na org.

O agente deve carregar `docs/agent-reference/SALESFORCE_UTF8_METADATA_GUIDE.md` sempre que a tarefa envolver:

```text
Objeto
Campo
Label
Description
Help Text
Validation Message
Flow text/label
Custom Label
FlexiPage
Layout
Custom Metadata com texto
Deploy para org destino
```

Checklist mínimo antes do deploy:

```text
XML mantém UTF-8?
Labels e descriptions estão legíveis?
Não há caracteres Ã, Â, � ou â€?
O diff do Git não mostra mojibake?
O deploy foi validado/dry-run quando aplicável?
```
