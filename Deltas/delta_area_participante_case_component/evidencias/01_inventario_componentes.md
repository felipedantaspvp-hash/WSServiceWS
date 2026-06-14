# Evidência 01 — Inventário de Componentes de Área Participante

**Data:** 2026-06-14

## Busca realizada

Padrões pesquisados:

- `areaParticipante` / `AreaParticipante`
- `caseAreaParticipante`
- `participante`
- `addParticipation` / `closeParticipation` / `getPanelData` / `getParticipationDetails`
- `AreaParticipanteController`

## LWC encontrados

| Componente | Caminho | Relacionado? |
|------------|---------|--------------|
| `gestaoSLAWorkspace` | `force-app/main/default/lwc/gestaoSLAWorkspace/` | Não — workspace administrativo de GestaoSLA/Categorização/Regras |

Nenhum LWC de Case ou de Área Participante encontrado.

## Aura encontrados

| Componente | Relacionado? |
|------------|--------------|
| `caseNewOverrideWrapper` | Não |
| `wsCaseNewOverride` | Não |
| `categorizacaoManagerOverride` | Não |
| `categorizacaoViewOverride` | Não |
| `loginForm`, `selfRegister`, `forgotPassword` | Não |

## Apex existente relacionado (backend reutilizado)

| Classe | Responsabilidade |
|--------|-----------------|
| `AreaParticipanteController` | Controller com 4 métodos @AuraEnabled |
| `AreaParticipanteService` | Regra de negócio: carregamento, acionamento, conclusão |
| `AreaParticipanteDTO` | DTOs: PanelDTO, AreaItemDTO, AddRequestDTO, CloseRequestDTO, etc. |
| `AreaParticipanteSelector` | SOQL: busca de Case, áreas do Case, regras elegíveis |
| `AreaParticipanteHelper` | Helpers: normalização, cálculo de percentual, status |

## Decisão

**Componente novo criado:** `caseAreaParticipantePanel`

Justificativa: backend completo disponível; nenhum componente visual reutilizável encontrado para o contexto de Case.
