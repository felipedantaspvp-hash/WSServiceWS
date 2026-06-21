# PROJECT_INDEX.md — Índice técnico leve do projeto

> Não copie código inteiro neste arquivo.  
> Use apenas referências para orientar leitura seletiva e economizar tokens.

## Última atualização

- Data: 2026-06-21
- Responsável: Claude (migração da manutenção de Categorizacao__c para o gestaoSLAWorkspace, a pedido de Jean Duarte)
- Observação: **Migração da distribuição de fila para o gestaoSLAWorkspace e descontinuação do override legado (2026-06-21):** Achado: existia um componente Aura `categorizacaoManagerOverride`/`categorizacaoViewOverride` (overrides de New/Edit/View do objeto `Categorizacao__c`) que delegava para LWCs `categorizacaoManagerV2`/`categorizacaoViewerV2` — nenhum dos dois estava versionado em `force-app` (vivia só na Org `WILSON_SERVICE`); recuperados via `sf project retrieve start -m "LightningComponentBundle:categorizacaoManagerV2,categorizacaoViewerV2"` para análise. Esse componente legado já implementava a parte que faltava no `gestaoSLAWorkspace`: listagem dinâmica de campos picklist do `Case` (`CategorizacaoController.getCasePicklistFields`), listagem de filas por unidade (`CategorizacaoController.getQueues`) e show/hide condicional dos campos de distribuição. Em vez de recriar essa lógica, ela foi **portada/reaproveitada** (sem duplicar Apex): `gestaoSLAWorkspace.js` agora importa `getCasePicklistFields`/`getQueues` diretamente de `CategorizacaoController` (classe mantida — também usada por `CategorizacaoHelper.isTrueFlag` em `CaseRecategorizationService`). `GestaoSLADTO.CategoriaRequest`/`CategoriaResumo`: +5/+8 campos de distribuição (`distribuirParaFila`, `porCategorizacao`, `filaDeveloperName`, `campoDistribuicao`, `valorDistribuicao` + labels/nome de fila no Resumo). `GestaoSLAService`: novo `applyDistribuicaoRequest()` (seta os campos a partir do request) e `queryCategoriaById()` (re-consulta pós-DML para refletir o que o trigger calculou); `createCategoria`/`updateCategoria` agora capturam `DmlException` e relançam como `FunctionalException` amigável — a validação de obrigatoriedade (fila obrigatória; campo+valor obrigatórios quando não é por categorização) **já existia** no trigger (`CategorizacaoTriggerHandler` -> `CategorizacaoService.beforeSave/validateAndNormalize`), rodando para qualquer ponto de entrada, então não foi duplicada. LWC `gestaoSLAWorkspace`: modal de Categoria ganhou toggles "Distribuir para fila?"/"Por categorização?" e combos de Fila/Campo/Valor, com show/hide replicando o padrão do componente legado. 8 novos Custom Labels (`GestaoSLA_CategoryDistributeToQueue`, `CategoryByCategorization`, `CategoryQueue(+Placeholder)`, `CategoryDistributionField(+Placeholder)`, `CategoryDistributionValue(+Placeholder)`) em PT/EN. Testes novos em `GestaoSLAServiceTest` (persistência dos campos de distribuição + 2 cenários de erro funcional amigável). **Descontinuação do componente legado:** `lwc/categorizacaoManagerV2`, `lwc/categorizacaoViewerV2`, `aura/categorizacaoManagerOverride`, `aura/categorizacaoViewOverride` excluídos do source local; `actionOverrides` de New/Edit/View em `Categorizacao__c.object-meta.xml` revertidos para `Default` (comportamento padrão do Salesforce). Exclusão da Org preparada em `Deltas/delta_categorizacao_legacy_lwc_removal/destructiveChanges.xml` (LightningComponentBundle + AuraDefinitionBundle) — **pendente de deploy**, não executado nesta sessão sem confirmação explícita do usuário. **Pendência geral:** nada deployado/testado em Org nesta sessão além do retrieve de leitura — rodar `sf project deploy validate` (código novo) e o destructive deploy (componentes legados) antes de considerar a frente fechada de fato. **Saneamento de segurança GestaoSLA por Record Type (2026-06-20):** Gap identificado por leitura de código: `GestaoSLAService.getBootstrap()` listava `GestaoSLA__c` de todas as 4 Unidades de Negócio para qualquer usuário com a Custom Permission `AcessarGestaoSLA`, sem checar o Record Type de Case disponível ao usuário — violando a segregação por unidade da especificação. Corrigido com `GestaoSLAHelper.getAllowedUnidadesNegocio()` (novo método: deriva as Unidades de Negócio permitidas a partir de `Schema.RecordTypeInfo.isAvailable()` em `Case` + mapeamento `ParametrosAtendimento__mdt.CaseRecordTypeDeveloperName__c -> UnidadeNegocio__c` via `AtendimentoConfigService`, com seam de teste `setAllowedUnidadesOverride`/`clearAllowedUnidadesOverride`). `GestaoSLAService`: novo helper privado `resolveAllowedUnidades(perms)` (retorna `null` = irrestrito para quem tem `canAdminTechnicalSettings`) e `ensureUnidadeAllowed(unidade, allowed)`, aplicados em `getBootstrap` (filtra a query + lança erro funcional se nenhuma unidade disponível), `getGestaoDetail`, `getCategorias`, `createCategoria`, `updateCategoria`, `deactivateCategoria`, `getInactiveCategorias` e `reactivateCategoria`. `GestaoSLADTO.BootstrapResponse`: +`unidadesDisponiveis` (List<String>, null=irrestrito) e +`unidadeUnica` (String, preenchido quando há só 1 opção). LWC `gestaoSLAWorkspace` não precisou de alteração: o seletor de Gestão já era condicionado a `canAdminTechnicalSettings` e `resolveSelectedGestaoId()` já auto-seleciona `gestoes[0]` — com a lista agora corretamente filtrada no backend, a auto-seleção passa a ser segura. Testes novos: `GestaoSLAHelperTest` (seam de override) e `GestaoSLAServiceTest` (bootstrap restrito a 1 unidade, admin irrestrito, sem unidade disponível lança erro, createCategoria/getCategorias bloqueados para unidade não permitida); todos os testes pré-existentes que chamam `getBootstrap/getGestaoDetail/getCategorias/createCategoria/updateCategoria/deactivateCategoria/reactivateCategoria` foram ajustados para chamar `GestaoSLAHelper.setAllowedUnidadesOverride(null)` junto do `clearPermissionOverrides()`, preservando o comportamento irrestrito que já assumiam. **Pendência:** não deployado nem testado em Org nesta sessão (sem sf CLI conectado) — rodar `sf project deploy validate` e a suíte de testes antes do merge. Achado correlato (registrado, não implementado): Permission Sets hoje não são segregados por Unidade de Negócio (apenas `GestaoSLAConfigurador`/`GestaoSLAAdminTecnico`/`CaseAcompanhamentoOperador`/`AccountCaseScheduleOperador`, todos globais) — proposta de saneamento (2 PS por unidade: Gestor/Atendente + 1 PS global de Admin Técnico) registrada na planilha de checklist, pendente de desenho/implementação. **Retrieve Marllon 17/06 (2026-06-18):** trazido para o working tree (ainda não commitado/revisado) tudo que o usuário Marllon Nascimento criou/alterou na `WILSON_SERVICE` em 2026-06-17, apurado via `SetupAuditTrail`. Novo módulo "Acompanhamento de Case": objeto custom `Acao__c` (registra início/fim, tipo, status, motivo de pausa, comentários de entrada/saída, duração calculada) relacionado a `Case`; campos novos em `Case` (`AcaoPausaAtiva__c`, `DataInicioAcompanhamento__c`, `EtapaAnteriorAcompanhamento__c`, `MotivoAcompanhamento__c`, `UltimoComentarioAcompanhamento__c`, `UsuarioInicioAcompanhamento__c`); classes `CaseAcompanhamentoController/DTO/Service(+Test)`; LWCs `caseAcompanhamentoAction`, `caseAcompanhamentoBanner`, `caseAcompanhamentoRefresh`; Quick Action `Colocar_em_Acompanhamento` no Case; Permission Set `CaseAcompanhamentoOperador`; FLS ajustado no profile `Admin`. Também trazidas: módulo de notificação de abertura de Case (`CaseOpeningNotificationService/ServiceAgent(+Test)`, chamado por `CaseAfterInsertTriggerHandler`), 3 novos campos em `ParametrosAtendimento__mdt` (`SendCaseOpeningEmail__c`, `CaseOpeningTemplateDeveloperName__c`, `CaseOpeningTemplateDeveloperNameEN__c`) com respectivo layout, e ajustes pontuais em `CaseClosureSurvey*`, `AtendimentoConfig*`, `CaseSurveyDispatchHelper/ServiceAgent`. Manifest usado: `manifest/retrieve-marllon-20260617.xml`. **Pendências de Omni-Channel (não retrieváveis/aplicáveis aqui, registradas só para contexto):** Marllon também criou/ajustou em 17/06 `QueueRoutingConfig Service_Routing_Case_N1`, `ServicePresenceStatus Caso_Disponivel`/`Caso_Messaging_Online`, renomeou o `ServiceChannel Email` para `Case`/`Caso`, e ajustou membership da fila `Atendimento N1 - Centro Logístico` — configuração viva na org, não capturada em metadata local. **Pacote 24 (2026-06-15):** Serviço read-only de auditoria de inconsistências de SLA. Novas classes: `GestaoSLAHealthCheckDTO` (DTO HealthCheckResult+Issue), `GestaoSLAHealthCheckService` (4 checks, 7 SOQL, 0 DML, `with sharing`), `GestaoSLAHealthCheckServiceTest` (16 testes). Regras detectadas: REGRA_SEM_BUSINESS_HOURS, ESCOPO_LEGADO, REGRA_DUPLICADA, REGRA_SEM_PRAZO (checkRegrasSLA); CUSTOM_ABERTA_SEM_PRAZO, SEM_STATUS_ATUACAO, SEM_STATUS_SLA, STATUS_SLA_INCOERENTE_*, VIOLOU_SLA_INCONSISTENTE_*, PAUSADO_SEM_DATA_INICIO_PAUSA, DATA_INICIO_PAUSA_INDEVIDA, TEMPO_PAUSADO_NEGATIVO (checkAreaParticipante); STANDARD_COM_PAUSA, STANDARD_SEM_MILESTONE, CUSTOM_COM_MILESTONE (checkStandardVsCustom); CASE_TERMINAL_COM_AREA_ABERTA (checkCaseEtapa). Delta: `delta_gestao_sla_health_check/`. Dry-run `0Afbe00000AAH8HCAX` Succeeded, 16/16 testes. **Pacote 22 ajustado (2026-06-15):** Hardcoded Ids removidos; teste de retomada de área vencida adicionado; sincronização delta↔force-app; dry-run `0Afbe00000AAAJhCAP` Succeeded, 40/40 testes. **Pacote 23 ajustado (2026-06-14):** `canPause` e `canResume` passaram a ser calculados no backend (`AreaParticipanteService` -> `AreaParticipanteDTO`) considerando `TipoAreaParticipante__c = Area Interna`, `OrigemSLA__c = Custom`, estado terminal e estado de pausa; o LWC `caseAreasParticipantesPanel` apenas renderiza as flags. O teste Jest do componente foi incluido no delta como artefato de apoio em `tests/lwc/...`. `package.xml` alinhado para `66.0`. Dry-run corrigido `0Afbe00000AAAd3CAH` Succeeded, 40/40 testes. **Pacote 22 (2026-06-14):** Pausa/retomada operacional de `AreaParticipante__c` para Area Interna Custom manual via `AreaParticipanteService` e `AreaParticipanteController`; sem criar Flow, Trigger, LWC, campo, layout ou Permission Set. Pausa usa `StatusSLA__c = 'Pausado'` e `DataHoraInicioPausa__c`, preservando `StatusAtuacao__c` porque nao existe valor oficial `Pausada`. Retomada acumula `TempoPausadoMinutos__c`, estende `DataHoraPrazo__c` e recalcula cache SLA. `OrigemSLA__c = Standard` e registros terminais sao rejeitados antes de DML. Delta: `delta_area_participante_pausa_retomada/`. Dry-run `0Afbe00000AA5NGCA1` Succeeded, 39/39 testes. **Pacote 21 v3 (2026-06-14):** Orquestração de EtapaAtendimento__c no ciclo de vida das Áreas Internas. `AreaParticipanteSelector`: removido IsClosed de getCaseById() (Status já existia); +OrigemSLA__c em getAreasByCase() e getAreaById(). `AreaParticipanteService.addParticipation()` e `closeParticipation()`: guard terminal usa `statusNorm.contains('fechad')` (Status) em vez de IsClosed; loop de contagem usa `OrigemSLA__c = 'Custom'` explicitamente em vez do proxy BloqueiaFechamentoCaso__c. `AreaParticipanteServiceTest`: teste de Case fechado usa `new Case(Status='Fechado')` sem JSON.deserialize. Deploy definitivo `0Afbe00000AA4PZCA1` Succeeded, 20/20 testes, Selector 97%, Service 85%. **Pacote 20 (2026-06-14):** Bloqueio de fechamento/cancelamento de Case com Área Interna aberta. `CaseTriggerHandler.beforeUpdate`: + detecção `EtapaAtendimento__c = 'Cancelado'`; + filtro `OrigemSLA__c = 'Custom'` na query; + mensagem funcional. `CaseTriggerHandlerTest`: 7 cenários (8 total). Dry-run `0Afbe00000AA0fJCAT` Succeeded, 12/12 testes, 96% cobertura. **Pacote 19 (2026-06-14):** Sincronização de CaseMilestones para AreaParticipante__c — 3 novas classes (Service, Batch, Scheduler) + 2 testes. AreaParticipanteSLAHelper: +ORIGEM_SLA_STANDARD. AreaParticipanteSLAService: guards Standard em beforeSave/closeSLA + fix NPE em MAX(SequenciaAcionamento__c). Dry-run 0Afbe00000AA05pCAD Succeeded, 45/45 testes. Delta: delta_area_participante_milestone_sync/. **Pacote 18 reformulado (2026-06-14):** Ajustado LWC existente `caseAreasParticipantesPanel` — componente real na `LP_Atendimento_Salvador`. Adicionados getter `canManage`, botão Atualizar e `masterLabel`. LWC `caseAreaParticipantePanel` (criado no Pacote 18 original) descartado e excluído do source. Delta: `Deltas/delta_area_participante_case_component_existing_fix/`. Dry-run `0Afbe00000A9ydVCAR` Succeeded (Changed 4 arquivos). **Cleanup RegrasSLA (2026-06-14):** Removido `MarcoSLA__c` de regras `Area Interna` em 6 classes de teste (RegrasSLA x5 + CategorizacaoServiceTest). Corrigido `SLACoverageCoreTest.testAreaLifecyclePauseResumeCloseAndBlockCaseClose` e `testBatchAndSchedulerAndGuard` para definir `Categorizacao.GestaoSLA__c` antes de inserir `AreaParticipante__c` (bug latente pós-17A v2). `testFindActiveRulesNovoN3Coverage` ajustado para assertar 0 resultados (método legado não retorna Area Interna sem MarcoSLA). Deploy `0Afbe00000A9x37CAB` Succeeded. 33/33 testes. Nota: `CategorizacaoServiceTest` ainda tem 2 ocorrências da violação (fora do escopo). **Cleanup 17A (2026-06-14):** Removido `createRegraLegada` (dead code) de `AreaParticipanteSLAServiceTest`. Removido `TipoAreaParticipante__c` desnecessário de `RegrasSLACategorizacao__c` em 3 test factories. Corrigido `CaseAreaParticipantePauseServiceTest.createRule` para incluir `Categorizacao.GestaoSLA__c` e remover `MarcoSLA__c` legado. Deploy `0Afbe00000A9wNBCAZ` Succeeded. 49/49 testes. **Pacote 17A v2 (2026-06-14):** SequenciaAcionamento__c agora é global por Case (não mais por Case+Area). findRule() e getEligibleAreaValuesForCase() incluem filtro explícito GestaoSLA__c via getSObject('Categorizacao__r'). Factory usa shared GestaoSLA__c para todos os registros do mesmo Case. +1 teste (testSequenciaGlobalPorCaseNaoPorArea). Deploy `0Afbe00000A9wAHCAZ` Succeeded. 43/43 testes. **17A v1 (2026-06-14):** Deploy `0Afbe00000A9vnhCAB` Succeeded. 42/42 testes. **16B (2026-06-13):** campos legados excluídos fisicamente da org via destructiveChanges — dry-run `0Afbe00000A9v9NCAR` (Succeeded) e deploy real `0Afbe00000A9vAzCAJ` (Succeeded). Campos excluídos: `RegrasSLACategorizacao__c.Origem__c`, `RegrasSLACategorizacao__c.VigenciaInicio__c`, `RegrasSLACategorizacao__c.VigenciaFim__c`, `AreaParticipante__c.TipoAtuacao__c`. Regra: `@last modified by` sempre nome do usuário Salesforce da org (nunca nome de IA).

