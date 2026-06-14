# Evidência 05 — Validação de Testes

**Data:** 2026-06-14

## Backend (Apex)

Nenhuma classe Apex foi criada ou modificada neste pacote.

Os métodos consumidos pelo LWC já possuem cobertura existente:

| Classe de teste | Métodos cobertos | Status anterior |
|-----------------|-----------------|-----------------|
| `AreaParticipanteControllerTest` | `getPanelData`, `addParticipation`, `closeParticipation`, `getParticipationDetails`, `getPanelDataFresh` + cenários de exceção | 96/96 Pass (suite 17B) |

## Jest (Frontend)

Jest não está configurado no projeto (ausência de `jest.config.js` ou `package.json` com dependência `@salesforce/sfdx-lwc-jest`).

Testes Jest não foram criados. Documentado como pendência no Pacote 19 ou pacote de governança.

## Critérios de aceite verificáveis manualmente

| Critério | Verificável via |
|----------|----------------|
| Componente carrega dados do Case | Teste manual na Record Page após deploy |
| Botão "Acionar" visível com canManage=true | Teste manual |
| Modal de acionamento valida campos obrigatórios | Teste manual |
| Backend valida e cria AreaParticipante__c | `AreaParticipanteControllerTest.testAddParticipationSuccess` |
| Erro de área duplicada exibido | `AreaParticipanteService` (DUPLICATE_OPEN_AREA) + toast |
| Erro sem regra SLA exibido | `AreaParticipanteControllerTest.testAddParticipationNoSlaRule` + toast |
| Modal de conclusão valida campos obrigatórios | Teste manual |
| Refresh atualiza a lista | Teste manual |
