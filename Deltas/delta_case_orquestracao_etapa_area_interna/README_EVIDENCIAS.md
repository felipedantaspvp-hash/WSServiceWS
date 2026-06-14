# Pacote 21 — Orquestração de EtapaAtendimento__c baseada no ciclo de vida de Áreas Internas

## 1. Objetivo

Orquestrar o campo `EtapaAtendimento__c` do Case de acordo com o ciclo de vida das Áreas Internas Custom:
- **Ao acionar** Área Interna: mover Case para "Aguardando Área Interna" (se não estiver em estado terminal)
- **Ao concluir**: se não restar nenhuma Área Interna Custom aberta → "Preparando Retorno ao Cliente"; caso contrário, manter "Aguardando Área Interna"
- Registros Standard (espelho de Milestone) **não afetam** a etapa do Case
- Cases com `Status='Fechado'` ou `EtapaAtendimento__c` em 'Concluído'/'Cancelado' **não têm** a etapa sobrescrita

## 2. Arquivos criados/alterados

| Arquivo | Operação | Descrição |
|---|---|---|
| `force-app/main/default/classes/AreaParticipanteSelector.cls` | Alterado | `getCaseById()`: removido `IsClosed`, `Status` já existia. `getAreasByCase()`: + `OrigemSLA__c`. `getAreaById()`: + `OrigemSLA__c` (desde v2) |
| `force-app/main/default/classes/AreaParticipanteService.cls` | Alterado | `addParticipation()`: + etapa → 'Aguardando Área Interna' (guard via `Status`). `closeParticipation()`: `rowIsCustomInterna` guard; `OrigemSLA__c = Custom` no loop; guard terminal via `Status='Fechado'` |
| `force-app/main/default/classes/AreaParticipanteServiceTest.cls` | Alterado | 8 novos cenários de orquestração de etapa |

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
- `closeParticipation()` já tinha lógica parcial de atualização de etapa
- Arquitetura: Controller → Service → Selector; coerente com o padrão existente
- Sem Flow existente para este objeto; criar um seria over-engineering

## 5. Gaps corrigidos na lógica original de `closeParticipation()`

| Gap | Correção |
|---|---|
| `openRemaining` contava APs Standard como "abertas" | `openCustomInterna` com filtro `TipoAreaParticipante__c='Área Interna' AND OrigemSLA__c='Custom'` |
| Sem guard para Case em estado terminal | `caseIsTerminal` via `Status='Fechado'` + etapa 'conclu'/'cancel' |
| Condição `current.contains('area')` era ampla demais | Removida — etapa é atualizada apenas quando `rowIsCustomInterna && !caseIsTerminal && openCustomInterna == 0` |
| `closeParticipation()` em Standard AP alterava etapa | `rowIsCustomInterna` guard impede |

## 6. Como a lógica funciona

### `addParticipation()` (trecho de etapa)
```apex
if (Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
    String etapaNorm = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
    String statusNorm = AreaParticipanteHelper.normalizeText(caseRow.Status);
    Boolean addIsTerminal = statusNorm.contains('fechad') || etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
    if (!addIsTerminal) {
        caseRow.EtapaAtendimento__c = 'Aguardando Área Interna';
    }
}
```

### `closeParticipation()` (lógica de orquestração)
```apex
Boolean rowIsCustomInterna = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(row.TipoAreaParticipante__c)
    && AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(row.OrigemSLA__c);

Integer openCustomInterna = 0;
for (AreaParticipante__c other : remainingRows) {
    if (other.Id == row.Id) continue;
    if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(other.TipoAreaParticipante__c)) continue;
    if (!AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(other.OrigemSLA__c)) continue;
    if (AreaParticipanteHelper.isAbertaOuAndamento(other.StatusAtuacao__c) || ...) openCustomInterna++;
}

String statusNormClose = AreaParticipanteHelper.normalizeText(caseRow.Status);
Boolean caseIsTerminal = statusNormClose.contains('fechad') || etapaNormClose.contains('conclu') || etapaNormClose.contains('cancel');

if (rowIsCustomInterna && !caseIsTerminal && Case.EtapaAtendimento__c.getDescribe().isUpdateable() && openCustomInterna == 0) {
    caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
    etapaUpdated = true;
}
```

