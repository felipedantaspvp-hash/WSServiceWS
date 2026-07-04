# 06 - Criterio de retomada

A retomada manual valida:

- `TipoAreaParticipante__c = Area Interna`;
- `OrigemSLA__c = Custom`;
- registro nao concluido;
- registro nao cancelado;
- `DataHoraInicioPausa__c != null`;
- regra SLA possui `BusinessHoursName__c`.

Ao retomar:

- calcula duracao da pausa desde `DataHoraInicioPausa__c`;
- usa `BusinessHours.diff` quando nao estiver em teste com bypass;
- soma os minutos em `TempoPausadoMinutos__c`;
- estende `DataHoraPrazo__c` pelo mesmo intervalo;
- limpa `DataHoraInicioPausa__c`;
- limpa `StatusAtuacaoAnteriorPausa__c`;
- recalcula cache operacional via `AreaParticipanteSLAService.calculateCacheBulk`.
