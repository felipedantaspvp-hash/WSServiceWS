# 15 - Ajustes Pós-Revisão (v2)

## Origem

Revisão após dry-run v1 identificou 7 pontos de melhoria.

---

## Ajuste 1: closeParticipation() só altera etapa quando AP fechado for Custom Interna

**Problema:** `closeParticipation()` poderia alterar `EtapaAtendimento__c` ao fechar qualquer AP (incluindo Standard).

**Solução:** Adicionado `rowIsCustomInterna` antes da lógica de etapa:
```apex
Boolean rowIsCustomInterna = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(row.TipoAreaParticipante__c)
    && AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(row.OrigemSLA__c);
// ...
if (rowIsCustomInterna && !caseIsTerminal && ... && openCustomInterna == 0) {
    caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
}
```

**Requer:** `OrigemSLA__c` em `getAreaById()` (Ajuste 3).

---

## Ajuste 2: Case fechado (IsClosed=true) não tem EtapaAtendimento sobrescrita

**Problema:** Guard terminal verificava apenas `EtapaAtendimento__c` ('conclu'/'cancel'). Um Case com `IsClosed=true` mas etapa inconsistente não era protegido.

**Solução:** Atualizado terminal check para incluir `caseRow.IsClosed`:
```apex
Boolean caseIsTerminal = caseRow.IsClosed || etapaNormClose.contains('conclu') || etapaNormClose.contains('cancel');
```

Idem em `addParticipation()`:
```apex
Boolean addIsTerminal = caseRow.IsClosed || etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
if (!addIsTerminal) { caseRow.EtapaAtendimento__c = 'Aguardando Área Interna'; }
```

**Requer:** `IsClosed` em `getCaseById()` (Ajuste 3).

---

## Ajuste 3: AreaParticipanteSelector atualizado

| Método | Campo adicionado | Motivo |
|---|---|---|
| `getCaseById()` | `IsClosed` | Habilita guard terminal baseado em estado real do Case |
| `getAreaById()` | `OrigemSLA__c` | Habilita `rowIsCustomInterna` check sem depender de proxy |

`getAreasByCase()` **não alterado** — usa `BloqueiaFechamentoCaso__c` como proxy para Custom aberta no loop in-memory (campo já existia na query).

---

## Ajuste 4: Teste — Standard fechado não altera etapa

**Cenário:** `closeParticipation()` chamado com AP Standard (`OrigemSLA__c='Standard'`) enquanto Case tem Custom Interna aberta.

**Resultado esperado:** `etapaAtualizada = false`, `EtapaAtendimento__c` permanece 'Aguardando Área Interna'.

Método: `testCloseStandardApDoesNotUpdateEtapa` ✅ PASS (1839ms)

---

## Ajuste 5: Teste — Case fechado (IsClosed) não tem etapa sobrescrita

**Cenário:** `closeParticipation()` chamado com Custom Interna AP enquanto `caseRow.IsClosed = true` (injetado via `AreaParticipanteSelector.testCase`).

**Técnica:** JSON.deserialize com `IsClosed=true` para criar Case com campo somente-leitura setado.

**Resultado esperado:** `etapaAtualizada = false`, `EtapaAtendimento__c` permanece 'Aguardando Área Interna'.

Método: `testCloseDoesNotUpdateEtapaWhenCaseIsClosed` ✅ PASS (1680ms)

---

## Ajuste 6: Cancelamento de Área Interna — documentação de escopo

Ver evidência `16_cancelamento_area_interna_escopo.md`.

---

## Ajuste 7: Novo dry-run executado

Deploy ID: `0Afbe00000AA3rhCAD` — Succeeded, 20/20 testes, 0 falhas.
AreaParticipanteSelector: 97% | AreaParticipanteService: 85%
