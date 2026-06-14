# Evidência 03 — Mapeamento de MilestoneType para TipoAreaParticipante__c

**Data:** 2026-06-14 (revisado)

## Tabela de mapeamento

| MilestoneType.Name (original) | Chave normalizada | TipoAreaParticipante__c |
|-------------------------------|-------------------|--------------------------|
| Triagem | `triagem` | Categorização Inicial |
| Resposta Chat | `resposta chat` | Categorização Inicial |
| Primeira Resposta (Fila N2) | `primeira resposta fila n2` | Tratamento Primário |
| Atendimento | `atendimento` | Tratamento Primário |
| ~~Atendimento N3~~ | ~~`atendimento n3`~~ | **Não mapeado** — ver nota abaixo |
| Retorno N3 | `retorno n3` | Retorno ao Cliente |
| Acompanhamento | `acompanhamento` | Retorno ao Cliente |
| SLA Total | `sla total` | **Tempo Total de Atendimento** |

## Normalização

A normalização usa `AreaParticipanteHelper.normalizeText()`:
1. Lowercase
2. Substituição de acentos (á→a, ç→c, etc.)
3. `replaceAll('[^a-z0-9 ]', ' ')` — remove parênteses, símbolos
4. `replaceAll('\\s+', ' ').trim()` — colapsa espaços

Exemplo crítico: `'Primeira Resposta (Fila N2)'` → `'primeira resposta fila n2'` (parênteses removidos).

## Milestone não mapeado — comportamento

Se `AreaParticipanteHelper.normalizeText(MilestoneType.Name)` não estiver no mapa `TIPO_BY_MILESTONE`,
o registro é **ignorado silenciosamente** em `syncInternal` (sem erro, sem DML).
Isso protege o batch de falhar em novos milestones futuros.

## Decisão sobre 'Atendimento N3'

`'Atendimento N3'` foi removido do mapa porque mapeá-lo para `TipoAreaParticipante__c = 'Área Interna'`
exigiria validações de `Caso__c` e `AreaAtendimento__c` que não se aplicam a espelhos Standard.
O mapeamento só deve ser adicionado com decisão explícita de negócio sobre qual Área usar.

## Campo NomeMarco__c

- Para todos os milestones: `NomeMarco__c = MilestoneType.Name` (nome original)
- **Exceção — SLA Total:** `NomeMarco__c = 'Tempo Total de Atendimento'` (conforme especificação)

## Picklist TipoAreaParticipante__c — mudança neste pacote

`'SLA Total'` foi **removido** do picklist. Substituído por `'Tempo Total de Atendimento'`.
O campo `TipoAreaParticipante__c.field-meta.xml` é incluído no deploy deste pacote.
