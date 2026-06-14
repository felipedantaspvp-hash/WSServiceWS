# Pacote 21 — Orquestração de EtapaAtendimento__c baseada no ciclo de vida de Áreas Internas

## 1. Objetivo

Orquestrar o campo `EtapaAtendimento__c` do Case de acordo com o ciclo de vida das Áreas Internas Custom:
- **Ao acionar** Área Interna: mover Case para "Aguardando Área Interna" (se não estiver em estado terminal)
- **Ao concluir**: se não restar nenhuma Área Interna Custom aberta → "Preparando Retorno ao Cliente"; caso contrário, manter "Aguardando Área Interna"
- Registros Standard (espelho de Milestone) **não afetam** a etapa do Case

## 2. Arquivos criados/alterados

| Arquivo | Operação | Descrição |
|---|---|---|
| `force-app/main/default/classes/AreaParticipanteService.cls` | Alterado | `addParticipation()`: + etapa → 'Aguardando Área Interna' (guard terminal). `closeParticipation()`: + filtro Custom Interna em `openCustomInterna`; + guard terminal; + lógica simplificada |
| `force-app/main/default/classes/AreaParticipanteServiceTest.cls` | Alterado | 6 novos cenários de orquestração de etapa |

## 3. Inventário de automações existentes para AreaParticipante__c

| Tipo | Artefato | Relevância |
|---|---|---|
| Trigger | AreaParticipanteTrigger | beforeInsert/beforeUpdate → SLAService; afterInsert/afterUpdate → AggregationService |
| Handler | AreaParticipanteTriggerHandler | Delegação pura ao SLAService e AggregationService |
| Service | AreaParticipanteService | Ponto central do ciclo de vida — addParticipation/closeParticipation |
| Flow | — | Nenhum Flow para AreaParticipante__c encontrado |

Nenhum Flow de AreaParticipante__c encontrado via `Glob *AreaParticipante*.flow-meta.xml`.

## 4. Decisão arquitetural

**Estender o `AreaParticipanteService` existente.**

Razões:
- `addParticipation()` e `closeParticipation()` já são o ponto central do ciclo de vida do AP
- `closeParticipation()` já tinha lógica parcial de atualização de etapa (linhas 207-213 da versão original)
- Arquitetura: Controller → Service → Selector; coerente com o padrão existente
- A lógica parcial existente tinha 3 gaps (sem filtro Custom Interna, sem guard terminal, condição muito ampla)
- Sem Flow existente para este objeto; criar um seria over-engineering

## 5. Gaps corrigidos na lógica original de `closeParticipation()`

| Gap | Correção |
|---|---|
| `openRemaining` contava APs Standard como "abertas" | Substituído por `openCustomInterna` com filtro `TipoAreaParticipante__c='Área Interna' AND BloqueiaFechamentoCaso__c=true` |
| Sem guard para Case em estado terminal | Adicionado `caseIsTerminal = etapaNorm.contains('conclu') OR etapaNorm.contains('cancel')` |
| Condição `current.contains('area')` era ampla demais | Removida — etapa é atualizada sempre que não-terminal e sem APs abertas |

## 6. Como a lógica funciona

### `addParticipation()` (novo trecho)
```apex
if (Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
    String etapaNorm = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
    if (!etapaNorm.contains('conclu') && !etapaNorm.contains('cancel')) {
        caseRow.EtapaAtendimento__c = 'Aguardando Área Interna';
    }
}
```

### `closeParticipation()` (lógica substituída)
```apex
Integer openCustomInterna = 0;
for (AreaParticipante__c other : remainingRows) {
    if (other.Id == row.Id) continue;
    if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(other.TipoAreaParticipante__c)) continue;
    if (!other.BloqueiaFechamentoCaso__c) continue;
    if (AreaParticipanteHelper.isAbertaOuAndamento(other.StatusAtuacao__c) || ...) openCustomInterna++;
}
Boolean caseIsTerminal = etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
if (!caseIsTerminal && ... && openCustomInterna == 0) {
    caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
    etapaUpdated = true;
}
```

## 7. Por que `BloqueiaFechamentoCaso__c = true` é o proxy para Custom aberta

- `AreaParticipanteSLAService.beforeSave()` define `BloqueiaFechamentoCaso__c = true` em toda Custom Área Interna que muda para status aberto
- `closeSLA()` define `BloqueiaFechamentoCaso__c = false` ao concluir/cancelar
- `buildRecord()` define `BloqueiaFechamentoCaso__c = false` para todos os registros Standard
- Portanto: `TipoAreaParticipante__c='Área Interna' AND BloqueiaFechamentoCaso__c=true` ↔ Custom Interna aberta

## 8. Restrições respeitadas

| Restrição | Status |
|---|---|
| Não alterar caseAreasParticipantesPanel | ✅ |
| Não alterar acionamento manual de Área Interna | ✅ |
| Não alterar espelhamento de Milestones | ✅ |
| Não alterar regras SLA / Entitlement | ✅ |
| Não criar campos novos / alterar picklists | ✅ |
| Não usar campos removidos no 16B | ✅ |
| Não usar valores antigos de EscopoRegra__c | ✅ |
| Bloqueio do Pacote 20 não alterado | ✅ |

## 9. Testes executados

| # | Método | Cenário | Resultado |
|---|---|---|---|
| 1 | `testAddParticipationSetsEtapaAguardandoAreaInterna` | addParticipation em Case com etapa 'Em Atendimento' → muda para 'Aguardando Área Interna' | ✅ PASS |
| 2 | `testAddParticipationDoesNotChangeEtapaForCancelledCase` | addParticipation em Case 'Cancelado' → etapa não muda | ✅ PASS |
| 3 | `testCloseLastCustomInternaMovesEtapaToPreparandoRetorno` | close última Custom Interna → 'Preparando Retorno ao Cliente' | ✅ PASS |
| 4 | `testCloseWithOtherOpenCustomInternaKeepsEtapa` | close uma com outra ainda aberta → mantém 'Aguardando Área Interna' | ✅ PASS |
| 5 | `testCloseWithStandardOnlyRemainingMovesEtapa` | Standard restante não conta → move para 'Preparando Retorno ao Cliente' | ✅ PASS |
| 6 | `testCloseDoesNotUpdateEtapaForTerminalCase` | Case 'Cancelado' → close não muda etapa | ✅ PASS |

## 10. Resultado do dry-run

**Deploy ID:** `0Afbe00000AA2ysCAD`
**Status:** Succeeded
**Testes:** 18/18 passando — 0 falhas
**Cobertura:** AreaParticipanteService 85% (237/280)
**Quick Deploy:** `sf project deploy quick --job-id 0Afbe00000AA2ysCAD --target-org WILSON_SERVICE`
