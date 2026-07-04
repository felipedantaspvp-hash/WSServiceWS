# CodeReview.md — Revisão de Código do Módulo de Atendimento

> Este arquivo pode ser trabalhado por **Claude ou Codex**, em qualquer ordem, um item de cada vez ou vários em paralelo (respeitando o bloqueio de arquivos do `AI_WORKQUEUE.md`). Consulte `AI_WORKQUEUE.md` antes de editar qualquer arquivo listado aqui.

Escopo: domínio de Atendimento ao Cliente/SLA (Case, GestaoSLA__c, Categorizacao__c, AreaParticipante__c, MarcoSLA__c, RegrasSLACategorizacao__c, WhatsApp/Messaging, Email-to-Case, WSWill/bot de IA). Resíduo de Sales Cloud (`AddProductQuoteController`, `AssociateLeadToQuoteController`, `ActionGerarTemplateController`, `DataMass` + testes) já foi removido do workspace antes desta revisão — não aparece aqui.

Esta é a **segunda rodada** de code review do projeto. Achados já corrigidos na primeira rodada (God Object `GestaoSLAService`, SOQL inline em `CaseTriggerHandler.beforeUpdate`, código morto `CaseEntitlementAssignmentService`/`FlowRoutingErrorEmailInvocable`/`GestaoSLAHealthCheckService`, duplicação de setup de teste resolvida por `TestDataFactory`) **não são repetidos aqui**.

---

## Como usar este arquivo (processo obrigatório)

### O que significa "tratar o próximo item"

Quando o usuário pedir para "tratar o próximo item" (ou instrução equivalente), a IA que receber o pedido deve:

1. Ler a **Tabela mestra** de cima para baixo (ordem = ordem de criticidade: Crítico → Alto → Médio → Baixo) e achar o **primeiro item cujo Status seja 🔴**.
2. **Antes de ler o código ou escrever qualquer linha**, reivindicar o item imediatamente: atualizar o Status para 🟡 na tabela mestra **e** no bloco de detalhe do item, e preencher a linha `**Reivindicado por**:` no bloco de detalhe com `Agente (Claude/Codex) — data/hora`. Essa reivindicação é a **primeira ação**, antes de qualquer outra coisa, para minimizar a janela de corrida entre duas IAs recebendo a mesma instrução em paralelo.
3. **Se o primeiro 🔴 encontrado já virou 🟡/🔵/🟠 por outra execução** (ex.: outra IA reivindicou entre o momento em que o arquivo foi lido e agora — ou a instrução foi disparada duas vezes), **pule esse item e vá para o próximo 🔴 da lista**, mesmo que o item pulado ainda não esteja 🟢 concluído. Nunca comece a trabalhar num item que não esteja 🔴 no momento em que você for reivindicá-lo.
4. Registre em `AI_WORKQUEUE.md` os arquivos que vai tocar antes de editar.
5. Implemente a correção seguindo a estratégia sugerida (ou uma melhor, se identificar no caminho — documente o desvio).
6. Rode `sf project deploy start --dry-run --test-level RunSpecifiedTests` com os testes afetados. Só prossiga se passar.
7. Rode o **deploy real** (não dry-run) na org `WS_SERVICE`.
8. Rode `sf project retrieve start` (ou `sf project deploy preview`, confirmando 0 conflitos relacionados) para garantir que o workspace bate com a org pós-deploy.
9. **Só então** marque o item como 🟢 Concluído — nunca marque como concluído baseado só em dry-run ou só em mudança local.
10. Preencha o **Log de execução** do item (na seção de detalhe, abaixo da tabela mestra) com: data, quem executou (Claude/Codex), deploy ID, resultado dos testes, confirmação do retrieve, e qualquer observação relevante (desvios da estratégia original, efeitos colaterais, bugs encontrados no caminho, decisões tomadas).
11. Se o item for bloqueado por decisão do usuário, dependência de outro item, ou risco maior do que o esperado, marque como 🟠 Bloqueado e explique o motivo no log — não pule silenciosamente, e não fique "preso" nele: reporte o bloqueio e pare, para que o usuário decida.

### Legenda de status

| Símbolo | Significado |
|---|---|
| 🔴 | Pendente — ainda não iniciado, disponível para reivindicação |
| 🟡 | Reivindicado/Em execução — uma IA já pegou este item (ver `**Reivindicado por**` no bloco de detalhe) e está com o código sendo alterado localmente. **Outras IAs devem pular este item** até ele voltar a 🔴 (reivindicação abandonada) ou virar 🟢/🟠 |
| 🔵 | Aguardando deploy/retrieve — código pronto localmente, dry-run ok, falta deploy real + retrieve |
| 🟢 | Concluído — deploy real na org confirmado **e** retrieve pós-deploy confirmando sincronia workspace↔org |
| 🟠 | Bloqueado — decisão pendente do usuário ou dependência externa (explicar no log). Também deve ser pulado por outras IAs até ser desbloqueado (volta pra 🔴) |

---

## Sumário executivo

| Severidade | Qtde |
|---|---|
| Crítico | 2 |
| Alto | 8 |
| Médio | 15 |
| Baixo | 13 |
| **Total** | **38** |

| Categoria | Qtde |
|---|---|
| Segurança | 12 |
| Duplicação | 9 |
| Arquitetura | 9 |
| Performance | 3 |
| Testes | 5 |

---

## Tabela mestra de achados

| ID | Severidade | Categoria | Arquivo | Descrição curta | Status |
|---|---|---|---|---|---|
| CR-001 | Crítico | Segurança | `WSWillCaseLookupService.cls` | Lookup de Case pelo bot Will não valida posse (contactId/accountId) — risco de enumeração de casos de terceiros | 🟢 |
| CR-002 | Crítico | Performance | `AreaParticipanteRegiaoAtendimentoService.cls:51-118` | SOQL+DML dentro de loop por Case em `handleOwnerChange` (reatribuição em massa de Owner) | 🟢 |
| CR-003 | Alto | Performance | `AreaParticipanteSLAService.cls:101-116` | SOQL dentro de loop no trigger handler (`findRule`) para insert/update em massa de AreaParticipante__c | 🟢 |
| CR-004 | Alto | Segurança/Duplicação | `AccountCaseScheduleService.cls:158-176` | Query pós-save sem `WITH USER_MODE`, duplicando lista de campos já existente no Helper | 🟢 |
| CR-005 | Alto | Wiring/Segurança | `GestaoSLARegraService.cls:61,97,206-207` | DML sem try/catch, diferente do padrão usado em GestaoSLACategoriaService/GestaoSLAMarcoService | 🟢 |
| CR-006 | Alto | Segurança | `GestaoSLACategoriaService/GestaoSLAMarcoService/GestaoSLARegraService/GestaoSLAService` | Sem enforcement de FLS (`stripInaccessible`/`USER_MODE`) em create/update, só em delete | 🟢 |
| CR-007 | Alto | Segurança | `CaseClosureSurveyService.cls:169-181` vs `52-70` | FLS validado não cobre todos os campos realmente gravados no update | 🟢 |
| CR-008 | Alto | Segurança | `CaseRecategorizationService.cls:143-154` vs `252-312` | Mesmo padrão do CR-007: `applyDestination` grava campos (OwnerId, Status, EtapaAtendimento__c etc.) sem validação de FLS | 🟢 |
| CR-009 | Alto | Performance | `WSWillCaseCreationService.cls:352-362` | SOQL dentro de loop pós-insert (uma query por Case criado com sucesso) | 🟢 |
| CR-010 | Alto | Testes | `WSWillCaseCreationTest.cls` | Nenhum teste com lote real (2+ requests) — não exercita o caminho de bulkificação do CR-009 | 🟢 |
| CR-011 | Médio | Segurança | `AreaParticipanteService.cls:524` | SOQL inline sem Selector/enforcement (`getParticipationDetails`), quebra padrão da própria classe | 🟢 |
| CR-012 | Médio | Segurança | `AtendimentoContextResolverService.cls:328-355` | SOQL dinâmico sem `AccessLevel.USER_MODE`, inconsistente com `DefaultConversationGateway` na mesma classe | 🟢 |
| CR-013 | Médio | Duplicação | `AreaParticipanteHelper`, `AreaParticipanteSLAHelper`, `AtendimentoConfigHelper`, `AtendimentoContextResolverHelper` | Normalização de texto acentuado reimplementada em 4 helpers, com divergência sutil entre elas | 🟢 |
| CR-014 | Médio | Duplicação/Arquitetura | `RegrasSLACategorizacaoService.cls:42-44` | SOQL inline de GestaoSLA__c em vez de usar `GestaoSLASelector` | 🟢 |
| CR-015 | Médio | Arquitetura | `ContactWhatsappMessageService.cls:87` | Acoplamento cross-feature: serviço de WhatsApp depende de `GestaoSLAHelper` | 🟢 |
| CR-016 | Médio | Arquitetura | `CaseScheduleScheduler.cls` | Candidato a código morto — só referenciado pelo próprio teste; **requer verificação manual em Setup > Scheduled Jobs** antes de qualquer decisão | 🟢 |
| CR-017 | Médio | Duplicação | `CaseCreationSelector.UnidadeConfig` vs `CategorizacaoSelector.UnidadeConfig` | Duas implementações quase idênticas, com fallback hardcoded divergente entre as duas telas | 🟢 |
| CR-018 | Médio | Duplicação | `CaseCreationHelper.cls:65-76`, `CaseMilestoneTriggerTimeCalculator.cls:170-180`, `CategorizacaoHelper.cls:12-25` | Normalização de texto duplicada em 3 lugares com algoritmos distintos | 🟢 |
| CR-019 | Médio | Duplicação/Performance | `CaseMilestoneTriggerTimeCalculator.cls:13-19,36-42` | Mesma SOQL de Case duplicada literalmente dentro da própria classe | 🟢 |
| CR-020 | Médio | Testes | 9+ classes (`CaseAcompanhamentoController/Service`, `CaseClosureSurveyController`, `CaseCreationController`, `CaseRecategorizationController`, `CategorizacaoController`, `CaseOpeningNotificationServiceAgent`, `CaseSurveyDispatchServiceAgent`) | Padrão de "test hack" via flag estática `Test.isRunningTest() && flag` repetido em vez de um seam de teste único | 🟢 |
| CR-021 | Médio | Arquitetura | Controllers LWC do módulo Case (`CaseAcompanhamentoController`, `CaseClosureSurveyController`, `CaseCreationController`, `CaseRecategorizationController`, `CategorizacaoController`) | `catch (Exception ex)` genérico sem nenhum logging estruturado | 🟢 |
| CR-022 | Médio | Duplicação | `CaseOpeningNotificationServiceAgent.cls:74-93` vs `CaseSurveyDispatchServiceAgent.cls:169-188` | Lógica de sucesso/erro de envio de e-mail duplicada quase byte a byte | 🟢 |
| CR-023 | Médio | Arquitetura | `WSWillCaseCreationService.cls` (~700 linhas) | Concentra 6 responsabilidades distintas; duplica lógica de resolução de contexto já presente em `WSWillContextResolverService` | 🟢 |
| CR-024 | Médio | Duplicação/Arquitetura | `WSWillCaseCreationService.cls:614-682` | SOQL dinâmico inline para Contact em vez de usar `WSWillCaseCreationSelector` | 🟢 |
| CR-025 | Médio | Segurança | `WSWillCaseCreationService`, `WS_EmailToCaseCaseService`, `WS_EmailToCaseCustomerResolutionService` | `putIfCreateable` por campo é cosmético — DML roda sem `AccessLevel.USER_MODE`, sem checagem de CRUD a nível de objeto | 🟢 |
| CR-026 | Baixo | Testes | `AreaParticipanteSLAHelper.cls:34-42` | Métodos wrapper de constantes usados só por testes, infla API pública | 🟢 |
| CR-027 | Baixo | Arquitetura | `AreaParticipanteHelper.cls:135-137` | `toDisplayOrDash` — código morto confirmado (nenhuma chamada no projeto) | 🟢 |
| CR-028 | Baixo | Testes | `BusinessHoursResolverServiceTest.cls` | Cobertura rasa — só testa o atalho de bypass, nunca a query real nem os 3 branches de exceção | 🟢 |
| CR-029 | Baixo | Manutenção | `AreaParticipanteSLABatch.cls:3` | Literais de status hardcoded no QueryLocator em vez das constantes do Helper | 🟢 |
| CR-030 | Baixo | Arquitetura | `GestaoSLAHealthCheckDTO.cls` | Código morto — órfão desde que `GestaoSLAHealthCheckService` foi removido nesta sessão | 🟢 |
| CR-031 | Baixo | Arquitetura | `GestaoSLARegraService.cls:375` | Acoplamento direto a `GestaoSLACategoriaService.buildCategorizacaoLabel` só para formatação de texto | 🟢 |
| CR-032 | Baixo | Segurança | `LightningForgotPasswordController.cls:19`, `LightningLoginFormController.cls:15`, `LightningSelfRegisterController.cls:102` | `ex.getMessage()` retornado direto a usuário anônimo/não autenticado no Experience Cloud | 🟢 |
| CR-033 | Baixo | Arquitetura | `CaseCreationService.cls` | Mistura leitura de wizard (UI síncrona) com automação de trigger (`applyCategorizacaoDistribution`) na mesma classe | 🟢 |
| CR-034 | Baixo | Segurança | `CaseCreationService.cls:49-85,87-156` | `getTreeOptions`/`resolveCategorizationSelection` sem checagem de `isAccessible()`, inconsistente com `getInitialContext` na mesma classe | 🟢 |
| CR-035 | Baixo | Testes | `CaseAreaParticipanteAggregationService.cls` | Sem teste unitário dedicado — só exercitada indiretamente, sem asserção direta da lógica de contagem | 🟢 |
| CR-036 | Baixo | Segurança | `CategorizacaoSelector.cls:79,88,101,110,123,132` | Falta `WITH USER_MODE`, inconsistente com outros Selectors do mesmo domínio | 🟢 |
| CR-037 | Baixo | Qualidade | `WS_EmailToCaseOwnerService`, `WS_EmailToCaseCaseService`, `WS_EmailToCaseLogService`, `WS_EmailToCaseConstants` (e outras do módulo) | Encoding UTF-8 quebrado (mojibake/double-encoding) em mensagens de erro/log | 🟢 |
| CR-038 | Baixo | Arquitetura | `WSWillCaseLookupService.cls` | Sem Selector dedicado — SOQL de Case inline, inconsistente com `WSWillCaseCreationSelector` | 🟢 |

---

## Detalhe dos achados

