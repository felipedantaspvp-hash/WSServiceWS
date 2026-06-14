# 05 - Implementação: addParticipation → 'Aguardando Área Interna'

## Trecho adicionado (antes de `try { insert row; update caseRow; }`)

```apex
if (Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
    String etapaNorm = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
    if (!etapaNorm.contains('conclu') && !etapaNorm.contains('cancel')) {
        caseRow.EtapaAtendimento__c = 'Aguardando Área Interna';
    }
}
```

## Comportamento

| Estado do Case | Resultado |
|---|---|
| EtapaAtendimento__c = 'Em Atendimento' | Muda para 'Aguardando Área Interna' |
| EtapaAtendimento__c = 'Aguardando Área Interna' | Permanece (idempotente) |
| EtapaAtendimento__c = 'Cancelado' | NÃO muda (guard terminal) |
| EtapaAtendimento__c = 'Concluído' | NÃO muda (guard terminal) |

## Integração com DML existente

O trecho é adicionado **antes** do `try { insert row; update caseRow; }`. Portanto, `EtapaAtendimento__c` é enviado na mesma operação `update caseRow` que já atualizava `AreasParticipantesSLA__c` e `AreasParticipantes__c`. Nenhum DML adicional.

## Verificação FLS

`Case.EtapaAtendimento__c.getDescribe().isUpdateable()` — consistente com o padrão já usado em `closeParticipation()`.
