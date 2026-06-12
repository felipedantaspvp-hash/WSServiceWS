# Agents Skills Triscal Salesforce

Repositório de instruções, quality gates, referências e skills para orientar agentes de IA em projetos Salesforce da Triscal.

O objetivo é padronizar como Codex e outros agentes trabalham em demandas Salesforce, reduzindo consumo de tokens, evitando alucinações e garantindo que análises, correções, implementações, reviews e deploys sigam uma sequência técnica segura.

## O que este projeto resolve

Em projetos Salesforce, uma resposta boa depende de contexto real: metadados existentes, arquitetura usada, permissões, automações, integrações, testes e padrão de deploy. Este repositório organiza esse contexto em camadas:

- `AGENTS.md`: instrução principal que o agente deve ler antes de trabalhar.
- `AI_HANDLERS.md`: checklist de quality gates para controlar escopo, arquitetura, segurança, testes e documentação.
- `docs/PROJECT_INDEX.md`: índice leve do projeto Salesforce, usado para localizar arquivos relevantes sem ler o repositório inteiro.
- `docs/agent-reference/`: guias detalhados carregados somente quando o tema exigir.
- `agents/skills/triscal-salesforce/SKILL.md`: skill principal com o padrão técnico Triscal Salesforce.
- `agents/skills/sf-skills/`: biblioteca de skills Salesforce especializadas por domínio.

Com isso, o agente deixa de depender de instruções longas em todo prompt e passa a seguir um fluxo previsível.

## Estrutura do repositório

```text
.
├─ AGENTS.md
├─ AI_HANDLERS.md
├─ MIGRATION_GUIDE.md
├─ README.md
├─ agents/
│  ├─ skills/
│  │  ├─ triscal-salesforce/
│  │  │  └─ SKILL.md
│  │  └─ sf-skills/
│  │     ├─ README.md
│  │     ├─ skills/
│  │     ├─ samples/
│  │     └─ scripts/
│  └─ triscal-salesforce/
│     └─ SKILL.md
└─ docs/
   ├─ PROJECT_INDEX.md
   └─ agent-reference/
      ├─ SALESFORCE_BUILD_GUIDELINES.md
      ├─ SALESFORCE_FLOW_GUIDE.md
      ├─ SALESFORCE_METADATA_GUIDE.md
      ├─ SALESFORCE_COMMENTS_TESTS_GUIDE.md
      ├─ SALESFORCE_SECURITY_DEVOPS_GUIDE.md
      └─ SALESFORCE_UTF8_METADATA_GUIDE.md
```

Observação: o caminho preferencial da skill Triscal é `agents/skills/triscal-salesforce/SKILL.md`. A pasta `agents/triscal-salesforce/` existe como referência/compatibilidade e deve ser mantida alinhada se for usada por algum fluxo legado.

## Fluxo obrigatório do agente

Antes de qualquer análise, implementação, refatoração, documentação, code review ou deploy Salesforce, o agente deve:

1. Consultar `docs/PROJECT_INDEX.md`.
2. Consultar `AI_HANDLERS.md`.
3. Usar `agents/skills/triscal-salesforce/SKILL.md`.
4. Identificar se existe uma skill específica em `agents/skills/sf-skills/skills/`.
5. Ler integralmente o `SKILL.md` específico quando o domínio for coberto por `sf-skills`.
6. Abrir somente os arquivos relevantes para a demanda.
7. Carregar guias detalhados de `docs/agent-reference/` apenas quando necessário.

Esse fluxo é obrigatório para evitar leitura desnecessária do projeto inteiro e para manter as respostas técnicas baseadas em evidência do repositório ou da org.

## Padrão técnico Triscal Salesforce

O padrão principal de arquitetura esperado é:

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

Regras centrais:

- Controller e FlowAction devem ser finos.
- Service concentra regra de negócio.
- ServiceAgent concentra integração externa.
- Trigger deve conter apenas roteamento.
- DTO representa payload estruturado.
- Não fazer SOQL/DML em loop.
- Não fazer Get/DML dentro de Loop em Flow.
- Não usar IDs hardcoded.
- Não expor segredo, token, senha, API key ou stack trace.

Ordem de preferência para solução:

```text
Configuração nativa > Flow > Apex > LWC
```

Código customizado deve existir por necessidade técnica, não por preferência.

## Quality gates

O arquivo `AI_HANDLERS.md` define a esteira mínima de qualidade:

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

Esses handlers ajudam o agente a responder perguntas como:

- O pedido está claro?
- Quais arquivos precisam ser lidos?
- A solução pode ser declarativa?
- Há impacto em segurança, CRUD/FLS, permissions ou sharing?
- O padrão Controller/FlowAction > Service > ServiceAgent foi respeitado?
- Há testes suficientes?
- O risco foi comunicado?

## PROJECT_INDEX.md

`docs/PROJECT_INDEX.md` é o mapa leve do projeto Salesforce. Ele deve conter referências estruturais, sem copiar código inteiro.

Use o índice para registrar:

- Controllers e FlowActions.
- Services e ServiceAgents.
- DTOs, Helpers, Selectors e Repositories.
- LWCs, Visualforce, Flows, Triggers e Invocable Apex.
- Objetos, campos, RecordTypes, layouts e FlexiPages relevantes.
- Permission Sets, Custom Metadata, Named Credentials e integrações.
- Classes de teste.
- Fluxos técnicos principais.

