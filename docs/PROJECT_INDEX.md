# PROJECT_INDEX.md — Índice técnico leve do projeto

> Não copie código inteiro neste arquivo.  
> Use apenas referências para orientar leitura seletiva e economizar tokens.

## Última atualização

- Data: 2026-06-14
- Responsável: Jean Duarte
- Observação: **Pacote 23 ajustado (2026-06-14):** `canPause` e `canResume` passaram a ser calculados no backend (`AreaParticipanteService` -> `AreaParticipanteDTO`) considerando `TipoAreaParticipante__c = Area Interna`, `OrigemSLA__c = Custom`, estado terminal e estado de pausa; o LWC `caseAreasParticipantesPanel` apenas renderiza as flags. O teste Jest do componente foi incluido no delta como artefato de apoio em `tests/lwc/...`. `package.xml` alinhado para `66.0`. Dry-run corrigido `0Afbe00000AAAd3CAH` Succeeded, 40/40 testes. **Pacote 22 (2026-06-14):** Pausa/retomada operacional de `AreaParticipante__c` para Area Interna Custom manual via `AreaParticipanteService` e `AreaParticipanteController`; sem criar Flow, Trigger, LWC, campo, layout ou Permission Set. Pausa usa `StatusSLA__c = 'Pausado'` e `DataHoraInicioPausa__c`, preservando `StatusAtuacao__c` porque nao existe valor oficial `Pausada`. Retomada acumula `TempoPausadoMinutos__c`, estende `DataHoraPrazo__c` e recalcula cache SLA. `OrigemSLA__c = Standard` e registros terminais sao rejeitados antes de DML. Delta: `delta_area_participante_pausa_retomada/`. Dry-run `0Afbe00000AA5NGCA1` Succeeded, 39/39 testes. **Pacote 21 v3 (2026-06-14):** Orquestração de EtapaAtendimento__c no ciclo de vida das Áreas Internas. `AreaParticipanteSelector`: removido IsClosed de getCaseById() (Status já existia); +OrigemSLA__c em getAreasByCase() e getAreaById(). `AreaParticipanteService.addParticipation()` e `closeParticipation()`: guard terminal usa `statusNorm.contains('fechad')` (Status) em vez de IsClosed; loop de contagem usa `OrigemSLA__c = 'Custom'` explicitamente em vez do proxy BloqueiaFechamentoCaso__c. `AreaParticipanteServiceTest`: teste de Case fechado usa `new Case(Status='Fechado')` sem JSON.deserialize. Deploy definitivo `0Afbe00000AA4PZCA1` Succeeded, 20/20 testes, Selector 97%, Service 85%. **Pacote 20 (2026-06-14):** Bloqueio de fechamento/cancelamento de Case com Área Interna aberta. `CaseTriggerHandler.beforeUpdate`: + detecção `EtapaAtendimento__c = 'Cancelado'`; + filtro `OrigemSLA__c = 'Custom'` na query; + mensagem funcional. `CaseTriggerHandlerTest`: 7 cenários (8 total). Dry-run `0Afbe00000AA0fJCAT` Succeeded, 12/12 testes, 96% cobertura. **Pacote 19 (2026-06-14):** Sincronização de CaseMilestones para AreaParticipante__c — 3 novas classes (Service, Batch, Scheduler) + 2 testes. AreaParticipanteSLAHelper: +ORIGEM_SLA_STANDARD. AreaParticipanteSLAService: guards Standard em beforeSave/closeSLA + fix NPE em MAX(SequenciaAcionamento__c). Dry-run 0Afbe00000AA05pCAD Succeeded, 45/45 testes. Delta: delta_area_participante_milestone_sync/. **Pacote 18 reformulado (2026-06-14):** Ajustado LWC existente `caseAreasParticipantesPanel` — componente real na `LP_Atendimento_Salvador`. Adicionados getter `canManage`, botão Atualizar e `masterLabel`. LWC `caseAreaParticipantePanel` (criado no Pacote 18 original) descartado e excluído do source. Delta: `Deltas/delta_area_participante_case_component_existing_fix/`. Dry-run `0Afbe00000A9ydVCAR` Succeeded (Changed 4 arquivos). **Cleanup RegrasSLA (2026-06-14):** Removido `MarcoSLA__c` de regras `Area Interna` em 6 classes de teste (RegrasSLA x5 + CategorizacaoServiceTest). Corrigido `SLACoverageCoreTest.testAreaLifecyclePauseResumeCloseAndBlockCaseClose` e `testBatchAndSchedulerAndGuard` para definir `Categorizacao.GestaoSLA__c` antes de inserir `AreaParticipante__c` (bug latente pós-17A v2). `testFindActiveRulesNovoN3Coverage` ajustado para assertar 0 resultados (método legado não retorna Area Interna sem MarcoSLA). Deploy `0Afbe00000A9x37CAB` Succeeded. 33/33 testes. Nota: `CategorizacaoServiceTest` ainda tem 2 ocorrências da violação (fora do escopo). **Cleanup 17A (2026-06-14):** Removido `createRegraLegada` (dead code) de `AreaParticipanteSLAServiceTest`. Removido `TipoAreaParticipante__c` desnecessário de `RegrasSLACategorizacao__c` em 3 test factories. Corrigido `CaseAreaParticipantePauseServiceTest.createRule` para incluir `Categorizacao.GestaoSLA__c` e remover `MarcoSLA__c` legado. Deploy `0Afbe00000A9wNBCAZ` Succeeded. 49/49 testes. **Pacote 17A v2 (2026-06-14):** SequenciaAcionamento__c agora é global por Case (não mais por Case+Area). findRule() e getEligibleAreaValuesForCase() incluem filtro explícito GestaoSLA__c via getSObject('Categorizacao__r'). Factory usa shared GestaoSLA__c para todos os registros do mesmo Case. +1 teste (testSequenciaGlobalPorCaseNaoPorArea). Deploy `0Afbe00000A9wAHCAZ` Succeeded. 43/43 testes. **17A v1 (2026-06-14):** Deploy `0Afbe00000A9vnhCAB` Succeeded. 42/42 testes. **16B (2026-06-13):** campos legados excluídos fisicamente da org via destructiveChanges — dry-run `0Afbe00000A9v9NCAR` (Succeeded) e deploy real `0Afbe00000A9vAzCAJ` (Succeeded). Campos excluídos: `RegrasSLACategorizacao__c.Origem__c`, `RegrasSLACategorizacao__c.VigenciaInicio__c`, `RegrasSLACategorizacao__c.VigenciaFim__c`, `AreaParticipante__c.TipoAtuacao__c`. Regra: `@last modified by` sempre nome do usuário Salesforce da org (nunca nome de IA).

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