---

## Estrutura principal

```text
force-app/
manifest/
```

---

## Arquitetura identificada

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

---

## Controllers / FlowActions

| Artefato | Caminho | Responsabilidade | Chama |
|---|---|---|---|
| AreaParticipanteController | force-app/main/default/classes/AreaParticipanteController.cls | Expõe endpoints @AuraEnabled para AreaParticipante__c: getPanelDataFresh, addParticipation, addParticipationBulk, closeParticipation, pauseParticipation, resumeParticipation, getParticipationDetails. Sem lógica de negócio. | AreaParticipanteService |
| CaseAcompanhamentoController | force-app/main/default/classes/CaseAcompanhamentoController.cls | Expõe endpoints @AuraEnabled para o módulo Ação/Acompanhamento de Case (criado por Marllon, retrieve 17/06/2026). | CaseAcompanhamentoService |

## Services

| Artefato | Caminho | Responsabilidade | Chamado por |
|---|---|---|---|
| AreaParticipanteService | force-app/main/default/classes/AreaParticipanteService.cls | Lógica de negócio de AreaParticipante__c: adição unitária (addParticipation) e bulk (addParticipationBulk), encerramento, pausa, retomada e leitura de painel. Valida CRUD/FLS, regras SLA, unicidade de ciclo aberto. | AreaParticipanteSLAService, AreaParticipanteSelector, BusinessHoursResolverService |
| CaseAreaParticipantePauseService | force-app/main/default/classes/CaseAreaParticipantePauseService.cls | Pausa/retoma AreaParticipante interna ao entrar/sair de "Aguardando Cliente"; registra DataHoraPausaMilestone__c no Case para rastreamento de pausa dos marcos nativos. | CaseTriggerHandler.afterUpdate |
| CaseMilestoneMacroService | force-app/main/default/classes/CaseMilestoneMacroService.cls | Fecha marcos SLA não-SLA Total em qualquer transição de EtapaAtendimento__c; fecha SLA Total na conclusão/cancelamento do Case. | CaseTriggerHandler.afterUpdate |
| AreaParticipanteMilestoneSyncService | force-app/main/default/classes/AreaParticipanteMilestoneSyncService.cls | Espelha CaseMilestones para AreaParticipante__c (OrigemSLA__c='Standard'); idempotência via CaseMilestoneId__c; preserva Custom. Pacote 19. | AreaParticipanteMilestoneSyncBatch, CaseMilestoneSyncQueueable |
| CaseAfterInsertTriggerHandler | force-app/main/default/classes/CaseAfterInsertTriggerHandler.cls | Handler do CaseAfterInsertTrigger; ao inserir um Case, enfileira CaseMilestoneSyncQueueable para sincronizar CaseMilestones gerados pelo EntitlementProcess; também dispara CaseOpeningNotificationServiceAgent (ajuste de Marllon, retrieve 17/06/2026). | CaseAfterInsertTrigger |
| CaseAcompanhamentoService | force-app/main/default/classes/CaseAcompanhamentoService.cls | Lógica de negócio do objeto `Acao__c` (início/fim de ação, pausa, comentários de entrada/saída) vinculada ao Case via Quick Action `Colocar_em_Acompanhamento`. Criado por Marllon, retrieve 17/06/2026. | CaseAcompanhamentoController |
| CaseOpeningNotificationService | force-app/main/default/classes/CaseOpeningNotificationService.cls | Envia e-mail de abertura de Case conforme `ParametrosAtendimento__mdt.SendCaseOpeningEmail__c`/`CaseOpeningTemplateDeveloperName__c`(EN). Criado por Marllon, retrieve 17/06/2026. | CaseOpeningNotificationServiceAgent |
| CaseOpeningNotificationServiceAgent | force-app/main/default/classes/CaseOpeningNotificationServiceAgent.cls | ServiceAgent acionado pelo CaseAfterInsertTriggerHandler para disparar a notificação de abertura. Criado por Marllon, retrieve 17/06/2026. | CaseAfterInsertTriggerHandler |
| CaseMilestoneSyncQueueable | force-app/main/default/classes/CaseMilestoneSyncQueueable.cls | Queueable que chama AreaParticipanteMilestoneSyncService.syncByCaseIds(); executa fora da transação para aguardar CaseMilestones do EntitlementProcess. Pacote 24A. | CaseAfterInsertTriggerHandler |
| AreaParticipanteMilestoneSyncBatch | force-app/main/default/classes/AreaParticipanteMilestoneSyncBatch.cls | Apex Batch que processa Cases em lote de 200 chamando syncByCaseIds; suporta filtro por Set<Id> ou QueryLocator global. Pacote 19. | AreaParticipanteMilestoneSyncScheduler |
| AreaParticipanteMilestoneSyncScheduler | force-app/main/default/classes/AreaParticipanteMilestoneSyncScheduler.cls | Schedulable que agenda AreaParticipanteMilestoneSyncBatch periodicamente (ex: daily às 02h). Pacote 19. | — |

