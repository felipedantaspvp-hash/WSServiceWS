# 08 - Validacao Custom Area Interna afetada

Somente registros com:

- `TipoAreaParticipante__c = Area Interna`;
- `OrigemSLA__c = Custom`;

sao aceitos para pausa/retomada manual.

Testes:

- `testPauseManualCustomAreaSuccess`
- `testResumeManualCustomAreaAccumulatesPausedTime`
- `testPauseResumeRowsBulk`
- `testPauseAndResumeParticipationSuccess`

Resultado: todos passaram no dry-run `0Afbe00000AA2h8CAD` (Succeeded, 40/40 testes).