## 7. Por que `OrigemSLA__c = 'Custom'` em vez de `BloqueiaFechamentoCaso__c` como proxy

`AreaParticipanteSLAService.beforeSave()` (linha 47) seta `OrigemSLA__c = ORIGEM_SLA_CUSTOM` explicitamente em todo AP Custom Área Interna. Usar `OrigemSLA__c` diretamente é mais preciso que o proxy `BloqueiaFechamentoCaso__c`:

| Campo | Quando true | Quando false |
|---|---|---|
| `BloqueiaFechamentoCaso__c` | Custom Interna aberta | Custom concluída/cancelada; Standard sempre false |
| `OrigemSLA__c = 'Custom'` | Qualquer AP Custom (aberta ou fechada) | AP Standard |

O filtro `OrigemSLA__c = 'Custom'` + status open/overdue substitui `BloqueiaFechamentoCaso__c` de forma mais explícita. `BloqueiaFechamentoCaso__c` ainda está no SELECT de `getAreasByCase()` para uso pelo `CaseTriggerHandler` (Pacote 20).

## 8. Guard terminal: `Case.Status='Fechado'` em vez de `IsClosed`

`IsClosed` é campo somente-leitura (fórmula derivada de `Status`). Usar `Status` diretamente:
- Evita dependência de campo fórmula no SELECT
- Simplifica testes: `Case c = new Case(Status='Fechado', ...)` — sem JSON deserialize hack
- `Status='Fechado'` é a única transição que o `CaseTriggerHandler` do Pacote 20 bloqueia quando há AP aberta

## 9. Restrições respeitadas

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

## 10. Testes executados

| # | Método | Cenário | Resultado |
|---|---|---|---|
| 1 | `testAddParticipationSetsEtapaAguardandoAreaInterna` | addParticipation em Case 'Em Atendimento' → muda para 'Aguardando Área Interna' | ✅ PASS |
| 2 | `testAddParticipationDoesNotChangeEtapaForCancelledCase` | addParticipation em Case 'Cancelado' → etapa não muda | ✅ PASS |
| 3 | `testCloseLastCustomInternaMovesEtapaToPreparandoRetorno` | close última Custom Interna → 'Preparando Retorno ao Cliente' | ✅ PASS |
| 4 | `testCloseWithOtherOpenCustomInternaKeepsEtapa` | close uma com outra Custom Interna ainda aberta → mantém 'Aguardando Área Interna' | ✅ PASS |
| 5 | `testCloseWithStandardOnlyRemainingMovesEtapa` | Standard restante não conta (OrigemSLA__c != Custom) → move para 'Preparando Retorno ao Cliente' | ✅ PASS |
| 6 | `testCloseDoesNotUpdateEtapaForTerminalCase` | Case com EtapaAtendimento='Cancelado' → close não muda etapa | ✅ PASS |
| 7 | `testCloseStandardApDoesNotUpdateEtapa` | closeParticipation em AP Standard → rowIsCustomInterna=false → etapaAtualizada=false | ✅ PASS |
| 8 | `testCloseDoesNotUpdateEtapaWhenCaseIsFechado` | testCase injection com Status='Fechado' → caseIsTerminal=true → etapaAtualizada=false | ✅ PASS |

## 11. Histórico de dry-runs

| Versão | Deploy ID | Status | Testes |
|---|---|---|---|
| v1 (inicial) | 0Afbe00000AA2ysCAD | Succeeded | 18/18 |
| v2 (rowIsCustomInterna + IsClosed) | 0Afbe00000AA3rhCAD | Succeeded | 20/20 |
| v3 (Status + OrigemSLA__c direto) | 0Afbe00000AA2naCAD | Succeeded | 20/20 |
