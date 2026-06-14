# Evidência 03 — Mapeamento de MilestoneType para TipoAreaParticipante__c

**Data:** 2026-06-14

## Tabela de mapeamento

| MilestoneType.Name (original) | Chave normalizada | TipoAreaParticipante__c |
|-------------------------------|-------------------|--------------------------|
| Triagem | `triagem` | Categorização Inicial |
| Resposta Chat | `resposta chat` | Categorização Inicial |
| Primeira Resposta (Fila N2) | `primeira resposta fila n2` | Tratamento Primário |
| Atendimento | `atendimento` | Tratamento Primário |
| Atendimento N3 | `atendimento n3` | Área Interna |
| Retorno N3 | `retorno n3` | Retorno ao Cliente |
| Acompanhamento | `acompanhamento` | Retorno ao Cliente |
| SLA Total | `sla total` | SLA Total |

## Normalização

A normalização usa `AreaParticipanteHelper.normalizeText()`:
1. Lowercase
2. Substituição de acentos (á→a, ç→c, etc.)
3. `replaceAll('[^a-z0-9 ]', ' ')` — remove parênteses, símbolos
4. `replaceAll('\\s+', ' ').trim()` — colapsa espaços

Exemplo crítico: `'Primeira Resposta (Fila N2)'` → `'primeira resposta fila n2'` (parênteses removidos).

## Campo NomeMarco__c

- Para todos os milestones: `NomeMarco__c = MilestoneType.Name` (nome original)
- **Exceção — SLA Total:** `NomeMarco__c = 'Tempo Total de Atendimento'` (conforme especificação)

## Limitação documentada

O picklist `TipoAreaParticipante__c` não possui o valor `'Tempo Total de Atendimento'`.
Solução adotada: usar `TipoAreaParticipante__c = 'SLA Total'` (valor existente) e armazenar `'Tempo Total de Atendimento'` em `NomeMarco__c` (campo de texto livre).