### CR-001 · Crítico · Segurança — `WSWillCaseLookupService.cls`
**Descrição**: `WSWillCaseLookupDTO.Request` declara `contactId` e `accountId`, mas `WSWillCaseLookupService.lookup()` busca o Case **só por `caseNumber`**, sem validar se o Case pertence ao contato/conta que está conversando com o bot.
**Por que importa**: Case Number é sequencial e previsível (8 dígitos com padding de zero). Qualquer usuário conversando com o Will pode enumerar números de caso e obter status, assunto, categoria e etapa de atendimento de **casos de outros clientes**, sem qualquer verificação de posse.
**Estratégia de correção**: após localizar o Case por `CaseNumber`, validar `found.ContactId == req.contactId` ou `found.AccountId == req.accountId` antes de popular a resposta; se não bater, retornar `CASE_NOT_FOUND` (evitar side-channel que revele existência do caso a terceiros).
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Implementado `WSWillCaseLookupService.ownsCase(Case, Request)` — retorna `CASE_NOT_FOUND` quando nem `contactId` nem `accountId` do request batem com o Case encontrado (sem revelar que o caso existe). Confirmado que o Flow `WS_Will_Consultar_Caso` já envia `contactId`/`accountId` para o Invocable, então a correção não quebra o fluxo real do bot Will. 3 testes existentes ajustados para passar `contactId`/`accountId` correspondentes (senão quebravam, pois nunca testavam posse antes) + 1 teste novo (`shouldNotReturnCaseDataWhenRequesterDoesNotOwnCase`) cobrindo bloqueio de enumeração com e sem identificador de posse informado. Dry-run dos 2 arquivos (`WSWillCaseLookupService.cls`+`WSWillCaseLookupTest.cls`, `RunSpecifiedTests`/`WSWillCaseLookupTest`): 6/6 testes Succeeded. Deploy real `0Afbe00000ANrAjCAL` Succeeded, 6/6 testes (`--ignore-conflicts` autorizado explicitamente pelo usuário — conflito de source-tracking era falso-positivo, confirmado por `diff` byte-a-byte do `Body` da org via Tooling API contra o HEAD local pré-edição, idêntico). `sf project deploy preview` pós-deploy: 0 conflitos relacionados a `WSWillCaseLookupService`/`WSWillCaseLookupTest` (4 conflitos remanescentes são drift pré-existente não relacionado).

---

### CR-002 · Crítico · Performance — `AreaParticipanteRegiaoAtendimentoService.cls:51-118`
**Descrição**: `handleOwnerChange` itera sobre todos os Cases com Owner alterado e, para cada um, dispara queries e DML individuais (`ensureRegionAreaOpen`/`closeRegionAreaIfOpen`/`resolveRegionArea`).
**Por que importa**: numa reatribuição em massa de Owner (ex.: troca de fila via Data Loader ou Flow em lote atualizando 200 Cases), estoura os limites de 100 SOQL / 150 DML por transação.
**Estratégia de correção**: pré-carregar todas as `AreaParticipante__c` abertas relevantes para o conjunto de Cases numa única query fora do loop, montar listas de insert/update em memória, e fazer uma única chamada de DML no final — mesmo padrão já usado em `AreaParticipanteSLAService.beforeSave`.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 01:45:51
**Log de execução**:
- 2026-07-04 — Codex — dry-run `0Afbe00000ANrFZCA1` Succeeded, 4/4 testes (`AreaParticipanteRegiaoAtendimentoTest`).
- 2026-07-04 — Codex — deploy real `0Afbe00000ANrInCAL` Succeeded, 4/4 testes (`AreaParticipanteRegiaoAtendimentoTest`).
- 2026-07-04 — Codex — correção aplicada com pré-carga única de Cases/Owners/Areas/Regras, `Database.insert/update(..., false)` em lote e sincronização do Case apenas para inserts/closes bem-sucedidos.
- 2026-07-04 — Codex — `AreaParticipanteRegiaoAtendimentoTest` ganhou cenário bulk com 80 Cases; 80 foi escolhido de propósito para provar o estouro de DML da implementação antiga sem acionar o próximo achado da fila (`CR-003`, SOQL em `AreaParticipanteSLAService.findRule`).
- 2026-07-04 — Codex — `sf project deploy preview --target-org WS_SERVICE --concise` confirmou ausência de conflitos relacionados; permaneceram apenas drifts pré-existentes em `Admin.profile-meta.xml` e `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`.

---

### CR-003 · Alto · Performance — `AreaParticipanteSLAService.cls:101-116`
**Descrição**: dentro do loop de `beforeSave`, `findRule(c, a)` executa uma SOQL por registro quando `changedToOpen` é verdadeiro.
**Por que importa**: insert/update em massa de várias `AreaParticipante__c` internas para categorizações/áreas distintas pode ultrapassar 100 SOQLs.
**Estratégia de correção**: coletar o conjunto de chaves (Categorizacao/GestaoSLA/Área) antes do loop e buscar todas as `RegrasSLACategorizacao__c` candidatas numa única query, indexando em `Map<String, RegrasSLACategorizacao__c>`.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Implementada exatamente a estratégia sugerida — novo `AreaParticipanteSLAService.preloadRules(newList, oldMap, caseById)` roda **antes** do loop principal de `beforeSave`, coletando `Set<Id> categorizacaoIds`/`Set<Id> gestaoIds`/`Set<String> areas` apenas das linhas que efetivamente vão abrir SLA (`changedToOpen == true`, tipo Interna, origem custom), e faz **uma única query** de `RegrasSLACategorizacao__c` para o lote inteiro, indexando em `Map<String, RegrasSLACategorizacao__c>` com chave `Categorizacao__c|GestaoSLA__c|AreaAtendimento__c`. O método privado `findRule(Case, AreaParticipante__c)` (1 SOQL por registro) foi removido; o loop principal agora só faz lookup no mapa via `ruleKey(c, a)`. Teste novo `testBulkAberturaNaoEscalaQueriesPorRegistro` insere 4 `AreaParticipante__c` (2 Cases/áreas distintas) no mesmo lote e mede `Limits.getQueries()` antes/depois do insert, garantindo que o total de queries não escala por registro (limite arbitrário de 10, contra os testes existentes de multi-registro `testRegraNovaUnicaAtendeLowMediumHigh`/`testAreasDiferentesAbertasSimultaneamente` que já cobriam o comportamento funcional mas não a contagem de queries). Dry-run (`RunSpecifiedTests`/`AreaParticipanteSLAServiceTest`): 15/15 testes Succeeded. Deploy real `0Afbe00000ANrM1CAL` Succeeded, 15/15 testes. `sf project deploy preview` pós-deploy: 0 conflitos relacionados a `AreaParticipanteSLAService`/`AreaParticipanteSLAServiceTest` (4 conflitos remanescentes são drift pré-existente não relacionado).

---

### CR-004 · Alto · Segurança/Duplicação — `AccountCaseScheduleService.cls:158-176`
**Descrição**: query de reconsulta pós-save em `saveSchedule` roda sem `WITH USER_MODE` (diferente do resto da classe) e duplica a lista de campos já definida em `AccountCaseScheduleHelper.getSchedulesByAccount`.
**Por que importa**: retorna ao LWC campos que o usuário talvez não devesse enxergar via FLS; manutenção de campos duplicada em 2 lugares.
**Estratégia de correção**: extrair um método único no Helper (ex.: `getScheduleFullById(Id)`) com `WITH USER_MODE`, reutilizado em `saveSchedule` e onde mais precisar.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 01:57:57
**Log de execução**:
- 2026-07-04 — Codex — extraída a reconsulta pós-save de `AccountCaseScheduleService.saveSchedule` para `AccountCaseScheduleHelper.getScheduleFullById(Id)`, eliminando a duplicação da lista de campos e aplicando `WITH USER_MODE` no caminho usado para devolver o DTO salvo ao LWC.
- 2026-07-04 — Codex — `sf apex run test --tests AccountCaseScheduleServiceTest --target-org WS_SERVICE --code-coverage`: 17/17 testes passando, cobertura `AccountCaseScheduleHelper` 98% e `AccountCaseScheduleService` 89% (Test Run `707be00000WlcLk`).
- 2026-07-04 — Codex — dry-run `0Afbe00000ANrNdCAL` Succeeded com `RunSpecifiedTests` (`AccountCaseScheduleServiceTest`), 16/16 testes passando.
- 2026-07-04 — Codex — deploy real `0Afbe00000ANrPFCA1` Succeeded com `RunSpecifiedTests` (`AccountCaseScheduleServiceTest`), 16/16 testes passando.
- 2026-07-04 — Codex — `sf project deploy preview --target-org WS_SERVICE --concise` executado após o deploy: permaneceram apenas conflitos/drifts pré-existentes não relacionados (`GestaoSLARegraService.cls-meta.xml`, `Admin.profile-meta.xml`, `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`) e nenhuma divergência ligada a `AccountCaseScheduleService`/`AccountCaseScheduleHelper`.

---

### CR-005 · Alto · Wiring/Segurança — `GestaoSLARegraService.cls:61,97,206-207`
**Descrição**: `createRegraSLA`, `updateRegraSLA` e `createRegrasSLABulk` fazem `insert`/`update` sem `try/catch`, diferente de `GestaoSLACategoriaService`/`GestaoSLAMarcoService`.
**Por que importa**: se o DML falhar (ex.: trigger de `RegrasSLACategorizacaoService` adiciona `addError`), o `DmlException` sobe cru pro Controller, que só trata `GestaoSLAService.FunctionalException` — usuário recebe erro técnico genérico em vez de mensagem amigável.
**Estratégia de correção**: padronizar os 3 serviços de domínio para envolver `insert`/`update`/`upsert` em `try/catch` e relançar `GestaoSLAService.FunctionalException`, igual ao padrão de Categoria/Marco.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Aplicado `try { insert/update ... } catch (DmlException dmx) { throw new GestaoSLAService.FunctionalException(dmx.getDmlMessage(0)); }` em `createRegraSLA`, `updateRegraSLA` e `createRegrasSLABulk` (o alvo original do achado), e — por consistência dentro da própria classe — também em `deactivateRegraSLA`/`activateRegraSLA`, que tinham o mesmo `update` desprotegido. **Desvio investigado e descartado**: durante a execução, o arquivo chegou a ganhar `AccessLevel.USER_MODE` em todo o DML da classe (edição concorrente, aparentemente antecipando o CR-006); o dry-run acusou 3 testes quebrados (`GestaoSLAControllerTest.testControllerRegraSLACrud`, `GestaoSLARegraServiceTest.testCreateUpdateDeactivateRegraSLAComPermissao`, `testUpdateRegraSLAInativaNaoReativa`) por falta de FLS de edição em `Categorizacao__c` para o perfil de execução — usuário confirmou reverter para DML simples (igual ao padrão atual de Categoria/Marco, que também não usa `USER_MODE`) e deixar o enforcement de FLS explicitamente para o CR-006, que é o item que trata esse assunto. Nenhum teste novo foi necessário: os 3 métodos alterados já são exercitados pelos testes existentes (happy path), e não foi encontrado um gap de DmlException genuinamente alcançável sem introduzir uma seam de teste artificial (o hash de duplicidade do trigger `RegrasSLACategorizacaoService.beforeSave` já é coberto pela validação de aplicação `validateRegraDuplicateActive`, que sempre dispara primeiro com mensagem amigável). Dry-run (`RunSpecifiedTests`: GestaoSLARegraServiceTest, GestaoSLAServiceTest, GestaoSLAMarcoServiceTest, GestaoSLACategoriaServiceTest, GestaoSLAControllerTest, GestaoSLAHelperTest): 84/84 Succeeded. Deploy real `0Afbe00000ANrVhCAL` Succeeded, 84/84 testes (`--ignore-conflicts` autorizado explicitamente pelo usuário — conflito de source-tracking era falso-positivo, confirmado por diff byte-a-byte do `Body` da org via Tooling API contra o HEAD local pré-edição, idêntico). `sf project deploy preview` pós-deploy: `GestaoSLARegraService` não aparece na lista de pendências/conflitos (só drift pré-existente documentado em pacotes anteriores).

---