## Services

| Artefato | Caminho | Responsabilidade | Chamado por |
|---|---|---|---|
| CaseAreaParticipantePauseService | force-app/main/default/classes/CaseAreaParticipantePauseService.cls | Pausa/retoma AreaParticipante interna ao entrar/sair de "Aguardando Cliente"; registra DataHoraPausaMilestone__c no Case para rastreamento de pausa dos marcos nativos. | CaseTriggerHandler.afterUpdate |
| CaseMilestoneMacroService | force-app/main/default/classes/CaseMilestoneMacroService.cls | Fecha marcos SLA não-SLA Total em qualquer transição de EtapaAtendimento__c; fecha SLA Total na conclusão/cancelamento do Case. | CaseTriggerHandler.afterUpdate |
| AreaParticipanteMilestoneSyncService | force-app/main/default/classes/AreaParticipanteMilestoneSyncService.cls | Espelha CaseMilestones para AreaParticipante__c (OrigemSLA__c='Standard'); idempotência via CaseMilestoneId__c; preserva Custom. Pacote 19. | AreaParticipanteMilestoneSyncBatch |
| AreaParticipanteMilestoneSyncBatch | force-app/main/default/classes/AreaParticipanteMilestoneSyncBatch.cls | Apex Batch que processa Cases em lote de 200 chamando syncByCaseIds; suporta filtro por Set<Id> ou QueryLocator global. Pacote 19. | AreaParticipanteMilestoneSyncScheduler |
| AreaParticipanteMilestoneSyncScheduler | force-app/main/default/classes/AreaParticipanteMilestoneSyncScheduler.cls | Schedulable que agenda AreaParticipanteMilestoneSyncBatch periodicamente (ex: daily às 02h). Pacote 19. | — |

## ServiceAgents / Integrações

| Artefato | Caminho | API/Sistema | Named Credential | Custom Metadata |
|---|---|---|---|---|

## DTOs / Wrappers

| Artefato | Caminho | Uso |
|---|---|---|

## LWCs

| Componente | Caminho | Apex usado | Responsabilidade |
|---|---|---|---|
| caseAreasParticipantesPanel | force-app/main/default/lwc/caseAreasParticipantesPanel/ | AreaParticipanteController (getPanelDataFresh, addParticipation, closeParticipation, getParticipationDetails) | Painel de Áreas Participantes na LP_Atendimento_Salvador (tela real do Case): lista agrupada Aberto/Concluído, aciona e conclui participações, modal de detalhes, bilíngue PT+EN, exibe dados SLA; canManage do backend controla visibilidade do Add. |
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
