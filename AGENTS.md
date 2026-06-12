# AGENTS.md — Triscal Salesforce

> Hub de roteamento. Lido automaticamente em toda tarefa deste repositório.
> Objetivo: eliminar alucinações, economizar tokens e direcionar o agente para os arquivos certos.

## Ativação — toda tarefa Salesforce executa nesta ordem

1. Leia `agents/skills/triscal-salesforce/SKILL.md` — padrões Triscal, arquitetura e regras base.
2. Consulte `docs/PROJECT_INDEX.md` — mapa do projeto; crie/atualize se ausente.
3. Consulte `AI_HANDLERS.md` — quality gates de implementação.
4. Identifique o domínio e selecione skill(s) sf-skills pela matriz abaixo.
5. Abra somente os arquivos relevantes; carregue `docs/agent-reference/` apenas se necessário.

**Resolução de conflito (maior → menor prioridade):**
`AGENTS.md` > `AI_HANDLERS.md` > `triscal-salesforce/SKILL.md` > skill sf-skills específica.

---

## Estrutura do repositório

```text
AGENTS.md / AI_HANDLERS.md
docs/PROJECT_INDEX.md
docs/agent-reference/          ← carregar sob demanda
agents/skills/triscal-salesforce/SKILL.md   ← sempre
agents/skills/sf-skills/skills/<nome>/SKILL.md  ← por domínio
force-app/   manifest/   sfdx-project.json
```

---

## Arquitetura Triscal (fonte canônica)

```text
LWC / Visualforce / Flow / API
        ↓
Controller / FlowAction   ← fino: recebe, delega, retorna
        ↓
Service                   ← regra de negócio
        ↓
ServiceAgent / Helper / Selector  ← integração externa / consulta
        ↓
Sistema externo / SObject / Metadata
```

**Proibido:** SOQL/DML em loop · Get/DML dentro de Loop em Flow · IDs hardcoded · segredo/token em código ou log · regra de negócio na Controller · callout fora da ServiceAgent · DML na ServiceAgent.

---

## Matriz de roteamento sf-skills

`triscal-salesforce` é sempre a camada base. Skills sf-skills são domínio-específicas.  
Para múltiplos domínios: combinar na ordem metadata/base > lógica > UI > permissão > teste > análise/deploy.  
**Sem geração de código** (análise conceitual, documentação, troubleshooting de acesso) → usar só triscal-salesforce.

| Demanda | Skill(s) |
|---|---|
| Apex, Trigger, Batch, Queueable, Schedulable, Service, Selector | `generating-apex` |
| Apex + testes juntos | `generating-apex` → `generating-apex-test` |
| Executar / reportar cobertura de testes | `running-apex-tests` |
| Debug log, governor limit, stack trace | `debugging-apex-logs` |
| SOQL/SOSL, query plan | `querying-soql` |
| Dados: import/export/massa/cleanup/anonymous Apex | `handling-sf-data` |
| Objeto customizado | `generating-custom-object` |
| Campo customizado | `generating-custom-field` |
| Tab · List View · Validation Rule · Custom Application | `generating-custom-tab` · `generating-list-view` · `generating-validation-rule` · `generating-custom-application` |
| Permission Set, FLS, object/app permissions | `generating-permission-set` |
| Flow (Screen/Autolaunched/Record-Triggered/Scheduled) | `generating-flow` |
| Lightning App completa | `generating-lightning-app` |
| FlexiPage / Lightning Page | `generating-flexipage` |
| LWC, wire, Jest | `generating-lwc-components` |
| SLDS, styling hooks, icons | `applying-slds` · `validating-slds` · `uplifting-components-to-slds2` |
| LWC mobile offline / Komaci | `reviewing-lwc-mobile-offline` |
| Mobile SDK iOS/Android | `building-mobile-apps` |
| Recursos nativos mobile em LWC | `using-mobile-native-capabilities` |
| Integração, Named/External Credential, REST/SOAP, CDC, Platform Event | `building-sf-integrations` |
| Connected App, OAuth, JWT | `configuring-connected-apps` |
| Deploy, scratch org, sandbox, CI/CD, erro de deploy | `deploying-metadata` |
| Flosum (branch, snapshot, pipeline, backpromotion) | `deploying-metadata` + `docs/agent-reference/SALESFORCE_SECURITY_DEVOPS_GUIDE.md` |
| Code Analyzer, PMD, ESLint, CPD, SFGE, static analysis | `running-code-analyzer` |
| Trocar org / alias SF CLI | `switching-org` |
| Documentação oficial Salesforce | `fetching-salesforce-docs` |
| Diagrama Mermaid | `generating-mermaid-diagrams` |
| Diagrama visual/renderizado | `generating-visual-diagrams` |
| Agentforce dev (`.agent`, aiAuthoringBundle) | `developing-agentforce` |
| Agentforce testes | `testing-agentforce` |
| Agentforce produção/sessão/STDM/telemetria | `observing-agentforce` · `investigating-agentforce-d360` |
| Agentforce arquitetura/inventário | `investigating-agentforce-architecture` |
| Custom Lightning Type (Agentforce) | `generating-custom-lightning-type` |
| UI Bundle — nova app React/SPA | `building-ui-bundle-app` |
| UI Bundle — frontend existente | `building-ui-bundle-frontend` |
| UI Bundle — metadata · features · site · custom-app · deploy · data · file-upload · Agentforce-client | `generating-ui-bundle-metadata` · `generating-ui-bundle-features` · `generating-ui-bundle-site` · `generating-ui-bundle-custom-app` · `deploying-ui-bundle` · `using-ui-bundle-salesforce-data` · `implementing-ui-bundle-file-upload` · `implementing-ui-bundle-agentforce-conversation-client` |
| OmniStudio OmniScript · FlexCard · Integration Procedure · Data Mapper · Callable Apex | `building-omnistudio-omniscript` · `building-omnistudio-flexcard` · `building-omnistudio-integration-procedure` · `building-omnistudio-datamapper` · `building-omnistudio-callable-apex` |
| OmniStudio dependências / DataPacks | `analyzing-omnistudio-dependencies` · `deploying-omnistudio-datapacks` |
| EPC/CME catálogo, Product2, ofertas | `modeling-omnistudio-epc-catalog` |
| B2B Commerce | `creating-b2b-commerce-store` · `integrating-b2b-commerce-open-code-components` |
| Data Cloud ponta a ponta | `orchestrating-datacloud` |
| Data Cloud conexão · preparo · harmonização · schema · consulta · segmentação · ativação | `connecting-datacloud` · `preparing-datacloud` · `harmonizing-datacloud` · `getting-datacloud-schema` · `retrieving-datacloud` · `segmenting-datacloud` · `activating-datacloud` |
| Data Cloud Code Extension | `developing-datacloud-code-extension` |
| CMS brand / mídia | `applying-cms-brand` · `searching-media` |
| Managed Event Subscription | `managing-managed-event-subscription` |