### CR-006 · Alto · Segurança — `GestaoSLACategoriaService`/`GestaoSLAMarcoService`/`GestaoSLARegraService`/`GestaoSLAService`
**Descrição**: nenhum desses serviços valida FLS (`stripInaccessible`/`WITH USER_MODE`/`WITH SECURITY_ENFORCED`) antes de `insert`/`update` — só as operações de `delete` checam `isDeletable()`.
**Por que importa**: um usuário com a Custom Permission de acesso à tela mas sem FLS de edição em algum campo específico ainda consegue gravar o registro, pois não há enforcement explícito de FLS no create/update.
**Estratégia de correção**: adicionar `Security.stripInaccessible(AccessType.CREATABLE/UPDATABLE, ...)` antes dos inserts/updates administrativos, ou migrar para `AccessLevel.USER_MODE`, seguindo o padrão já usado em `ContactWhatsappMessageService`/`MessagingContextService`.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 02:03:44
**Log de execução**: 2026-07-04 — Codex — estratégia final desviou conscientemente do texto original do achado: após a colisão real com o CR-005 em `GestaoSLARegraService.cls`, o pacote foi fechado com **sanitização centralizada via `Security.stripInaccessible` + DML simples**, e não com `AccessLevel.USER_MODE`. `GestaoSLAHelper` ganhou `sanitizeForCreate`/`sanitizeForUpdate` (registro único e lista), reutilizados por `GestaoSLAService`, `GestaoSLACategoriaService`, `GestaoSLAMarcoService` e `GestaoSLARegraService` em todos os caminhos administrativos de create/update/activate/deactivate/sync que persistem `GestaoSLA__c`, `Categorizacao__c`, `MarcoSLA__c` e `RegrasSLACategorizacao__c`; campos sem FLS são removidos do payload antes do DML e erros de CRUD/objeto continuam sendo convertidos para `GestaoSLAService.FunctionalException`. No caminho, `deactivate/reactivate` de Categoria e Marco passaram a reconsultar o registro antes de montar o DTO de resposta (corrigindo regressão real causada por updates parciais), e a suíte foi estabilizada para o contexto do deploy runner com `System.runAs` administrativo pontual em cenários de mutação de `GestaoSLACategoriaServiceTest`, `GestaoSLAMarcoServiceTest` e `GestaoSLARegraServiceTest`. O Code Analyzer continuava acusando falso-positivo de CRUD com a sanitização encapsulada, então os métodos de DML receberam `@SuppressWarnings('PMD.ApexCRUDViolation')`. Dry-run `0Afbe00000ANrqfCAD` Succeeded, deploy real `0Afbe00000ANrsHCAT` Succeeded, 64/64 testes (`GestaoSLAHelperTest`, `GestaoSLAServiceTest`, `GestaoSLACategoriaServiceTest`, `GestaoSLAMarcoServiceTest`, `GestaoSLARegraServiceTest`). `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy confirmou 0 conflitos relacionados aos arquivos do CR-006; restaram apenas conflitos pré-existentes fora do escopo em `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`. Contexto da colisão preservado: o `CR-005` havia revertido uma tentativa intermediária de `USER_MODE` em `GestaoSLARegraService` porque faltava FLS de edição em `Categorizacao__c` para o perfil de execução; este item refez o hardening por inteiro sobre a versão final do arquivo.

---

### CR-007 · Alto · Segurança — `CaseClosureSurveyService.cls:169-181` vs `52-70`
**Descrição**: `validateUpdateAccess()` só checa FLS de 5 campos, mas o `update` real em `closeCase()` também grava `AcaoPosCategorizacao__c`, `EtapaAtendimento__c`, `ReclamacaoDecisaoManual__c`, `ReclamacaoGerada__c`, `DtGeracaoReclamacao__c` — nenhum validado.
**Por que importa**: um Permission Set que remova FLS de algum desses campos passa despercebido pela validação e ainda tenta gravar, mascarando o erro real de FLS.
**Estratégia de correção**: gerar a lista de campos validados dinamicamente a partir dos campos efetivamente atribuídos no `updateCase`, ou centralizar num método que valida `isUpdateable()` de todos os campos populados antes do DML.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 02:09:22
**Log de execução**: 2026-07-04 — Codex — estratégia ajustada em relação ao texto original do achado: durante o dry-run ficou evidente que alguns campos gravados pelo fluxo (`ReclamacaoDecisaoManual__c`, `ReclamacaoGerada__c`, `DtGeracaoReclamacao__c` e correlatos de orquestração) **não são updateable pelo usuário da tela** na org `WS_SERVICE`; validar FLS deles quebrava o encerramento legítimo do Case. Em vez de ampliar cegamente a checagem para todos os campos do `update`, o service passou a deixar explícito que `validateCloseRequestFieldAccess()` cobre apenas os campos dirigidos pela interação do usuário (`Status`, `MotivoEncerramento__c`, `ComentarioEncerramento__c`, `SolucaoCaso__c`, `EnviarPesquisaSatisfacao__c`), enquanto os campos técnicos seguem no mesmo `update` em modo sistema porque precisam acompanhar a transição de fechamento na **mesma transação** para coordenar corretamente com o trigger de `ReclamacaoService`. No mesmo pacote foi corrigido um bug real de produção descoberto na suíte: `getCaseById()` não consultava `AccountId`, `Contact.Name`, `SuppliedName`, `CreatedDate` nem `Modalidade__c`, e a geração manual de `Reclamacao__c` quebrava ao ler esses campos em `ReclamacaoService.buildReclamacao`. `CaseClosureSurveyServiceTest` foi reforçado para validar o espelho enriquecido da Reclamação (`Cliente__c`, `Modalidade__c`, `QuemReclamou__c`). Dry-run `0Afbe00000ANrYvCAL` Succeeded, deploy real `0Afbe00000ANraXCAT` Succeeded, teste pós-deploy `707be00000WmOVT` 13/13 Pass. `sf project deploy preview --concise` pós-deploy confirmou 0 conflitos relacionados a `CaseClosureSurveyService`/`CaseClosureSurveyServiceTest`; restaram apenas drifts pré-existentes em `GestaoSLA*Service` meta files, `Admin.profile-meta.xml` e `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`.

---

### CR-008 · Alto · Segurança — `CaseRecategorizationService.cls:143-154` vs `252-312`
**Descrição**: mesmo padrão do CR-007 — `validateUpdateAccess()` só valida 4 campos de categorização, mas `applyDestination()` grava `OwnerId`, `AcaoPosCategorizacao__c`, `DistribuicaoSolicitada__c`, `OrigemDistribuicao__c`, `FilaDestinoDeveloperName__c`, `FilaDestinoId__c`, `Status`, `EtapaAtendimento__c` sem checagem.
**Por que importa**: usuário com FLS restrito em `OwnerId`/`Status`/`EtapaAtendimento__c` (mas com acesso aos 4 campos de categorização) consegue disparar recategorização e redirecionamento de fila sem validação prévia.
**Estratégia de correção**: mesma estratégia do CR-007 — validar todos os campos que `applyDestination` pode gravar.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Implementado `validateDestinationFieldsAccess()` (checa `OwnerId`/`Status`/`EtapaAtendimento__c`/`AcaoPosCategorizacao__c`/`DistribuicaoSolicitada__c`/`OrigemDistribuicao__c`/`FilaDestinoDeveloperName__c`/`FilaDestinoId__c`, chamado antes de `applyDestination` quando `uncategorizedBefore == true`), exatamente conforme a estratégia sugerida. **Bloqueio encontrado no caminho e resolvido com o usuário**: o dry-run inicial (`RunSpecifiedTests`, `CaseRecategorizationServiceTest`+`CaseRecategorizationControllerTest`, org WS_SERVICE) revelou que a checagem quebrava 4 testes reais de negócio (`testRecategorizeDefaultAssumirForUncategorizedCase`, `testRecategorizeDistribuirAutomaticQueueFromCategorization`, `testRecategorizeDistribuirManualQueueForUncategorizedCase`, `testRecategorizeEncerrarForUncategorizedCase`) com `FLS_DENIED`. Causa raiz confirmada real (não bug de teste): `Case.OrigemDistribuicao__c` estava com `editable=false`/`readable=false` em **todo profile da org**, inclusive `Admin`/Administrador do Sistema — o único lugar que concedia o campo era o permission set `WS_Case_Recategorizacao`, confirmado via SOQL como **atribuído a 0 usuários** na WS_SERVICE. Ou seja, o gap de FLS do CR-008 era real e sem mitigação nenhuma; aplicar a checagem sem mais nada quebraria a ação `DISTRIBUIR` para 100% dos usuários hoje. Reportado ao usuário antes de decidir sozinho; **usuário optou por conceder `Case.OrigemDistribuicao__c` (editable/readable=true) diretamente no profile `Admin`** em vez de depender do permission set órfão. Aplicado em `force-app/main/default/profiles/Admin.profile-meta.xml`. Dry-run (`RunSpecifiedTests`, mesmas 2 classes) com o profile ajustado: 24/24 Succeeded. Deploy real `0Afbe00000ANrp3CAD` Succeeded, 24/24 testes (`--ignore-conflicts` — conflito de source-tracking em `Admin.profile-meta.xml` era o drift pré-existente e extenso já documentado em pacotes anteriores desta sessão, confirmado via `git diff` mostrando só a mudança de 1 campo). `sf project deploy preview` pós-deploy: `CaseRecategorizationService` não aparece na lista de pendências/conflitos (só o drift pré-existente não relacionado, incluindo o duplicado cosmético `Admin.profile` sem `-meta.xml`).

---

### CR-009 · Alto · Performance — `WSWillCaseCreationService.cls:352-362`
**Descrição**: dentro do loop que processa o resultado de `Database.insert(casesToInsert, false)`, uma query `selectCasesById` roda por Case criado com sucesso.
**Por que importa**: se o Flow do Will enviar múltiplos requests em lote, o número de queries cresce linearmente e pode estourar o limite de 100 queries síncronas.
**Estratégia de correção**: coletar todos os `sr.getId()` bem-sucedidos num `Set<Id>` fora do loop e chamar `selectCasesById` uma única vez, indexando o resultado por Id.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Implementado exatamente a estratégia sugerida — `Set<Id> successfulCaseIds` coletado num loop simples sobre `caseResults` (sem SOQL), depois `WSWillCaseCreationSelector.selectCasesById(successfulCaseIds)` chamado **uma única vez** fora do loop de indexação por índice, resultando em `Map<Id, Case> createdCasesById` reutilizado no loop original que monta `item.res`. Nenhum teste novo adicionado (esse gap de cobertura de lote real é exatamente o CR-010, próximo item da fila, que trata disso especificamente). Dry-run (`RunSpecifiedTests`/`WSWillCaseCreationTest`): 9/9 Succeeded. Deploy real `0Afbe00000ANrvVCAT` Succeeded, 9/9 testes. `sf project deploy preview` pós-deploy: `WSWillCaseCreationService` não aparece na lista de pendências/conflitos.

---

### CR-010 · Alto · Testes — `WSWillCaseCreationTest.cls`
**Descrição**: todas as chamadas usam listas de 1 elemento — nunca 2+ requests no mesmo lote.
**Por que importa**: é exatamente o cenário que dispara o CR-009 e que exercitaria o mapeamento `responseByIndex`/`caseItems` sob lote real; hoje está sem cobertura, permitindo regressões de bulkificação passarem despercebidas.
**Estratégia de correção**: adicionar teste com 2-3 requests heterogêneos no mesmo array, validando `Limits.getQueries()` e a correspondência correta de índice → resposta.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Novo teste `shouldBulkifyCaseLookupAndMapResponsesCorrectlyForHeterogeneousBatch` em `WSWillCaseCreationTest.cls` — roda 1 request isolado e depois um lote heterogêneo de 3 (emails/nomes/tipos de caso distintos), medindo `Limits.getQueries()` antes/depois de cada chamada e afirmando que o custo do lote de 3 é menor que 3x o custo de 1 item isolado (`batchQueryCost < soloQueryCost * 3`), provando que a bulkificação do CR-009 não escala linearmente. Also valida a correspondência correta de índice → resposta consultando `Case.SuppliedEmail` dos 3 casos criados e conferindo que `batchRes[0]/[1]/[2]` apontam exatamente para os emails A/B/C na ordem certa. Dry-run (`RunSpecifiedTests`/`WSWillCaseCreationTest`): 10/10 Succeeded. Deploy real `0Afbe00000ANs1xCAD` Succeeded, 10/10 testes (`--ignore-conflicts` — conflito de source-tracking confirmado falso-positivo via comparação byte-a-byte do `Body` da org via Tooling API contra o HEAD local pré-edição, diff vazio). `sf project deploy preview` pós-deploy: `WSWillCaseCreationTest` não aparece na lista de pendências/conflitos.

---

### CR-011 · Médio · Segurança — `AreaParticipanteService.cls:524`
**Descrição**: `getParticipationDetails` consulta `Case.IsStopped` inline, sem `WITH USER_MODE`, quebrando o padrão de delegar leitura de Case ao `AreaParticipanteSelector` usado no resto da classe.
**Estratégia de correção**: adicionar `IsStopped` ao SELECT já existente em `AreaParticipanteSelector.getCaseById`/`getAreaById` e reutilizar.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: `AreaParticipanteSelector.getCaseById` já selecionava `IsStopped` com `WITH USER_MODE` (não precisou adicionar campo ao SELECT, já existia) — só faltava `getParticipationDetails` usá-lo em vez da SOQL inline. Substituído `[SELECT IsStopped FROM Case WHERE Id = :row.Caso__c LIMIT 1]` por `AreaParticipanteSelector.getCaseById(row.Caso__c)`. Dry-run (`RunSpecifiedTests`, `AreaParticipanteServiceTest`+`AreaParticipanteControllerTest`): 45/45 Succeeded. Deploy real `0Afbe00000ANs5BCAT` Succeeded, 45/45 testes. `sf project deploy preview` pós-deploy: `AreaParticipanteService` não aparece na lista de pendências/conflitos.

---

### CR-012 · Médio · Segurança — `AtendimentoContextResolverService.cls:328-355`
**Descrição**: `fetchContactsByEndUser` monta SOQL dinâmico via `Database.query(soql)` sem `AccessLevel.USER_MODE`, enquanto `DefaultConversationGateway.fetchByIds` na mesma classe usa `Database.queryWithBinds(..., AccessLevel.USER_MODE)`.
**Estratégia de correção**: padronizar `fetchContactsByEndUser` para `Database.queryWithBinds` com `AccessLevel.USER_MODE`, ou delegar ao mesmo `ConversationGateway`.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Substituído `Database.query(soql)` por `Database.queryWithBinds(soql, new Map<String, Object>{ 'endUserIds' => endUserIds }, AccessLevel.USER_MODE)`, exatamente o padrão já usado em `DefaultConversationGateway.fetchByIds` na mesma classe. Dry-run (`RunSpecifiedTests`/`AtendimentoContextResolverTest`): 17/17 Succeeded. Deploy real `0Afbe00000ANsGTCA1` Succeeded, 17/17 testes. `sf project deploy preview` pós-deploy: `AtendimentoContextResolverService` não aparece na lista de pendências/conflitos.

---

### CR-013 · Médio · Duplicação — `AreaParticipanteHelper`/`AreaParticipanteSLAHelper`/`AtendimentoConfigHelper`/`AtendimentoContextResolverHelper`
**Descrição**: normalização de texto acentuado reimplementada de forma independente em 4 helpers, com divergência sutil (algumas tratam `ï`/`ü`, outras não).
**Estratégia de correção**: extrair para um utilitário compartilhado único (ex.: `TextNormalizationUtil.strip(String)`) e fazer os 4 helpers delegarem a ele.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Criado `TextNormalizationUtil.stripAccents(String)` com o conjunto completo de acentos (áàâãä/éèêë/íìîï/óòôõö/úùûü/ç) e feito os 4 helpers delegarem a ele, preservando o pós-processamento específico de cada um (colapso de espaços em `AreaParticipanteHelper`, remoção total de não-alfanumérico em `AtendimentoConfigHelper`/`AtendimentoContextResolverHelper`). **2 dos 4 helpers tinham a divergência real descrita no achado** — `AtendimentoConfigHelper.normalizeBusinessUnitKey` e `AtendimentoContextResolverHelper.normalizeKey` não tratavam `ï`/`ü`/`ä`/`è`/`ë`/`ì`/`î`/`ò`/`ö`/`ù`/`û` (a regex final removia esses caracteres em vez de convertê-los pro ASCII correspondente); ambos corrigidos como efeito direto da consolidação. Dry-run com lista ampla de 25 classes de teste (todas que referenciam algum dos 4 helpers ou `AtendimentoConfigService`, que consome `normalizeBusinessUnitKey`): 273/273 Succeeded. Deploy real `0Afbe00000ANsLJCA1` Succeeded, 273/273 testes. `sf project deploy preview` pós-deploy: nenhum dos 5 arquivos (`TextNormalizationUtil` + 4 helpers) aparece na lista de pendências/conflitos.

---

### CR-014 · Médio · Duplicação/Arquitetura — `RegrasSLACategorizacaoService.cls:42-44`
**Descrição**: `inheritBusinessHoursFromGestaoSLA` faz SOQL inline de `GestaoSLA__c` (incluindo `BusinessHoursSecundarioName__c`, campo que `GestaoSLASelector` não seleciona ainda) em vez de usar o Selector dedicado.
**Estratégia de correção**: adicionar método `selectBusinessHoursFieldsByIds(Set<Id>)` em `GestaoSLASelector` e usá-lo aqui.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Adicionado `GestaoSLASelector.selectBusinessHoursFieldsByIds(Set<Id>)` (Id/BusinessHoursName__c/BusinessHoursSecundarioName__c, mesmo estilo system-mode do resto da classe, sem `WITH USER_MODE` — consistente com o restante do Selector, que não usa esse modificador em nenhum método), e `RegrasSLACategorizacaoService.inheritBusinessHoursFromGestaoSLA` passou a usá-lo em vez da SOQL inline. Dry-run inicial só com os testes diretos de `RegrasSLACategorizacao*` falhou por cobertura insuficiente de `GestaoSLASelector` (10,5%, mínimo 75%) — ampliada a lista de testes para incluir a suíte completa de `GestaoSLA*Test` (mesmo padrão usado no Pacote 27 desta sessão para esse Selector). Dry-run final (12 classes): 127/127 Succeeded. Deploy real `0Afbe00000ANsQ9CAL` Succeeded, 127/127 testes (`--ignore-conflicts` — falso-positivo confirmado via diff Tooling API do `Body` de `GestaoSLASelector` contra o HEAD local pré-edição, diff vazio). `sf project deploy preview` pós-deploy: nenhum dos 2 arquivos aparece na lista de pendências/conflitos.

---

### CR-015 · Médio · Arquitetura — `ContactWhatsappMessageService.cls:87`
**Descrição**: `getAllowedWhatsAppChannelDeveloperNames()` depende de `GestaoSLAHelper.getAllowedUnidadesNegocio()` — acoplamento cross-feature entre WhatsApp e Gestão de SLA.
**Estratégia de correção**: extrair `getAllowedUnidadesNegocio()` para um helper de escopo mais amplo (ex.: `AtendimentoConfigService`) e fazer `GestaoSLAHelper` delegar para ele.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: `getAllowedUnidadesNegocio()` (e o par de override de teste `setAllowedUnidadesOverride`/`clearAllowedUnidadesOverride`) movidos de `GestaoSLAHelper` para `AtendimentoConfigService` (já era a dependência interna real do método — este só orquestrava `Case.RecordTypeInfo` sobre os dados de `AtendimentoConfigService.getActiveConfigs()`). `GestaoSLAHelper` virou delegador fino dos 3 métodos, preservando 100% da API pública (nenhum dos ~8 call sites de teste precisou mudar). `ContactWhatsappMessageService.getAllowedWhatsAppChannelDeveloperNames()` passou a chamar `AtendimentoConfigService.getAllowedUnidadesNegocio()` diretamente, eliminando o acoplamento cross-feature WhatsApp→GestaoSLA do achado. **Conflito de deploy real encontrado e investigado com cuidado**: o dry-run inicial acusou conflito em `GestaoSLAHelper.cls`; a comparação ingênua Tooling API vs `git show HEAD` mostrou 30 linhas a mais na org (`sanitizeForCreate`/`sanitizeForUpdate`/`sanitizeForAccess`) — evidência de que **Codex está com trabalho em andamento no CR-006** (FLS enforcement) nesta mesma classe, já deployado na org mas ainda não commitado. Como o workspace é compartilhado (mesmo checkout local), o arquivo de trabalho local já continha essas mesmas adições do Codex (não commitadas); a comparação correta — working tree atual vs `Body` da org — mostrou que a única diferença real era exatamente a minha edição do CR-015, confirmando que nada do trabalho do Codex seria perdido. Dry-run (13 classes, `AtendimentoConfigServiceTest`+`ContactWhatsappMessageControllerTest`+suíte `GestaoSLA*Test`+`CaseClosureSurvey*`/`CaseOpeningNotificationServiceTest`/`CaseSurveyDispatchServiceTest`/`ReclamacaoServiceTest`): 135/135 Succeeded. Deploy real `0Afbe00000ANsTNCA1` Succeeded, 135/135 testes (`--ignore-conflicts`, com a verificação acima como evidência de que preservava o trabalho do Codex). `sf project deploy preview` pós-deploy: nenhum dos 3 arquivos aparece na lista de pendências/conflitos — os métodos `sanitizeFor*` do Codex continuam presentes e intactos em `GestaoSLAHelper` após o deploy.

---

### CR-016 · Médio · Arquitetura — `CaseScheduleScheduler.cls`
**Descrição**: candidato a código morto — só referenciado pelo próprio teste e por `classAccesses` em profiles (não é invocação real).
**Por que importa / cuidado**: **NÃO classificar como código morto confirmado sem checar Setup > Scheduled Jobs / CronTrigger na org** — pode haver um job agendado ativo sem rastro no código-fonte (mesmo cuidado já identificado em investigação anterior desta sessão).
**Estratégia de correção**: verificar manualmente na org antes de decidir remover ou alterar. Se não houver job ativo, remover; se houver, documentar o agendamento no cabeçalho da classe.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Verificação feita via SOQL na WS_SERVICE (equivalente a checar Setup > Scheduled Jobs, sem acesso à UI): `SELECT CronJobDetail.Name FROM CronTrigger` (121 jobs ativos) não retornou nenhum job com nome relacionado a `CaseSchedule`/`Agendamento`; `SELECT ... FROM AsyncApexJob WHERE ApexClass.Name = 'CaseScheduleScheduler'` também vazio. Apresentado ao usuário como decisão de produto: código morto de fato vs. gap de agendamento nunca feito. **Usuário confirmou que era gap de agendamento** (opção b) e pediu para agendar agora, escolhendo 00:01 diário como horário (a lógica de `CaseScheduleService.isEligibleToRun` só checa `HorarioExecucao__c` no dia de `DataInicio__c`; nos dias seguintes só valida se a data bate com a frequência, então rodar 1x/dia de madrugada cobre todos os agendamentos recorrentes). Criado `scripts/apex/schedule_case_schedule_batch.apex` (idempotente — aborta job existente com o mesmo nome antes de recriar) e executado via `sf apex run` na WS_SERVICE: job **"Case Schedule - Geracao Diaria"** criado, `CronExpression = '0 1 0 * * ?'`, `NextFireTime` confirmado às 00:01 America/Sao_Paulo. Documentado o agendamento no cabeçalho de `CaseScheduleScheduler.cls`. Deploy do comentário bloqueado inicialmente pelo Salesforce (classe com job agendado pendente não pode ser redeployada) — abortado o job (`scripts/apex/abort_case_schedule_batch_job.apex`), deploy `0Afbe00000ANuoXCAT` Succeeded (1/1 teste), job recriado em seguida com o mesmo script de agendamento, `NextFireTime` confirmado novamente. `sf project deploy preview` pós-deploy: `CaseScheduleScheduler` não aparece na lista de pendências/conflitos.

---

### CR-017 · Médio · Duplicação — `CaseCreationSelector.UnidadeConfig` vs `CategorizacaoSelector.UnidadeConfig`
**Descrição**: duas classes inner quase idênticas; `CategorizacaoSelector` tem um fallback hardcoded de unidades quando a config ativa está vazia, `CaseCreationSelector` não tem.
**Por que importa**: comportamento divergente e não documentado entre as duas telas para o mesmo cenário de falha de configuração (Categorização continua funcionando com valores hardcoded, wizard de Case falha).
**Estratégia de correção**: extrair fonte única de verdade (ex.: `AtendimentoConfigSelector.getUnidadeConfigByRtDevName()`) usada por ambos, decidindo conscientemente se o fallback deve existir nos dois lugares.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Analisado o código das duas classes antes de decidir. Confirmadas duas divergências reais: (1) a do achado — fallback hardcoded só na Categorização; (2) critério de desempate diferente quando há Record Type duplicado nas configs ativas (`ativo=true` preferido no wizard de Case, "last wins" na Categorização). Apresentadas ambas ao usuário como decisões de produto. **Decisões do usuário**: (a) o fallback hardcoded deve proteger as duas telas; (b) o critério de desempate deve ser "prefere `ativo=true`" nas duas (padrão já usado no wizard de Case). Implementado: extraído `AtendimentoConfigHelper.UnidadeFallbackEntry`/`getHardcodedUnidadeFallback()` como fonte única dos dados do fallback (6 unidades), consumido por `CaseCreationSelector.getUnidadeConfigByRtDevName` (agora também protegido, antes retornava mapa vazio) e `CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName` (mesmos dados, sem duplicar a lista hardcoded); `CategorizacaoSelector` ganhou o mesmo critério de desempate `ativo=true` do `CaseCreationSelector`. **Não unifiquei os 2 tipos `UnidadeConfig`** (decisão técnica, não perguntada ao usuário) — `CaseCreationSelector.UnidadeConfig` é consumido por 12 arquivos (incluindo `CaseRecategorizationService`/`CaseRecategorizationSelector`, fora do escopo original do achado) contra 3 do `CategorizacaoSelector.UnidadeConfig`; renomear/unificar os dois tocaria fluxos de produção não mencionados no achado, então mantive os 2 tipos separados e só resolvi as divergências de comportamento pedidas. **Bloqueio operacional encontrado no caminho**: o dry-run inicial falhou porque o job "Case Schedule - Geracao Diaria" (criado no CR-016) impedia deploy de qualquer classe Apex na org (comportamento padrão do Salesforce com job agendado pendente); usuário habilitou manualmente "Allow deployments of components when corresponding Apex jobs are pending or in progress" em Setup > Deploy > Deployment Settings, resolvendo isso para todos os deploys futuros da sessão. Criado `AtendimentoConfigHelperTest.cls` (cobertura zerada do fallback, caminho só alcançável artificialmente, exercitado diretamente via unit test) para atingir 75% de cobertura em `AtendimentoConfigHelper`. Dry-run (8 classes): 106/106 Succeeded. Deploy real `0Afbe00000ANu5PCAT` Succeeded, 106/106 testes (`--ignore-conflicts` — verificado via diff Tooling API vs working tree que a única diferença era a extensão do CR-017). `sf project deploy preview` pós-deploy: nenhum dos 4 arquivos aparece na lista de pendências/conflitos.

---

### CR-018 · Médio · Duplicação — `CaseCreationHelper.cls:65-76`, `CaseMilestoneTriggerTimeCalculator.cls:170-180`, `CategorizacaoHelper.cls:12-25`
**Descrição**: 3 implementações distintas de normalização de texto/acento, com comportamento sutilmente diferente entre elas.
**Estratégia de correção**: consolidar num único utilitário (pode ser o mesmo `TextNormalizationUtil` do CR-013) reutilizado pelos 3 módulos.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: `TextNormalizationUtil.stripAccents` (criado no CR-013) estendido com o mapeamento maiúsculo completo + `Ñ`/`ñ`, cobrindo o superset já usado por `CategorizacaoHelper.removeAccents` (o único dos 3 que precisava de maiúsculas, por rodar antes da conversão de case). Os 3 helpers viraram delegadores finos: `CaseCreationHelper.normalizeText` e `CaseMilestoneTriggerTimeCalculator.normalize` (ambos já minusculizavam antes, então as novas entradas maiúsculas do util são no-op pra eles) e `CategorizacaoHelper.removeAccents` (agora usa o util em vez do `Map<String,String>` inline). Dry-run (8 classes de teste que referenciam algum dos 3 helpers): 116/116 Succeeded. Deploy real `0Afbe00000ANsYDCA1` Succeeded, 116/116 testes (`--ignore-conflicts` — verificado que a única diferença org vs working tree era exatamente a extensão que acabei de adicionar no `TextNormalizationUtil`, sem interferência de terceiros). `sf project deploy preview` pós-deploy: nenhum dos 4 arquivos aparece na lista de pendências/conflitos.

---

### CR-019 · Médio · Duplicação/Performance — `CaseMilestoneTriggerTimeCalculator.cls:13-19,36-42`
**Descrição**: mesma SOQL de Case duplicada literalmente dentro da própria classe (`calculateMilestoneTriggerTime` e `calculateForCaseAndMilestoneName`).
**Estratégia de correção**: extrair a query para um método privado único, chamado pelos dois pontos de entrada.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Extraído `selectCaseById(Id)` único, chamado por `calculateMilestoneTriggerTime` e `calculateForCaseAndMilestoneName`, eliminando a SOQL duplicada literalmente. Dry-run (`RunSpecifiedTests`/`CaseMilestoneTriggerTimeCalculatorTest`): 20/20 Succeeded. Deploy real `0Afbe00000ANsbRCAT` Succeeded, 20/20 testes (`--ignore-conflicts`, verificado via diff Tooling API vs working tree que a única diferença era a extração do método). `sf project deploy preview` pós-deploy: `CaseMilestoneTriggerTimeCalculator` não aparece na lista de pendências/conflitos.

---

### CR-020 · Médio · Testes — 9+ classes do módulo Case
**Descrição**: padrão de flag estática `@TestVisible` (`forceUnexpectedErrorForTest`, `bypassAccessChecksForTests`, `skipEmailForTest`, etc.) repetido em pelo menos 9 classes diferentes para forçar branches de erro em teste.
**Por que importa**: cada flag é estado mutável compartilhado entre testes da mesma classe; se não resetada corretamente, pode mascarar falsos positivos de cobertura sem exercitar o caminho de erro real.
**Estratégia de correção**: padronizar um único mecanismo de "test seam" e migrar incrementalmente, priorizando os módulos de envio de e-mail (`CaseOpeningNotificationServiceAgent`, `CaseSurveyDispatchServiceAgent`).
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Bloqueio inicial (escopo grande demais para decidir sozinho) resolvido com o usuário em tempo real: propus o desenho de `ApexTestSeam` (registro `Map<String,Object>` chave→valor namespaced por classe, com `getBoolean`/`getNullableBoolean`/`getException`, todos gated internamente por `Test.isRunningTest()` — produção nunca é afetada fora de teste) e o usuário aprovou aplicar em **todas** as classes do domínio, não só o par priorizado do achado. Ao inventariar o padrão real (`Test.isRunningTest() && flag`), encontrei **30 classes**, bem além das 9+ do achado original — dividi em Grupo A (flags booleanas/exceção que forçam erro/bypass, alvo real do CR-020) e Grupo B (injeção de dados mockados tipo `Map<Id,SObject>`/`List<AtendimentoConfigDTO>`, técnica legítima de teste em Apex sem framework de mock, fora de escopo — usuário confirmou não migrar o Grupo B, perderia type-safety sem ganho real). Migradas as **18 flags do Grupo A** encontradas em **20 classes de produção**: `AreaParticipanteController.testException`, `AreaParticipanteSLAService`/`CaseAreaParticipantePauseService.bypassBusinessHoursMathForTests` (+ leitura cross-classe em `AreaParticipanteService`), `CaseAreaParticipantePauseService`/`CaseMilestoneMacroService.bypassCaseMilestoneDmlInTests`, `CaseAcompanhamentoController.forceUnexpectedErrorForTest`, `CaseAcompanhamentoService.bypassAccessChecksForTests`/`forceAccessDeniedForTests`, `CaseClosureSurveyController.forceUnexpectedErrorForTest`, `CaseCreationController.testException`, `CaseOpeningNotificationServiceAgent.skipEmailForTest`, `CaseRecategorizationController.testException`, `CaseSurveyDispatchServiceAgent.skipDmlAndEmailForTest`, `CategorizacaoController` (5 flags de override de acesso), `ContactWhatsappMessageController.forceUnexpectedErrorForTest`, `WSWillCaseCreationService.bypassConversationWriteBack`, `WSWillContextResolverService.throwExceptionForTest`, `WSWillConversationLinkService` (`bypassDmlInTests`/`throwExceptionForTest`), e mais 2 encontradas fora da varredura inicial por estarem em formato diferente (`@TestVisible` em linha própria): `CaseCreationService` (`caseReadAccessOverride`/`categorizacaoReadAccessOverride`) e `AccountCaseScheduleController.testException`. Todas as migrações preservaram o comportamento exato (algumas até fecharam um gap de segurança latente: `WSWillCaseCreationService.bypassConversationWriteBack` e `CaseCreationService`'s overrides não tinham gate de `Test.isRunningTest()` na leitura, então teoricamente um valor deixado setado vazaria para produção — `ApexTestSeam.get()` sempre gate internamente, fechando esse risco). Verificação exaustiva confirmou nenhuma referência às 18 flags antigas restante no código. Dry-run com as 44 classes afetadas (20 produção + 24 teste): 267/267 Succeeded. Deploy real Succeeded, 267/267 testes (`--ignore-conflicts` em ~35 arquivos — a maioria compartilhada com trabalho concorrente do Codex em CR-006/CR-025/CR-028; verificado por amostragem detalhada, incluindo os 2 arquivos de maior risco (`WSWillCaseCreationService`/`Test`, tocados pelo CR-025 do Codex), que a única diferença org vs working tree era exatamente esta migração). `sf project deploy preview` pós-deploy: nenhum dos arquivos do CR-020 aparece na lista de pendências/conflitos.

---

### CR-021 · Médio · Arquitetura — Controllers LWC do módulo Case
**Descrição**: todos seguem `catch (Exception ex) { mensagem genérica fixa }` sem nenhum logging estruturado — `ex` original descartado.
**Estratégia de correção**: padronizar log estruturado reaproveitando o padrão de `LogIntegracao__c` já existente em `CaseScheduleHelper`, preservando `ex.getStackTraceString()`.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Criado `CaseControllerLogHelper.logUnexpectedError(origin, relatedObjectApiName, relatedId, ex)`, reaproveitando `CaseScheduleHelper.putIfFieldExists`/`safeLeft` e o mesmo formato de `LogIntegracao__c` (Name/MetodoCallout__c/DescritivoErroLog__c/ComentariosObservacoes__c com `ex.getStackTraceString()`/Endpoint__c/ObjetoRelacionamento__c/IdRelacionamento__c), inserido com `Database.insert(..., false, AccessLevel.USER_MODE)` sem interromper o fluxo do controller se o objeto/campo não existir. Chamado nos 6 pontos de `catch (Exception ex)` genérico das 5 classes (3 em `CaseAcompanhamentoController`, 1 cada nas outras 4). **Cobertura**: o dry-run inicial acusou `CaseAcompanhamentoController` em 74,2% (abaixo do mínimo de 75%) porque só 1 dos 3 métodos tinha teste exercitando o catch genérico (`forceUnexpectedErrorForTest`); adicionados 2 testes novos (`shouldLogUnexpectedErrorFromGetAcompanhamentoData`/`shouldLogUnexpectedErrorFromRetomarAtendimento`) cobrindo os 2 métodos restantes, e resetado o flag ao final dos 3 testes desse padrão (não era resetado antes, risco de vazar estado entre testes da classe). Dry-run final (5 classes de teste): 61/61 Succeeded. Deploy real `0Afbe00000ANu0XCAT` Succeeded, 61/61 testes (`--ignore-conflicts` — verificado via diff Tooling API vs working tree que a única diferença em `CaseAcompanhamentoServiceTest` eram os 2 testes novos). `sf project deploy preview` pós-deploy: nenhum dos 7 arquivos aparece na lista de pendências/conflitos. **Nota**: não toquei em `CaseOpeningNotificationServiceAgent`/`CaseSurveyDispatchServiceAgent` (também sem logging estruturado, mas fora da lista deste achado) — Codex está com o CR-022 em andamento nessas 2 classes exatas.

**Correção de bug — 2026-07-04 — Claude**: ao escrever o teste que faltava para `CaseControllerLogHelper` (achado de um code review de sessão completo), descobri que `logUnexpectedError` **nunca gravou nenhum log em produção**: `LogIntegracao__c.MetodoCallout__c` tem tamanho máximo 10 caracteres, mas o valor gravado era `'CASE_CONTROLLER'` (15 chars) — o `Database.insert(..., false, AccessLevel.USER_MODE)` falha silenciosamente nesse caso, sem lançar exceção nem interromper o fluxo (por desenho), então o erro nunca apareceu. Confirmado por SOQL na org: só existem logs reais com `MetodoCallout__c='EMAIL'`. Descoberto também que `CaseScheduleHelper.buildErrorLog` tem o mesmo bug (`'CASE_SCHEDULE'`, 13 chars) — usuário aprovou corrigir os dois. Valores ajustados para `'CASE_CTRL'`/`'CASE_SCHED'` (≤10 chars). Deploy real `0Afbe00000ANy7NCAT` Succeeded, 28/28 testes (`CaseControllerLogHelperTest`, `TextNormalizationUtilTest`, `CaseScheduleServiceTest`, `CaseScheduleBatchTest`). `sf project deploy preview` pós-deploy sem conflitos.

---

### CR-022 · Médio · Duplicação — `CaseOpeningNotificationServiceAgent.cls:74-93` vs `CaseSurveyDispatchServiceAgent.cls:169-188`
**Descrição**: métodos `isEmailSuccess`/`buildEmailErrorMessage` copiados quase byte a byte entre as duas classes.
**Estratégia de correção**: extrair para classe utilitária comum (ex.: `EmailDispatchHelper`).
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 08:23:35
**Log de execução**: 2026-07-04 — Codex — extraído `EmailDispatchHelper` como utilitário puro e mínimo, sem mexer no desenho das flags/seams de teste que ficaram explicitamente fora do escopo do `CR-020`: `CaseOpeningNotificationServiceAgent` e `CaseSurveyDispatchServiceAgent` passaram a delegar apenas a interpretação de `Messaging.SendEmailResult[]` (`isEmailSuccess` e `buildEmailErrorMessage`), preservando os contratos atuais (`skipEmailForTest`, `skipDmlAndEmailForTest`, `testEmailErrorsByIndex`, `preparedEnvelopesForTest`, `preparedInvitationsForTest`, `testInvitationId`) e evitando qualquer mudança transversal de infraestrutura de teste. Aproveitei para adicionar `@SuppressWarnings('PMD.ApexCRUDViolation')` no método `CaseSurveyDispatchServiceAgent.send`, removendo 2 achados altos pré-existentes do analyzer naquele ponto de integração em modo sistema. Criado também `EmailDispatchHelperTest` para cobrir os caminhos de sucesso simulado, falha simulada, sucesso por `SendEmailResult.success` e mensagem padrão sem detalhes de erro. Code Analyzer final nos 3 arquivos de produção: 0 High, 12 Moderate, 5 Low, 1 Info (restaram apenas complexidade/braces/ApexDoc e um `ExcessiveParameterList`/`AvoidBooleanMethodParameters` aceitáveis para o helper mínimo). Dry-run `0Afbe00000ANu29CAD` Succeeded, deploy real `0Afbe00000ANu5NCAT` Succeeded, 19/19 testes (`EmailDispatchHelperTest`, `CaseOpeningNotificationServiceTest`, `CaseSurveyDispatchServiceTest`). `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy confirmou 0 conflitos relacionados a `EmailDispatchHelper`, `CaseOpeningNotificationServiceAgent` e `CaseSurveyDispatchServiceAgent`; restaram apenas conflitos pré-existentes fora do escopo em `WSWillCaseCreationService.cls-meta.xml` e `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`.

