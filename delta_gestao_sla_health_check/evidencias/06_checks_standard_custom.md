# 06 - Checks: Standard vs Custom

## 3 SOQLs utilizados (sem loop)

### SOQL 1 — Standard com pausa
```soql
SELECT Id, Name FROM AreaParticipante__c
WHERE TipoAreaParticipante__c = 'Área Interna'
  AND OrigemSLA__c = 'Standard'
  AND DataHoraInicioPausa__c != null
LIMIT :lim
```

### SOQL 2 — Standard sem CaseMilestone
```soql
SELECT Id, Name FROM AreaParticipante__c
WHERE TipoAreaParticipante__c = 'Área Interna'
  AND OrigemSLA__c = 'Standard'
  AND CaseMilestoneId__c = null
LIMIT :lim
```

### SOQL 3 — Custom com CaseMilestone
```soql
SELECT Id, Name FROM AreaParticipante__c
WHERE TipoAreaParticipante__c = 'Área Interna'
  AND OrigemSLA__c = 'Custom'
  AND CaseMilestoneId__c != null
LIMIT :lim
```

## Regras detectadas

| Codigo | Severidade | Condicao |
|--------|-----------|----------|
| `STANDARD_COM_PAUSA` | Critical | Standard com DataHoraInicioPausa__c — pausa proibida para Standard |
| `STANDARD_SEM_MILESTONE` | Info | Standard sem CaseMilestoneId__c — pode ser sync pendente |
| `CUSTOM_COM_MILESTONE` | High | Custom com CaseMilestoneId__c — vinculo indevido |

## Motivo da separacao em 3 SOQLs

Nao ha relacao de filho nomeado (`__r`) para AreaParticipante__c em Case via SOQL padrao.
Os 3 SOQLs permitem filtros seletivos e evitam trazer todos os campos em um unico SOQL largo.
