# Evidência 04 — Mudanças Apex

## AreaParticipanteSLAService.cls

### findRule() — correção de filtro
**Antes:** `AND TipoAreaParticipante__c = :a.TipoAreaParticipante__c`
**Depois:** `AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA`

**Motivo:** O campo correto para identificar regras de Área Interna é `EscopoRegra__c` (na tabela de regras), não `TipoAreaParticipante__c` (que pertence ao registro de AreaParticipante__c sendo inserido).

### Tratamento de erro — distinção entre prioridade inválida e tempo nulo
**Antes:** mensagem genérica com "origem"
**Depois:** distingue `errMsg.contains('não suportada')` → prioridade inválida vs. tempo não configurado

## AreaParticipanteSelector.cls

### getEligibleAreaValuesForCase() — correção de filtro
**Antes:** `AND TipoAreaParticipante__c = 'Área Interna'`
**Depois:** `AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA`

**Motivo:** Consistência com findRule(). Filtra regras pelo escopo correto.

## AreaParticipanteService.cls

### addParticipation() — correção da mensagem de erro
**Antes:** "Não existe regra de SLA ativa para a categorização, área participante, origem e prioridade informadas."
**Depois:** "Não existe regra de SLA ativa para a categorização, área participante e prioridade informadas."

**Motivo:** Campo `Origem__c` foi removido no Pacote 16B. Mensagem removeu referência obsoleta.

### addParticipation() — campos no novo registro
**Adicionado:**
```apex
row.TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA;
row.OrigemAtuacao__c = 'Manual';
```

**Motivo:** Garante explicitamente que o registro criado via serviço é do tipo Área Interna e de origem Manual, independente de defaults de picklist. Isso dispara corretamente a lógica SLA no trigger.

## GestaoSLA__c — não é necessário filtro explícito
O filtro `Categorizacao__c = :c.Categorizacao__c` já restringe implicitamente à GestaoSLA__c correta, pois cada Categorizacao__c pertence a exatamente uma GestaoSLA__c. Adicionar filtro explícito exigiria SOQL extra para obter o Id via Categorizacao__c.