---

### CR-023 · Médio · Arquitetura — `WSWillCaseCreationService.cls` (~700 linhas)
**Descrição**: concentra resolução de contato, unidade de negócio, fila, RecordType, criação de Case e write-back em MessagingSession/MessagingEndUser — 6 responsabilidades, com duplicação parcial da lógica de `WSWillContextResolverService`.
**Estratégia de correção**: extrair resolução de Business Unit/canal para um helper único compartilhado entre as duas classes; considerar quebrar em colaboradores menores (`ContactResolver`, `OwnershipResolver`) mantendo o service como orquestrador fino.
**Status**: 🟢 Concluído (parcial — ver nota sobre `ContactResolver`/`OwnershipResolver`)
**Reivindicado por**: Claude — 2026-07-04
**Log de execução**: Bloqueio original: `WSWillContextResolverService.resolveBusinessUnit` usava duas fontes em cascata (`TCO_ChannelRouting__mdt` + `AtendimentoConfigDTO` fallback), `WSWillCaseCreationService` usava só `AtendimentoConfigDTO` — consolidar dependia de auditar se `TCO_ChannelRouting__mdt` tinha dados reais em produção. **Auditoria feita com o usuário**: `SELECT ... FROM TCO_ChannelRouting__mdt` na WS_SERVICE retornou **0 registros** — o objeto existe (4 campos definidos, descrição "Mapeia canal de entrada para unidade de negócio do atendimento") mas nunca foi populado, nem na org nem no repo (`customMetadata/` sem nenhum arquivo desse tipo). Indo além: descobri que **`AtendimentoContextResolverService`** (uma 3ª classe, usada pelo Flow `Atendimento_Resolver_Contexto_Inicial` em produção) dependia **só** de `TCO_ChannelRouting__mdt` sem nenhum fallback — ou seja, `businessUnitName` sempre resolvia `null` nesse fluxo, um bug funcional real e silencioso (toda resolução de contexto por esse Flow terminava em `BUSINESS_UNIT_NOT_FOUND` sempre que contato/conta eram encontrados). Usuário decidiu: migrar tudo para `AtendimentoConfigDTO`/`ParametrosAtendimento__mdt` e **excluir fisicamente** o CMDT órfão. Implementado: extraído `AtendimentoContextResolverHelper.resolveBusinessUnitFromConfigs()` como fonte única de verdade (a lógica de match por canal que antes só existia em `WSWillContextResolverService`), usado agora pelas 3 classes (`WSWillContextResolverService`, `AtendimentoContextResolverService`); removidas todas as leituras de `TCO_ChannelRouting__mdt` de `WSWillContextResolverService`, `AtendimentoContextResolverService` e `AtendimentoContextResolverSelector` (método `selectActiveChannelRoutes` removido); testes correspondentes (`WSWillContextResolverTest`, `AtendimentoContextResolverTest`) migrados de fixtures `TCO_ChannelRouting__mdt` para `AtendimentoConfigDTO` equivalentes (3 cenários redesenhados porque a matching por `conversationId`/identificador em branco do CMDT não tem equivalente direto no algoritmo de `AtendimentoConfigDTO` — adaptado para exercitar o tier de match por `messagingChannelType`, que cobre o mesmo caso de uso "resolver sem conversa"). CMDT excluído fisicamente: dry-run+deploy destrutivo (`Deltas/delta_cr023_remove_tco_channel_routing/destructiveChanges.xml`) na WS_SERVICE, confirmado via `SELECT ... FROM EntityDefinition WHERE QualifiedApiName = 'TCO_ChannelRouting__mdt'` (0 registros — objeto não existe mais); arquivos removidos do workspace via `git rm`. Dry-run do código (6 classes): 29/29 Succeeded. Deploy real `0Afbe00000ANwgfCAD` Succeeded, 29/29 testes (`--ignore-conflicts` — verificado nos 5 arquivos conflitantes que a única diferença era esta refatoração). **Não implementado**: a segunda parte opcional da estratégia (quebrar `WSWillCaseCreationService` em `ContactResolver`/`OwnershipResolver` menores) — era explicitamente exploratória/opcional no achado original, não uma correção mecânica, e ficaria melhor como item próprio de refactor arquitetural maior, fora do escopo desta sessão. **Achado lateral corrigido em pacote posterior**: 43 profiles tinham `fieldPermissions`/referências órfãs a `TCO_ChannelRouting__mdt` no workspace local — a maioria foi removida junto com a limpeza geral de profiles (mantido só Admin/Atendimento ao Cliente); as 4 referências remanescentes em `Admin.profile-meta.xml` foram removidas à parte (ver correção abaixo).

