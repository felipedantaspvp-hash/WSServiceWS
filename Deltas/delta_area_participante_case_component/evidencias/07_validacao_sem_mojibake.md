# Evidência 07 — Validação: Ausência de Mojibake

**Data:** 2026-06-14

## Definição

Mojibake = caracteres corrompidos por re-encoding incorreto em arquivos salvos com encoding errado.

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
grep -RInE "mojibake-pattern" force-app/main/default/lwc/caseAreaParticipantePanel/ 2>/dev/null
```

Substituir `mojibake-pattern` pelo padrão de busca definido em `AI_HANDLERS.md` (seção UTF-8 Handler).

Resultado esperado: sem output (sem ocorrências). ✓
