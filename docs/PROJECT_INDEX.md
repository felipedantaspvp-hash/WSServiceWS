# PROJECT_INDEX.md — Índice técnico leve do projeto

> Não copie código inteiro neste arquivo.  
> Use apenas referências para orientar leitura seletiva e economizar tokens.

## Última atualização

- Data: 2026-06-13
- Responsável: Codex
- Observação: Incluído mapeamento do Entitlement Process `atendimento salvador_v2` e dependências de SLA recuperadas da org `WILSON_SERVICE`.

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

## ServiceAgents / Integrações

| Artefato | Caminho | API/Sistema | Named Credential | Custom Metadata |
|---|---|---|---|---|

## DTOs / Wrappers

| Artefato | Caminho | Uso |
|---|---|---|

## LWCs

| Componente | Caminho | Apex usado | Responsabilidade |
|---|---|---|---|

## Flows

| Flow | Caminho | Objeto | Tipo | Before/After | Observação |
|---|---|---|---|---|---|

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

## Layouts / FlexiPages

| Artefato | Caminho | Objeto | Ativação/uso |
|---|---|---|---|

## Permission Sets / Profiles

| Artefato | Caminho | Finalidade |
|---|---|---|

## Testes

| Classe de teste | Caminho | Cobre |
|---|---|---|

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