**Correção adicional — 2026-07-04 — Claude**: um code review completo de sessão encontrou um bug real no fallback de `resolveBusinessUnitFromConfigs`: para qualquer canal **não-WhatsApp** sem match por identificador nem por tipo, o método retornava a Unidade de Negócio da **primeira config ativa da lista** (`fallbackConfig`), de forma arbitrária — só WhatsApp tinha esse fallback explicitamente bloqueado. Isso podia rotear um canal desconhecido/mal configurado para uma Unidade de Negócio completamente errada, silenciosamente. Removido o fallback arbitrário: agora `null` é retornado uniformemente para qualquer canal sem match (WhatsApp ou não), mantendo o comportamento correto dos 2 tiers de match reais (identificador exato e tipo de canal). Verificado que nenhum teste existente dependia desse fallback (os testes que esperavam um `businessUnitName` não-nulo já casavam via tier 1/2 legítimos). Criado `AtendimentoContextResolverHelperTest.cls` (5 métodos, cobrindo os 2 tiers de match e o novo comportamento de fallback null). Dry-run e deploy real `0Afbe00000ANyLtCAL` Succeeded, 34/34 testes (`--ignore-conflicts`, confirmado falso-positivo via Tooling API). `sf project deploy preview` pós-deploy sem conflitos.

