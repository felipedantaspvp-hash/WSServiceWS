# Evidência 07 — Mudanças Apex v2

Complementa a evidência `04_mudancas_apex.md` (v1 do Pacote 17A).

## AreaParticipanteSLAService.cls

### SequenciaAcionamento__c — sequência global por Case (era por Case+Area)

**Antes:** cada área reiniciava a sequência a partir do máximo de registros da mesma área no mesmo Case.

**Depois:** sequência é global por Case — independente da área, cada novo AreaParticipante__c no mesmo Case recebe o próximo número na sequência.

```apex
// Coleta máximo global por Case
Map<Id, Integer> maxSeqByCaseId = new Map<Id, Integer>();
for (AggregateResult ar : [
    SELECT Caso__c c, MAX(SequenciaAcionamento__c) m
    FROM AreaParticipante__c
    WHERE Caso__c IN :caseIds
    GROUP BY Caso__c
]) {
    maxSeqByCaseId.put((Id) ar.get('c'), ((Decimal) ar.get('m')).intValue());
}
// Atribuição
Integer seq = maxSeqByCaseId.containsKey(a.Caso__c) ? maxSeqByCaseId.get(a.Caso__c) + 1 : 1;
a.SequenciaAcionamento__c = seq;
maxSeqByCaseId.put(a.Caso__c, seq);
```

### findRule() — filtro GestaoSLA__c explícito

**Antes:** não filtrava por GestaoSLA__c; a Categorizacao__c como único filtro poderia retornar regras de outra GestaoSLA__c se houvesse sobreposição.

**Depois:** recupera GestaoSLA__c via `c.getSObject('Categorizacao__r')` e aplica filtro explícito na query.

```apex
SObject categRel = c.getSObject('Categorizacao__r');
Id gestaoId = categRel != null ? (Id) categRel.get('GestaoSLA__c') : null;
if (gestaoId == null) return null;
// Query inclui: AND GestaoSLA__c = :gestaoId
```

**Por quê getSObject em vez de getPopulatedFieldsAsMap():** `getSObject` é a API canônica do Apex para acessar SObjects de relacionamento. `getPopulatedFieldsAsMap()` pode não conter a chave `'Categorizacao__r'` dependendo do contexto de execução.

## AreaParticipanteSelector.cls

### getCaseById() — inclui Categorizacao__r.GestaoSLA__c no SELECT

**Motivo:** necessário para que `findRule()` e `getEligibleAreaValuesForCase()` possam usar `getSObject('Categorizacao__r')`.

### getEligibleAreaValuesForCase() — filtro GestaoSLA__c explícito

**Antes:** filtrava apenas por `Categorizacao__c` e `EscopoRegra__c`.

**Depois:** também filtra por `GestaoSLA__c`. Usa try-catch para `SObjectException` pois o Case pode ser injetado em testes sem o relacionamento no SOQL.

```apex
Id gestaoId;
try {
    SObject categRel = caseRow.getSObject('Categorizacao__r');
    gestaoId = categRel != null ? (Id) categRel.get('GestaoSLA__c') : null;
} catch (SObjectException ex) {}
if (gestaoId == null) return out;
// Query inclui: AND GestaoSLA__c = :gestaoId
```

## AreaParticipanteSLAServiceTest.cls

### createRegraNova() — removido parâmetro MarcoSLA__c

**Motivo:** regras de Area Interna não requerem MarcoSLA__c. O campo `<required>false</required>` na metadata.

Assinatura anterior: `createRegraNova(Id categId, Id gestaoId, Id marcoSlaId, String area, String escopo)`
Assinatura nova: `createRegraNova(Id categId, Id gestaoId, String area, String escopo)`

### Novo teste: testSequenciaGlobalPorCaseNaoPorArea

Verifica comportamento da sequência global:
1. Area1 inserida → seq = 1
2. Area2 (área diferente) inserida no mesmo Case → seq = 2 (não reinicia)

## AreaParticipanteTestDataFactory.cls

### Introduzido createSharedGestao()

Cria uma única GestaoSLA__c por setup de Case. Todas as regras criadas para o mesmo Case compartilham o mesmo GestaoSLA__c, garantindo que o filtro em findRule() e getEligibleAreaValuesForCase() encontre as regras corretamente.

**Causa do problema anterior:** factory criava GestaoSLA__c diferente para cada regra. Com o novo filtro explícito, o Case aponta para gestao1, mas regra de area2 aponta para gestao2 → nenhuma correspondência → "Não existe regra de SLA ativa".

## AreaParticipanteSLABatchTest.cls

### createRule() — atualiza Categorizacao.GestaoSLA__c após criar regra

**Motivo:** `createCategorizacao()` no batch test não pré-vincula GestaoSLA__c. Após criar a GestaoSLA__c e a regra, agora atualiza o registro Categorizacao__c para apontar para essa GestaoSLA__c, habilitando o filtro a funcionar.

### Removido MarcoSLA__c

Consistente com a mudança nas outras classes de teste — Area Interna não requer MarcoSLA__c.
