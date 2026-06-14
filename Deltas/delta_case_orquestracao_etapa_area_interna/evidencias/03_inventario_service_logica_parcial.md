# 03 - Inventário do Service — Lógica Parcial Pré-existente

## `AreaParticipanteService.addParticipation()` — antes do Pacote 21

Atualizava `caseRow.AreasParticipantesSLA__c` e `caseRow.AreasParticipantes__c` mas **não tocava em `EtapaAtendimento__c`**.

## `AreaParticipanteService.closeParticipation()` — antes do Pacote 21 (linhas 196-213)

```apex
Integer openRemaining = 0;
for (AreaParticipante__c other : remainingRows) {
    if (other.Id == row.Id) continue;
    if (AreaParticipanteHelper.isAbertaOuAndamento(other.StatusAtuacao__c) || ...) {
        openRemaining++;  // ← contava APs Standard também
    }
}
if (openRemaining == 0 && Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
    String current = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
    if (String.isBlank(current) || current.contains('aguardando') || current.contains('area interna') || current.contains('area')) {
        // ← condição contains('area') ampla demais
        // ← sem guard para Case terminal
        caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
        etapaUpdated = true;
    }
}
```

## Gaps identificados

| # | Gap | Impacto |
|---|---|---|
| 1 | `openRemaining` sem filtro `TipoAreaParticipante__c='Área Interna' AND BloqueiaFechamentoCaso__c=true` | APs Standard com `StatusAtuacao__c='Aberta'` contavam como "abertas", bloqueando transição para 'Preparando Retorno ao Cliente' |
| 2 | Sem guard para Case em estado terminal | Case 'Cancelado' ou 'Concluído' poderia ter etapa alterada |
| 3 | Condição `contains('area')` ampla demais | Poderia mover etapa em estados inesperados |
| 4 | Sem lógica de `addParticipation()` → 'Aguardando Área Interna' | Etapa não era atualizada ao acionar nova Área Interna |
