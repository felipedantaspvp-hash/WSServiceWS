# 03 - Regras de exibicao dos botoes

## Pausar

Exibe quando `item.canPause = true`.

Backend calcula `canPause` considerando:

- `panel.canManage = true`
- `TipoAreaParticipante__c = Area Interna`
- `OrigemSLA__c = Custom`
- nao concluido
- nao cancelado
- nao pausado
- status compativel com pausa

## Retomar

Exibe quando `item.canResume = true`.

Backend calcula `canResume` considerando:

- `panel.canManage = true`
- `TipoAreaParticipante__c = Area Interna`
- `OrigemSLA__c = Custom`
- nao concluido
- nao cancelado
- pausado

A validacao funcional permanece em Apex.
