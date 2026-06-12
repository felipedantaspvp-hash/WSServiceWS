# AI_HANDLERS.md — Triscal Salesforce Quality Gates

## Objetivo

Este arquivo é um checklist curto para reduzir alucinações, controlar escopo e garantir qualidade.  
Use junto com `AGENTS.md`, `docs/PROJECT_INDEX.md` e `agents/skills/triscal-salesforce/SKILL.md`.

---

## Fluxo obrigatório

Aplique os handlers abaixo conforme a demanda:

```text
1. Context
2. Index
3. Scope
4. Metadata
5. Architecture
6. Declarative First
7. Security
8. Implementation
9. Test
10. Documentation
11. Final Gate
```

---

## 1. Context Handler

Identifique:

```text
Tipo: análise, bug, implementação, refatoração, doc, code review, deploy, integração ou teste.
Domínio: Apex, LWC, Flow, Visualforce, Object/Field, Layout, FlexiPage, Permission, Validation Rule, Metadata, Flosum.
```

Pergunte internamente:

```text
O pedido está claro?
Preciso consultar arquivos?
Preciso consultar metadados/org?
A solução pode ser declarativa?
```

---

## 2. Index Handler

Antes de abrir arquivos:

```text
Consultar docs/PROJECT_INDEX.md.
Selecionar arquivos candidatos.
Abrir apenas arquivos relevantes.
Evitar ler o projeto inteiro.
Não copiar código inteiro na resposta.
```

Se o índice não existir e o contexto for amplo, criar/atualizar índice leve.

---

## 3. Scope Handler

Delimite:

```text
Escopo.
Arquivos impactados.
Arquivos fora de escopo.
Menor solução segura.
Risco.
```

Evite reescrever arquitetura, alterar contrato público, refatorar código não relacionado ou criar abstração sem necessidade.

---

## 4. Metadata Handler

Use a fonte correta:

```text
Source local → metadado versionado.
Describe → estrutura de objeto/campo.
SOQL/REST → dados de negócio.
Tooling API → Apex, FlowDefinition, cobertura e logs técnicos.
Metadata API/SF CLI → XML, retrieve, deploy e comparação source x org.
UI API → experiência efetiva do usuário.
Logs/Auditoria → execução e rastreabilidade.
```

Nunca assumir existência ou permissão de campo, Flow, RecordType, layout, Permission Set, Named Credential ou Custom Metadata.

---

## 5. Architecture Handler

Validar padrão:

```text
LWC / Visualforce / Flow / API
        ↓
Controller / FlowAction
        ↓
Service
        ↓
ServiceAgent / Helper / Selector
        ↓
Sistema externo / SObject / Metadata
```

Bloquear/avisar se houver:

```text
Regra na Controller.
Callout fora da ServiceAgent.
DML na ServiceAgent.
SOQL/DML em loop.
Get/DML dentro de Loop em Flow.
ID hardcoded.
LWC com regra crítica só no front-end.
```

---

## 6. Declarative First Handler

Validar ordem:

```text
Configuração nativa > Flow > Apex > LWC
```

Só usar código customizado com justificativa.

---

## 7. Security Handler

Avaliar:

```text
CRUD/FLS.
Sharing.
Permission Sets.
Custom Permissions.
Apex Class Access.
Flow Access.
RecordType access.
Tab visibility.
Dados sensíveis/LGPD.
Segredos e logs.
```

Preferir Permission Sets a Profiles específicos.

---

## 8. Implementation Handler

Checklist mínimo:

```text
Sem SOQL/DML em loop.
Sem Get/DML dentro de Loop em Flow.
Sem IDs hardcoded.
Sem segredo em código/metadado/log.
Comentários úteis em classes/métodos relevantes.
Objetos/campos com Description.
Validation Rules com mensagem clara.
LWC com loading/error/empty/success quando aplicável.
```

---

## 9. Test Handler

Quando alterar Apex:

```text
Criar/atualizar testes.
Não depender de dados reais.
Usar mocks para callout.
Usar Test.startTest/stopTest.
Preferir Assert.areEqual/areNotEqual/isTrue.
Testar positivo, negativo, exceção e bulk quando aplicável.
Buscar 95% para código novo/alterado, salvo justificativa.
```

---

## 10. Documentation Handler

Documentar quando houver:

```text
Mudança de arquitetura.
Nova integração.
Novo Flow crítico.
Novo objeto/campo relevante.
Nova regra de negócio.
Mudança de segurança/permissão.
Mudança de deploy/Flosum.
Correção de bug relevante.
```

**Atualizar `docs/PROJECT_INDEX.md` obrigatoriamente** quando qualquer item acima ocorrer.
Regra: apenas referências estruturais — nome, caminho e responsabilidade em uma linha. Nunca copiar código.

---

## 11. Final Gate Handler

Antes de responder:

```text
Arquivos relevantes foram analisados?
PROJECT_INDEX.md foi consultado?
PROJECT_INDEX.md foi atualizado com conhecimento novo descoberto nesta tarefa?
A solução é a menor segura?
Foi avaliado declarativo antes de código?
Arquitetura Triscal foi respeitada?
Segurança foi considerada?
Testes foram considerados?
Comentários foram considerados?
Risco e validação foram indicados?
Resposta está objetiva?
```

Se falhar item crítico, corrija ou declare limitação e risco.

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