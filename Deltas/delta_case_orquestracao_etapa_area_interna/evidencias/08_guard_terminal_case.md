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

## Adição de IsClosed ao guard (v2)

`AreaParticipanteSelector.getCaseById()` agora seleciona `IsClosed`. O guard terminal foi expandido:

```apex
Boolean caseIsTerminal = caseRow.IsClosed || etapaNormClose.contains('conclu') || etapaNormClose.contains('cancel');
```

Idem em `addParticipation()`:
```apex
Boolean addIsTerminal = caseRow.IsClosed || etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
if (!addIsTerminal) { caseRow.EtapaAtendimento__c = 'Aguardando Área Interna'; }
```

Isso protege contra o cenário onde `IsClosed=true` mas `EtapaAtendimento__c` está inconsistente (ex: vazio ou valor não-terminal por inconsistência de dados).
