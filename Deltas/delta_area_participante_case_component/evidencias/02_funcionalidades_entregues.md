# Evidência 02 — Funcionalidades Entregues

**Data:** 2026-06-14

## Componente: caseAreaParticipantePanel

### Carregamento

- Recebe `recordId` do Case via `@api recordId`
- Chama `getPanelData(caseId)` no `connectedCallback`
- Exibe spinner durante carregamento
- Exibe alerta SLDS em caso de erro
- Estado vazio com mensagem quando não há áreas registradas

### Listagem de Áreas Participantes

- Lista todas as `AreaParticipante__c` do Case via `items` do `PanelDTO`
- Barra de resumo: abertas / vencidas / concluídas
- Por item exibido:
  - Área de atendimento (label)
  - Badge de status com cor diferenciada (Aberta=azul, Vencida=vermelho, Concluída=verde, Cancelada=cinza)
  - Indicador de violação de SLA (badge vermelho)
  - Sequência de acionamento (#N)
  - Início, Prazo, Conclusão (datetime formatado)
  - SLA em minutos, Tempo restante, Status SLA
  - Regra SLA aplicada (nomeMarco)
  - Tempo textual
  - Barra de progresso (percentualDecorrido) com cor: verde/amarelo/vermelho
  - Borda lateral colorida por status (azul/vermelho/verde)

### Acionamento de Área Interna

- Botão "Acionar Área Interna" visível somente se `canManage = true`
- Modal com:
  - Combobox de área (populado com `areaOptions` do backend — apenas áreas elegíveis e não ocupadas)
  - Banner informativo se não houver áreas disponíveis
  - Campo obrigatório: Comentário de Solicitação
- Confirmação chama `addParticipation` com `caseId`, `area`, `comentarioSolicitacao`
- Toast de sucesso + refresh do painel após confirmação
- Toast de erro com mensagem funcional do backend

### Conclusão de Participação

- Botão "Concluir" visível por item quando `canClose = true` (aberta ou vencida, com permissão)
- Modal com:
  - Campo obrigatório: Comentário de Retorno
  - Campo obrigatório: Solução / Retorno da Área
- Confirmação chama `closeParticipation` com `areaParticipanteId`, `comentarioRetorno`, `solucaoRetorno`
- Toast de sucesso + refresh do painel após confirmação
- Toast de erro com mensagem funcional do backend

### Refresh Manual

- Botão de refresh (ícone utility:refresh) disponível sempre
- Recarrega `getPanelData` ao clicar

### Exibição de Status Visual

| Status | Borda | Badge | Fundo |
|--------|-------|-------|-------|
| Aberta | azul | azul | neutro |
| Vencida | vermelho | vermelho | rosa claro |
| Concluída | verde | verde | neutro (opacidade reduzida) |
| Cancelada | — | cinza | neutro |

### Responsividade

- Layout SLDS grid: `slds-size_1-of-2` mobile, `slds-medium-size_1-of-3` desktop
- Sem CSS complexo, sem biblioteca externa
