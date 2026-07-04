# 04 - Decisao arquitetural Flow/Apex/Service

## Flow-first avaliado

Nao foi criado Flow novo porque:

- ja existe ciclo de vida centralizado em `AreaParticipanteService`;
- o calculo de retomada depende de Business Hours e acumulacao de tempo;
- `AreaParticipanteSLAService.calculateCacheBulk` ja concentra o recalculo operacional;
- criar Flow paralelo duplicaria regra de negocio.

## Decisao

Usar Service Apex existente:

- `AreaParticipanteController`: expõe `pauseParticipation` e `resumeParticipation`;
- `AreaParticipanteService`: valida e executa pausa/retomada;
- `AreaParticipanteSelector`: carrega campos necessarios;
- `AreaParticipanteSLAService`: preserva `StatusSLA__c = Pausado` enquanto houver pausa ativa.

## Trigger nova

Nao criada.
