# Patch para SKILL.md — Encoding UTF-8 e metadados Salesforce

Adicionar esta seção na Skill `triscal-salesforce`, preferencialmente após as regras de construção declarativa ou metadados.

---

## Encoding UTF-8 obrigatório para metadados Salesforce

O agente deve preservar UTF-8 em todos os arquivos criados ou alterados.

Problema que deve ser evitado:

```text
Correto: Categorização
Quebrado: CategorizaÃ§Ã£o
```

Regras obrigatórias:

- Todo arquivo Salesforce, XML, Apex, LWC, JSON, YAML, Markdown e configuração deve ser lido/escrito como UTF-8.
- Todo XML Salesforce deve manter `<?xml version="1.0" encoding="UTF-8"?>`.
- Nunca salvar metadata em ANSI, Latin-1, ISO-8859-1 ou Windows-1252.
- Nunca remover acentos como solução.
- Nunca aceitar labels, plural labels, descriptions, help texts, messages ou picklist values com mojibake.
- Antes de deploy, executar checagem de caracteres quebrados.
- Após deploy crítico, recuperar metadata da org e comparar se os acentos foram preservados.

Validar principalmente:

```text
CustomObject.label
CustomObject.pluralLabel
CustomObject.description
CustomObject.nameField.label
CustomField.label
CustomField.description
CustomField.inlineHelpText
ValidationRule.errorMessage
ValidationRule.description
Flow labels/descriptions/textTemplates
CustomLabel.value
FlexiPage labels/descriptions
Layout section labels
CustomMetadata text fields
```

Padrões proibidos:

```text
Ã
Â
�
â€™
â€œ
â€
â€“
â€”
Ã§
Ã£
Ã¡
Ã©
Ãª
Ã³
Ãº
```

Exemplo correto:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Categorização</label>
    <pluralLabel>Categorizações</pluralLabel>
    <description>Categorização - objeto criado para operação Service Cloud Wilson Sons.</description>
</CustomObject>
```

Exemplo proibido:

```xml
<label>CategorizaÃ§Ã£o</label>
<pluralLabel>CategorizaÃ§Ãµes</pluralLabel>
<description>CategorizaÃ§Ã£o - objeto criado para operaÃ§Ã£o Service Cloud Wilson Sons.</description>
```

Quando usar scripts:

Python:

```python
Path(path).read_text(encoding="utf-8")
Path(path).write_text(content, encoding="utf-8")
```

Node/TypeScript:

```ts
await fs.promises.readFile(path, "utf8");
await fs.promises.writeFile(path, content, { encoding: "utf8" });
```

Antes de deploy:

```bash
grep -RInE "Ã|Â|�|â€™|â€œ|â€|Ã§|Ã£|Ã¡|Ã©|Ãª|Ã³|Ãº" force-app manifest docs .agents AGENTS.md AI_HANDLERS.md 2>/dev/null
```

Se encontrar ocorrência, corrigir antes de deploy.
