# Evidência 04 — Métodos Apex consumidos pelo componente

**Data:** 2026-06-14

## Imports Apex no caseAreasParticipantesPanel.js

```javascript
import getPanelDataFresh from '@salesforce/apex/AreaParticipanteController.getPanelDataFresh';
import closeParticipation from '@salesforce/apex/AreaParticipanteController.closeParticipation';
import getParticipationDetails from '@salesforce/apex/AreaParticipanteController.getParticipationDetails';
import addParticipation from '@salesforce/apex/AreaParticipanteController.addParticipation';
```

## Tabela de métodos

| Método | Controller | Quando acionado | DTO utilizado |
|--------|------------|-----------------|---------------|
| `getPanelDataFresh(caseId, refreshToken)` | `AreaParticipanteController` | `connectedCallback` + `handleRefresh` | Retorna `PanelDTO` com `canManage`, `areaOptions`, `items`, `totalAbertas`, `totalVencidas`, `proximoPrazo` |
| `addParticipation(request)` | `AreaParticipanteController` | Confirmar modal Adicionar | `AddRequestDTO`: `caseId`, `area`, `comentarioSolicitacao` |
| `closeParticipation(request)` | `AreaParticipanteController` | Confirmar modal Encerrar | `CloseRequestDTO`: `areaParticipanteId`, `comentarioRetorno`, `solucaoRetorno` |
| `getParticipationDetails(areaParticipanteId)` | `AreaParticipanteController` | Clique em Detalhes | Retorna `ParticipationDetailsDTO` com campos de retorno |

## Regra SLA (17A — sem mudança no LWC)

O método `addParticipation` delega ao backend a busca da regra SLA por:

- `GestaoSLA__c` (campo explícito via `EscopoRegra__c = 'Area Interna'`)
- `Categorizacao__c` (da categorização do Case)
- `AreaAtendimento__c` (da área acionada)
- `Ativo__c = true`

Zero cálculo de SLA no JavaScript. ✓
