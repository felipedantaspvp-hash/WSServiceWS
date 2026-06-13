# AI_WORKQUEUE.md — Protocolo de Trabalho Paralelo Claude + Codex

> Ambos os agentes devem ler este arquivo antes de iniciar qualquer tarefa.
> Atualizar a tabela de trabalho em andamento ao começar e ao concluir.

---

## Trabalho em andamento

| Agente | Branch | Arquivos bloqueados | Tarefa | Status |
|--------|--------|---------------------|--------|--------|
| Codex  | main   | `force-app/main/default/objects/Account/fields/Teste__c.field-meta.xml`, `docs/PROJECT_INDEX.md` | Excluir campo texto Teste em Account | ✅ concluído |
| Codex  | feat/codex/retrieve-entitlement-atendimento-salvador | `AI_WORKQUEUE.md`, `manifest/entitlement-atendimento-salvador.xml`, `force-app/main/default/entitlementProcesses/*`, `force-app/main/default/milestoneTypes/*`, `force-app/main/default/settings/BusinessHours.settings-meta.xml`, `force-app/main/default/settings/Entitlement.settings-meta.xml`, `docs/PROJECT_INDEX.md` | Baixar Entitlement Process ativo Atendimento Salvador v2 e dependências | ✅ concluído |
| —      | —      | —                   | —      | —      |

**Status válidos:** `🔄 em andamento` · `✅ concluído` · `⏸ pausado` · `🔀 merge pendente`

Limpe linhas com `✅` após o merge ser feito.

---

## Protocolo antes de editar

```text
1. Ler AI_WORKQUEUE.md.
2. Verificar se os arquivos que serão editados estão na coluna "Arquivos bloqueados".
3. Se estiverem livres → registrar a linha na tabela acima e iniciar.
4. Se estiverem bloqueados → trabalhar em branch separada e aguardar liberação.
5. Ao concluir → atualizar status para ✅ e indicar branch/PR.
```

---

## Divisão de domínio padrão

Define qual agente tem **preferência** para cada tipo de tarefa.
Não é exclusivo — qualquer agente pode atuar fora do seu domínio, mas o domínio preferencial reduz conflitos.

| Domínio | Agente preferencial | Motivo |
|---------|--------------------|---------| 
| Lógica Apex complexa (Service, Helper, ServiceAgent) | **Claude** | Análise de contexto longo, revisão de arquitetura |
| Revisão de código e code review | **Claude** | Raciocínio comparativo e memória de sessão |
| Segurança, permissões, CRUD/FLS | **Claude** | Checklist multi-layer e auditoria |
| Geração de boilerplate Apex / LWC | **Codex** | Velocidade, geração guiada por skill |
| Flows e automações declarativas | **Codex** | Geração direta de XML de metadados |
| Metadata XML (objetos, campos, layouts) | **Codex** | Geração em massa e deploy |
| Testes Apex | Qualquer um | Dependendo de quem alterou o código |
| Documentação e PROJECT_INDEX | Qualquer um | Quem tiver mais contexto da mudança |

---

## Convenção de branches

```text
feat/claude/[slug-da-tarefa]    ← Claude Code
feat/codex/[slug-da-tarefa]     ← Codex CLI
fix/claude/[slug-do-bug]
fix/codex/[slug-do-bug]
```

Exemplos:
```text
feat/claude/sla-marco-calculo
feat/codex/lwc-case-panel-botao
fix/claude/gestao-sla-query-bulk
```

---

## Regra de merge

1. O agente que criou a branch é responsável pelo merge ou PR.
2. Antes do merge, verificar se o outro agente não alterou os mesmos arquivos em outra branch.
3. Resolução de conflito: priorizar a versão mais recente salvo indicação contrária no commit.
4. Após merge, limpar a linha do AI_WORKQUEUE.md.

---

## Comunicação entre agentes

Agentes não se comunicam diretamente. A coordenação é feita por:

1. **AI_WORKQUEUE.md** — status de trabalho em andamento.
2. **Mensagens de commit** — descrever claramente o que foi alterado e por quê.
3. **PROJECT_INDEX.md** — manter atualizado após mudanças estruturais.
4. **docs/GESTAO_SLA_PROJECT_CONTEXT.md** — atualizar ao mudar arquitetura de domínio.

---

## Checklist de entrada (qualquer agente)

```text
[ ] Li AI_WORKQUEUE.md.
[ ] Os arquivos que vou editar estão livres.
[ ] Registrei minha tarefa na tabela acima.
[ ] Escolhi a branch correta (feat/[agente]/[tarefa]).
[ ] Consultei PROJECT_INDEX.md.
[ ] Consultei AI_HANDLERS.md.
```

## Checklist de saída (qualquer agente)

```text
[ ] Atualizei o status no AI_WORKQUEUE.md.
[ ] Commit com mensagem descritiva.
[ ] PROJECT_INDEX.md atualizado se houve mudança estrutural.
[ ] UTF-8 validado se alterei metadata.
[ ] Testes considerados se alterei Apex.
```
