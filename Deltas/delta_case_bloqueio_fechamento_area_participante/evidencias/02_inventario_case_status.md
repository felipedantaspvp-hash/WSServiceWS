# 02 - Inventário de Status do Case

## Método de identificação

O campo `Case.Status` é um campo padrão do Salesforce. O arquivo de metadado `Status.field-meta.xml` não está presente no source local (campo padrão gerenciado pelo org). A identificação foi feita por análise de código:

- `CaseClosureSurveyService.cls` define `private static final String CLOSED_STATUS = 'Fechado'`
- Fechamento via UI: `Case.Status = 'Fechado'` → `Case.IsClosed = true` (mapeado no picklist do org)
- `CaseMilestoneMacroService.cls` define `ETAPA_CANCELADO = 'Cancelado'` e trata como condição separada de `IsClosed = true`

## Status considerados para bloqueio

| Mecanismo | Valor | Como detectado no trigger |
|---|---|---|
| Fechamento | `IsClosed = false → true` | `!oldC.IsClosed && newC.IsClosed` |
| Cancelamento | `EtapaAtendimento__c = 'Cancelado'` | `ETAPA_CANCELADO.equals(newC.EtapaAtendimento__c) && !ETAPA_CANCELADO.equals(oldC.EtapaAtendimento__c)` |

## EtapaAtendimento__c (campo customizado)

Picklist definida em `force-app/main/default/objects/Case/fields/EtapaAtendimento__c.field-meta.xml`:

| Valor | Default |
|---|---|
| Novo | Sim |
| Em Triagem | Não |
| Em Atendimento | Não |
| Aguardando Cliente | Não |
| Aguardando Área Interna | Não |
| Em Acompanhamento | Não |
| Preparando Retorno ao Cliente | Não |
| Concluído | Não |
| **Cancelado** | Não |
| Aguardando atendimento | Não |

## Justificativa para detectar cancelamento via EtapaAtendimento__c

`CaseMilestoneMacroService.completeByStageTransition()` trata `EtapaAtendimento__c = 'Cancelado'` como condição SEPARADA de `IsClosed = true`, confirmando que cancelamento pode ocorrer sem que `IsClosed` transite para `true`. A lógica:

```apex
if ((o.IsClosed == false && n.IsClosed == true)
    || isIn(n.EtapaAtendimento__c, new Set<String>{ ETAPA_CONCLUIDO, ETAPA_CANCELADO })) {
```

Portanto, o trigger deve detectar AMBAS as condições para garantir bloqueio completo.

## Status hardcoded não utilizados

Nenhum status hardcoded foi introduzido neste pacote. O cancelamento é detectado via constante privada `ETAPA_CANCELADO = 'Cancelado'` alinhada ao valor real da picklist `EtapaAtendimento__c`.