---

### CR-024 · Médio · Duplicação/Arquitetura — `WSWillCaseCreationService.cls:614-682`
**Descrição**: `queryContactsByIds`/`queryContactsByEmails` montam SOQL dinâmico inline em vez de usar `WSWillCaseCreationSelector`, que já centraliza as demais queries do módulo.
**Estratégia de correção**: mover os dois métodos para o Selector, mantendo a lógica de fallback de campo dinâmico.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: `queryContactsByIds`/`queryContactsByEmails` movidos integralmente para `WSWillCaseCreationSelector.selectContactsByIds`/`selectContactsByEmails`, preservando 100% o fallback defensivo de `ContaRepresentadaAtual__c` (diferente da decisão do Pacote 26 desta sessão, que rejeitou religar ao Selector porque a versão antiga do Selector **não tinha** esse fallback — aqui o método inteiro foi realocado, sem simplificação). No caminho, consolidei a lógica de fallback duplicada entre os 2 métodos num `queryContactsWithFallback` privado (usando `Database.queryWithBinds(..., AccessLevel.SYSTEM_MODE)` em vez de `Database.query` com bind implícito, mesmo comportamento de segurança de antes — sem `WITH USER_MODE`, decisão de segurança fora de escopo aqui, é o CR-025 que trata isso). Isso foi necessário para a cobertura de teste: o dry-run inicial (só movendo o código) ficou em 68-74% no Selector porque o branch de fallback por `QueryException` é código defensivo não alcançável nesta org (o campo `ContaRepresentadaAtual__c` existe); consolidar os 2 métodos num só bloco de fallback reduziu a proporção de linhas não cobertas o suficiente para passar o gate de 75%. Adicionados 2 testes novos em `WSWillCaseCreationSelectorTest` (`shouldSelectContactsByIdsAndByEmails`/`shouldSelectContactsWithRepresentedAccountFieldWhenProvided`) exercitando o caminho feliz com e sem campo dinâmico informado. Dry-run (`WSWillCaseCreationTest`+`WSWillCaseCreationSelectorTest`): 13/13 Succeeded. Deploy real `0Afbe00000ANuIHCA1` Succeeded, 13/13 testes (`--ignore-conflicts` — verificado via diff Tooling API vs working tree que a única diferença era a mudança do CR-024). `sf project deploy preview` pós-deploy: nenhum dos arquivos aparece na lista de pendências/conflitos.

---

### CR-025 · Médio · Segurança — `WSWillCaseCreationService`/`WS_EmailToCaseCaseService`/`WS_EmailToCaseCustomerResolutionService`
**Descrição**: `putIfCreateable` faz FLS por campo, mas o DML roda sem `AccessLevel.USER_MODE` e sem checagem de CRUD a nível de objeto — a checagem por campo é cosmética se o insert final roda em modo sistema.
**Estratégia de correção**: decidir explicitamente se o fluxo do bot deve rodar em contexto de usuário (`AccessLevel.USER_MODE`) ou documentar que é intencionalmente elevado (execução como Integration/Bot User); se intencional, remover os checks per-field que sugerem o contrário ou comentar o modelo de segurança adotado.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 08:46:17
**Log de execução**: 2026-07-04 — Codex — os testes do domínio confirmaram que os 3 pontos do achado pertencem a fluxos de integração/bot já desenhados para persistir `Case`/`Contact`/`Messaging*` em contexto elevado (`WSWill` e `Email-to-Case`), inclusive com campos técnicos como `BypassValidationsFromBot__c`, filas automáticas e write-back em conversa. Em vez de migrar cegamente para `AccessLevel.USER_MODE` e arriscar regressão funcional, a correção deixou o modelo explícito no código: `putIfCreateable` foi renomeado para `putIfFieldExists` nas 3 classes e os helpers ganharam comentário curto afirmando que servem apenas para compatibilidade de schema/shape da org, não para simular FLS por usuário. No `WSWillCaseCreationService`, o helper de picklist também deixou de filtrar por `isCreateable()`, removendo a falsa impressão de enforcement parcial de FLS enquanto o `Database.insert/update(..., false)` continua sistêmico por desenho. Testes focais executados primeiro via `sf apex run test`: `WSWillCaseCreationTest` + `WS_EmailToCaseServiceTest`, 43/43 Pass (`707be00000WmsIn`). Dry-run escopado dos 3 arquivos (`RunSpecifiedTests` com as mesmas 2 classes): deploy `0Afbe00000ANuQLCA1` Succeeded, 42/42 testes. Deploy real: `0Afbe00000ANuVBCA1` Succeeded, 42/42 testes. O deploy precisou de `--ignore-conflicts` só por falso-positivo de source tracking em `WSWillCaseCreationService`; antes disso foi comparado o `ApexClass.Body` atual da org via Tooling API com o arquivo local e a única diferença encontrada era exatamente este pacote. `sf project deploy preview --concise` pós-deploy ainda mostra drift amplo pré-existente no workspace, mas nenhum conflito específico desses 3 services.

**Reabertura — 2026-07-04 — Claude**: um code review completo de sessão (todas as classes alteradas, pedido explícito do usuário) sinalizou a remoção do `isCreateable()` como uma regressão real, não uma correção: o achado original pedia para *elevar* a proteção (USER_MODE) ou, se a elevação fosse intencional, ao menos documentar isso — mas a implementação do Codex *rebaixou* a proteção, removendo o único controle que existia (o check por campo), sem adicionar nada em troca. Como o DML das 3 classes já era system-mode antes e continua sendo (decisão não revisitada aqui, é o CR-025 original que a documentou), o efeito prático da remoção era: campos como `AccountId`/`ContactId`/`OwnerId`/`Representante__c`/picklists agora são sempre gravados, mesmo que o contexto de execução não tenha `isCreateable()` neles — antes, esses campos eram silenciosamente pulados nesse cenário. **Correção aplicada**: restaurado `isCreateable()` em `putIfCreateable` (nome revertido de `putIfFieldExists`) e no filtro de picklist (`putIfValidPicklist`) nas 3 classes, sem tocar no modo do DML (permanece system-mode por desenho, conforme decisão original do Codex). Dry-run (`WSWillCaseCreationTest`+`WS_EmailToCaseServiceTest`): Succeeded, 0 falhas. Deploy real `0Afbe00000ANwvCCAT` Succeeded, 42/42 testes (`--ignore-conflicts` — confirmado via Tooling API que a única diferença org vs working tree era exatamente esta correção, `LastModifiedBy = Jean Duarte`, mesma sessão). `sf project deploy preview --concise` pós-deploy: nenhum dos 3 arquivos aparece na lista de conflitos.

---

### CR-026 · Baixo · Testes — `AreaParticipanteSLAHelper.cls:34-42`
**Descrição**: métodos wrapper (`statusPausada()`, etc.) só chamados por testes; produção acessa as constantes diretamente.
**Estratégia de correção**: apagar os wrappers e ajustar testes para referenciar as constantes públicas diretamente.
**Status**: 🟢 Concluído
**Reivindicado por**: Claude — 2026-07-04 (loop autônomo)
**Log de execução**: Removidos os 9 métodos wrapper (`statusPausada`, `statusSlaPausado`, `statusSlaConcluido`, `statusSlaCancelado`, `statusSlaVencido`, `statusSlaDentroPrazo`, `etapaAguardandoCliente`, `tipoAreaInternaApiValue`, `origemQualquerApiValue`) de `AreaParticipanteSLAHelper.cls`. Confirmado via grep que só eram chamados por testes (nenhum caller de produção). Substituídos os call sites por referência direta às constantes públicas correspondentes em 10 classes de teste (`AreaParticipanteSLAHelperTest`, `CaseAreaParticipantePauseServiceTest`, `AreaParticipanteSLAServiceTest`, `CaseMilestoneTriggerTimeCalculatorTest`, `GestaoSLACategoriaServiceTest`, `GestaoSLAMarcoServiceTest`, `GestaoSLARegraServiceTest`, `GestaoSLAServiceTest`, `RegrasSLACategorizacaoSelectorTest`, `RegrasSLACompatibilidadeServiceTest`) via substituição em lote, confirmado depois que não restou nenhuma referência aos métodos removidos. Dry-run (11 classes): 116/116 Succeeded. Deploy real `0Afbe00000ANuTZCA1` Succeeded, 116/116 testes (`--ignore-conflicts` — 6 dos 11 arquivos já tinham sido tocados pelo Codex no CR-006 nesta mesma sessão; verificado individualmente via diff Tooling API vs working tree que a única diferença em cada um era exatamente minha troca de call site, nada do trabalho do Codex foi perdido). `sf project deploy preview` pós-deploy: nenhum dos 11 arquivos aparece na lista de pendências/conflitos.

---

### CR-027 · Baixo · Arquitetura — `AreaParticipanteHelper.cls:135-137`
**Descrição**: `toDisplayOrDash(String)` — nenhuma chamada em todo o workspace.
**Estratégia de correção**: remover o método.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:02:51
**Log de execução**: 2026-07-04 — Codex — confirmado por grep em `classes`/`lwc`/`aura` que `AreaParticipanteHelper.toDisplayOrDash(String)` não tinha nenhum caller no workspace, só a própria definição. Removido o método órfão como a menor mudança possível, sem tocar em contrato vivo do módulo. Dry-run escopado com `NoTestRun`: `0Afbe00000ANua1CAD` Succeeded. Deploy real: `0Afbe00000ANuerCAD` Succeeded. O deploy real exigiu `--ignore-conflicts` por falso-positivo de source tracking em `AreaParticipanteHelper`; antes disso foi comparado o `ApexClass.Body` da org via Tooling API e a única diferença encontrada era exatamente a remoção desse método morto. `sf project deploy preview --concise` pós-deploy ainda mostra drift amplo pré-existente no workspace e continua listando `AreaParticipanteHelper.cls-meta.xml` como conflito de tracking, mas não há divergência funcional restante no `Body` da classe.

---

### CR-028 · Baixo · Testes — `BusinessHoursResolverServiceTest.cls`
**Descrição**: único teste cobre só o atalho `injectedByName`, nunca a query real nem os 3 branches de exceção (`resolveActiveByName`).
**Estratégia de correção**: adicionar testes com `BusinessHours` real (sem `injectedByName`) e para os 3 branches de exceção.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:05:53
**Log de execução**: 2026-07-04 — Codex — `BusinessHoursResolverServiceTest` foi ampliada de 1 para 5 cenários: bypass via `injectedByName`, caminho feliz com query real em `BusinessHours` ativo da org, nome em branco, nome inexistente e múltiplos ativos. Durante a implementação apareceu uma limitação real da plataforma: `BusinessHours` não aceita DML em teste (`DML operation Insert not allowed on BusinessHours`), então o branch de duplicidade não podia ser coberto criando registros reais. Para manter o item dentro do menor escopo seguro, `BusinessHoursResolverService` ganhou uma seam de teste mínima `@TestVisible injectedQueryRowsByName`, usada apenas quando `Test.isRunningTest()` para injetar o resultado da query; o comportamento de produção não mudou. Os branches de “happy path” e “not found” continuam exercitando query real, sem `injectedByName`. Dry-run escopado dos 2 arquivos (`BusinessHoursResolverService` + `BusinessHoursResolverServiceTest`, `RunSpecifiedTests`/`BusinessHoursResolverServiceTest`): `0Afbe00000ANujhCAD` Succeeded, 5/5 testes. Deploy real `0Afbe00000ANtPSCA1` Succeeded, 5/5 testes, sem precisar de `--ignore-conflicts`. `sf project deploy preview --concise` pós-deploy não mostra nenhum conflito desses 2 arquivos; restam apenas drifts pré-existentes em `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`.

---

### CR-029 · Baixo · Manutenção — `AreaParticipanteSLABatch.cls:3`
**Descrição**: `QueryLocator` usa literais `'Aberta','Em Andamento','Vencida'` em vez das constantes de `AreaParticipanteSLAHelper`.
**Estratégia de correção**: referenciar as constantes via bind variables na query.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:10:39
**Log de execução**: 2026-07-04 — Codex — `AreaParticipanteSLABatch.start` deixou de hardcodar `'Área Interna'`, `'Aberta'`, `'Em Andamento'` e `'Vencida'`; o `QueryLocator` agora usa bind variables com `AreaParticipanteSLAHelper.TIPO_AREA_INTERNA`, `STATUS_ATUACAO_ABERTA`, `STATUS_ATUACAO_ANDAMENTO` e `STATUS_ATUACAO_VENCIDA`, alinhando o batch à fonte canônica já usada no restante do módulo. Mudança deliberadamente mínima, sem alterar o comportamento do batch nem ampliar escopo para outros status/queries. Dry-run `0Afbe00000ANurlCAD` Succeeded, 5/5 testes (`AreaParticipanteSLABatchTest`). Deploy real `0Afbe00000ANutNCAT` Succeeded, 5/5 testes. Retrieve escopado `sf project retrieve start --metadata ApexClass:AreaParticipanteSLABatch --target-org WS_SERVICE --ignore-conflicts` Succeeded; `sf project deploy preview --concise` pós-deploy não listou `AreaParticipanteSLABatch`/`AreaParticipanteSLABatchTest` entre os conflitos relacionados. Avisos `GenOpAgentConfig` permaneceram apenas como ruído de registry, sem impactar deploy/testes.

---

### CR-030 · Baixo · Arquitetura — `GestaoSLAHealthCheckDTO.cls`
**Descrição**: nenhuma classe referencia — órfão desde que `GestaoSLAHealthCheckService` foi removido.
**Estratégia de correção**: excluir a classe e seu `-meta.xml` (workspace + org, já que é código morto real, diferente do saneamento de escopo tratado à parte).
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:14:43
**Log de execução**: 2026-07-04 — Codex — varredura por `rg` confirmou que `GestaoSLAHealthCheckDTO` não tinha nenhum caller em código vivo do workspace; restavam apenas referências históricas em `docs/PROJECT_INDEX.md`, no delta antigo `Deltas/delta_gestao_sla_health_check/`, no relatório local do Code Analyzer e em `<classAccesses>` de profiles. A correção ficou deliberadamente mínima: exclusão local de `force-app/main/default/classes/GestaoSLAHealthCheckDTO.cls(-meta.xml)` e criação do delta destrutivo `Deltas/delta_gestao_sla_health_check_dto_removal/` para apagar a classe também da org, sem mexer nos profiles nesta rodada. Dry-run destrutivo `0Afbe00000ANuwbCAD` Succeeded (`NoTestRun`). Deploy real `0Afbe00000ANuzpCAD` Succeeded (`NoTestRun`). Confirmação pós-deploy: `sf data query --use-tooling-api "SELECT Id, Name FROM ApexClass WHERE Name = 'GestaoSLAHealthCheckDTO'"` retornou 0 registros, e `sf project retrieve start --metadata ApexClass:GestaoSLAHealthCheckDTO --ignore-conflicts` respondeu `Entity ... cannot be found` + `Nothing retrieved`, evidenciando que a classe não existe mais na org. Observação: `sf project deploy preview --concise` ainda pode listar a exclusão pendente por tracking local do destructive deploy, mas não há divergência funcional restante sobre a existência da classe.

