# SKILL_SECURITY.md — Segurança e DevOps

> Carregar somente para tarefas: Permission Sets, Profiles, CRUD/FLS, Sharing, deploy, Flosum, pipeline, auditoria.

## Segurança

Sempre avaliar:

- **CRUD/FLS** — verificar acesso ao objeto e ao campo antes de query e DML.
- **Sharing** — definir `with sharing` / `without sharing` / `inherited sharing` conscientemente.
- **Permission Sets** — preferir Permission Sets a Profiles específicos.
- **Custom Permissions** — usar para controle de feature granular.
- **Apex Class Access** — garantir acesso no Permission Set correto.
- **Flow Access** — garantir que o Flow está acessível ao usuário/perfil/PS esperado.
- **RecordType access** — garantir visibilidade correta por perfil/PS.
- **Tab visibility** — garantir acesso à Tab quando aplicável.
- **Dados sensíveis/LGPD** — não expor dados sensíveis em log, resposta de API ou UI.
- **Segredos** — nunca hardcodar senha, token ou API key; usar Named Credential ou Custom Metadata protegida.

Detalhes: `docs/agent-reference/SALESFORCE_SECURITY_DEVOPS_GUIDE.md`

## DevOps / Flosum

Considerar quando a tarefa envolver deploy ou pipeline:

- Usar branch correto e snapshot no Flosum antes de alterar.
- Aplicar overwrite protection para metadados sensíveis.
- Exigir peer review antes de promover para produção.
- Validar/dry-run deploy antes de executar em produção.
- Registrar backpromotion quando necessário.
- Confirmar pipeline e ordem de deploy para dependências entre metadados.
- Após deploy crítico, verificar integridade na org destino.