## Selectors

| Artefato | Caminho | SObjects cobertos | Chamado por |
|---|---|---|---|
| AreaParticipanteSelector | force-app/main/default/classes/AreaParticipanteSelector.cls | AreaParticipante__c | AreaParticipanteService |
| GestaoSLASelector | force-app/main/default/classes/GestaoSLASelector.cls | GestaoSLA__c, Categorizacao__c, MarcoSLA__c, RegrasSLACategorizacao__c — 26 métodos estáticos | GestaoSLAService |
| CaseSurveyDispatchSelector | force-app/main/default/classes/CaseSurveyDispatchSelector.cls | Case, SurveySubject, Survey, EmailTemplate, OrgWideEmailAddress, Network | CaseSurveyDispatchService |
| WSWillCaseCreationSelector | force-app/main/default/classes/WSWillCaseCreationSelector.cls | Contact, MessagingSession, MessagingEndUser, Case, QueueSobject — 6 métodos; corrige SOQL-in-loop do insert de Cases | WSWillCaseCreationService |
| AtendimentoContextResolverSelector | force-app/main/default/classes/AtendimentoContextResolverSelector.cls | Contact, Account, TCO_ChannelRouting__mdt — 3 métodos estáticos; SOQLs dinâmicos (ConversationGateway, fetchContactsByEndUser) permanecem no Service por necessidade de schema runtime | AtendimentoContextResolverService |

