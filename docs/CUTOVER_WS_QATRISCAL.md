# Cutover de Deploy — WS_QATRISCAL

> Documento de trabalho para o cutover de deploy (via Flosum) da branch B-5077 para a sandbox **WS_QATRISCAL**, org de testes de usuário (UAT).
> Mantenha este arquivo atualizado conforme o cutover avança — é o registro oficial de atividades pré/pós-deploy.

## Contexto

- **Org de destino:** WS_QATRISCAL — refresh feito a partir da **produção real** (não da WILSON_SERVICE), para reproduzir o cenário mais próximo possível do que será encontrado no go-live.
- **Implicação principal:** como a produção real não tem a feature de Atendimento (Categorização/SLA) ainda em uso, é muito provável que **WS_QATRISCAL não tenha nenhum dado de `Categorizacao__c`/`RegrasSLACategorizacao__c`/`GestaoSLA__c`** das 4 unidades (Centro Logístico, Rebocadores, Rio Grande, Tecon Salvador), mesmo depois do deploy de metadados. Metadado (schema) e dado (registros) são coisas separadas — o deploy cria o objeto vazio, não popula linhas.
- **Mecanismo de deploy:** Flosum, branch B-5077 (`a0BbJ00000ImorNUAR`), repositório "Wilson Sons".
- **Status:** 🔲 Não iniciado

## Sumário de atividades

| Fase | Responsável | Status |
|---|---|---|
| Pré-deploy | — | 🔲 Pendente |
| Deploy (Flosum) | Usuário (via Flosum) | 🔲 Pendente |
| Validação pós-deploy (diff source vs org) | Claude | 🔲 Pendente |
| Pós-deploy — dados | — | 🔲 Pendente |

---

## 1. Atividades PRÉ-deploy

### 1.1 Congelamento / comunicação
- [ ] Confirmar que nenhum outro trabalho está em andamento na WS_QATRISCAL que possa colidir com o deploy (checar se há outro consumidor da sandbox).
- [ ] Definir e comunicar a janela do cutover (data/hora de início e fim esperado).

### 1.2 Preparar a exportação dos dados de Categorização (fonte: WILSON_SERVICE)
Como só existe script de carga pronto para **Rio Grande** (`scripts/apex/carga_categorizacao_rio_grande_parte1.apex` + `parte2.apex`), e ele tem um **Id hardcoded específico da WILSON_SERVICE** (`gestaoSlaId = 'a3Nbe000000Q1BlEAK'`) que não existirá na WS_QATRISCAL, a estratégia recomendada é:

- [ ] **Exportar** de WILSON_SERVICE (fonte de verdade atual) os registros de:
  - `GestaoSLA__c` (4 unidades)
  - `Categorizacao__c` (todas as unidades)
  - `RegrasSLACategorizacao__c` (todas as unidades)
  - `MarcoSLA__c` (se aplicável)
  - via `sf data export` / Data Loader, preservando as chaves naturais (`UnidadeNegocios__c`, `TipoCaso__c`, `Categoria__c`, `Assunto__c`, `Subassunto__c`) para permitir religar relacionamentos por lookup em vez de por Id fixo.
- [ ] Confirmar contagem esperada por unidade antes de exportar (ex: Rio Grande = 273 `Categorizacao__c` + 1.127 `RegrasSLACategorizacao__c`, conforme carga mais recente).
- [ ] Guardar os CSVs exportados numa pasta versionada (sugestão: `Deltas/delta_cutover_qatriscal/dados_categorizacao/`).

### 1.3 Validar manifest/branch no Flosum
- [ ] Confirmar no Flosum que a branch B-5077 reflete o estado atual do `force-app` (rodar um novo Org Sync se necessário — ver histórico de gaps discutido nesta sessão).
- [ ] Revisar a lista de componentes da branch por tipo, comparando com a tabela de gap já levantada (CustomField/CustomLabel/WebLink/ReportType legados de CRM podem ser deixados de fora do cutover de Atendimento).