Não execute scripts sf-skills sem entender pré-requisitos, impacto na org e se alteram arquivos, dados ou metadados.  
Não altere arquivos em `agents/skills/sf-skills/` salvo quando a tarefa for manter a própria biblioteca.

---

## Referências sob demanda

Carregar apenas quando o tema exigir detalhe técnico específico:

| Tema | Arquivo |
|---|---|
| Objetos, campos, layouts, validações, LWC, ordem de solução | `docs/agent-reference/SALESFORCE_BUILD_GUIDELINES.md` |
| Flow, bulk safety, idempotência, fault paths | `docs/agent-reference/SALESFORCE_FLOW_GUIDE.md` |
| Metadata, Describe, Tooling API, SF CLI | `docs/agent-reference/SALESFORCE_METADATA_GUIDE.md` |
| Comentários, JSDoc Apex/LWC, testes | `docs/agent-reference/SALESFORCE_COMMENTS_TESTS_GUIDE.md` |
| Segurança, permissões, Flosum, DevOps | `docs/agent-reference/SALESFORCE_SECURITY_DEVOPS_GUIDE.md` |
| UTF-8, encoding, mojibake | `docs/agent-reference/SALESFORCE_UTF8_METADATA_GUIDE.md` |

---

## PROJECT_INDEX.md — conteúdo esperado

Mapa leve (sem copiar código): pastas · Controllers/FlowActions · Services/ServiceAgents · DTOs/Helpers/Selectors · LWCs · Flows/Triggers · objetos/campos relevantes · layouts/FlexiPages · Permission Sets · Custom Metadata/Named Credentials · classes de teste · fluxos técnicos principais.

---

## Checklist final

```text
[ ] triscal-salesforce/SKILL.md carregado como base
[ ] PROJECT_INDEX.md consultado ou criado
[ ] skill(s) sf-skills corretas selecionadas (ou justificativa para não usar)
[ ] AI Handlers aplicados
[ ] Menor mudança que resolve o problema com segurança
[ ] Arquitetura Controller → Service → ServiceAgent respeitada
[ ] Segurança (CRUD/FLS/Sharing/Permission) considerada
[ ] Testes criados/atualizados para Apex alterado (≥95%)
[ ] UTF-8 verificado em metadados criados/alterados
[ ] Risco classificado (Baixo/Médio/Alto) com motivo
```

Item crítico falhando → corrija antes de responder ou declare limitação e risco explicitamente.