## ServiceAgents / Integrações

| Artefato | Caminho | API/Sistema | Named Credential | Custom Metadata |
|---|---|---|---|---|

## DTOs / Wrappers

| Artefato | Caminho | Uso |
|---|---|---|
| AreaParticipanteDTO | force-app/main/default/classes/AreaParticipanteDTO.cls | DTOs do módulo AreaParticipante: PanelDTO, AreaItemDTO, AddRequestDTO, AddBulkRequestDTO/ItemDTO/ResponseDTO, CloseRequestDTO/ResponseDTO, PauseResumeRequestDTO/ResponseDTO, DetailDTO. |

## LWCs

| Componente | Caminho | Apex usado | Responsabilidade |
|---|---|---|---|
| caseAreasParticipantesPanel | force-app/main/default/lwc/caseAreasParticipantesPanel/ | AreaParticipanteController (getPanelDataFresh, addParticipationBulk, closeParticipation, pauseParticipation, resumeParticipation, getParticipationDetails) | Painel de Áreas Participantes na LP_Atendimento_Salvador: lista agrupada Aberto/Concluído, modal wizard 2 passos (dual-listbox de seleção + comentário por área) para adicionar múltiplas áreas, encerramento, pausa/retomada, detalhes, bilíngue PT+EN, SLA. |
| caseAcompanhamentoAction / caseAcompanhamentoBanner / caseAcompanhamentoRefresh | force-app/main/default/lwc/caseAcompanhamento*/ | CaseAcompanhamentoController | Trio de LWCs na LP_Atendimento_Salvador para colocar o Case "em Espera" (Quick Action `Colocar_em_Acompanhamento`), exibir banner de status e permitir refresh manual. Criado por Marllon, retrieve 17/06/2026. |
| caseClosureSurvey | force-app/main/default/lwc/caseClosureSurvey/ | CaseClosureSurveyController | Pesquisa de satisfação no encerramento do Case; ajustado por Marllon em 17/06/2026 (sincronizado via retrieve, sem alteração de Claude/Codex). |
| gestaoSLAWorkspace | force-app/main/default/lwc/gestaoSLAWorkspace/ | GestaoSLAController | Workspace administrativo de GestaoSLA — gerencia Categorias e Regras SLA; usado em AppPage/Tab. |