### 1.4 Itens com trava de plataforma conhecidos (não vão via deploy padrão)
Baseado no que encontramos na WS_PKG5 — confirmar se aplicam também à WS_QATRISCAL antes do deploy:
- [ ] **Ativar a licença/feature de Einstein Bots na WS_QATRISCAL antes do deploy.** Confirmado no deploy `0Af8800000PAHdt` (05/07/2026): Bot `Will_Smoke` falhou com "Not available for deploy for this organization", mesma trava vista na WS_PKG5. Sem isso habilitado previamente, o Bot (e os Flows `Route_to_Will_Smoke`/`Route_to_Will_Rebind` que dependem dele) não entram no deploy.
- [ ] **Ativar Email Deliverability (Setup → Email → Deliverability → "All Email").** Confirmado no deploy `0Af8800000PAHdt`: `QuickAction Case.WS_Email` falhou com "Send Email is disabled or activities are not allowed", quebrando em cascata os Layouts `Case-Case Layout Logística`/`Rebocadores`. Sandboxes costumam vir com Deliverability em "No Access"/"System Email Only" por padrão — precisa estar em "All Email" antes do deploy para a QuickAction de envio de e-mail ser aceita.
- [ ] **Habilitar FLS (readable/editable) do campo standard `IsStopped` de `Case` para o profile Admin.** Achado durante a análise de testes falhos (deploy `0Af8800000PAjbmCAD`, WS_QATRISCAL): `System.QueryException: No such column 'IsStopped' on entity 'Case'` — o campo standard existe no objeto, mas não está acessível para o profile Admin, o que faz o SOQL falhar como se a coluna não existisse. Verificar/ativar antes do deploy via Setup → Profiles → Admin → Field-Level Security → Case → `IsStopped` (Read + Edit).
- [ ] `PresenceUserConfig` (`default_presence_config`) — geralmente read-only, criado automaticamente pela plataforma.
- [ ] `ServiceChannel` "Case" — pode precisar ser criado manualmente via Setup (Omni-Channel) se não existir ainda, escolhendo o Capacity Model antes de tentar o deploy.
- [x] **Desativar manualmente Flows/Process Builders ativos legados do Case antes de excluí-los.** A Salesforce não permite excluir uma versão de Flow ativa via API/deploy (nenhum caminho de CLI/Metadata API contorna isso — é preciso usar o botão "Deactivate" em Setup → Flows). Achado durante a limpeza de campos legados do Case na QATRISCAL: `Case_Atualiza_Record_Type_Rebocadores` precisou ser desativado manualmente antes da exclusão. **Para o cutover real:** mapear e desativar previamente qualquer Flow/Process Builder ativo que referencie campos do Case que serão excluídos, para não travar o processo no meio.

### 1.5 Limpeza de campos legados do Case (herdados da produção)
A WS_QATRISCAL foi refreshada da produção real, então o objeto Case veio com ~156 campos customizados legados (sync de Zendesk, categorias antigas de atendimento por telefone/totem, etc.) que não fazem parte do novo modelo de Atendimento. Antes do deploy da branch B-5077, esses candidatos a exclusão precisam ser tratados (ver lista completa gerada durante a sessão, comparando `force-app/main/default/objects/Case/fields` local vs describe da org):
- [x] Identificar os campos "só existem na org" (não fazem parte do `force-app`) — 153 campos mapeados.
- [x] Excluir dependências que bloqueavam a exclusão dos campos:
  - [x] FlexiPage legada `Case_Record_Page1` (~116 campos dependiam dela)
  - [x] SharingCriteriaRule `Rebocadores`/`Tecon_Rio_Grande`/`Tecon_Salvador` (referenciavam `Unidade_Negocio__c`)
  - [x] Process Builder `Case_da_Conta` (referenciava `Raiz_CNPJ__c`/`Codigo_SAP__c`)
  - [x] Flow `Case_Atualiza_Record_Type_Rebocadores` + 4 versões antigas (referenciava campos `Zendesk_Support_Ticket_*`)
  - [x] Assignment Rule "Default Assignment" (inativa, mas ainda referenciava `Zendesk_Support_Ticket_Form_Name__c` — `ruleEntry` removida)
