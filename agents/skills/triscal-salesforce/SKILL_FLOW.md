# SKILL_FLOW.md — Regras Flow

> Carregar somente para tarefas: Record-Triggered Flow, Autolaunched Flow, Scheduled Flow, Platform Event Flow, Screen Flow.

## Regras obrigatórias

- Todo Record-Triggered Flow deve ser bulk safe.
- Nunca Get/Create/Update/Delete dentro de Loop.
- Fazer Get **antes** do Loop.
- Montar coleções **durante** o Loop.
- Executar DML **uma vez após** o Loop.
- Validar campos antes de Assignment, Create ou Update.
- Considerar Fault Paths em Flows críticos.
- Considerar idempotência, reentrada e recursão.
- Não usar IDs hardcoded.
- Usar Flow Trigger Explorer quando houver múltiplos Flows no mesmo objeto.
- Descrever elementos críticos do Flow.

Detalhes: `docs/agent-reference/SALESFORCE_FLOW_GUIDE.md`
