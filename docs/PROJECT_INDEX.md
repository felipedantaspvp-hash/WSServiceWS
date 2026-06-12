# PROJECT_INDEX.md — Índice técnico do projeto WS_SERVICE

> Não copie código inteiro neste arquivo.
> Use apenas referências para orientar leitura seletiva e economizar tokens.

## Última atualização

- Data: 2026-06-12
- Responsável: Jean Duarte
- Observação: Consolidação completa refletindo estado atual do source (Pacotes 1–10 + evolução pós-Pacote 10)

---

## Documentos de referência

| Documento | Caminho | Finalidade |
|---|---|---|
| Contexto Gestão SLA | `docs/GESTAO_SLA_PROJECT_CONTEXT.md` | Arquitetura SLA, objetos, regras de prioridade, compatibilidade legado/novo |
| Especificação Funcional V2 | Arquivo DOCX externo (21/05/2026) | Regras de negócio oficiais de todos os módulos |
| Skills Library | `docs/SF_SKILLS_LIBRARY.md` | Biblioteca de skills Salesforce do time |
| Team Checklist | `docs/SF_SKILLS_TEAM_CHECKLIST.md` | Guia diário de uso das skills |

---

## Estrutura principal do repositório

```text
.agents/            → Skills oficiais Salesforce (forcedotcom/sf-skills)
agents/             → Skill local Triskal
docs/               → Documentação técnica e funcional
force-app/          → Source Salesforce (SFDX)
manifest/           → package.xml de deploy
scripts/            → PowerShell utilitários (sync, deploy)
```

---

## Arquitetura de camadas

```text
LWC / Visualforce / Flow / API
        ↓
Controller (AuraEnabled)
        ↓
Service
        ↓
ServiceAgent / Helper / Selector / DAO
        ↓
SObject / Custom Metadata / Sistema Externo
```

Para SLA:
```text
Entitlement Process / Case Trigger / AreaParticipante__c
        ↓
CaseMilestoneTriggerTimeCalculator  /  AreaParticipanteSLAService
        ↓
RegrasSLACompatibilidadeService
        ↓
RegrasSLACategorizacao__c / MarcoSLA__c / GestaoSLA__c / Categorizacao__c
```

---

## Controllers principais (AuraEnabled / @RemoteAction)

| Artefato | Caminho | Responsabilidade |
|---|---|---|
| `GestaoSLAController` | `classes/GestaoSLAController.cls` | Backend LWC gestaoSLAWorkspace (CRUD GestaoSLA, MarcoSLA, Regras) |
| `AreaParticipanteController` | `classes/AreaParticipanteController.cls` | Backend painel Áreas Participantes (caseAreasParticipantesPanel) |
| `CaseCreationController` | `classes/CaseCreationController.cls` | Abertura manual de Cases |
| `CaseRecategorizationController` | `classes/CaseRecategorizationController.cls` | Recategorização de Cases |
| `CaseClosureSurveyController` | `classes/CaseClosureSurveyController.cls` | Encerramento com pesquisa de satisfação |
| `CategorizacaoController` | `classes/CategorizacaoController.cls` | CRUD de Categorização |
| `MessagingContextController` | `classes/MessagingContextController.cls` | Resolução de contexto para Messaging (WhatsApp/Chat) |
| `ControleLogIntegracoesController` | `classes/ControleLogIntegracoesController.cls` | Painel de logs de integração |
| `StartIntegracaoController` | `classes/StartIntegracaoController.cls` | Disparador manual de integrações |
| `WSBulkServicesUpdateController` | `classes/WSBulkServicesUpdateController.cls` | Atualização bulk de serviços |
| `ActionGerarTemplateController` | `classes/ActionGerarTemplateController.cls` | Geração de templates PDF |

---

## Services — Módulo Service Cloud / SLA

