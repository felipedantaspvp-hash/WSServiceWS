# AI_WORKQUEUE.md — Protocolo de Trabalho Paralelo Claude + Codex

> Ambos os agentes devem ler este arquivo antes de iniciar qualquer tarefa.
> Atualizar a tabela de trabalho em andamento ao começar e ao concluir.

---

## Trabalho em andamento

| Agente | Branch | Arquivos bloqueados | Tarefa | Status |
|--------|--------|---------------------|--------|--------|
| Codex  | main   | `force-app/main/default/objects/Account/fields/Teste__c.field-meta.xml`, `docs/PROJECT_INDEX.md` | Excluir campo texto Teste em Account | ✅ concluído |
| Codex  | feat/codex/retrieve-entitlement-atendimento-salvador | `AI_WORKQUEUE.md`, `manifest/entitlement-atendimento-salvador.xml`, `force-app/main/default/entitlementProcesses/*`, `force-app/main/default/milestoneTypes/*`, `force-app/main/default/settings/BusinessHours.settings-meta.xml`, `force-app/main/default/settings/Entitlement.settings-meta.xml`, `docs/PROJECT_INDEX.md` | Baixar Entitlement Process ativo Atendimento Salvador v2 e dependências | ✅ concluído |
| Claude | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `force-app/main/default/entitlementProcesses/*`, `docs/PROJECT_INDEX.md` | Clonar EntitlementProcess Salvador para Rio Grande, Centro Logístico e Rebocadores | ✅ concluído |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `Deltas/delta_gestao_sla_destructive_campos_legados/**` | Pacote 16B: excluir fisicamente 4 campos legados via destructiveChanges, validar dry-run e documentar evidências | ✅ concluído |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `Deltas/delta_gestao_sla_destructive_campos_legados/**` | Pacote 16B: exportar backups CSV, ajustar evidências e formalizar bloqueio/alternativa de dry-run | ✅ concluído |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `force-app/main/default/profiles/Admin.profile-meta.xml`, `docs/PROJECT_INDEX.md` | Adicionar todos os campos de AreaParticipante__c ao perfil Admin e deployar na WILSON_SERVICE | ✅ concluído |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `force-app/main/default/objects/AreaParticipante__c/**`, `force-app/main/default/profiles/Admin.profile-meta.xml` | Retrieve do objeto AreaParticipante__c completo e do perfil Admin a partir da WILSON_SERVICE | ✅ concluído |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `force-app/main/default/profiles/**`, `force-app/main/default/objects/AreaParticipante__c/**`, `docs/PROJECT_INDEX.md` | Restringir FLS de AreaParticipante__c para somente Admin e remover acesso dos demais perfis | ✅ concluído com ressalva: 39 perfis deployados; `B2BMA Integration User` bloqueado por licença gerenciada (`dfsle__EOS_Type__c View All`) |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `delta_area_participante_pausa_retomada/**`, `force-app/main/default/classes/**`, `docs/PROJECT_INDEX.md` | Pacote 22: pausa e retomada operacional de Área Interna Custom manual | ✅ concluído — dry-run `0Afbe00000AA5NGCA1` Succeeded, 39/39 testes |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `delta_area_participante_pausa_retomada_ux/**`, `force-app/main/default/lwc/caseAreasParticipantesPanel/**`, `force-app/main/default/classes/AreaParticipanteController.cls`, `force-app/main/default/classes/AreaParticipanteDTO.cls`, `docs/PROJECT_INDEX.md` | Pacote 23: expor Pausar/Retomar Area Interna Custom no LWC caseAreasParticipantesPanel | ✅ concluído — dry-run `0Afbe00000AAAOXCA5` Succeeded |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `delta_area_participante_pausa_retomada_ux/**`, `force-app/main/default/lwc/caseAreasParticipantesPanel/**`, `force-app/main/default/classes/AreaParticipanteDTO.cls`, `force-app/main/default/classes/AreaParticipanteService.cls`, `docs/PROJECT_INDEX.md` | Pacote 23 ajuste: mover canPause/canResume para backend, alinhar delta e evidencias | ✅ concluído — dry-run `0Afbe00000AAAd3CAH` Succeeded, 40/40 testes |
| Codex  | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `force-app/main/default/classes/AreaParticipanteDTO.*`, `force-app/main/default/classes/AreaParticipanteService.*`, `force-app/main/default/lwc/caseAreasParticipantesPanel/**`, `docs/PROJECT_INDEX.md` | Sincronizar conflitos locais com a org WILSON_SERVICE, fazendo a org prevalecer, e verificar tracking | ✅ concluído |
| Claude | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `Deltas/delta_16B_exclusao_campos_legados/**` | Pacote 16B: excluir fisicamente 4 campos legados via destructiveChanges | ✅ concluído — deploy `0Afbe00000A9vAzCAJ` Succeeded |
| Claude | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `Deltas/delta_area_participante_regra_sla_area_interna/**`, `force-app/main/default/classes/AreaParticipanteSLAService.cls`, `force-app/main/default/classes/AreaParticipanteSelector.cls`, `force-app/main/default/classes/AreaParticipanteService.cls`, `force-app/main/default/classes/AreaParticipanteSLAServiceTest.cls`, `force-app/main/default/classes/AreaParticipanteServiceTest.cls`, `force-app/main/default/classes/AreaParticipanteControllerTest.cls`, `force-app/main/default/classes/AreaParticipanteTestDataFactory.cls`, `force-app/main/default/classes/AreaParticipanteSLABatchTest.cls` | Pacote 17A v2: sequência global por Case, filtro GestaoSLA__c explícito em findRule/getEligibleAreaValuesForCase, shared GestaoSLA na factory, +1 teste sequência global | ✅ concluído — deploy `0Afbe00000A9wAHCAZ` Succeeded, 43/43 testes passando |
| Claude | feat/claude/entitlement-rio-grande-centro-logistico-rebocadores | `force-app/main/default/classes/AreaParticipanteSLAServiceTest.cls`, `force-app/main/default/classes/AreaParticipanteTestDataFactory.cls`, `force-app/main/default/classes/AreaParticipanteSLABatchTest.cls`, `force-app/main/default/classes/CaseAreaParticipantePauseServiceTest.cls`, `Deltas/delta_area_participante_regra_sla_cleanup/**` | Cleanup 17A: removido createRegraLegada (dead code), TipoAreaParticipante__c e MarcoSLA__c desnecessários em RegrasSLACategorizacao__c nos testes do pacote | ✅ concluído — deploy 0Afbe00000A9wNBCAZ Succeeded, 49/49 testes |
| Claude | feat/codex/retrieve-entitlement-atendimento-salvador | `force-app/main/default/classes/RegrasSLACompatibilidadeServiceTest.cls`, `force-app/main/default/classes/SLACoverageCoreTest.cls`, `force-app/main/default/classes/RegrasSLACategorizacaoSelectorTest.cls`, `force-app/main/default/classes/RegrasSLACategorizacaoHelperTest.cls`, `force-app/main/default/classes/CaseMilestoneTriggerTimeCalculatorTest.cls`, `Deltas/delta_regras_sla_cleanup_area_interna_tests/**` | Cleanup transversal: remover MarcoSLA__c de regras Area Interna em 5 classes de teste RegrasSLA; corrigir GestaoSLA__c em SLACoverageCoreTest | ✅ concluído — deploy final 0Afbe00000A9xEPCAZ Succeeded, 47/47 testes (6 classes, incl. CategorizacaoServiceTest + HelperTest vMarco) |
| Claude | feat/claude/area-participante-case-component | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `force-app/main/default/lwc/caseAreaParticipantePanel/**`, `Deltas/delta_area_participante_case_component/**` | Pacote 18: LWC caseAreaParticipantePanel para Record Page do Case — listar, acionar e concluir Área Participante; sem alteração de Apex ou metadata | ✅ concluído — commit 77dbe3d |
| Claude | feat/claude/area-participante-existing-fix | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `force-app/main/default/lwc/caseAreasParticipantesPanel/**`, `Deltas/delta_area_participante_case_component_existing_fix/**` | Pacote 18 reformulado: ajustar LWC existente caseAreasParticipantesPanel (canManage + refresh); descartar caseAreaParticipantePanel | ✅ concluído — commit ac66a76 |
| Claude | feat/claude/area-participante-milestone-sync | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `force-app/main/default/classes/AreaParticipanteSLAHelper.cls`, `force-app/main/default/classes/AreaParticipanteSLAService.cls`, `force-app/main/default/classes/AreaParticipanteMilestoneSync*.cls`, `Deltas/delta_area_participante_milestone_sync/**` | Pacote 19: sincronização de CaseMilestones para AreaParticipante__c (espelho Standard) | ✅ concluído — commit 87a6cb7, dry-run 0Afbe00000AA05pCAD Succeeded, 45/45 testes |
| Claude | feat/claude/area-participante-existing-fix | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `force-app/main/default/classes/CaseTriggerHandler.cls`, `force-app/main/default/classes/CaseTriggerHandlerTest.cls`, `Deltas/delta_case_bloqueio_fechamento_area_participante/**` | Pacote 20: bloqueio de fechamento/cancelamento de Case com Área Interna aberta | ✅ concluído — deploy definitivo `0Afbe00000AA1xxCAD` Succeeded, 12/12 testes |
| Claude | feat/claude/area-participante-existing-fix | `AI_WORKQUEUE.md`, `docs/PROJECT_INDEX.md`, `force-app/main/default/classes/AreaParticipanteSelector.cls`, `force-app/main/default/classes/AreaParticipanteService.cls`, `force-app/main/default/classes/AreaParticipanteServiceTest.cls`, `Deltas/delta_case_orquestracao_etapa_area_interna/**` | Pacote 21 v3: Status no guard terminal; OrigemSLA__c em getAreasByCase(); filtro direto no loop; teste sem JSON hack | ✅ concluído — deploy definitivo `0Afbe00000AA4PZCA1` Succeeded, 20/20 testes, commit bae7b25 |
| Claude | feat/claude/area-participante-existing-fix | `AI_WORKQUEUE.md`, `manifest/retrieve-marllon-20260617.xml`, `force-app/main/default/classes/CaseAcompanhamento*`, `force-app/main/default/classes/CaseOpeningNotification*`, `force-app/main/default/classes/CaseClosureSurvey*`, `force-app/main/default/classes/AtendimentoConfig*`, `force-app/main/default/classes/CaseAfterInsertTriggerHandler.cls`, `force-app/main/default/classes/CaseSurveyDispatch*`, `force-app/main/default/lwc/caseAcompanhamento*`, `force-app/main/default/lwc/caseClosureSurvey/**`, `force-app/main/default/objects/Acao__c/**`, `force-app/main/default/objects/Case/fields/*Acompanhamento*`, `force-app/main/default/objects/ParametrosAtendimento__mdt/fields/*CaseOpening*`, `force-app/main/default/objects/ParametrosAtendimento__mdt/fields/SendCaseOpeningEmail__c.field-meta.xml`, `force-app/main/default/layouts/ParametrosAtendimento__mdt-Layout*`, `force-app/main/default/customMetadata/ParametrosAtendimento.*`, `force-app/main/default/permissionsets/CaseAcompanhamentoOperador.permissionset-meta.xml`, `force-app/main/default/flexipages/LP_Atendimento_Salvador.flexipage-meta.xml`, `force-app/main/default/profiles/Admin.profile-meta.xml` | Retrieve do que o usuário Marllon Nascimento criou/alterou na WILSON_SERVICE em 17/06/2026 (apurado via SetupAuditTrail): objeto custom Ação__c (workflow de acompanhamento de Case), classes/LWC de Acompanhamento, Closure Survey e Opening Notification, ajustes em AtendimentoConfig/CaseAfterInsertTriggerHandler/CaseSurveyDispatch, novos campos de mdt ParametrosAtendimento__mdt (envio de e-mail de abertura), permission set CaseAcompanhamentoOperador, FlexiPage LP Atendimento Salvador e FLS no profile Admin | 🔄 em andamento — retrieve trazido para o working tree, ainda não revisado/commitado |
| —      | —      | —                   | —      | —      |

