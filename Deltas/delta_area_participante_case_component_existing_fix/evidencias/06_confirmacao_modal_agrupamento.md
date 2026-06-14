# Evidência 06 — Confirmação: modal de detalhes e agrupamentos preservados

**Data:** 2026-06-14

## Modal de Detalhes

A funcionalidade de modal de detalhes foi preservada integralmente.

### Trigger no HTML
```html
<lightning-button variant="base" label={labels.details} data-id={item.id} onclick={handleViewDetails}></lightning-button>
```

### Handler no JS
```javascript
async handleViewDetails(event) {
    const itemId = event.currentTarget.dataset.id;
    const detail = await getParticipationDetails({ areaParticipanteId: itemId });
    this.selectedItem = detail?.item;
    this.showDetailModal = true;
}
```

### Modal HTML (showDetailModal)
Exibe: área, status, comentário de solicitação, comentário de retorno, solução — todos readonly. ✓

## Agrupamento Aberto / Concluído

| Grupo | Getter | Comportamento |
|-------|--------|---------------|
| Em aberto | `openItems` | `!isConcluida && !isCancelada` — expansível, aberto por padrão |
| Concluídas | `doneItems` | `isConcluida || isCancelada` — expansível, fechado por padrão |

Ambos os grupos têm `toggleOpenGroup()` / `toggleDoneGroup()` com ícone chevron colapsável.

## Status Pills (buildClassificationPills)

8 variações preservadas: `paused`, `done-violated`, `done-intime`, `cancelled-violated`, `cancelled`, `overdue`, `in-time`, `open`. ✓
