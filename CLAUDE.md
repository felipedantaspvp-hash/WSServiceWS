# CLAUDE.md — Claude Code Bootstrap

> Arquivo de boot para Claude Code. Regras completas do projeto estão em `AGENTS.md`.
> Não duplique conteúdo — referencie.

## Sequência de boot obrigatória

1. Consulte `AI_WORKQUEUE.md` — verifique arquivos em uso pelo Codex antes de editar.
2. Consulte `docs/PROJECT_INDEX.md` — identifique arquivos relevantes à tarefa.
3. Consulte `AI_HANDLERS.md` — aplique os quality gates.
4. Para tarefas Salesforce, ative skills via `/skill [nome]` (ex: `/skill generating-apex`).
5. Leia `AGENTS.md` somente se precisar de detalhe de arquitetura ou regra específica.

## Regras Claude-específicas

- Prefira ferramentas nativas (Glob, Grep, Read) antes de Bash.
- Não carregue arquivos inteiros se o PROJECT_INDEX.md já orientar os trechos relevantes.
- Use memória persistente para capturar decisões de arquitetura entre sessões.
- Formato de resposta esperado: ver `AGENTS.md` seção "Formato de resposta esperado".

## Alimentação obrigatória do PROJECT_INDEX.md

Ao concluir qualquer tarefa que revele ou crie conhecimento novo sobre o projeto, atualize `docs/PROJECT_INDEX.md` **antes de encerrar a resposta**.

Atualizar quando houver:

- Nova classe, método público relevante, trigger ou batch descoberto ou criado.
- Novo objeto, campo, RecordType, Custom Metadata ou Named Credential.
- Novo LWC, Flow, FlexiPage ou layout relevante.
- Nova integração, endpoint ou ServiceAgent.
- Mudança de arquitetura (ex: nova camada, novo padrão adotado).
- Bug relevante corrigido que revele comportamento importante.
- Nova regra de negócio identificada que ainda não estava documentada.

Regras de escrita no PROJECT_INDEX.md:

- Apenas referências estruturais — nunca copiar código inteiro.
- Uma linha por artefato: nome, caminho, responsabilidade em uma frase.
- Atualizar seção existente se o artefato já estiver listado (não duplicar).
- Manter o índice como o menor mapa útil do projeto.

## Skill do projeto (Salesforce)

Para qualquer tarefa Salesforce, leia `agents/skills/triscal-salesforce/SKILL.md` (índice ~2KB) e depois **apenas o fragmento relevante**:

| Tarefa | Fragmento |
|--------|-----------|
| Apex, Trigger, Batch, Testes | `SKILL_APEX.md` |
| Flow (qualquer tipo) | `SKILL_FLOW.md` |
| LWC / Aura | `SKILL_LWC.md` |
| Objeto, campo, layout, deploy, UTF-8 | `SKILL_METADATA.md` |
| Permissões, CRUD/FLS, Flosum | `SKILL_SECURITY.md` |

Tarefas multi-domínio → carregar os fragmentos relevantes.

## Skills oficiais Salesforce

Skills da biblioteca oficial estão em `.agents/skills/`. Use via `/skill [nome]`:

| Tarefa | Skill |
|--------|-------|
| Gerar Apex / Testes | `/skill generating-apex` · `/skill generating-apex-test` |
| Gerar LWC | `/skill generating-lwc-components` |
| Deploy / Retrieve | `/skill deploying-metadata` |
| Debug logs | `/skill debugging-apex-logs` |
| Segurança | `/skill generating-permission-set` |

## Coordenação com Codex

- Branch padrão: `feat/claude/[tarefa]`
- Domínio preferencial Claude: lógica Apex complexa, revisão de código, segurança, arquitetura.
- Antes de editar qualquer arquivo, registre no `AI_WORKQUEUE.md`.
- Se um arquivo estiver marcado como em uso pelo Codex, trabalhe em branch separada ou aguarde.

## Referências sob demanda

| Tema | Arquivo |
|------|---------|
| Arquitetura e convenções | `AGENTS.md` |
| Quality gates (11 handlers) | `AI_HANDLERS.md` |
| Mapa do projeto | `docs/PROJECT_INDEX.md` |
| Coordenação paralela | `AI_WORKQUEUE.md` |
| Revisão de código (achados priorizados + correção) | `CodeReview.md` |
| Contexto SLA | `docs/GESTAO_SLA_PROJECT_CONTEXT.md` |
| Guias detalhados | `docs/agent-reference/SALESFORCE_[TEMA]_GUIDE.md` |
