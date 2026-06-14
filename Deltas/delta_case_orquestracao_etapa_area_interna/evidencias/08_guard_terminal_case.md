# 08 - Guard para Case em Estado Terminal

## Problema

Sem guard, `closeParticipation()` poderia sobrescrever `EtapaAtendimento__c = 'Cancelado'` com 'Preparando Retorno ao Cliente' — comportamento incorreto.

## Solução

```apex
String etapaNormClose = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
Boolean caseIsTerminal = etapaNormClose.contains('conclu') || etapaNormClose.contains('cancel');

if (!caseIsTerminal && Case.EtapaAtendimento__c.getDescribe().isUpdateable() && openCustomInterna == 0) {
    // Apenas atualiza se não-terminal
}
```

## Valores terminais cobertos

| EtapaAtendimento__c | Normalizado | Detectado como terminal? |
|---|---|---|
| Concluído | 'concluido' | ✅ (contains 'conclu') |
| Cancelado | 'cancelado' | ✅ (contains 'cancel') |
| Aguardando Área Interna | 'aguardando area interna' | ❌ (não-terminal) |
| Preparando Retorno ao Cliente | 'preparando retorno ao cliente' | ❌ (não-terminal) |
| Em Atendimento | 'em atendimento' | ❌ (não-terminal) |

## O mesmo guard em `addParticipation()`

```apex
if (!etapaNorm.contains('conclu') && !etapaNorm.contains('cancel')) {
    caseRow.EtapaAtendimento__c = 'Aguardando Área Interna';
}
```

Idêntico em semântica — impede sobrescrever 'Concluído' ou 'Cancelado'.

## Por que não usar `IsClosed`

`AreaParticipanteSelector.getCaseById()` não seleciona `IsClosed`. Como `IsClosed = true` implica `Status='Fechado'` que implica `EtapaAtendimento__c='Concluído'`, verificar a etapa é suficiente. Minimiza alterações ao Selector.
