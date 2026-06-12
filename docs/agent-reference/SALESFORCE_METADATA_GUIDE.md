# SALESFORCE_METADATA_GUIDE.md

## Quando consultar

Leia este arquivo quando precisar decidir como consultar dados, metadados, permissões, layout, Flow ativo, source x org, cobertura ou logs.

## Matriz de decisão

| Necessidade | Fonte |
|---|---|
| Source versionado | Arquivos locais |
| Estrutura objeto/campo | Describe / sObject Describe |
| Dados de negócio | SOQL / REST |
| Apex, FlowDefinition, cobertura, logs técnicos | Tooling API |
| XML, retrieve, deploy, layout, Flow completo | Metadata API / SF CLI |
| Experiência efetiva do usuário | UI API |
| Auditoria e execução | Setup Audit Trail, EventLogFile, ApexLog, AsyncApexJob |

## Ordem recomendada

```text
1. PROJECT_INDEX.md
2. Arquivos locais
3. Describe
4. SOQL para dados
5. Tooling API
6. Metadata API / SF CLI
7. UI API
8. Logs/Auditoria
```

## Nunca assumir

- Campo existe ou é editável.
- Campo está no layout.
- Campo está liberado por FLS.
- RecordType existe.
- Flow está ativo.
- Layout está atribuído ao perfil correto.
- Lightning Page está ativada para app/perfil/RecordType.
- Permission Set concede acesso.
- Named Credential existe.
- Custom Metadata está configurado.
- Org está igual ao source.

## Source x org

Quando houver divergência:

```text
Metadado:
Fonte local:
Fonte org:
Diferença:
Impacto:
Correção:
```

## Flow na org

Validar arquivo local, versão ativa, FlowDefinition, objeto, tipo, critérios, loops, DML, subflows, Apex invocável, fault paths e dependências.

## Layout/FlexiPage

Validar arquivo local, retrieve se necessário, Page Layout Assignment, RecordType, Profile/Permission Set, FLS, actions, related lists, ativação, componentes condicionais e Dynamic Forms.

## Permissões

Avaliar Profile, Permission Set, Permission Set Group, Object Permission, FLS, Apex Class Access, Flow Access, Custom Permission, Tab Visibility, RecordType access, Sharing, OWD e Restriction Rules.
