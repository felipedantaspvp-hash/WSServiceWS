# 05 - Criterio de pausa

A pausa manual valida:

- `TipoAreaParticipante__c = Area Interna`;
- `OrigemSLA__c = Custom`;
- registro nao concluido;
- registro nao cancelado;
- `DataHoraFim__c = null`;
- `DataHoraInicioPausa__c = null`;
- `StatusSLA__c != Pausado`;
- status operacional aberto/em andamento/vencido.

Ao pausar:

- grava `DataHoraInicioPausa__c = System.now()`;
- grava `StatusAtuacaoAnteriorPausa__c` com o status atual;
- grava `StatusSLA__c = Pausado`;
- preserva `StatusAtuacao__c`, pois nao existe valor real `Pausada`.
