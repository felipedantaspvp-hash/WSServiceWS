# AI_HANDLERS.md — Triscal Salesforce Quality Gates

> Checklist de implementação. Usar junto com `AGENTS.md` e `triscal-salesforce/SKILL.md`.
> Para tarefas simples (pergunta conceitual, label lookup) → aplicar apenas Context e Final Gate.

---

## Handlers — aplicar conforme a demanda

### 1. Context Handler

Identifique internamente:
- **Tipo:** análise · bug · implementação · refatoração · doc · code review · deploy · integração · teste
- **Domínio:** Apex · LWC · Flow · Visualforce · Object/Field · Layout · FlexiPage · Permission · Metadata · Flosum

Pergunte internamente: O pedido está claro? Preciso consultar arquivos? A solução pode ser declarativa?

---

### 2. Index Handler

```text
Consultar docs/PROJECT_INDEX.md.
Selecionar arquivos candidatos.
Abrir apenas os relevantes.
Não copiar código inteiro na resposta.
```
Se o índice não existir e o contexto for amplo, criar/atualizar o índice antes de avançar.

---

### 3. Scope Handler

```text
Delimitar escopo e arquivos impactados.
Identificar o que está fora do escopo.
Definir a menor mudança que resolve o problema com segurança:
  - Menor = mínimo de arquivos alterados, mínimo de lógica nova, zero abstração sem uso imediato.
Classificar risco (Baixo/Médio/Alto).
```
Não reescrever arquitetura, alterar contrato público, refatorar código não relacionado ou criar abstração sem necessidade imediata.

---

### 4. Metadata Handler

Use a fonte correta — nunca assumir existência sem validar:

| Necessidade | Fonte |
|---|---|
| Source versionado | Arquivos locais |
| Estrutura objeto/campo | Describe / sObject Describe |
| Dados de negócio | SOQL / REST |
| Diagnóstico técnico | Tooling API |
| XML / deploy / retrieve | Metadata API / SF CLI |
| Experiência por usuário | UI API |
| Execução e rastreabilidade | Logs / Auditoria |

---

### 5. Architecture Handler

Arquitetura canônica em `AGENTS.md`. Bloquear/avisar se houver:

```text
Regra de negócio na Controller/FlowAction.
Callout fora da ServiceAgent.
DML na ServiceAgent.
SOQL/DML em loop.
Get/DML dentro de Loop em Flow.
ID, ProfileName ou RecordTypeId hardcoded.
Regra crítica apenas no front-end LWC.
```

---

### 6. Declarative First Handler

```text
Configuração nativa > Flow > Apex > LWC
```
Flow quando: lógica declarável, ≤2000 registros simultâneos, sem callout externo, sem reuso entre canais.  
Apex quando: volume alto, integração, transação, lógica complexa, assíncrono ou reuso entre canais.  
Código customizado só com justificativa documentada.

---

### 7. Security Handler

```text
CRUD / FLS / Sharing / Permission Sets / Custom Permissions
Apex Class Access / Flow Access / RecordType access / Tab visibility
Dados sensíveis / LGPD
Segredos e tokens não expostos em código, metadado ou log
```
Preferir Permission Sets a Profiles específicos.

---

### 8. Implementation Handler

```text
Sem SOQL/DML em loop.
Sem Get/DML dentro de Loop em Flow.
Sem IDs, ProfileName ou RecordTypeId hardcoded.
Sem segredo/token em código, metadado ou log.
Objetos/campos com Description.
Validation Rules: description dev-facing, mensagem orientada ao usuário (sem stack trace).
LWC com loading/error/empty/success quando aplicável.
```

---

### 9. Test Handler

Quando alterar Apex com lógica (não apenas comentários ou renomeação):

```text
Criar/atualizar testes.
Não depender de dados reais; usar @TestSetup e TestDataFactory.
Usar mocks para callout (HttpCalloutMock / WebServiceMock).
Usar Test.startTest/stopTest para limits e async.
Preferir Assert.areEqual / areNotEqual / isTrue.
Testar: positivo, negativo, exceção e bulk quando aplicável.
Meta: ≥95% para código novo/alterado; desvio requer justificativa explícita.
```

---

### 10. Documentation Handler

Documentar quando houver:

```text
Mudança de arquitetura ou integração.
Novo Flow crítico ou objeto/campo relevante.
Nova regra de negócio ou mudança de segurança/permissão.
Mudança de deploy/Flosum.
Correção de bug relevante.
```

---

### 11. Final Gate Handler

```text
[ ] Arquivos relevantes foram analisados?
[ ] PROJECT_INDEX.md foi consultado (ou criado)?
[ ] Skill(s) sf-skills corretas foram selecionadas?
[ ] A solução é a menor que resolve com segurança?
[ ] Declarativo foi avaliado antes de código?
[ ] Arquitetura Triscal respeitada?
[ ] Segurança considerada?
[ ] Testes considerados (Apex alterado)?
[ ] UTF-8 verificado (metadados criados/alterados)?
[ ] Risco e validação indicados?
[ ] Resposta está objetiva?
```
Se falhar item crítico, corrija ou declare limitação e risco.

---

## UTF-8 Handler (fonte canônica)

Antes de salvar ou deployar qualquer arquivo com texto (objeto, campo, label, description, help text, validation message, flow, custom label, FlexiPage, layout, custom metadata):

```text
[ ] Arquivo está em UTF-8.
[ ] XML Salesforce mantém encoding="UTF-8".
[ ] Labels, descriptions e mensagens são legíveis (sem mojibake).
[ ] Diff do Git não contém caracteres quebrados.
[ ] Deploy foi validado/dry-run quando aplicável.
```

Padrões proibidos (bloqueiam entrega):
```text
Ã · Â · â€™ · â€œ · â€ · Ã§ · Ã£ · Ã¡ · Ã© · Ãª · Ã³ · Ãº · â€" · â€" · 
```

Verificação antes do deploy:
```bash
grep -RInE "Ã|Â|â€™|â€œ|â€|Ã§|Ã£|Ã¡|Ã©|Ãª|Ã³|Ãº" force-app manifest 2>/dev/null
```

Se retornar ocorrência: abrir o arquivo, identificar a string com mojibake, reescrever em UTF-8 correto e re-validar antes de deployar.  
Detalhes e exemplos completos: `docs/agent-reference/SALESFORCE_UTF8_METADATA_GUIDE.md`.
