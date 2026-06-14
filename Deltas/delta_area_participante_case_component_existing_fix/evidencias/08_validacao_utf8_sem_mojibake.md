# Evidência 08 — UTF-8 sem BOM e ausência de mojibake

**Data:** 2026-06-14

## Encoding

| Arquivo | Encoding | BOM | Bytes iniciais (hex) |
|---------|----------|-----|----------------------|
| `caseAreasParticipantesPanel.html` | UTF-8 | **Sem BOM** ✓ | `3C 74 65` (`<te`) — BOM removido neste pacote |
| `caseAreasParticipantesPanel.js` | UTF-8 | Sem BOM | — |
| `caseAreasParticipantesPanel.css` | UTF-8 | Sem BOM | — |
| `caseAreasParticipantesPanel.js-meta.xml` | UTF-8 | Sem BOM | Com `encoding="UTF-8"` no header XML |

### Histórico da correção do HTML

O arquivo `caseAreasParticipantesPanel.html` continha BOM (`EF BB BF`) proveniente do retrieve da org.
Verificado via `[System.IO.File]::ReadAllBytes` (PowerShell): bytes iniciais eram `EF BB BF`.
BOM removido por reescrita binária sem alterar conteúdo. Bytes iniciais após correção: `3C 74 65`.

Nenhum outro arquivo funcional foi alterado nesta correção.

## Caracteres com acento (verificados no JS — labels PT)

| String | Encoding |
|--------|----------|
| `'Áreas Participantes'` | UTF-8 correto |
| `'Área Interna'` | UTF-8 correto |
| `'Resumo operacional'` | UTF-8 correto |
| `'Concluídas'` | UTF-8 correto |
| `'Encerrar Participação'` | UTF-8 correto |
| `'Adicionar Área Participante'` | UTF-8 correto |
| `'Atualizar'` (label refresh — novo) | UTF-8 correto |

## masterLabel no meta.xml

```xml
<masterLabel>Áreas Participantes SLA</masterLabel>
```

String com acento em UTF-8 válido. ✓

## Verificação de mojibake

Nenhum caractere corrompido por re-encoding nos arquivos alterados.
Os arquivos originais já estavam em UTF-8 correto; as adições deste pacote seguem o mesmo padrão. ✓
