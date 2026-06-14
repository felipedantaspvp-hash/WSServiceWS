# Evidência 08 — Pendências e Próximos Pacotes

**Data:** 2026-06-14

## Pendências deste pacote

| Item | Motivo |
|------|--------|
| Deploy na org não realizado | Aguardando validação manual e aprovação |
| Componente não adicionado à FlexiPage do Case | Fora do escopo do Pacote 18 |
| Jest não configurado | Projeto sem `jest.config.js`; criação do zero fora do escopo |

## Próximos pacotes recomendados

### Pacote 19 — FlexiPage: Adicionar componente ao layout do Case

- Incluir `caseAreaParticipantePanel` na Record Page do Case via App Builder ou FlexiPage XML
- Definir posição no layout (sugestão: coluna direita, abaixo de detalhes do caso)
- Documentar flexipage alterada no package.xml

### Pacote 20 — Permissões de acesso ao componente

- Avaliar se é necessário Permission Set para expor o LWC a perfis não-Admin
- Criar Permission Set se necessário; documentar escopo de acesso
- Verificar FLS de `AreaParticipante__c` para perfis de atendimento

### Pacote 21 — Jest para o LWC (opcional)

- Configurar `@salesforce/sfdx-lwc-jest` no projeto
- Criar testes unitários para `caseAreaParticipantePanel`
- Cobrir: carregamento, modal de acionamento, modal de conclusão, estados de erro

### Observações de governança

- O campo `AreaParticipante__c.Solicitante__c` é populado se `isCreateable()` → verificar permissão para perfis de atendimento
- O campo `AreaParticipante__c.FinalizadoPor__c` é populado se `isUpdateable()` → verificar permissão
- `canManage` retornado pelo backend depende de `Schema.sObjectType.AreaParticipante__c.isUpdateable()` — se atendente não tiver permissão de update, o botão "Acionar" não aparecerá