## Flows

| Flow | Caminho | Objeto | Tipo | Before/After | Observação |
|---|---|---|---|---|---|
| Case_EntitlementAutoAssignment | force-app/main/default/flows/Case_EntitlementAutoAssignment.flow-meta.xml | Case | Record-Triggered | Before Save — Create | Busca Entitlement WHERE UnidadeNegocio__c = Case.UnidadeNegocio__c (LIMIT 1) e atribui EntitlementId. Substitui o Apex CaseEntitlementAssignmentService.assignForSalvador, cobrindo todas as 4 unidades. Ativo. |

## Objetos / Campos relevantes

| Objeto | Campo/Metadata | Caminho | Uso |
|---|---|---|---|
| EntitlementProcess | atendimento salvador_v2 | force-app/main/default/entitlementProcesses/atendimento salvador_v2.entitlementProcess-meta.xml | Processo ativo/default v2 de Atendimento Salvador para Case; referencia Business Hours `Atendimento Salvador` e milestones de SLA. |
| EntitlementProcess | atendimento rio grande_v2 | force-app/main/default/entitlementProcesses/atendimento rio grande_v2.entitlementProcess-meta.xml | Processo ativo/default v2 de Atendimento Rio Grande para Case; referencia Business Hours `Atendimento Rio Grande` (a criar na org) e milestones de SLA. |
| EntitlementProcess | atendimento centro logistico_v2 | force-app/main/default/entitlementProcesses/atendimento centro logistico_v2.entitlementProcess-meta.xml | Processo ativo/default v2 de Atendimento Centro Logístico para Case; referencia Business Hours `Atendimento Centro Logístico` (a criar na org) e milestones de SLA. |
| EntitlementProcess | atendimento rebocadores_v2 | force-app/main/default/entitlementProcesses/atendimento rebocadores_v2.entitlementProcess-meta.xml | Processo ativo/default v2 de Atendimento Rebocadores para Case; referencia Business Hours `Atendimento Rebocadores` (a criar na org) e milestones de SLA. |
| MilestoneType | Acompanhamento; Atendimento; Atendimento N3; Primeira Resposta (Fila N2); Resposta Chat; Retorno N3; SLA Total; Triagem | force-app/main/default/milestoneTypes/ | Milestones usados pelo Entitlement Process `atendimento salvador_v2`. |
| Settings | BusinessHours | force-app/main/default/settings/BusinessHours.settings-meta.xml | Settings org-level de Business Hours; inclui `Atendimento Salvador`, além de outros horários retornados pela Metadata API. |
| Settings | Entitlement | force-app/main/default/settings/Entitlement.settings-meta.xml | Settings org-level necessários para Entitlement Management. |
| Case | DataHoraPausaMilestone__c (DateTime) | force-app/main/default/objects/Case/fields/DataHoraPausaMilestone__c.field-meta.xml | Registra início da pausa dos marcos SLA nativos ao entrar em "Aguardando Cliente"; limpo ao sair. Usado por CaseAreaParticipantePauseService. FLS Admin: editable+readable. |
| Acao__c | Objeto custom (Case__c, DataInicio__c, DataFim__c, Status__c, Tipo__c, MotivoPausa__c, SlaPausado__c, EtapaAnterior__c, ComentarioEntrada__c, ComentarioSaida__c, UsuarioInicio__c, UsuarioFim__c, DuracaoMinutos__c fórmula) | force-app/main/default/objects/Acao__c/ | Registro de ações/acompanhamento atrelado ao Case (módulo "Colocar em Espera"). Criado por Marllon, retrieve 17/06/2026. |
| Case | AcaoPausaAtiva__c, DataInicioAcompanhamento__c, EtapaAnteriorAcompanhamento__c, MotivoAcompanhamento__c, UltimoComentarioAcompanhamento__c, UsuarioInicioAcompanhamento__c | force-app/main/default/objects/Case/fields/ | Espelham o estado da Ação ativa de acompanhamento no próprio Case. Criado por Marllon, retrieve 17/06/2026. |
| ParametrosAtendimento__mdt | SendCaseOpeningEmail__c, CaseOpeningTemplateDeveloperName__c, CaseOpeningTemplateDeveloperNameEN__c | force-app/main/default/objects/ParametrosAtendimento__mdt/fields/ | Controlam se/qual template de e-mail é enviado na abertura do Case (CaseOpeningNotificationService). Habilitado em 17/06/2026 nos registros Tecon Salvador, Tecon Rio Grande, Rebocadores e Centro Logístico. |

