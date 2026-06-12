# SKILL_METADATA.md — Metadados, Construção Declarativa e UTF-8

> Carregar somente para tarefas: objetos, campos, layouts, FlexiPages, Validation Rules, Custom Labels, Custom Metadata, deploy, retrieve.

## Fonte de dados correta

```text
Arquivos locais         → source versionado.
Describe / sObject      → objetos, campos, picklists, RecordTypes.
SOQL / REST             → dados de negócio.
Tooling API             → Apex, FlowDefinition, cobertura, logs técnicos.
Metadata API / SF CLI   → XML, deploy, layouts, flows, permission sets.
UI API                  → experiência efetiva por usuário, FLS, layout e picklists.
Logs / Auditoria        → ApexLog, AsyncApexJob, Setup Audit Trail, Event Monitoring.
```

Nunca assumir que campo, Flow, RecordType, layout, Permission Set ou Named Credential existe sem validar.

Detalhes: `docs/agent-reference/SALESFORCE_METADATA_GUIDE.md`

## Construção declarativa

- Objetos e campos devem ter `Description`.
- Campos novos: considerar FLS, layout, Dynamic Forms, relatório, integração e tradução.
- Perguntar se contexto é multilíngue ao criar labels, picklists, mensagens ou textos traduzíveis.
- Não usar campo tipo `Time`; preferir `Text` quando necessário.
- Preferir Permission Sets a Profiles específicos.
- Lightning Pages: preferir `Field Section` em vez de `Record Detail`.
- Highlights Panel deve usar Dynamic Actions.
- Template padrão de Lightning Page: `Header and Right Sidebar`.
- Validation Rules precisam de descrição, mensagem clara e escopo restrito.

Detalhes: `docs/agent-reference/SALESFORCE_BUILD_GUIDELINES.md`

## UTF-8 obrigatório

Preservar UTF-8 em todos os arquivos criados ou alterados.

**Problema a evitar:**
```text
Correto:  Categorização
Quebrado: CategorizaÃ§Ã£o
```

**Regras:**
- Todo XML Salesforce deve manter `<?xml version="1.0" encoding="UTF-8"?>`.
- Nunca salvar em ANSI, Latin-1, ISO-8859-1 ou Windows-1252.
- Nunca remover acentos como solução.
- Antes de deploy, executar scan de mojibake.
- Após deploy crítico, recuperar metadata da org e confirmar acentuação.

**Campos mais sensíveis:**
```text
CustomObject: label, pluralLabel, description, nameField.label
CustomField: label, description, inlineHelpText
ValidationRule: errorMessage, description
Flow: labels, descriptions, textTemplates
CustomLabel: value
FlexiPage: labels, descriptions
Layout: section labels
CustomMetadata: campos texto
```

**Padrões proibidos:**
```text
Ã  Â  ï¿½  â€™  â€œ  â€  â€"  Ã§  Ã£  Ã¡  Ã©  Ãª  Ã³  Ãº
```

**Scan antes de deploy:**
```bash
grep -RInE "Ã|Â|ï¿½|â€™|â€œ|â€|Ã§|Ã£|Ã¡|Ã©|Ãª|Ã³|Ãº" force-app manifest 2>/dev/null
```

**PowerShell — bootstrap obrigatório antes de write/deploy/retrieve:**
```powershell
chcp 65001
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding           = [System.Text.UTF8Encoding]::new($false)
```

**Scripts:**
```python
# Python
Path(path).read_text(encoding="utf-8")
Path(path).write_text(content, encoding="utf-8")
```
```ts
// Node/TypeScript
await fs.promises.readFile(path, "utf8");
await fs.promises.writeFile(path, content, { encoding: "utf8" });
```

Detalhes: `docs/agent-reference/SALESFORCE_UTF8_METADATA_GUIDE.md`