| Artefato | Caminho | Responsabilidade | Chamado por |
|---|---|---|---|
| `GestaoSLAService` | `classes/GestaoSLAService.cls` | CRUD + consulta GestaoSLA__c e MarcoSLA__c | GestaoSLAController |
| `GestaoSLAHelper` | `classes/GestaoSLAHelper.cls` | Auxiliar de montagem/validação de dados SLA | GestaoSLAService |
| `RegrasSLACategorizacaoService` | `classes/RegrasSLACategorizacaoService.cls` | Validação + geração de chave única de RegrasSLACategorizacao__c | GestaoSLAController, Trigger |
| `RegrasSLACompatibilidadeService` | `classes/RegrasSLACompatibilidadeService.cls` | Detecção modelo novo/legado; resolução de tempo por prioridade; fallback | CaseMilestoneTriggerTimeCalculator, AreaParticipanteSLAService |
| `AreaParticipanteSLAService` | `classes/AreaParticipanteSLAService.cls` | Motor N3: beforeSave, calculateCacheBulk, closeSLA | Trigger AreaParticipante__c |
| `CaseAreaParticipantePauseService` | `classes/CaseAreaParticipantePauseService.cls` | Pausa/retomada SLA por EtapaAtendimento | Trigger Case |
| `CaseAreaParticipanteAggregationService` | `classes/CaseAreaParticipanteAggregationService.cls` | Agrega contagens QtdAtuacoesAbertas/Vencidas no Case | AreaParticipanteSLAService |
| `CaseMilestoneMacroService` | `classes/CaseMilestoneMacroService.cls` | SLA macro via Entitlement Process | CaseMilestoneTriggerTimeCalculator |
| `CaseEntitlementAssignmentService` | `classes/CaseEntitlementAssignmentService.cls` | Atribuição de Entitlement ao Case | Trigger Case |
| `CaseCreationService` | `classes/CaseCreationService.cls` | Orquestra abertura manual: herança de valores, Categorização, Entitlement | CaseCreationController |
| `CaseRecategorizationService` | `classes/CaseRecategorizationService.cls` | Recategorização: validação, cópia de campos, redistribuição | CaseRecategorizationController |
| `CaseClosureSurveyService` | `classes/CaseClosureSurveyService.cls` | Controle de fechamento + alerta de pesquisa duplicada | CaseClosureSurveyController |
| `CaseSurveyDispatchService` | `classes/CaseSurveyDispatchService.cls` | Envio efetivo da pesquisa de satisfação | CaseClosureSurveyService |
| `AtendimentoContextResolverService` | `classes/AtendimentoContextResolverService.cls` | Resolve contexto de unidade/atendimento para roteamento | Múltiplos |
| `AtendimentoConfigService` | `classes/AtendimentoConfigService.cls` | Lê configurações por unidade (Custom Metadata) | Múltiplos |
| `BusinessHoursResolverService` | `classes/BusinessHoursResolverService.cls` | Resolução de BusinessHours por unidade | AreaParticipanteSLAService |
| `MessagingContextService` | `classes/MessagingContextService.cls` | Contexto de canal Messaging para WhatsApp/Chat | MessagingContextController |
| `AreaParticipanteService` | `classes/AreaParticipanteService.cls` | CRUD Área Participante + regras de negócio | AreaParticipanteController |
| `LogIntegracaoService` | `classes/LogIntegracaoService.cls` | Registro de erros em LogIntegracao__c | Múltiplas integrações |
| `ControleLogIntegracoesService` | `classes/ControleLogIntegracoesService.cls` | Consulta e limpeza de logs de integração | ControleLogIntegracoesController |

---

## Services — Email-to-Case customizado

| Artefato | Caminho | Responsabilidade |
|---|---|---|
| `WS_EmailToCaseInboundService` | `classes/WS_EmailToCaseInboundService.cls` | Handler principal (implementa InboundEmailHandler) |
| `WS_EmailToCaseRouteService` | `classes/WS_EmailToCaseRouteService.cls` | Resolve rota via WS_Email_Route__mdt; detecta ambiguidade |
| `WS_EmailToCaseDedupService` | `classes/WS_EmailToCaseDedupService.cls` | Deduplicação por MessageIdentifier + rota |
| `WS_EmailToCaseThreadingService` | `classes/WS_EmailToCaseThreadingService.cls` | Resolve Case existente por token/header |
| `WS_EmailToCaseCaseService` | `classes/WS_EmailToCaseCaseService.cls` | Cria / reabre Case |
| `WS_EmailToCaseOwnerService` | `classes/WS_EmailToCaseOwnerService.cls` | Resolve fila/usuário dono |
| `WS_EmailToCaseEmailMessageService` | `classes/WS_EmailToCaseEmailMessageService.cls` | Cria EmailMessage inbound |
| `WS_EmailToCaseAttachmentService` | `classes/WS_EmailToCaseAttachmentService.cls` | Converte anexos para ContentVersion |
| `WS_EmailToCaseLogService` | `classes/WS_EmailToCaseLogService.cls` | Registra erros (somente falhas) |
| `WS_EmailToCaseConfigService` | `classes/WS_EmailToCaseConfigService.cls` | Lê WS_Email_Route__mdt |

---

## Services — Integrações TecSys / TugSys

