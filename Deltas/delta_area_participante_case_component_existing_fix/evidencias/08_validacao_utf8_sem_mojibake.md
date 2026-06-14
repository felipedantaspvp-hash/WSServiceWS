# Evidência 08 — UTF-8 sem BOM e ausência de mojibake

**Data:** 2026-06-14

## Encoding

| Arquivo | Encoding | BOM |
|---------|----------|-----|
| `caseAreasParticipantesPanel.html` | UTF-8 | Sem BOM |
| `caseAreasParticipantesPanel.js` | UTF-8 | Sem BOM |
| `caseAreasParticipantesPanel.css` | UTF-8 | Sem BOM |
| `caseAreasParticipantesPanel.js-meta.xml` | UTF-8 | Sem BOM (com `encoding="UTF-8"` no header XML) |

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
