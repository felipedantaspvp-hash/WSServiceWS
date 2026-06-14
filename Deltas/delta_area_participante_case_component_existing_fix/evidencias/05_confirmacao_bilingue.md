# Evidência 05 — Confirmação: componente permanece bilíngue

**Data:** 2026-06-14

## Estratégia de internacionalização

O componente usa `@salesforce/i18n/lang` para detectar o idioma da sessão:

```javascript
import LANG from '@salesforce/i18n/lang';
lang = (LANG || '').toLowerCase();
isEnglish = this.lang.startsWith('en');
labels = this.isEnglish ? { ...EN } : { ...PT };
```

## Label `refresh` adicionado em ambos os idiomas

| Idioma | Valor |
|--------|-------|
| EN | `'Refresh'` |
| PT | `'Atualizar'` |

## Demais labels (preservados sem alteração)

| Label | EN | PT |
|-------|----|----|
| `title` | Participant Areas | Áreas Participantes |
| `add` | Add area | Adicionar área |
| `close` | Close | Encerrar |
| `details` | Details | Detalhes |
| `closeTitle` | Close Participation | Encerrar Participação |
| `addTitle` | Add Participant Area | Adicionar Área Participante |
| `openGroup` | Open | Em aberto |
| `doneGroup` | Completed | Concluídas |
| `empty` | No active participant area... | Nenhuma área participante ativa... |

Bilinguismo preservado integralmente. ✓
