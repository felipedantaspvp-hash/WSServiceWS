# Evidência 05 — Análise de Segurança: AreaParticipanteTrigger com Registros Standard

**Data:** 2026-06-14

## Contexto

O trigger `AreaParticipante__c` (via `AreaParticipanteTriggerHandler`) executa ao inserir/atualizar registros espelho Standard. Esta evidência documenta que os registros Standard são tratados com segurança.

## Análise por handler

### beforeInsert → AreaParticipanteSLAService.beforeSave

```apex
for (AreaParticipante__c a : newList){
    // LINHA 16: salta se não é Área Interna
    if (!AreaParticipanteSLAHelper.isTipoInterna(a.TipoAreaParticipante__c)) continue;
    // LINHA 17: salta se é Standard (guarda adicionado neste pacote)
    if (AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) continue;
    // Validações de Caso e Área — nunca alcançadas por Standard
    ...
}
```

**Resultado:** Nenhum registro Standard passa pelas validações de Caso/Área obrigatória.

### beforeSave → calculateCacheBulk

Linha 137–142: skip quando `RegraSLACategorizacao__c == null` ou `rule == null`.
Registros Standard não têm regra → `continue` imediato. Status/tempo não são recalculados.

### beforeSave → validateNoOpenDuplicate

Linha 62: filtra por `isTipoInterna()`. Só registros com `TipoAreaParticipante__c = 'Área Interna'` participam.
Para Standard com `TipoAreaParticipante__c = 'Área Interna'` (Atendimento N3): `AreaAtendimento__c` é null.
A validação usa chave `CaseId + '|' + AreaAtendimento__c`. Há no máximo 1 milestone 'Atendimento N3' por Case, então sem duplicata dentro do lote.

### beforeUpdate → AreaParticipanteSLAService.closeSLA

```apex
public static void closeSLA(List<AreaParticipante__c> rows){
    calculateCacheBulk(rows, System.now()); // skip por rule==null (ver acima)
    for (AreaParticipante__c a : rows){
        // GUARDA adicionado neste pacote: Standard preserva StatusSLA__c
        if (!AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) {
            if (...isConcluida...) a.StatusSLA__c = STATUS_SLA_CONCLUIDO;
            if (...isCancelada...) a.StatusSLA__c = STATUS_SLA_CANCELADO;
        }
        a.BloqueiaFechamentoCaso__c = false;
    }
}
```

**Resultado:** Standard nunca tem StatusSLA__c sobrescrito pelo closeSLA. O valor definido em buildRecord é preservado.

### afterInsert / afterUpdate → CaseAreaParticipanteAggregationService

Apenas conta registros por Case. Seguro — inclui Standard e Custom igualmente.

## Conclusão

Todos os pontos do trigger tratam registros Standard corretamente. Nenhum erro de validação é lançado para espelhos.
