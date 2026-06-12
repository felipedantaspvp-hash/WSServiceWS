# SALESFORCE_SECURITY_DEVOPS_GUIDE.md

## Quando consultar

Leia este arquivo quando a tarefa envolver segurança, permissões, dados sensíveis, integração, deploy, Flosum ou ambientes.

## Segurança

Sempre avaliar:

- CRUD/FLS.
- Sharing.
- Permission Sets.
- Profiles.
- Custom Permissions.
- Apex Class Access.
- Flow Access.
- RecordType access.
- Tab visibility.
- Dados sensíveis/LGPD.
- Logs com dados confidenciais.
- Segredos em código/metadados.

## Permissionamento

Preferência Triscal:

```text
Permission Sets > Profiles específicos
```

Evitar criar Profiles específicos sem necessidade.

Quando criar objeto/campo:

```text
O acesso será controlado por Permission Set ou Profile?
Recomendação Triscal: Permission Sets.
```

## Segredos

Nunca expor:

- Token.
- Senha.
- API Key.
- Segredo.
- Stack trace ao usuário final.
- Payload sensível em log.

Usar Named Credential / External Credential para autenticação e segredos. Custom Metadata é para configuração, não cofre de segredo.

## Integrações

Validar:

- Named Credential.
- External Credential/Auth Provider quando aplicável.
- Custom Metadata com paths/configuração.
- Remote Site Settings se legado.
- ServiceAgent.
- DTO request/response.
- Logs.
- Status HTTP.
- Timeout.
- Payload enviado/recebido.
- Tratamento de erro.

## Flosum / DevOps

Quando envolver deploy:

- Preservar rastreabilidade.
- Identificar branch, pacote, ambiente e metadados.
- Considerar UAT, SIT, QA, Hotfix e Produção.
- Validar dependências.
- Considerar testes obrigatórios.
- Avaliar rollback.
- Considerar backpromotion.
- Não remover metadados sem impacto validado.

Separar erros:

```text
Deploy
Validação
Consulta de status
Dependência
Permissão
Metadado
Teste
Versão/API
```

Conceitos:

```text
Branch
Snapshot
Predeploy Fix
Overwrite Protection
Peer Review
Aprovação técnica
Aprovação de negócio
Pipeline
Deploy
Backpromotion
```
