# MIGRATION_GUIDE.md — Como aplicar a versão otimizada

## Objetivo

Reduzir consumo de tokens e manter qualidade separando instruções curtas de referências detalhadas.

## Passos

1. Fazer backup dos arquivos atuais:
   - `AGENTS.md`
   - `AI_HANDLERS_TRISCAL.md`
   - `.agents/skills/triscal-salesforce/SKILL.md`

2. Substituir:
   - `AGENTS.md` pelo novo `AGENTS.md`.
   - `AI_HANDLERS_TRISCAL.md` pelo novo `AI_HANDLERS.md` ou renomear o novo arquivo para `AI_HANDLERS_TRISCAL.md`.
   - `.agents/skills/triscal-salesforce/SKILL.md` pelo novo `SKILL.md`.

3. Criar a pasta:
   - `docs/agent-reference/`

4. Adicionar os arquivos de referência:
   - `SALESFORCE_BUILD_GUIDELINES.md`
   - `SALESFORCE_FLOW_GUIDE.md`
   - `SALESFORCE_METADATA_GUIDE.md`
   - `SALESFORCE_COMMENTS_TESTS_GUIDE.md`
   - `SALESFORCE_SECURITY_DEVOPS_GUIDE.md`

5. Criar ou atualizar:
   - `docs/PROJECT_INDEX.md`

## Regra de uso

O Codex deve ler primeiro:

```text
AGENTS.md
AI_HANDLERS.md
docs/PROJECT_INDEX.md
.agents/skills/triscal-salesforce/SKILL.md
```

E só depois carregar `docs/agent-reference/*` quando a demanda pedir detalhe.

## Resultado esperado

- Menos tokens no início da tarefa.
- Menos duplicidade.
- Mais contexto útil.
- Menor chance de alucinação.
- Melhor governança por tema.