**Status válidos:** `🔄 em andamento` · `✅ concluído` · `⏸ pausado` · `🔀 merge pendente`

Limpe linhas com `✅` após o merge ser feito.

---

## Protocolo antes de editar

```text
1. Ler AI_WORKQUEUE.md.
2. Verificar se os arquivos que serão editados estão na coluna "Arquivos bloqueados".
3. Se estiverem livres → registrar a linha na tabela acima e iniciar.
4. Se estiverem bloqueados → trabalhar em branch separada e aguardar liberação.
5. Ao concluir → atualizar status para ✅ e indicar branch/PR.
```

---

## Divisão de domínio padrão

Define qual agente tem **preferência** para cada tipo de tarefa.
Não é exclusivo — qualquer agente pode atuar fora do seu domínio, mas o domínio preferencial reduz conflitos.

| Domínio | Agente preferencial | Motivo |
|---------|--------------------|---------| 
| Lógica Apex complexa (Service, Helper, ServiceAgent) | **Claude** | Análise de contexto longo, revisão de arquitetura |
| Revisão de código e code review | **Claude** | Raciocínio comparativo e memória de sessão |
| Segurança, permissões, CRUD/FLS | **Claude** | Checklist multi-layer e auditoria |
| Geração de boilerplate Apex / LWC | **Codex** | Velocidade, geração guiada por skill |
| Flows e automações declarativas | **Codex** | Geração direta de XML de metadados |
| Metadata XML (objetos, campos, layouts) | **Codex** | Geração em massa e deploy |
| Testes Apex | Qualquer um | Dependendo de quem alterou o código |
| Documentação e PROJECT_INDEX | Qualquer um | Quem tiver mais contexto da mudança |

