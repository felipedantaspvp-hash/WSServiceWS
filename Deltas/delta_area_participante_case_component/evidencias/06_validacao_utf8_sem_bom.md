# Evidência 06 — Validação UTF-8 sem BOM

**Data:** 2026-06-14

## Arquivos criados neste pacote

| Arquivo | Encoding | BOM | Status |
|---------|----------|-----|--------|
| `caseAreaParticipantePanel.html` | UTF-8 | Sem BOM | ✓ |
| `caseAreaParticipantePanel.js` | UTF-8 | Sem BOM | ✓ |
| `caseAreaParticipantePanel.css` | UTF-8 | Sem BOM | ✓ |
| `caseAreaParticipantePanel.js-meta.xml` | UTF-8 | Sem BOM (com `encoding="UTF-8"` no header XML) | ✓ |

## Verificação de caracteres especiais

Arquivos LWC contêm texto puro em ASCII/UTF-8. Strings em português presentes apenas em comentários e labels de UI (não em metadata XML implantável via Apex).

Nenhum caractere fora do range ASCII básico em arquivos `.js`.

String com acento no `.html` (ex.: `Conclusão`, `Área`) são texto puro UTF-8 — suportado pelo LWC runtime.

## Padrões proibidos verificados

Nenhuma ocorrência de caracteres corrompidos por re-encoding nos arquivos deste pacote. ✓
