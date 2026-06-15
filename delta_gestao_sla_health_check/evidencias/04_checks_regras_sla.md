# 04 - Checks: Regras SLA

## SOQL utilizado

```soql
SELECT Id, Name, Ativo__c, EscopoRegra__c, BusinessHoursName__c,
       TempoAlta__c, TempoBaixa__c, TempoMedia__c, ChaveUnica__c
FROM RegrasSLACategorizacao__c
LIMIT :lim
```

## Regras detectadas

| Codigo | Severidade | Condicao |
|--------|-----------|----------|
| `REGRA_SEM_PRAZO` | High | TempoAlta__c AND TempoMedia__c AND TempoBaixa__c todos nulos |
| `ESCOPO_LEGADO` | Critical | EscopoRegra__c em {'Global', 'Por Categorizacao', 'Por Area Interna'} |
| `REGRA_DUPLICADA` | High | ChaveUnica__c aparece mais de uma vez no resultado da query |
| `REGRA_SEM_BUSINESS_HOURS` | Medium | BusinessHoursName__c em branco |

## Deteccao de duplicatas

Usa Map<String, Integer> chaveCount construido em loop pre-checagem. Sem SOQL adicional.

## Valores legados de EscopoRegra__c (Pacote 15D)

Valores removidos e invalidados: `'Global'`, `'Por Categorizacao'`, `'Por Area Interna'`.
Valores validos atuais: `'Atendimento'`, `'Area Interna'`.