| Artefato | Caminho | Sistema |
|---|---|---|
| `WSServiceInterfaceTugSys` | `classes/WSServiceInterfaceTugSys.cls` | Integração com TugSys (Rebocadores) |
| `WSServiceInterfaceAgreementTugSys` | `classes/WSServiceInterfaceAgreementTugSys.cls` | Contratos TugSys |
| `IntegracaoTecSys` | `classes/IntegracaoTecSys.cls` | Integração TecSys (cotação/proposta) |
| `TecsysServiceAgent` | `classes/TecsysServiceAgent.cls` | Agent HTTP TecSys |
| `TecsysPartnersEmailService` | `classes/TecsysPartnersEmailService.cls` | Envio de email a parceiros TecSys |
| `GerarTokenTecSys` | `classes/GerarTokenTecSys.cls` | Geração de token TecSys |
| `WSWillCaseCreationService` | `classes/WSWillCaseCreationService.cls` | Criação de Case via Will (bot) |
| `WSWillCaseLookupService` | `classes/WSWillCaseLookupService.cls` | Consulta de Case via Will |
| `WSWillConversationLinkService` | `classes/WSWillConversationLinkService.cls` | Vinculação de conversa Will ao Case |
| `WSWillContextResolverService` | `classes/WSWillContextResolverService.cls` | Resolução de contexto Will |

---

## Classes de cálculo / motor SLA

| Artefato | Caminho | Responsabilidade |
|---|---|---|
| `CaseMilestoneTriggerTimeCalculator` | `classes/CaseMilestoneTriggerTimeCalculator.cls` | Calcula minutos de milestone macro via MarcoSLA__c + GestaoSLA__c |
| `RegrasSLACompatibilidadeService` | `classes/RegrasSLACompatibilidadeService.cls` | Bridge legado/novo; prioridade → TempoBaixa/Media/Alta |
| `AreaParticipanteSLAService` | `classes/AreaParticipanteSLAService.cls` | Motor N3 customizado com fallback |

---

## DTOs / Wrappers

| Artefato | Caminho | Uso |
|---|---|---|
| `GestaoSLADTO` | `classes/GestaoSLADTO.cls` | Transfer Object para LWC gestaoSLAWorkspace |
| `CategorizacaoDTO` | `classes/CategorizacaoDTO.cls` | Transfer Object para categorizacaoManager |
| `InterfaceTugSysTO` | `classes/InterfaceTugSysTO.cls` | Payload TugSys |
| `IntegracaoTecSysTO` | `classes/IntegracaoTecSysTO.cls` | Payload TecSys |

---

## LWC — Módulo Service Cloud

| Componente | Caminho | Apex usado | Responsabilidade |
|---|---|---|---|
| `gestaoSLAWorkspace` | `lwc/gestaoSLAWorkspace/` | GestaoSLAController | Tela administrativa de Gestão de SLA (CRUD GestaoSLA, MarcoSLA, Regras) |
| `caseAreasParticipantesPanel` | `lwc/caseAreasParticipantesPanel/` | AreaParticipanteController | Sidebar do Case: cards com barra de progresso, encerramento de área interna |
| `caseNewCategorization` | `lwc/caseNewCategorization/` | CategorizacaoController | Categorização inicial na abertura manual |
| `caseRecategorization` | `lwc/caseRecategorization/` | CaseRecategorizationController | Recategorização de Case existente |
| `caseClosureSurvey` | `lwc/caseClosureSurvey/` | CaseClosureSurveyController | Encerramento controlado + pesquisa de satisfação |
| `categorizacaoManager` | `lwc/categorizacaoManager/` | CategorizacaoController | CRUD de Categorização (versão SLDS2) |
| `categorizacaoManagerV2` | `lwc/categorizacaoManagerV2/` | CategorizacaoController | V2 do manager (evoluída) |
| `categorizacaoViewerV2` | `lwc/categorizacaoViewerV2/` | CategorizacaoController | Visualizador de árvore de categorização |
| `controleLogIntegracoes` | `lwc/controleLogIntegracoes/` | ControleLogIntegracoesController | Painel de logs de integração |

---

## Triggers e Handlers

| Objeto | Handler | Caminho | Observação |
|---|---|---|---|
| `Categorizacao__c` | `CategorizacaoTriggerHandler` | `classes/CategorizacaoTriggerHandler.cls` | Chave natural/hash, validações |
| `Quote` | `QuoteTriggerHandler` | `classes/QuoteTriggerHandler.cls` | Integração TecSys |
| `QuoteLineItem` | `QuoteLineItemTriggerHandler` | `classes/QuoteLineItemTriggerHandler.cls` | Precificação |
| `Opportunity` | `OpportunityTriggerHandler` | `classes/OpportunityTriggerHandler.cls` | Webhook Lead |
| `InativarProposta` | `InativarPropostaTriggerHandler` | `classes/InativarPropostaTriggerHandler.cls` | Inativar proposta TecSys |

