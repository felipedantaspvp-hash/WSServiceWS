# Evidência 03 — Métodos Apex Consumidos

**Data:** 2026-06-14

## Controller: AreaParticipanteController

| Método | Assinatura | Cacheable | Import LWC |
|--------|-----------|-----------|------------|
| `getPanelData` | `getPanelData(Id caseId) : PanelDTO` | Não | `AreaParticipanteController.getPanelData` |
| `addParticipation` | `addParticipation(AddRequestDTO request) : AddResponseDTO` | Não | `AreaParticipanteController.addParticipation` |
| `closeParticipation` | `closeParticipation(CloseRequestDTO request) : CloseResponseDTO` | Não | `AreaParticipanteController.closeParticipation` |

`getParticipationDetails` disponível no Controller mas não consumido neste pacote (dados já disponíveis via `getPanelData`).

## DTOs utilizados

### PanelDTO (retorno de getPanelData)

| Campo | Tipo | Uso no LWC |
|-------|------|------------|
| `items` | `List<AreaItemDTO>` | Lista de participações |
| `canManage` | `Boolean` | Controla visibilidade do botão "Acionar" e "Concluir" |
| `areaOptions` | `List<PicklistOptionDTO>` | Opções do combobox de área |
| `totalAbertas` | `Integer` | Contador da barra de resumo |
| `totalVencidas` | `Integer` | Contador da barra de resumo |
| `totalConcluidas` | `Integer` | Contador da barra de resumo |

### AreaItemDTO (campos exibidos)

| Campo | Uso |
|-------|-----|
| `id` | key do for:each e data-id do botão Concluir |
| `areaLabel` | Nome da área no cabeçalho |
| `statusLabel` | Texto do badge de status |
| `statusBadgeClass` (computado no JS) | Classe CSS do badge |
| `containerClass` (computado no JS) | Classe da div container do item |
| `sequenciaAcionamento` | # exibido no canto direito |
| `violouSLA` | Badge de violação |
| `dataHoraInicio` | Campo Início |
| `dataHoraPrazo` | Campo Prazo |
| `dataHoraFim` | Campo Conclusão (condicional) |
| `tempoSLAMinutos` | Campo SLA (min) |
| `tempoRestanteMinutos` | Campo Restante (min) |
| `statusSLA` | Campo Status SLA |
| `nomeMarco` | Campo Regra SLA |
| `tempoTexto` | Campo Tempo |
| `percentualDecorrido` | Barra de progresso + % |
| `progressClass` | Cor da barra (ok/warning/overdue) |
| `progressStyle` (computado no JS) | `width: N%` inline |
| `hasPercent` (computado no JS) | Controla visibilidade da barra |
| `canClose` | Visibilidade do botão Concluir |

### AddRequestDTO (enviado em addParticipation)

| Campo | Valor |
|-------|-------|
| `caseId` | `this.recordId` (Case ID da página) |
| `area` | Valor selecionado no combobox |
| `comentarioSolicitacao` | Texto do campo obrigatório |

### CloseRequestDTO (enviado em closeParticipation)

| Campo | Valor |
|-------|-------|
| `areaParticipanteId` | `data-id` do item clicado |
| `comentarioRetorno` | Texto do campo obrigatório |
| `solucaoRetorno` | Texto do campo obrigatório |

## Confirmação: SLA calculado 100% no backend

O JS não contém nenhum cálculo de tempo, prazo, percentual ou violação.
Todos os campos derivados chegam prontos via DTO.