## Layouts / FlexiPages

| Artefato | Caminho | Objeto | Ativação/uso |
|---|---|---|---|

## Permission Sets / Profiles

| Artefato | Caminho | Finalidade |
|---|---|---|
| Profiles (`force-app/main/default/profiles/`) | force-app/main/default/profiles/ | Fonte local dos perfis recuperados da `WILSON_SERVICE`; FLS de `AreaParticipante__c` padronizado para `Admin` com acesso total e demais perfis sem acesso aos 32 campos locais. Exceção pendente: `B2BMA Integration User`, bloqueado por licença gerenciada ao redeployar o profile completo. |
| Admin | force-app/main/default/profiles/Admin.profile-meta.xml | Perfil administrativo com `readable/editable` ativo em todos os 32 campos locais de `AreaParticipante__c`, após normalização de FLS. |

## Testes

| Classe de teste | Caminho | Cobre |
|---|---|---|

## Histórico de pacotes relevantes

| Pacote | Escopo | Campos/Constantes removidos |
|---|---|---|
| 20 | Bloqueio de fechamento/cancelamento de Case com Área Interna aberta | — |
| 15D | Refatoração de escopos | `ESCOPO_GLOBAL`, `ESCOPO_POR_CATEGORIZACAO`, `ESCOPO_POR_AREA_INTERNA` renomeados para `ESCOPO_ATENDIMENTO` e `ESCOPO_AREA_INTERNA` em `RegrasSLACompatibilidadeService` |
| 16A | Remoção de referências de campos legados | `Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c` de `RegrasSLACategorizacao__c`; `TipoAtuacao__c` de `AreaParticipante__c` — referências removidas do código/metadado |
| 16B | Exclusão física dos campos | `RegrasSLACategorizacao__c.Origem__c`, `VigenciaInicio__c`, `VigenciaFim__c`; `AreaParticipante__c.TipoAtuacao__c` — excluídos via destructiveChanges. Deploy `0Afbe00000A9vAzCAJ` Succeeded. |

## Fluxos técnicos principais

### Fluxo 1

```text
Entrada:
Camadas:
Saída:
Riscos:
```

### SLA Atendimento Salvador v2

```text
Entrada: Case associado ao Entitlement Process ativo/default `atendimento salvador_v2`.
Camadas: EntitlementProcess -> MilestoneType -> ApexClass CaseMilestoneTriggerTimeCalculator.
Saída: Milestones de triagem, resposta, atendimento, acompanhamento e SLA total aplicados ao Case.
Riscos: BusinessHours é recuperado como Settings org-level; revisar escopo antes de deploy para não sobrescrever horários não relacionados.
```
