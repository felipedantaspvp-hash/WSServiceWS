# AGENTS.md — Triscal Salesforce Project Instructions

> Arquivo curto de instruções do repositório.  
> Objetivo: reduzir consumo de tokens, evitar alucinações e direcionar o Codex para os arquivos certos.

## Regra principal

Antes de qualquer análise, implementação, refatoração, documentação ou code review:

1. Consulte `AI_WORKQUEUE.md` — verifique se os arquivos que serão editados estão livres.
2. Consulte `docs/PROJECT_INDEX.md`.
3. Consulte `AI_HANDLERS.md`.
4. Use a skill local ativa `.agents/skills/triscal-salesforce/SKILL.md` quando a tarefa envolver Salesforce.
5. Abra somente os arquivos relevantes para a demanda.
6. Carregue arquivos de `docs/agent-reference/` apenas quando o tema exigir detalhe.

Não leia o projeto inteiro sem necessidade.

> Claude Code usa `CLAUDE.md` como boot. Codex CLI usa este arquivo (`AGENTS.md`).
> Ambos compartilham `AI_HANDLERS.md`, `docs/PROJECT_INDEX.md` e `AI_WORKQUEUE.md`.

## Convenção de skills

- Biblioteca oficial sincronizada: `.agents/skills/`
- Skill local ativa do projeto: `agents/skills/triscal-salesforce/SKILL.md`

Para qualquer tarefa Salesforce, leia `agents/skills/triscal-salesforce/SKILL.md` (índice) e carregue apenas o fragmento relevante:

| Tarefa | Fragmento |
|--------|-----------|
| Apex, Trigger, Batch, Testes | `SKILL_APEX.md` |
| Flow (qualquer tipo) | `SKILL_FLOW.md` |
| LWC / Aura | `SKILL_LWC.md` |
| Objeto, campo, layout, deploy, UTF-8 | `SKILL_METADATA.md` |
| Permissões, CRUD/FLS, Flosum | `SKILL_SECURITY.md` |

---

## Estrutura esperada

```text
meu-projeto-salesforce/
├── AGENTS.md
├── AI_HANDLERS.md
├── docs/
│  ├── PROJECT_INDEX.md
│  └── agent-reference/
│     ├── SALESFORCE_BUILD_GUIDELINES.md
│     ├── SALESFORCE_FLOW_GUIDE.md
│     ├── SALESFORCE_METADATA_GUIDE.md
│     ├── SALESFORCE_COMMENTS_TESTS_GUIDE.md
│     ├── SALESFORCE_SECURITY_DEVOPS_GUIDE.md
│     └── SALESFORCE_UTF8_METADATA_GUIDE.md
├── .agents/
│  └── skills/
│     ├── generating-apex/
│     ├── generating-lwc-components/
│     ├── deploying-metadata/
│     └── triscal-salesforce/
├── agents/
│  └── skills/
│     └── triscal-salesforce/
├── force-app/
├── manifest/
├── scripts/
└── sfdx-project.json
```

---

## Uso obrigatório do PROJECT_INDEX.md

`docs/PROJECT_INDEX.md` é o mapa leve do projeto.

Ele deve conter apenas referências estruturais, sem copiar código inteiro:

- Estrutura de pastas.
- Controllers / FlowActions.
- Services / ServiceAgents.
- DTOs / Helpers / Selectors / Repositories.
- LWCs / Visualforce.
- Flows / Triggers / Invocable Apex.
- Objetos, campos e RecordTypes relevantes.
- Layouts, FlexiPages e Permission Sets relevantes.
- Custom Metadata, Named Credentials e integrações.
- Classes de teste.
- Fluxos técnicos principais.
- Infra de skills usada pelo projeto.

Se o índice não existir ou estiver desatualizado, atualize-o de forma objetiva antes de aprofundar a análise.

---

## Princípios obrigatórios

- Ser pontual, conclusivo e técnico.
- Não inventar informações não encontradas no repositório ou na org.
- Não implementar antes de ler os arquivos relevantes.
- Implementar a menor solução segura.
- Preferir configuração nativa antes de Flow, Apex ou LWC.
- Preferir Flow antes de Apex quando for sustentável.
- Usar Apex quando houver complexidade, volume, integração, transação ou necessidade de controle fino.
- Usar LWC apenas quando componentes padrão, App Builder, Dynamic Forms ou Screen Flow não atenderem.
- Preservar arquitetura existente.
- Evitar overengineering.
- Evitar alterações fora do escopo.

