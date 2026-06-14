# Evidência 05 — Inventário do Componente Visual

**Data:** 2026-06-14
**Escopo:** LWC/Aura para acionamento manual de AreaParticipante__c

## Status atual

Nenhum componente LWC ou Aura de acionamento manual de AreaParticipante__c existe no repositório.

## Inventário realizado

Busca em `force-app/main/default/lwc/` e `force-app/main/default/aura/`:
- Nenhum componente com referência a `addParticipation`, `AreaParticipanteService` ou `areaParticipante` encontrado.

Endpoint backend disponível: `AreaParticipanteController.addParticipation(AddRequestDTO)`.

## Campos disponíveis no AddRequestDTO

| Campo | Tipo | Descrição |
|-------|------|-----------|
| caseId | Id | Id do Case |
| area | String | Valor do picklist AreaAtendimento__c |
| comentarioSolicitacao | String | Comentário obrigatório |

## Campos disponíveis no AddResponseDTO

| Campo | Tipo | Descrição |
|-------|------|-----------|
| success | Boolean | Resultado da operação |
| message | String | Mensagem de retorno |
| caseId | Id | Id do Case |
| areaParticipanteId | Id | Id do registro criado |
| updatedAreas | String | Multipicklist atualizado no Case |

## Áreas elegíveis

O método `AreaParticipanteController.getPanelData(caseId)` retorna `areaOptions` — lista de áreas que têm regra de SLA ativa para a categorização do Case e ainda não estão em ciclo aberto.

## Próximo passo

O LWC de acionamento manual será entregue em pacote separado (Pacote 18). O backend deste pacote (17A) está completo e pronto para consumo.