Framework base: `TriggerHandler.cls`

---

## Objetos customizados principais

| Objeto | Finalidade |
|---|---|
| `GestaoSLA__c` | Cabeçalho de configuração SLA por unidade |
| `MarcoSLA__c` | Marcos administráveis por Gestão de SLA |
| `Categorizacao__c` | Árvore Tipo→Categoria→Assunto→Subassunto por unidade |
| `RegrasSLACategorizacao__c` | Regra central SLA (legado: TempoMinutos__c; novo: TempoBaixa/Media/Alta) |
| `Atuacao__c` | Área Participante — SLA individual N3 customizado |
| `Agendamento__c` | Configuração de Cases recorrentes (Apex Scheduler) |
| `Reclamacao__c` | Espelho de reclamações para operação Salvador |
| `LogIntegracao__c` | Log de erros de integração e email-to-case |

---

## Custom Metadata

| Metadata | Finalidade |
|---|---|
| `WS_Email_Route__mdt` | Rotas do Email-to-Case customizado (ativa, match mode, RT, fila, comportamento reabrir) |
| `AtendimentoConfig__mdt` | Configurações por unidade de negócio |

---

## Campos canônicos críticos

| Campo | Objeto | Valor canônico |
|---|---|---|
| `UnidadeNegocios__c` | `Categorizacao__c` | `Atendimento Salvador` / `Atendimento Rio Grande` |
| `UnidadeNegocio__c` | `Case` | Define unidade no Case |
| `EtapaAtendimento__c` | `Case` | Novo, Em Triagem, Em Atendimento, Aguardando Cliente, Aguardando Área Interna, Em Acompanhamento, Preparando Retorno ao Cliente, Concluído, Cancelado |
| `AreasAtendimentoAtivas__c` | `Case` | Multi-Select Picklist — ativa milestones concorrentes de área interna |
| `EscopoRegra__c` | `RegrasSLACategorizacao__c` | Global / Por Categorizacao / Por Area Interna |
| `ChaveNaturalHash__c` | `Categorizacao__c` | Text 64, Unique — unicidade da categorização |
| `ExternalId__c` | `Categorizacao__c` | External ID para upsert seguro |

## Campos customizados relevantes

| Campo | Objeto | Caminho | Responsabilidade |
|---|---|---|---|
| `Teste__c` | `Account` | `objects/Account/fields/Teste__c.field-meta.xml` | Campo texto 255 de teste para WilsonSons Service |

---

## Record Types por objeto

| Objeto | Record Types |
|---|---|
| `Categorizacao__c` | TeconSalvador, TeconRioGrande, CentroLogistico, Rebocadores |
| `Case` | Por unidade de negócio |

---

## Permission Sets

| Permission Set | Escopo |
|---|---|
| Atendimento Salvador | App + RTs + Filas + Páginas/Reports Salvador |
| Atendimento Rio Grande | App + RTs + Filas Rio Grande |
| Atendimento Centro Logístico | App + RTs + Agendamento + Reports CL |
| Atendimento Rebocadores | App + RTs + Filas Rebocadores |
| Supervisor Unidade | Visibilidade expandida dentro da própria unidade |
| Admin / Governança | Acesso admin conforme política de segurança |

---

## Regras de negócio críticas (design constraints)

1. **Compatibilidade legado/novo:** Toda lógica de SLA deve checar `EscopoRegra__c` antes de usar `TempoMinutos__c`. Classe: `RegrasSLACompatibilidadeService`.
2. **Prioridade no modelo novo:** Não entra na chave lógica — apenas seleciona entre `TempoBaixa__c`, `TempoMedia__c`, `TempoAlta__c`.
3. **Case como objeto central:** Todo atendimento é um Case; o modelo de compartilhamento é Private com visibilidade por roles.
4. **Segregação por unidade:** Filas, Record Types, Permission Sets e roles garantem isolamento entre unidades.
5. **Email-to-Case:** Não usa o mecanismo nativo do Salesforce — toda lógica está em `WS_EmailToCaseInboundService` e camadas subjacentes.
6. **Idioma do código:** Inglês para todo código/metadado/label; tradução pt_BR via CustomLabels, Translations e GlobalValueSetTranslations.
7. **Chave natural/hash em Categorização:** Gerada em Apex (trigger), garante unicidade sem uso de External ID do Salesforce como chave de negócio.

