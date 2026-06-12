# SALESFORCE_UTF8_METADATA_GUIDE.md

## Objetivo

Evitar quebra de acentuação, labels e descrições em metadados Salesforce durante alterações feitas por Codex/Agent, especialmente em deploys para orgs de destino.

Problema típico:

```text
Correto: Categorização
Quebrado: CategorizaÃ§Ã£o
```

Isso normalmente indica mojibake: texto UTF-8 sendo lido ou escrito como Windows-1252/Latin-1, ou arquivo salvo com encoding incorreto.

---

## Regra principal

Todo arquivo Salesforce, Markdown, XML, Apex, LWC, JSON, YAML e configuração criada/alterada pelo agente deve ser lido e escrito como UTF-8.

Para arquivos XML de metadados Salesforce, manter o cabeçalho:

```xml
<?xml version="1.0" encoding="UTF-8"?>
```

Nunca trocar para:

```xml
encoding="ISO-8859-1"
encoding="Windows-1252"
encoding="latin1"
```

---

## Regras obrigatórias para o Codex/Agent

Antes de criar, alterar ou salvar metadados Salesforce com texto acentuado:

1. Preservar UTF-8.
2. Não converter encoding sem solicitação explícita.
3. Não remover acentos para “resolver” erro.
4. Não substituir caracteres especiais por sequências quebradas.
5. Não salvar arquivos em ANSI, Latin-1, ISO-8859-1 ou Windows-1252.
6. Não misturar conteúdo copiado de terminal/log com metadata sem validar encoding.
7. Validar labels, plural labels, descriptions, help texts, validation messages e picklist values.
8. Validar se o arquivo XML mantém `encoding="UTF-8"`.
9. Executar checagem de mojibake antes de deploy.
10. Se houver caracteres quebrados, corrigir a origem antes do deploy.

---

## Campos/metadados mais sensíveis

Validar encoding especialmente em:

- CustomObject:
  - `label`
  - `pluralLabel`
  - `description`
  - `nameField.label`
- CustomField:
  - `label`
  - `description`
  - `inlineHelpText`
  - `picklist/valueSet` labels
- ValidationRule:
  - `errorMessage`
  - `description`
- Flow:
  - `label`
  - `description`
  - `textTemplates`
  - `screenFields`
  - mensagens de erro
- CustomLabel:
  - `value`
  - `shortDescription`
- FlexiPage / Lightning Page:
  - labels e descrições
- Layout:
  - custom buttons/actions/section labels quando aplicável
- CustomMetadata:
  - campos Text/TextArea com conteúdo funcional
- PermissionSet/Profile:
  - não costumam ter acento de negócio, mas validar se houver labels customizadas relacionadas

---

## Padrões proibidos

O agente deve bloquear ou corrigir qualquer ocorrência de:

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

Exemplos:

```text
CategorizaÃ§Ã£o       → Categorização
operaÃ§Ã£o            → operação
descriÃ§Ã£o           → descrição
NÃºmero              → Número
InformaÃ§Ãµes         → Informações
```

---

## Regra para criação de objetos e campos

Ao criar objeto/campo com label ou description em português:

- Gerar texto final já em UTF-8.
- Validar visualmente o texto antes de salvar.
- Não usar entidade HTML para acento em metadata XML comum, salvo exigência específica.
- Não usar escape manual como `\u00e7` em XML Salesforce.
- Em XML, texto deve aparecer legível:

```xml
<label>Categorização</label>
<pluralLabel>Categorizações</pluralLabel>
<description>Categorização - objeto criado para operação Service Cloud Wilson Sons.</description>
```

Não aceitar:

```xml
<label>CategorizaÃ§Ã£o</label>
<pluralLabel>CategorizaÃ§Ãµes</pluralLabel>
<description>CategorizaÃ§Ã£o - objeto criado para operaÃ§Ã£o Service Cloud Wilson Sons.</description>
```

---

## Regra para ferramentas e scripts

Quando usar Python:

```python
Path(path).read_text(encoding="utf-8")
Path(path).write_text(content, encoding="utf-8")
```

Quando usar Node/TypeScript:

```ts
await fs.promises.readFile(path, "utf8");
await fs.promises.writeFile(path, content, { encoding: "utf8" });
```

Quando usar shell:

```bash
LC_ALL=C.UTF-8
LANG=C.UTF-8
```

Evitar comandos que possam regravar arquivos com encoding do sistema operacional sem controle.

---

## Checagem obrigatória antes de deploy

Antes de fazer deploy de metadados criados/alterados, executar uma verificação de encoding/mojibake nos arquivos alterados.

Checklist:

```text
1. Buscar caracteres quebrados.
2. Validar XML header UTF-8.
3. Validar labels/descriptions com acentos.
4. Validar diff do Git.
5. Executar deploy validate/dry-run quando aplicável.
6. Após deploy crítico, recuperar metadata da org e comparar se acentos permaneceram corretos.
```

---

## Comando sugerido de inspeção simples

```bash
grep -RInE "Ã|Â|�|â€™|â€œ|â€|Ã§|Ã£|Ã¡|Ã©|Ãª|Ã³|Ãº" force-app manifest docs .agents AGENTS.md AI_HANDLERS.md 2>/dev/null
```

Se retornar resultado em metadata Salesforce, revisar antes do deploy.

---

## Script sugerido

Criar script local:

```text
scripts/validate-salesforce-encoding.mjs
```

Executar:

```bash
node scripts/validate-salesforce-encoding.mjs
```

O script deve falhar com exit code `1` quando encontrar mojibake ou XML Salesforce sem UTF-8.

---

## Critério de aceite

Uma alteração Salesforce só pode ser considerada pronta quando:

- Nenhum label/description aparece com mojibake.
- Arquivos XML Salesforce mantêm `encoding="UTF-8"`.
- Textos em português aparecem legíveis no source.
- O diff não contém caracteres corrompidos.
- A validação de encoding foi executada antes do deploy.
- Se houve deploy, o metadado recuperado da org continua com acentuação correta.