- [x] Excluir os 153 campos customizados legados do Case (destructiveChanges) — deploy `0Af8800000PALPmCAP` Succeeded, 153/153, 0 erros.
- [ ] Excluir Lightning Pages (LP) legadas do Case (além da `Case_Record_Page1`, já removida — verificar se há outras).
- [ ] Excluir Layout Page (Page Layout) legado do Case não usado no novo modelo de Atendimento.
- [ ] Excluir Case Close Layouts legados (Close Case Layouts) não usados.
- [ ] Excluir Buttons, Links and Actions (WebLinks/QuickActions) legados do Case não usados no novo modelo.
- [ ] Excluir SharingRules de Case (as 3 `SharingCriteriaRule` que bloqueavam os campos já foram removidas — revisar se sobra alguma outra regra legada de produção, ex: `sharingOwnerRules` "Logistica", e excluir as que não fazem parte do novo modelo de Atendimento).
- [ ] Excluir Workflow Rules de Case legados (herdados da produção, não fazem parte do novo modelo de Atendimento).
- [ ] Excluir RecordTypes de Case legados (herdados da produção, não fazem parte do novo modelo de Atendimento — ver `Default`, `Logistica`, `Zendesk_Ticket_Sync`, etc. encontrados no retrieve da sessão).
- [ ] Excluir demais Campos de Case legados que ainda restarem (revisar se surgiram novos campos "só na org" após as exclusões já feitas, repetindo o comparativo `force-app` vs describe).
- [ ] Repetir esse levantamento/limpeza para os demais objetos padrão relevantes (Contact, Account) se aplicável — não fizemos essa varredura ainda para eles.
- [ ] `MessagingChannel` (WhatsApp/WebChat) — não é rastreado via metadata; se a QATRISCAL precisar de canais de mensageria funcionais para teste, configurar manualmente.
- [ ] Verificar se `Contact.Idioma__c` já existe como Picklist ou como Text na WS_QATRISCAL (mesmo problema de conversão de tipo que tivemos na PKG5) — se for Text, planejar rename para `Idioma_Old__c` antes do deploy, como fizemos na PKG5.

---

## 2. Deploy (via Flosum)

- [ ] Usuário executa o deploy da branch B-5077 para WS_QATRISCAL via Flosum.
- [ ] Registrar aqui o ID do deploy resultante e o horário de conclusão.

| Deploy ID | Horário | Status | Observações |
|---|---|---|---|
| _(preencher)_ | | | |

---

## 3. Validação pós-deploy — diff source vs org

- [ ] Claude roda comparação entre o `force-app` local e o estado real da WS_QATRISCAL (retrieve completo + `sf project deploy preview`, ou manifest comparativo) para confirmar 0 divergências reais.
- [ ] Documentar aqui qualquer diferença encontrada e sua causa (drift esperado de org vs bug real).

---

## 4. Atividades PÓS-deploy — dados

### 4.0 Ajustes manuais de metadado
- [ ] Excluir o Record Type `Default` de `Case` após o deploy, via Setup, para manter apenas os Record Types do novo modelo de Atendimento na WS_QATRISCAL.

### 4.1 Carga de Categorização (todas as 4 unidades)
- [ ] Importar `GestaoSLA__c` primeiro (pai).
- [ ] Importar `Categorizacao__c` (religando `GestaoSLA__c` por relacionamento, não por Id fixo).
- [ ] Importar `RegrasSLACategorizacao__c` (religando `Categorizacao__c` por relacionamento).
- [ ] Importar `MarcoSLA__c` se aplicável.
- [ ] Validar contagem pós-carga por unidade (comparar com o export da seção 1.2).

### 4.2 Backfills obrigatórios (idempotentes, seguros para rodar em qualquer org)
Executar nesta ordem após a carga de Categorização, via Apex anônimo:

1. [ ] `scripts/apex/backfill_permite_assumir_fila.apex` — preenche `PermiteAssumirComFilaParametrizada__c` (default "Sim") nos registros sem valor.
2. [ ] `scripts/apex/backfill_etapa_atendimento_distribuicao.apex` — preenche `EtapaAtendimentoDistribuicao__c` (obrigatório quando `DistribuirParaFila__c='Sim'`).
3. [ ] `scripts/apex/recalc_categorizacao_hash.apex` — recalcula `ChaveNaturalHash__c` de todas as Categorizações ativas (garante consistência pós-carga via CSV, que não passa pelo trigger da mesma forma que um `update` direto).

### 4.3 Validações finais
- [ ] Rodar a suíte de testes Apex relevante (`CoberturaProjetoCore` ou equivalente) na WS_QATRISCAL.
- [ ] Smoke test manual: criar 1 Case por unidade de negócio e confirmar que a Categorização/SLA/roteamento funcionam ponta a ponta.
- [ ] Confirmar FLS do Admin profile e demais profiles relevantes para os objetos/campos novos.

---

## 5. Pendências / decisões abertas

_(preencher conforme surgirem durante o cutover)_