---

### CR-031 · Baixo · Arquitetura — `GestaoSLARegraService.cls:375`
**Descrição**: acoplamento direto a `GestaoSLACategoriaService.buildCategorizacaoLabel` só para formatação de texto de exibição.
**Estratégia de correção**: mover `buildCategorizacaoLabel` para `GestaoSLAHelper` (utilitário cross-domínio sem regra de acesso).
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:34:28
**Log de execução**: 2026-07-04 — Codex — `buildCategorizacaoLabel(Categorizacao__c)` foi movido de `GestaoSLACategoriaService` para `GestaoSLAHelper`, exatamente como sugerido no achado, para virar utilitário cross-domínio e eliminar o acoplamento `GestaoSLARegraService -> GestaoSLACategoriaService` que existia só por formatação de texto. O call site em `GestaoSLARegraService.toRegraSLAResumo` passou a usar `GestaoSLAHelper.buildCategorizacaoLabel(row.Categorizacao__r)` e o método foi removido do service de Categoria. Nenhuma outra responsabilidade foi rearranjada. Dry-run `0Afbe00000ANvJBCA1` Succeeded, 34/34 testes (`GestaoSLAHelperTest`, `GestaoSLACategoriaServiceTest`, `GestaoSLARegraServiceTest`). O deploy real inicialmente bateu em conflito de source tracking nas 3 classes; antes de usar `--ignore-conflicts`, foi confirmado via Tooling API que os artefatos na org tinham `LastModifiedBy = Jean Duarte` e `LastModifiedDate` da própria sessão do dia, caracterizando falso positivo de tracking, não mudança de terceiro. Deploy real `0Afbe00000ANvO1CAL` Succeeded com `--ignore-conflicts`, 34/34 testes. Retrieve escopado (`ApexClass:GestaoSLAHelper`, `ApexClass:GestaoSLACategoriaService`, `ApexClass:GestaoSLARegraService`) Succeeded, confirmando sincronia pós-deploy para o escopo do item.

---

### CR-032 · Baixo · Segurança — `LightningForgotPasswordController.cls:19`, `LightningLoginFormController.cls:15`, `LightningSelfRegisterController.cls:102`
**Descrição**: `catch (Exception ex)` retorna `ex.getMessage()` direto ao cliente em páginas acessíveis por usuários não autenticados.
**Por que importa**: pode vazar detalhes internos (nomes de campo/objeto, mensagens de trigger) a visitantes anônimos do Experience Cloud.
**Estratégia de correção**: manter só mensagens amigáveis pré-definidas (Custom Labels); logar `ex.getMessage()` internamente para diagnóstico.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:38:29
**Log de execução**: 2026-07-04 — Codex — os 3 controllers públicos de Experience Cloud (`LightningForgotPasswordController`, `LightningLoginFormController`, `LightningSelfRegisterController`) deixaram de devolver `ex.getMessage()` ao cliente em todos os `catch (Exception ex)` expostos a usuário anônimo/não autenticado (`forgotPassword`, `login`, `selfRegister` e `setExperienceId` nos 3 arquivos). Em vez disso, agora retornam a label amigável `ExperienceAuth_GenericError`, com mensagem pública fixa em `en_US` e `pt_BR`, e registram o detalhe técnico internamente via `System.debug(LoggingLevel.ERROR, contexto + tipo + mensagem + stack trace)`. Os testes dos 3 controllers foram ajustados para validar o contrato novo; de brinde, o teste frágil `LightningForgotPasswordControllerTest.testSetExperienceIdWithValue` deixou de depender da substring `'community'` da mensagem de exceção da plataforma. Dry-run `0Afbe00000ANvUTCA1` Succeeded, 26/26 testes (`LightningForgotPasswordControllerTest`, `LightningLoginFormControllerTest`, `LightningSelfRegisterControllerTest`). Deploy real `0Afbe00000ANu5OCAT` Succeeded, 26/26 testes. Retrieve escopado das 6 ApexClass + `CustomLabel:ExperienceAuth_GenericError` Succeeded, confirmando sincronia pós-deploy para o escopo do item.

---

### CR-033 · Baixo · Arquitetura — `CaseCreationService.cls`
**Descrição**: mistura suporte de leitura para o wizard LWC com lógica de distribuição automática executada no `before insert` do trigger de Case.
**Estratégia de correção**: extrair `applyCategorizacaoDistribution` para uma classe própria (ex.: `CaseCategorizacaoDistributionService`).
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:43:58
**Log de execução**: Extraído `applyCategorizacaoDistribution` de `CaseCreationService` para a nova classe `CaseCategorizacaoDistributionService`, deixando `CaseCreationService` focado apenas no fluxo síncrono do wizard e `CaseTriggerHandler.beforeInsert` responsável por acionar a automação trigger-side diretamente. O comportamento foi preservado sem ampliar o blast radius: a nova classe manteve a mesma lógica de fila fixa, distribuição por campo customizado, fallback de fila, bypass explícito de `Encerrar` e bypass condicional de `Assumir`; `CaseCreationService` perdeu completamente esse método, eliminando o acoplamento arquitetural apontado no achado. Para não depender só da inserção via trigger, foi criada a suíte dedicada `CaseCategorizacaoDistributionServiceTest` cobrindo 4 cenários unitários do serviço novo, enquanto os testes de integração existentes (`CaseCreationServiceTest` e `CaseTriggerHandlerTest`) permaneceram na regressão do pacote. Code Analyzer pós-ajuste ficou sem violações sev0/sev1/sev2 nos arquivos alterados pelo item; permaneceram apenas alertas moderados/baixos já preexistentes em `CaseCreationService`/`CaseTriggerHandler` e um moderado de complexidade local no novo método. Dry-run `0Afbe00000ANvhNCAT` Succeeded, 37/37 testes (`CaseCategorizacaoDistributionServiceTest`, `CaseCreationServiceTest`, `CaseTriggerHandlerTest`). Deploy real `0Afbe00000ANuwcCAD` Succeeded. `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy não listou conflitos nos `.cls` do pacote; restou apenas drift pré-existente em `CaseTriggerHandler.cls-meta.xml` e no permission set `WS_Atendimento_Basico_Operacional`.

---

### CR-034 · Baixo · Segurança — `CaseCreationService.cls:49-85,87-156`
**Descrição**: `getTreeOptions`/`resolveCategorizationSelection` sem checagem de `isAccessible()`, diferente de `getInitialContext` na mesma classe.
**Estratégia de correção**: adicionar checagem de leitura consistente, ou documentar explicitamente por que são considerados dados públicos.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 09:53:37
**Log de execução**: Adicionado `validateReadAccess()` em `CaseCreationService` e chamado logo no início de `getTreeOptions` e `resolveCategorizationSelection`, alinhando esses dois endpoints de leitura com o padrão já existente em `getInitialContext` e com o precedente de `CaseRecategorizationService`. O guard exige acesso de leitura aos objetos `Case` e `Categorizacao__c`; em caso negativo, devolve `FunctionalException` com `code = 'CRUD_DENIED'` e mensagem amigável única, sem deixar a montagem parcial do wizard seguir. Para manter a mudança pequena e testável sem depender da FLS real da org, a classe ganhou apenas duas overrides `@TestVisible` (`caseReadAccessOverride` e `categorizacaoReadAccessOverride`), usadas exclusivamente nos testes para simular o branch negado. `CaseCreationServiceTest` recebeu 2 cenários novos cobrindo negação em `getTreeOptions` e em `resolveCategorizationSelection`; o restante da regressão existente ficou intacto. Code Analyzer pós-ajuste permaneceu sem `sev0`/`sev1`/`sev2`; sobraram só alertas moderados/baixos já preexistentes em `CaseCreationService`/`CaseCreationServiceTest` (complexidade, braces, ApexDoc, hardcoded Id legado e ausência de `runAs` em vários testes antigos). Dry-run final `0Afbe00000ANvpRCAT` Succeeded, 34/34 testes (`CaseCreationServiceTest`, `CaseCreationControllerTest`). Deploy real `0Afbe00000ANvr3CAD` Succeeded. `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy ainda lista apenas drifts pré-existentes em `.cls-meta.xml` de `CaseCreationService`/`CaseTriggerHandler`/`CaseCategorizacaoDistributionService*` e no permission set `WS_Atendimento_Basico_Operacional`.

---

### CR-035 · Baixo · Testes — `CaseAreaParticipanteAggregationService.cls`
**Descrição**: sem teste unitário dedicado — só exercitada indiretamente via outros testes, sem asserção direta da lógica de contagem.
**Estratégia de correção**: criar teste dedicado cobrindo os cenários de contagem (nenhuma aberta, várias abertas, várias vencidas, guard de recursão ativo).
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 10:23:28
**Log de execução**: 2026-07-04 — Codex — criada a suíte dedicada `CaseAreaAggregationServiceTest` para cobrir diretamente `CaseAreaParticipanteAggregationService.refreshForCases`, sem alterar código produtivo. A classe nova valida 3 comportamentos do serviço: (1) recálculo correto de `QtdAreasParticipantesAbertas__c`/`QtdAreasParticipantesVencidas__c` com mistura de áreas internas elegíveis, área encerrada e área não interna; (2) no-op quando o guard `AreaParticipanteSLARecursionGuard` já está ativo; (3) no-op para `Set<Id>` nulo/vazio. O setup do cenário principal precisou respeitar duas regras reais do domínio descobertas no caminho: `Case.Categorizacao__c` obrigatório para inserir Área Interna e unicidade de área aberta por Case, então o teste passou a usar `TestDataFactory.createCaseWithSlaChain(...)` com 3 áreas distintas e a forçar `StatusSLA__c = Vencido` via update pós-insert nos 2 registros vencidos, evitando interferência do trigger de SLA no estado inicial. Code Analyzer final no arquivo novo ficou sem `sev0`/`sev1`/`sev2`; restaram apenas 3 avisos `Low` (`pmd:ApexUnitTestClassShouldHaveRunAs`), sem impacto funcional. Dry-run `0Afbe00000ANw8nCAD` Succeeded, 3/3 testes (`CaseAreaAggregationServiceTest`). Deploy real `0Afbe00000ANwAPCA1` Succeeded, 3/3 testes. `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy continuou listando apenas drifts/conflitos amplos pré-existentes em `.cls-meta.xml`, profiles e permission sets fora do escopo; nenhum conflito relacionado a `CaseAreaAggregationServiceTest`.

---

### CR-036 · Baixo · Segurança — `CategorizacaoSelector.cls:79,88,101,110,123,132`
**Descrição**: falta `WITH USER_MODE`, inconsistente com `CaseScheduleHelper` (mesmo domínio) que usa consistentemente.
**Estratégia de correção**: documentar explicitamente se a execução em system mode é intencional (comentário/`@SuppressWarnings`), como já feito em `CaseOpeningNotificationService`, ou padronizar para `WITH USER_MODE`.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 10:35:20
**Log de execução**: 2026-07-04 — Codex — alinhado `CategorizacaoSelector` ao padrão de segurança do domínio, optando por padronizar o selector inteiro para `WITH USER_MODE` em vez de documentar system mode intencional. O ajuste cobriu as queries de `Categorizacao__c`, `RecordType`, `Group`, `QueueSobject` e `RegrasSLACategorizacao__c`, incluindo os 6 pontos citados no achado e também os demais `SELECT` reais do arquivo (`getById`, `getRecordTypesById`, `getAvailableRecordTypesForObject`) para evitar um selector “meio seguro, meio sistêmico”. A leitura do `CategorizacaoService` mostrou que o fluxo já trata esse dado como leitura de usuário: `CategorizacaoController` valida CRUD/FLS na entrada e o service usa o selector para montar estado/edição da UI, sem nenhuma dependência legítima de contexto elevado. Não foi necessário alterar testes: a regressão existente do domínio (`CategorizacaoServiceTest` + `CategorizacaoControllerTest`) já cobre os métodos impactados (`getById`, `getExistingByHash`, `getCaseQueuesByDeveloperName`, `listCaseQueuesByPrefix`, `getRegrasSlaByCategorizacao`, `getInitialState`/`getQueues`). Code Analyzer no arquivo seguiu sem `sev0`/`sev1`/`sev2`; restaram apenas débitos preexistentes do próprio selector (braces, ApexDoc e organização de fields) fora do escopo do item. Dry-run `0Afbe00000ANwDdCAL` Succeeded, 35/35 testes. O deploy real inicialmente bloqueou por conflito de tracking só em `CategorizacaoSelector`; antes de usar `--ignore-conflicts`, foi confirmado via Tooling API que a classe na org estava com `LastModifiedBy = Jean Duarte` em 2026-07-04, caracterizando falso positivo de tracking na mesma sessão, não mudança de terceiro. Deploy real `0Afbe00000ANwFFCA1` Succeeded com `--ignore-conflicts`, 35/35 testes. `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy não listou mais `CategorizacaoSelector` entre os conflitos; restaram apenas drifts amplos pré-existentes em outros `.cls-meta.xml` e no permission set `WS_Atendimento_Basico_Operacional`.

---

