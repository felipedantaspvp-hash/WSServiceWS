# 03 - Inventario de status AreaParticipante

## `StatusAtuacao__c`

Valores reais via describe da org:

- `Aberta`
- `Em Andamento`
- `Concluida`
- `Cancelada`
- `Vencida`

Nao existe valor real `Pausada` em `StatusAtuacao__c`.

## `StatusSLA__c`

Valores reais via describe da org:

- `Dentro do Prazo`
- `Em Atencao`
- `Vencido`
- `Concluido`
- `Cancelado`
- `Pausado`

## Decisao

A pausa manual usa `StatusSLA__c = Pausado` e `DataHoraInicioPausa__c` como marcador operacional. `StatusAtuacao__c` e preservado para nao inventar valor novo.