---

## Entitlement Process autoritativo

- `force-app/main/default/entitlementProcesses/atendimento salvador_v2.entitlementProcess-meta.xml`
- Milestones macro: Categorização Inicial, Tratamento Principal, Atendimento Área Interna por área, Retorno ao Cliente, SLA Total
- Critério `Resposta Chat`: deve ser OR (Whatsapp OU Chat) — pendência conhecida

---

## Pacotes de desenvolvimento (histórico de evolução)

| Pacote | Entregável principal |
|---|---|
| 1 | GestaoSLA__c + MarcoSLA__c |
| 2 | Categorizacao__c.GestaoSLA__c |
| 3 | Campos modelo novo em RegrasSLACategorizacao__c |
| 4 | RegrasSLACompatibilidadeService + RegrasSLACategorizacaoSelector |
| 5 | CaseMilestoneTriggerTimeCalculator |
| 6 | AreaParticipanteSLAService (motor N3 + fallback) |
| 6.1 | Reforço de testes N3 |
| 7 | Consolidação de metadados + Entitlement Process + alinhamento LWC legado |
| 8 | RegrasSLACategorizacaoService (validação + chave única) |
| 8.1 | Cobertura de testes de classes dependentes |
| 9 | Custom Permissions + Permission Sets da solução |
| 10 | GestaoSLAController / Service / Helper / DTO (backend LWC) |
| Pós-10 | gestaoSLAWorkspace (LWC funcional completa), testes ampliados, metadados renomeados (RioGrande/Salvador/TeconSalvador), globalValueSets, profiles |

---

## Fluxos técnicos principais

### Abertura de Case via Email

```text
Email inbound
  → WS_EmailToCaseInboundService
  → WS_EmailToCaseRouteService (resolve rota via WS_Email_Route__mdt)
  → WS_EmailToCaseDedupService (dedup por MessageIdentifier)
  → WS_EmailToCaseThreadingService (Case existente por token?)
  → WS_EmailToCaseCaseService (cria / reabre Case)
  → WS_EmailToCaseOwnerService (fila/usuário dono)
  → WS_EmailToCaseEmailMessageService (EmailMessage inbound)
  → WS_EmailToCaseAttachmentService (ContentVersion)
  → LogIntegracao__c (somente em erro)
```

### Cálculo de SLA macro (Entitlement Process)

```text
Case salvo
  → CaseMilestoneTriggerTimeCalculator
  → CaseMilestoneMacroService
  → RegrasSLACompatibilidadeService (resolve tempo por modelo + prioridade)
  → RegrasSLACategorizacao__c / MarcoSLA__c / GestaoSLA__c
```

### SLA individual N3 (Área Participante)

```text
Atuacao__c criada/atualizada
  → AreaParticipanteSLAService.beforeSave / calculateCacheBulk / closeSLA
  → RegrasSLACompatibilidadeService (EscopoRegra = Por Area Interna; fallback legado)
  → BusinessHoursResolverService (business hours por unidade)
  → CaseAreaParticipanteAggregationService (atualiza contagens no Case)
```

### Categorização de Case (manual)

```text
LWC caseNewCategorization
  → CaseCreationController
  → CaseCreationService (herança de campos, lookup Categorização, Entitlement)
  → CaseEntitlementAssignmentService
  → Trigger Case
```

### Gestão de SLA (tela administrativa)

```text
LWC gestaoSLAWorkspace
  → GestaoSLAController
  → GestaoSLAService
  → GestaoSLAHelper / GestaoSLADTO
  → GestaoSLA__c / MarcoSLA__c / RegrasSLACategorizacao__c
```

---

## Pendências conhecidas

1. Critério `Resposta Chat` no Entitlement Process — precisa ser OR (Whatsapp OU Chat)
2. `PROJECT_INDEX.md` era raso desde o commit inicial — agora atualizado (2026-06-12)
3. Permission Sets evoluíram além do escopo original do Pacote 9

---

## Infra de Skills para Agentes

| Artefato | Caminho | Finalidade |
|---|---|---|
| Biblioteca oficial Salesforce | `.agents/skills/` | Skills do repositório `forcedotcom/sf-skills` |
| Skill local Triskal | `agents/skills/triscal-salesforce/SKILL.md` | Padrões do projeto |
| Controle de versão | `.agents/SF_SKILLS_VERSION.json` | Commit e origem da biblioteca |
| Script de atualização | `scripts/sync-sf-skills.ps1` | Resync seguro sem perder skill local |
