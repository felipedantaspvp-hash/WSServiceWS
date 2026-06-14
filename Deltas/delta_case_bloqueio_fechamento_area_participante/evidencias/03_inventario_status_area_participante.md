# 03 - Inventário de Status de Área Participante

## Fonte

`force-app/main/default/objects/AreaParticipante__c/fields/StatusAtuacao__c.field-meta.xml`

## Valores existentes da picklist StatusAtuacao__c

| Valor | Default | Classificação |
|---|---|---|
| Aberta | Sim | **Aberta (bloqueante)** |
| Em Andamento | Não | **Aberta (bloqueante)** |
| Concluída | Não | Encerrada (não bloqueante) |
| Cancelada | Não | Encerrada (não bloqueante) |
| Vencida | Não | **Aberta (bloqueante)** |

> Nota: `Pausada` aparece em `AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA` e `isOpenStatus()` inclui 'pausada'. Contudo, o valor não consta na picklist do campo. Não foi criado nenhum valor novo.

## Como o bloqueio identifica registros abertos

A query usa:
- `BloqueiaFechamentoCaso__c = true` — campo setado como `true` apenas em registros Custom de Área Interna quando abertos (em `AreaParticipanteSLAService.beforeSave`)
- `DataHoraFim__c = null` — registros encerrados (Concluída, Cancelada) têm `DataHoraFim__c` preenchido

Esta abordagem é **equivalente e mais robusta** que filtrar `StatusAtuacao__c IN ('Aberta', 'Em Andamento', 'Vencida')`, pois:
1. `BloqueiaFechamentoCaso__c` é gerenciado explicitamente pelo service
2. `DataHoraFim__c = null` garante que registros com DataHoraFim preenchido não bloqueiam, independente do status

## Mapeamento AreaParticipanteSLAHelper.isOpenStatus()

```apex
public static Boolean isOpenStatus(String v){
    String x = n(v);
    return x.contains('aberta') || x.contains('andamento') || x.contains('pausada') || x.contains('vencida');
}
```

Estados abertos: Aberta, Em Andamento, Pausada, Vencida.  
Estados fechados: Concluída, Cancelada.

## Conclusão

Nenhum valor novo de picklist foi criado. A lógica de identificação de registros abertos usa `BloqueiaFechamentoCaso__c = true AND DataHoraFim__c = null`, consistente com o modelo de dados existente.
