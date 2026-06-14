# 06 - Implementação: closeParticipation → Orquestração de Etapa

## Bloco substituído

### Antes (original)

```apex
Integer openRemaining = 0;
for (AreaParticipante__c other : remainingRows) {
    if (other.Id == row.Id) continue;
    if (AreaParticipanteHelper.isAbertaOuAndamento(other.StatusAtuacao__c) || isOverdue(...)) {
        openRemaining++;
    }
}
Boolean etapaUpdated = false;
String novaEtapa;
List<String> warnings = new List<String>();
if (openRemaining == 0 && Case.EtapaAtendimento__c.getDescribe().isUpdateable()) {
    String current = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
    if (String.isBlank(current) || current.contains('aguardando') || current.contains('area interna') || current.contains('area')) {
        caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
        etapaUpdated = true;
        novaEtapa = caseRow.EtapaAtendimento__c;
    }
}
```

### Depois (Pacote 21)

```apex
Integer openCustomInterna = 0;
for (AreaParticipante__c other : remainingRows) {
    if (other.Id == row.Id) continue;
    if (!AreaParticipanteSLAHelper.TIPO_AREA_INTERNA.equals(other.TipoAreaParticipante__c)) continue;
    if (!other.BloqueiaFechamentoCaso__c) continue;
    if (AreaParticipanteHelper.isAbertaOuAndamento(other.StatusAtuacao__c) || isOverdue(...)) {
        openCustomInterna++;
    }
}
Boolean etapaUpdated = false;
String novaEtapa;
List<String> warnings = new List<String>();

String etapaNormClose = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
Boolean caseIsTerminal = etapaNormClose.contains('conclu') || etapaNormClose.contains('cancel');

if (!caseIsTerminal && Case.EtapaAtendimento__c.getDescribe().isUpdateable() && openCustomInterna == 0) {
    caseRow.EtapaAtendimento__c = 'Preparando Retorno ao Cliente';
    etapaUpdated = true;
    novaEtapa = caseRow.EtapaAtendimento__c;
}
```

## Mudanças e razões

| Mudança | Razão |
|---|---|
| `openRemaining` → `openCustomInterna` | Contar apenas Custom Interna (excluir Standard e não-Interna) |
| Filtro `TipoAreaParticipante__c = 'Área Interna'` | Excluir marcos SLA e outros tipos |
| Filtro `BloqueiaFechamentoCaso__c = true` | Proxy para Custom aberta (Standard sempre tem = false) |
| Guard `caseIsTerminal` | Não sobrescrever etapa de Case 'Concluído' ou 'Cancelado' |
| Removida condição `current.contains(...)` | Desnecessária após guard terminal; simplifica a lógica |

## Dados de output não alterados

`etapaAtualizada`, `novaEtapa` e `warnings` da `CloseResponseDTO` mantêm semântica idêntica.
