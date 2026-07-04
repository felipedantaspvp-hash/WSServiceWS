# 07 - Checks: Case / Etapa de Atendimento

## 2 SOQLs utilizados

### SOQL 1 — Areas abertas por Case
```soql
SELECT Caso__c FROM AreaParticipante__c
WHERE TipoAreaParticipante__c = 'Área Interna'
  AND StatusAtuacao__c NOT IN ('Concluída', 'Cancelada')
  AND Caso__c != null
LIMIT :lim  -- lim = min(maxRecords, 100)
```

### SOQL 2 — Cases terminais com essas areas
```soql
SELECT Id, CaseNumber, EtapaAtendimento__c, Status
FROM Case
WHERE Id IN :caseIdsComAreaAberta
  AND (EtapaAtendimento__c = 'Concluído' OR EtapaAtendimento__c = 'Cancelado')
```

## Regras detectadas

| Codigo | Severidade | Condicao |
|--------|-----------|----------|
| `CASE_TERMINAL_COM_AREA_ABERTA` | High | Case com EtapaAtendimento__c terminal (Concluido/Cancelado) mas tem AP aberta |

## Limite

Limitado a `min(maxRecords, 100)` Cases para evitar exceder governors em auditorias grandes.
O segundo SOQL nao tem LIMIT pois recebe apenas Ids ja filtrados pelo primeiro.

## Motivo do design em 2 passos

Nao existe nome de relacao filho para AreaParticipante__c em Case via SOQL padrao.
O anti-join alternativo `WHERE Caso__c IN (SELECT Id FROM Case WHERE ...)` seria menos seletivo.
