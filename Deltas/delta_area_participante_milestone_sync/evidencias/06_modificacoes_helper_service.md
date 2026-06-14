# Evidência 06 — Modificações em AreaParticipanteSLAHelper e AreaParticipanteSLAService

**Data:** 2026-06-14

## AreaParticipanteSLAHelper.cls

**Adição:** Constante `ORIGEM_SLA_STANDARD`

```apex
public static final String ORIGEM_SLA_CUSTOM    = 'Custom';   // pré-existente
public static final String ORIGEM_SLA_STANDARD  = 'Standard'; // NOVO — linha 16
```

Sem alteração de nenhum método existente.

---

## AreaParticipanteSLAService.cls

### Modificação 1 — beforeSave (guard de Standard)

Linha adicionada após a verificação `isTipoInterna` existente:

```apex
// Linha 17 — antes: não existia
if (AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) continue;
```

**Efeito:** Registros Standard com `TipoAreaParticipante__c = 'Área Interna'` (Atendimento N3)
nunca passam pela validação de Caso/Área obrigatória, evitando erro "Caso e Área são obrigatórios".

### Modificação 2 — closeSLA (preservação de StatusSLA__c)

```apex
// ANTES (lógica original):
if (AreaParticipanteSLAHelper.isConcluida(a.StatusAtuacao__c)) a.StatusSLA__c = STATUS_SLA_CONCLUIDO;
if (AreaParticipanteSLAHelper.isCancelada(a.StatusAtuacao__c)) a.StatusSLA__c = STATUS_SLA_CANCELADO;

// DEPOIS (com guard):
if (!AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD.equals(a.OrigemSLA__c)) {
    if (AreaParticipanteSLAHelper.isConcluida(a.StatusAtuacao__c)) a.StatusSLA__c = STATUS_SLA_CONCLUIDO;
    if (AreaParticipanteSLAHelper.isCancelada(a.StatusAtuacao__c)) a.StatusSLA__c = STATUS_SLA_CANCELADO;
}
a.BloqueiaFechamentoCaso__c = false;
```

**Efeito:** Para registros Standard com milestone concluído+violado, `StatusSLA__c` permanece
'Vencido' (definido em buildRecord) em vez de ser sobrescrito para 'Concluído'.

## Impacto em lógica Custom

Nenhuma linha da lógica Custom foi alterada. Os guards adicionados têm condição `!ORIGEM_SLA_STANDARD`,
portanto Custom continua com comportamento idêntico ao anterior.
