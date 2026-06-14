# 16 - Cancelamento de Área Interna: Documentação de Escopo

## Conclusão

**`cancelParticipation()` não existe** neste escopo e não foi implementado.

## Evidências

### AreaParticipanteService

O service expõe apenas:
- `addParticipation()` — cria AP Custom Interna
- `closeParticipation()` — conclui AP (status → Concluída)
- `getPanelData()` — leitura

Não há método `cancelParticipation()`, `cancelArea()` ou equivalente.

### LWC: caseAreasParticipantesPanel

O método `toItem()` do DTO (ou Service) define `canCancel = false` para todos os registros. O botão de cancelamento no LWC fica desabilitado/oculto — a UI nunca chama cancelamento.

### Motivo do não-escopo

Cancelar uma Área Interna Custom implicaria:
- Decidir o impacto em `EtapaAtendimento__c` (voltar para estado anterior? qual?)
- Decidir se SLA é abortado ou apenas pausado
- Regras de negócio ainda não definidas

O produto atual suporta apenas **conclusão** (`closeParticipation()`), que é a única saída disponível via UI.

## Impacto no Pacote 21

Nenhum. O Pacote 21 só orquestra `addParticipation()` e `closeParticipation()`. Cancelamento não entra no escopo de orquestração de `EtapaAtendimento__c`.
