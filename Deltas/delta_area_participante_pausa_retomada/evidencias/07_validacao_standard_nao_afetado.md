# 07 - Validacao Standard nao afetado

Registros `OrigemSLA__c = Standard` sao rejeitados por `AreaParticipanteService.validateManualPauseResumeTarget`.

Testes:

- `testPauseRejectsStandardArea`
- `testResumeRejectsStandardArea`

Resultado: ambos passaram no dry-run `0Afbe00000AA2h8CAD` (Succeeded, 40/40 testes).
