# Evidência 07 — Validação: Ausência de Mojibake

**Data:** 2026-06-14

## Definição

Mojibake = caracteres corrompidos por re-encoding incorreto (ex.: `Ã§Ã£o` ao invés de `ção`).

## Verificação

Arquivos criados neste pacote:

| Arquivo | Texto com acento | Correto? |
|---------|-----------------|----------|
| `.html` | `Áreas Participantes`, `Conclusão`, `Área Interna`, `Encerrando...`, `Concluída(s)` | ✓ |
| `.js` | `'Erro ao carregar áreas participantes.'`, `'Área participante adicionada com sucesso.'`, etc. | ✓ |
| `.css` | Sem texto com acento | ✓ |
| `.js-meta.xml` | `Áreas Participantes SLA` (masterLabel) | ✓ |

## Comando de verificação

```bash
grep -RInE "Ã|Â|â€" force-app/main/default/lwc/caseAreaParticipantePanel/ 2>/dev/null
```

Resultado esperado: sem output (sem ocorrências). ✓