---

## Convenção de branches

```text
feat/claude/[slug-da-tarefa]    ← Claude Code
feat/codex/[slug-da-tarefa]     ← Codex CLI
fix/claude/[slug-do-bug]
fix/codex/[slug-do-bug]
```

Exemplos:
```text
feat/claude/sla-marco-calculo
feat/codex/lwc-case-panel-botao
fix/claude/gestao-sla-query-bulk
```

---

## Regra de merge

1. O agente que criou a branch é responsável pelo merge ou PR.
2. Antes do merge, verificar se o outro agente não alterou os mesmos arquivos em outra branch.
3. Resolução de conflito: priorizar a versão mais recente salvo indicação contrária no commit.
4. Após merge, limpar a linha do AI_WORKQUEUE.md.

---

## Comunicação entre agentes

Agentes não se comunicam diretamente. A coordenação é feita por:

1. **AI_WORKQUEUE.md** — status de trabalho em andamento.
2. **Mensagens de commit** — descrever claramente o que foi alterado e por quê.
3. **PROJECT_INDEX.md** — manter atualizado após mudanças estruturais.
4. **docs/GESTAO_SLA_PROJECT_CONTEXT.md** — atualizar ao mudar arquitetura de domínio.

---

## Checklist de entrada (qualquer agente)

```text
[ ] Li AI_WORKQUEUE.md.
[ ] Os arquivos que vou editar estão livres.
[ ] Registrei minha tarefa na tabela acima.
[ ] Escolhi a branch correta (feat/[agente]/[tarefa]).
[ ] Consultei PROJECT_INDEX.md.
[ ] Consultei AI_HANDLERS.md.
```

## Checklist de saída (qualquer agente)

```text
[ ] Atualizei o status no AI_WORKQUEUE.md.
[ ] Commit com mensagem descritiva.
[ ] PROJECT_INDEX.md atualizado se houve mudança estrutural.
[ ] UTF-8 validado se alterei metadata.
[ ] Testes considerados se alterei Apex.
```