---

## Arquitetura Triscal Salesforce

Padrão principal:

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

Regras:

- Controller e FlowAction devem ser finos.
- Service concentra regra de negócio.
- ServiceAgent concentra integração externa.
- Trigger deve conter apenas roteamento.
- DTO representa payload estruturado.
- Não fazer SOQL/DML em loop.
- Não fazer Get/DML dentro de Loop em Flow.
- Não usar IDs hardcoded.
- Não expor segredo, token, senha, API key ou stack trace.

---

## Referências sob demanda

Use estes arquivos somente quando a tarefa exigir detalhe:

| Tema | Arquivo |
|---|---|
| Objetos, campos, layouts, validações, LWC e ordem de solução | `docs/agent-reference/SALESFORCE_BUILD_GUIDELINES.md` |
| Flow, bulk safety, idempotência e fault paths | `docs/agent-reference/SALESFORCE_FLOW_GUIDE.md` |
| Dados, metadados, Describe, Tooling API, Metadata API, UI API | `docs/agent-reference/SALESFORCE_METADATA_GUIDE.md` |
| Comentários, JSDoc Apex/LWC e testes | `docs/agent-reference/SALESFORCE_COMMENTS_TESTS_GUIDE.md` |
| Segurança, permissões, Flosum e DevOps | `docs/agent-reference/SALESFORCE_SECURITY_DEVOPS_GUIDE.md` |
| UTF-8, BOM e prevenção de mojibake em metadata | `docs/agent-reference/SALESFORCE_UTF8_METADATA_GUIDE.md` |

---

## Formato de resposta esperado

Para análise ou implementação:

```text
Conclusão:
...

Arquivos analisados:
- ...

Alteração proposta/realizada:
- ...

Risco:
Baixo/Médio/Alto — motivo.

Testes:
- ...

Próximo passo:
...
```

Para correção simples:

```text
Causa:
...

Correção:
...

Teste:
...
```

---

## Alimentação obrigatória do PROJECT_INDEX.md

Ao concluir qualquer tarefa que revele ou crie conhecimento novo sobre o projeto, atualize `docs/PROJECT_INDEX.md` **antes de encerrar a resposta**.

Atualizar quando houver:

- Nova classe, método público relevante, trigger ou batch descoberto ou criado.
- Novo objeto, campo, RecordType, Custom Metadata ou Named Credential.
- Novo LWC, Flow, FlexiPage ou layout relevante.
- Nova integração, endpoint ou ServiceAgent.
- Mudança de arquitetura ou novo padrão adotado.
- Bug relevante corrigido que revele comportamento importante.
- Nova regra de negócio identificada que ainda não estava documentada.

Regras de escrita:

- Apenas referências estruturais — nunca copiar código inteiro.
- Uma linha por artefato: nome, caminho e responsabilidade em uma frase.
- Atualizar entrada existente se o artefato já estiver listado — não duplicar.
- Manter o índice como o menor mapa útil do projeto.

---

## Regra final

Antes de entregar, valide:

```text
Li os arquivos certos?
Consultei o PROJECT_INDEX.md?
Usei a skill ativa em .agents/skills quando aplicável?
Apliquei os AI Handlers?
A solução é a menor segura?
Respeitei Controller/FlowAction > Service > ServiceAgent?
Considerei segurança, testes e risco?
```

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
Não há caracteres Ãƒ, Ã‚, ï¿½ ou Ã¢â‚¬?
O diff do Git não mostra mojibake?
O deploy foi validado/dry-run quando aplicável?
```

## PowerShell UTF-8 Session Bootstrap

Before any metadata write/deploy/retrieve in Windows PowerShell, run:

```powershell
chcp 65001
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding           = [System.Text.UTF8Encoding]::new($false)
```

Additional rules:

- Avoid writing accented text via inline `Set-Content` when possible.
- Prefer writing metadata text files via Python with explicit `encoding='utf-8'`.
- After generation, run mojibake scan before deploy.
