---
name: triscal-salesforce
description: Índice da Skill Triscal Salesforce. Leia este arquivo primeiro, depois carregue apenas o fragmento relevante à tarefa. Aplica análise seletiva, arquitetura Controller→Service→ServiceAgent, declarativo-first, segurança, testes e resposta objetiva.
---

# Skill: Triscal Salesforce — Índice

## Fluxo obrigatório

1. Consulte `docs/PROJECT_INDEX.md`.
2. Identifique arquivos candidatos — abra somente os relevantes.
3. Carregue o fragmento da skill correspondente à tarefa (tabela abaixo).
4. Aplique `AI_HANDLERS.md`.
5. Verifique se precisa de detalhe em `docs/agent-reference/`.
6. Implemente a menor solução segura.

Não assumir nomes de classes, campos, objetos, RecordTypes, Flows, layouts ou permissões sem validar.

## Fragmento por tipo de tarefa

| Tarefa | Carregar |
|--------|----------|
| Apex, Trigger, Batch, Queueable, Schedulable, Invocable, Testes | `SKILL_APEX.md` |
| Flow (Record-Triggered, Autolaunched, Scheduled, Screen, Platform Event) | `SKILL_FLOW.md` |
| LWC, Aura, componente customizado em Screen Flow | `SKILL_LWC.md` |
| Objeto, campo, layout, FlexiPage, Validation Rule, Custom Label, deploy, retrieve | `SKILL_METADATA.md` |
| Permission Set, CRUD/FLS, Sharing, Flosum, pipeline, auditoria | `SKILL_SECURITY.md` |

Tarefas que cruzam domínios (ex: Apex + deploy) → carregue os dois fragmentos relevantes.

## Ordem de solução Salesforce

```text
Configuração nativa > Flow > Apex > LWC
```

Use Apex quando houver volume, integração, transação, lógica complexa, processamento assíncrono ou necessidade de controle fino.

Use LWC apenas quando componentes padrão, App Builder, Dynamic Forms ou Screen Flow não atenderem.

## Arquitetura obrigatória

```text
LWC / Visualforce / Flow / API
        ↓
Controller / FlowAction      ← recebe, delega, retorna
        ↓
Service                      ← regra de negócio
        ↓
ServiceAgent / Helper / Selector  ← integração externa / consulta
        ↓
Sistema externo / SObject / Metadata
```

- Trigger contém apenas roteamento.
- DTOs representam payloads estruturados.
- Não fazer SOQL/DML em loop.
- Não usar IDs hardcoded.

## Formato de resposta

```text
Conclusão:
...

Arquivos analisados:
- ...

Alteração proposta/realizada:
- ...

Risco:
Baixo/Médio/Alto — motivo.

Testes:
- ...

Próximo passo:
...
```

Para correção simples:

```text
Causa:
...

Correção:
...

Teste:
...
```
