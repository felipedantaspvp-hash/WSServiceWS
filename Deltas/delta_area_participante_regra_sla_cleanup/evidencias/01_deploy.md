# Evidência 01 — Deploy

**Deploy ID:** 0Afbe00000A9wNBCAZ
**Data:** 2026-06-14
**Org:** jduarte@wilsonsons.com.br.service
**Tipo:** Deploy Real (após Dry Run com 28/28 aprovado)

## Resultado

- **Status:** Succeeded
- **Classes implantadas:** 4

## Classes implantadas

| Classe | Mudança |
|--------|---------|
| AreaParticipanteSLAServiceTest | Removido método `createRegraLegada` (dead code); removido `TipoAreaParticipante__c` desnecessário de `createRegraNova` |
| AreaParticipanteTestDataFactory | Removido `TipoAreaParticipante__c` desnecessário de `createSlaRule` |
| AreaParticipanteSLABatchTest | Removido `TipoAreaParticipante__c` desnecessário de `createRule` (RegrasSLACategorizacao__c) |
| CaseAreaParticipantePauseServiceTest | Removido `createMarcoSLA` + `MarcoSLA__c = m.Id`; removido `TipoAreaParticipante__c`; adicionado `Categorizacao.GestaoSLA__c = g.Id` |
