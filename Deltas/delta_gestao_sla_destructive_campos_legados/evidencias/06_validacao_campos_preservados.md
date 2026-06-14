# Evidencia 06 - Campos preservados

Campos confirmados como fora do escopo do destructive:

- `AreaParticipante__c.OrigemSLA__c`
- `AreaParticipante__c.TipoAreaParticipante__c`

Conclusao:

- Nenhum dos dois campos foi incluido em `destructiveChanges.xml`.
- Nenhuma alteracao de metadata foi feita nesses campos.
- No repositorio local, os arquivos desses campos existem.
- No org `WILSON_SERVICE`, esses dois campos nao aparecem em `FieldDefinition` para `AreaParticipante__c`; portanto, a preservacao foi garantida pelo nao uso no pacote, nao por validacao de existencia no ambiente alvo.