Se o índice estiver vazio ou desatualizado, ele deve ser atualizado objetivamente antes de aprofundar a análise.

## Skills disponíveis

### Skill Triscal

`agents/skills/triscal-salesforce/SKILL.md` é a skill principal. Ela define:

- Princípios de arquitetura Triscal.
- Regras essenciais para Apex, Flow e LWC.
- Critérios de segurança e DevOps.
- Padrões de comentários e testes.
- Formato de resposta esperado.
- Regras obrigatórias de UTF-8 para metadados Salesforce.

### Salesforce Skills Library

`agents/skills/sf-skills/` é uma biblioteca de workflows Salesforce especializados. Cada skill possui seu próprio `SKILL.md` e pode incluir `references/`, `assets/`, `scripts/`, `examples/`, `docs/` ou `implementation/`.

Exemplos de domínios cobertos:

- Apex, testes Apex, SOQL e debug logs.
- Flow, objetos, campos, validation rules, permission sets e FlexiPages.
- LWC, SLDS, mobile offline e recursos nativos mobile.
- Integrações, Named Credentials, Connected Apps e OAuth.
- Deploy, Salesforce Code Analyzer e troca de org.
- Agentforce, Data Cloud, OmniStudio, B2B Commerce e UI Bundles.

O agente deve selecionar a skill específica pelo domínio da demanda e ler o `SKILL.md` correspondente antes de agir.

## Referências detalhadas

Os arquivos em `docs/agent-reference/` são carregados sob demanda:

| Tema | Arquivo |
|---|---|
| Objetos, campos, layouts, validações, LWC e ordem de solução | `SALESFORCE_BUILD_GUIDELINES.md` |
| Flow, bulk safety, idempotência e fault paths | `SALESFORCE_FLOW_GUIDE.md` |
| Dados, metadados, Describe, Tooling API, Metadata API e UI API | `SALESFORCE_METADATA_GUIDE.md` |
| Comentários, JSDoc Apex/LWC e testes | `SALESFORCE_COMMENTS_TESTS_GUIDE.md` |
| Segurança, permissões, Flosum e DevOps | `SALESFORCE_SECURITY_DEVOPS_GUIDE.md` |
| Encoding, acentuação e mojibake em metadados | `SALESFORCE_UTF8_METADATA_GUIDE.md` |

Esses arquivos não devem ser carregados automaticamente em toda tarefa. Eles existem para aprofundar o contexto quando o tema exigir.

## UTF-8 e metadados Salesforce

Este projeto exige UTF-8 para metadados Salesforce e documentação.

Antes de deploy, retrieve, geração ou alteração de metadados com texto, validar:

- XML mantém `encoding="UTF-8"`.
- Labels, descriptions, help texts e mensagens estão legíveis.
- Não há mojibake como `Ã`, `Â`, `�` ou `â€`.
- O diff do Git não mostra caracteres quebrados.
- O deploy foi validado ou executado em dry-run quando aplicável.

Não remova acentos como solução. Corrija a origem do encoding.

## Como usar em um projeto Salesforce

1. Copie ou mantenha estes arquivos na raiz do projeto Salesforce.
2. Atualize `docs/PROJECT_INDEX.md` com o mapa leve do projeto.
3. Garanta que `AGENTS.md`, `AI_HANDLERS.md` e `agents/skills/triscal-salesforce/SKILL.md` estejam versionados.
4. Mantenha `docs/agent-reference/` disponível para consultas sob demanda.
5. Use `agents/skills/sf-skills/` como catálogo de skills especializadas.
6. Antes de cada demanda, peça ao agente para seguir o `AGENTS.md` do repositório.

Para migração de projetos existentes, consulte `MIGRATION_GUIDE.md`.

## Como manter este repositório

Ao alterar instruções:

- Prefira atualizar `AGENTS.md` quando a regra for obrigatória e curta.
- Use `AI_HANDLERS.md` para quality gates e checklists operacionais.
- Use `docs/agent-reference/` para detalhes extensos por tema.
- Use `agents/skills/triscal-salesforce/SKILL.md` para o padrão técnico reutilizável da Triscal.
- Não duplique regras longas em vários arquivos sem necessidade.
- Se adicionar uma nova skill em `sf-skills`, atualize a matriz de roteamento do `AGENTS.md`.

Ao preparar uma alteração para Git:

```bash
git diff --check
git status --short
```

Se houver alteração de metadados Salesforce, rode também uma busca por mojibake nos arquivos impactados.

## Critério de aceite para contribuições

Uma contribuição neste repositório deve:

- Preservar o objetivo de economia de tokens.
- Evitar instruções ambíguas ou contraditórias.
- Manter a prioridade entre `AGENTS.md`, `AI_HANDLERS.md`, Skill Triscal e `sf-skills`.
- Não incentivar leitura do projeto inteiro.
- Não inventar padrões que não estejam documentados.
- Considerar segurança, testes, deploy e UTF-8.
- Ser escrita de forma objetiva e aplicável por agentes.

## Licenciamento e origem de conteúdos

Este repositório é de uso restrito a consultores autorizados e projetos da Triscal. Consulte `LICENSE.md`.

O projeto combina instruções internas Triscal com uma biblioteca local `sf-skills`. Conteúdos de terceiros mantêm suas próprias licenças, créditos e restrições. Antes de publicar em um Git remoto, valide permissões de redistribuição dos conteúdos importados em `agents/skills/sf-skills/`.