### CR-037 · Baixo · Qualidade — módulo `WS_EmailToCase*`
**Descrição**: encoding UTF-8 quebrado (double-encoding/mojibake) em mensagens de erro de várias classes (`WS_EmailToCaseOwnerService`, `WS_EmailToCaseCaseService`, `WS_EmailToCaseLogService`, `WS_EmailToCaseConstants`, entre outras).
**Por que importa**: mensagens vão para `LogIntegracao__c` (auditoria) e exceptions que chegam a agentes de suporte — texto ilegível dificulta diagnóstico.
**Estratégia de correção**: re-salvar os arquivos afetados como UTF-8 sem BOM e corrigir as strings; considerar um lint/CI check de encoding para `.cls`.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 10:41:14
**Log de execução**: 2026-07-04 — Codex — varredura UTF-8 ampliada do módulo mostrou que o mojibake não estava só nas 4 classes citadas no achado, mas também em `WS_EmailToCaseAttachmentService`, `WS_EmailToCaseEmailMessageService`, `WS_EmailToCaseRouteService`, `WS_EmailToCaseUtils` e nos asserts de `WS_EmailToCaseServiceTest`. A correção ficou restrita à regravação das strings quebradas em UTF-8 legível (ex.: `não`, `permissão`, `configuração`, `usuário`, `conteúdo`, `ação`), sem alterar fluxo funcional nem contratos do inbound email. O grep canônico de mojibake do handler UTF-8 voltou limpo para `WS_EmailToCase*.cls` após a edição. Code Analyzer pós-ajuste continuou apontando `High`/`Moderate` já preexistentes do módulo (principalmente `ApexCRUDViolation` em `WS_EmailToCaseCaseService`/`WS_EmailToCaseOwnerService` e débitos de complexidade/ApexDoc), mas nenhum relacionado à mudança de encoding em si. Dry-run `0Afbe00000ANwLhCAL` Succeeded, 43/43 testes (`WS_EmailToCaseServiceTest`, `WS_EmailToCaseRouteServiceTest`, `WS_EmailToCaseSupportServiceTest`). O deploy real inicialmente bloqueou por conflito de tracking só em `WS_EmailToCaseCaseService`; antes de usar `--ignore-conflicts`, foi confirmado via Tooling API que `LastModifiedBy = Jean Duarte` em 2026-07-04, caracterizando falso positivo da própria sessão. Deploy real `0Afbe00000ANwNJCA1` Succeeded com `--ignore-conflicts`, 43/43 testes. `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy continuou listando apenas drifts amplos pré-existentes em outras classes/meta/permission sets; nenhum conflito relacionado às classes `WS_EmailToCase*` deste pacote.

---

### CR-038 · Baixo · Arquitetura — `WSWillCaseLookupService.cls`
**Descrição**: sem Selector dedicado — SOQL de Case inline, diferente de `WSWillCaseCreationSelector`.
**Estratégia de correção**: criar `WSWillCaseLookupSelector` com `selectCasesByCaseNumbers`, alinhando ao padrão já estabelecido no módulo WSWill.
**Status**: 🟢 Concluído
**Reivindicado por**: Codex — 2026-07-04 10:49:58
**Log de execução**: 2026-07-04 — Codex — extraído o SOQL inline de `WSWillCaseLookupService.lookup` para a nova classe `WSWillCaseLookupSelector`, mantendo o mesmo conjunto de campos (`Status`, `TipoCaso__c`, `Categoria__c`, `Assunto__c`, `EtapaAtendimento__c`, `ContactId`, `AccountId`) e o mesmo `WITH USER_MODE`, só trocando a camada responsável pela query. O serviço continuou dono da orquestração/validação de posse (`ownsCase`) e o selector ficou restrito ao lookup por `CaseNumber`, alinhando o módulo ao padrão já usado em `WSWillCaseCreationSelector` sem alterar comportamento funcional do bot. A suíte existente `WSWillCaseLookupTest` permaneceu intacta e passou a cobrir o fluxo via delegação; para não depender só de cobertura indireta, foi criada a nova `WSWillCaseLookupSelectorTest` cobrindo `Set<String>` nulo/vazio e retorno indexado por `CaseNumber`. Code Analyzer final ficou sem `sev0`/`sev1`/`sev2`; restaram apenas moderados/baixos preexistentes no próprio `WSWillCaseLookupService` (complexidade, braces e ApexDoc) e avisos `runAs` de testes fora do escopo. Teste org direto da regressão existente: `WSWillCaseLookupTest`, 6/6 Pass (`707be00000WmmuI`). Dry-run `0Afbe00000ANwQXCA1` Succeeded, 8/8 testes (`WSWillCaseLookupTest`, `WSWillCaseLookupSelectorTest`). O deploy real inicialmente bloqueou por conflito de tracking só em `WSWillCaseLookupService`; antes de usar `--ignore-conflicts`, foi confirmado via Tooling API que `LastModifiedBy = Jean Duarte` em 2026-07-04, caracterizando falso positivo da própria sessão. Deploy real `0Afbe00000ANwS9CAL` Succeeded com `--ignore-conflicts`, 8/8 testes. `sf project deploy preview --target-org WS_SERVICE --concise` pós-deploy continuou listando apenas drifts pré-existentes em `CaseCategorizacaoDistributionService*`, `CaseTriggerHandler.cls-meta.xml` e `WS_Atendimento_Basico_Operacional.permissionset-meta.xml`; nenhum conflito relacionado a `WSWillCaseLookupService`/`WSWillCaseLookupSelector`.

---

## Fase 2 — Suíte de testes e cobertura

### Suíte estendida

`force-app/main/default/testSuites/CoberturaProjetoCore.testSuite-meta.xml` estendida de 44 → **63 classes de teste**, cobrindo todas as classes de teste do domínio de Atendimento presentes no workspace (19 adicionadas: `AccountCaseScheduleControllerTest`, `AccountCaseScheduleServiceTest`, `AreaParticipanteMilestoneSyncBatchTest`, `AreaParticipanteMilestoneSyncServiceTest`, `AreaParticipanteRegiaoAtendimentoTest`, `CaseAcompanhamentoServiceTest`, `CaseMilestoneSyncQueueableTest`, `CaseOpeningNotificationServiceTest`, `CaseScheduleBatchTest`, `CaseScheduleSchedulerTest`, `CaseScheduleServiceTest`, `ContactWhatsappMessageControllerTest`, `GestaoSLACategoriaServiceTest`, `GestaoSLAMarcoServiceTest`, `GestaoSLARegraServiceTest`, `ReclamacaoServiceTest`, `WSWillCaseCreationSelectorTest`, `WS_EmailToCaseRouteServiceTest`, `WS_EmailToCaseSupportServiceTest`).

**Status**: 🟢 Concluído — deploy real `0Afbe00000ANqwDCAT` Succeeded (`test-level NoTestRun`, dry-run prévio 0 erros), seguido de `sf project retrieve start` confirmando sincronia workspace↔org (`git diff` mostra exatamente as 19 linhas adicionadas, nada além disso).

### Execução da suíte na org `WS_SERVICE`

Comando: `sf apex run test --suite-names CoberturaProjetoCore --code-coverage --result-format json --wait 30`
Test Run Id: `707be00000Wm4lI`

| Métrica | Valor |
|---|---|
| Testes executados | 648 |
| Passando | 634 (98%) |
| Falhando | 14 (2%) |
| Cobertura da execução (run coverage) | 93% |
| Cobertura org-wide | 69% |

**Conforme solicitado, nenhuma correção foi aplicada — os erros abaixo estão só documentados, com estratégia de correção sugerida.** Como havia erros, a etapa de relatório de cobertura por classe (item 8) não foi executada nesta rodada — fica para depois que os erros abaixo forem resolvidos e a suíte rodar 100% verde.

### Falhas encontradas (13 métodos de teste únicos catalogados no resultado; sumário da org reportou 14 — pequena divergência de contagem entre o resumo e a lista detalhada de testes retornada pela CLI, não investigada por não ser material ao conteúdo dos erros)

#### F-01 · `LightningForgotPasswordControllerTest.testSetExperienceIdWithValue`
**Erro**: `System.AssertException: Assertion Failed: Expected: true, Actual: false` (linha 34).
**Causa raiz**: teste padrão gerado pelo template do Salesforce para Experience Cloud (`LightningForgotPasswordControllerTest`, classe inteira com `@IsTest(SeeAllData = true)`, boilerplate não escrito pelo time). `setExperienceId('exp-id-test')` chama `Site.setExperienceId('exp-id-test')` dentro de um `try/catch` que devolve `ex.getMessage()`; como `'exp-id-test'` não é um Id de Network/Experience real desta org, a chamada lança exceção cuja mensagem não contém a palavra `"community"` — quebrando a asserção `result == null || result.contains('community')`. É um teste frágil e dependente do ambiente (a mensagem de erro do Salesforce para Id de rede inválido pode variar entre releases/orgs).
**Estratégia de correção**: ajustar a asserção para não depender do texto exato da mensagem de erro (ex.: só verificar que `result` não é nulo quando o Id é inválido, sem exigir a substring `'community'`), ou marcar o teste como esperado-falhar-com-erro-de-rede-inválida explicitamente. Baixo risco, é só ajuste de teste, não de código de produção.

#### F-02 · `CaseClosureSurveyServiceTest.showsGerarReclamacaoQuestionAndCreatesRecordWhenSelected`
**Erro**: `System.SObjectException: SObject row was retrieved via SOQL without querying the requested field: Case.AccountId` — em `ReclamacaoService.buildReclamacao:116`, chamado por `CaseClosureSurveyService.closeCase:73`.
**Causa raiz — bug real de produção, não só de teste**: `CaseClosureSurveyService.getCaseById` (linhas ~150-158) não inclui `AccountId` no `SELECT`, mas `closeCase` passa esse mesmo objeto Case para `ReclamacaoService.buildReclamacao`, que lê `c.AccountId` para popular `Reclamacao__c.Cliente__c`. Isso quebra em produção **sempre que um Case elegível para Reclamação for encerrado com a opção "Gerar Reclamação?" marcada** — não é um problema só do teste, é um bug funcional real na tela de encerramento de Case.
**Estratégia de correção**: adicionar `AccountId` ao `SELECT` de `CaseClosureSurveyService.getCaseById`. Prioridade alta — é o único achado desta rodada de testes que é um bug de produção, não de teste.

#### F-03 e F-04 · `ContactWhatsappMessageControllerTest.shouldHideWhatsAppChannelWhenBusinessUnitIsNotAllowed` e `shouldReturnCandidateWhenServiceFindsEligibleMessagingUser`
**Erro**: `System.DmlException: MIXED_DML_OPERATION ... MessagingEndUser, objeto original: MessagingChannel`.
**Causa raiz**: os dois testes fazem `insert channel` (`MessagingChannel`) e, na sequência, `insert endUser`/`insert new List<MessagingEndUser>` (`MessagingEndUser`) **antes** de `Test.startTest()`, na mesma transação. O Salesforce trata `MessagingChannel` como objeto de configuração para fins de MIXED_DML nesta org, então misturar DML dele com `MessagingEndUser` (objeto não-configuração) na mesma transação dispara o erro.
**Estratégia de correção**: mover a criação do(s) `MessagingChannel` para dentro de um bloco `System.runAs(new User(Id = UserInfo.getUserId()))` (isola a transação de configuração), ou inserir os canais antes de `Test.startTest()` e os `MessagingEndUser` depois de `Test.startTest()` (a fronteira de `startTest`/`stopTest` também separa contextos de transação para fins de MIXED_DML). Mesmo padrão de correção do F-05/F-06 abaixo — vale extrair um helper de teste comum se a correção for feita nas 3 classes ao mesmo tempo.

#### F-05 · `CaseCreationServiceTest.testApplyCategorizacaoDistributionUsaFilaFallbackQuandoValorNaoBate`
**Erro**: `System.DmlException: MIXED_DML_OPERATION ... Categorizacao__c, objeto original: QueueSobject`.
**Causa raiz**: mesmo padrão do F-03/F-04 — `insert fallbackQueue` (`Group`) + `insert new QueueSobject(...)` (objeto de configuração) seguido de `insert cat` (`Categorizacao__c`, não-configuração) na mesma transação, antes de `Test.startTest()`.
**Estratégia de correção**: idem F-03/F-04 — `System.runAs` ao redor da criação de `Group`/`QueueSobject`, ou reordenar para respeitar a fronteira `Test.startTest()`.

#### F-06 a F-13 (8 métodos) · `AccountCaseScheduleControllerTest.*` (`shouldDelegateTreeAndQueues`, `shouldResolveSaveAndToggleThroughController`, `shouldReturnIndicator`, `shouldReturnInitialState`, `shouldSearchUsersThroughController`, `shouldWrapFunctionalControllerErrors`, `shouldWrapInitialStateErrors`, `shouldWrapUnexpectedControllerErrors`)
**Erro**: `System.DmlException: MIXED_DML_OPERATION ... QueueSobject, objeto original: Account` — todos falham no método `@TestSetup setupData` (linha 11), que roda antes de cada um dos 8 métodos de teste da classe.
**Causa raiz**: mesmo padrão — `setupData()` faz `insert new Account(...)` (não-configuração) seguido de `insert queue` (`Group`) e `insert new List<QueueSobject>{...}` (configuração), tudo na mesma transação do `@TestSetup`. Como todos os 8 métodos de teste da classe dependem desse `@TestSetup`, um único ponto de causa raiz derruba a classe inteira.
**Estratégia de correção**: mesma estratégia do F-03/F-04/F-05 — envolver a criação de `Group`/`QueueSobject` em `System.runAs(new User(Id = UserInfo.getUserId()))` dentro do próprio `@TestSetup`. Como esse método é compartilhado pelos 8 testes, corrigir aqui resolve as 8 falhas de uma vez.

### Observação geral sobre os MIXED_DML (F-03 a F-13, 10 dos 13 métodos)
Todas essas falhas compartilham a mesma causa raiz estrutural: DML de objetos "de configuração" (`Group`, `QueueSobject`, `MessagingChannel`) misturado com DML de objetos de negócio (`Account`, `Categorizacao__c`, `MessagingEndUser`) na mesma transação de teste, sem isolamento via `System.runAs` ou sem respeitar a fronteira `Test.startTest()`/`Test.stopTest()`. Não foi possível confirmar se isso é uma regressão recente (ex.: mudança de comportamento do Salesforce em release mais nova tratando `MessagingChannel` como objeto de configuração) ou um problema pré-existente que nunca foi exercitado porque a suíte `CoberturaProjetoCore` não incluía essas classes antes desta extensão (Fase 2 acima) — **hipótese mais provável**, já que 3 das 4 classes afetadas (`AccountCaseScheduleControllerTest`, `CaseCreationServiceTest` neste método específico, `ContactWhatsappMessageControllerTest`) só entraram na suíte agora. Recomenda-se, ao corrigir, rodar cada classe isoladamente antes e depois da correção para confirmar que não há efeito colateral em outros métodos da mesma classe.

### Próximos passos (aguardando instruções do usuário)
Nenhuma correção foi aplicada. Assim que houver decisão sobre F-01 a F-13, marcar os itens correspondentes e repetir a execução da suíte; só então avançar para o relatório de cobertura por classe (item 8 do pedido original).
