# SALESFORCE_BUILD_GUIDELINES.md

## Quando consultar

Leia este arquivo quando a tarefa envolver criação/alteração de objetos, campos, layouts, Lightning Pages, Validation Rules, LWC ou decisão entre configuração, Flow, Apex e LWC.

## Ordem de solução

```text
Configuração nativa > Flow > Apex > LWC
```

Nunca usar código customizado apenas por preferência.

## Idioma e multilíngue

Salesforce será administrado em inglês, mas clientes podem ter ambientes multilíngues.

Ao criar artefatos traduzíveis, avaliar/perguntar idiomas:

- Object Labels.
- Field Labels.
- Custom Labels.
- Picklist Values.
- Validation Rule messages.
- Flow labels/mensagens.
- Lightning Page labels.
- Help Text.

Traduções devem considerar contexto de negócio.

## Objetos personalizados

Todo objeto novo precisa de `Description` com finalidade, projeto, contexto e funcionalidade.

Antes de criar, avaliar:

- Reports.
- Activities.
- Track Field History.
- Name Text ou Auto Number.
- Allow Search.
- Tab.
- Record Types.
- Page Layout.
- Lightning Record Page.
- Permission Set.
- Relacionamento Master-Detail ou Lookup.
- Dados sensíveis/LGPD.

## Campos personalizados

Todo campo novo precisa de `Description` com finalidade, projeto, contexto, funcionalidade, origem e regra de preenchimento quando aplicável.

Regras:

- Permissão inicial apenas para Administrador padrão, salvo orientação diferente.
- Preferir Permission Sets a Profiles.
- Não usar prefixos como TCF, salvo padrão do cliente.
- Evitar preposições e nomes longos.
- Não usar campo tipo Time; usar Text quando necessário e documentar.
- Long Text/Rich Text com tamanho factível e sem excesso.
- Validar FLS, layout, Flow, Apex/LWC, relatório, integração, tradução e LGPD.

## Layouts e Lightning Pages

- Novos campos devem ir ao Page Layout padrão, salvo orientação contrária.
- Validar RecordTypes e Page Layout Assignment.
- Lightning Pages devem usar Field Section em vez de Record Detail, quando aplicável.
- Highlights Panel deve usar Dynamic Actions.
- Template padrão: Header and Right Sidebar.
- Perguntar o que fica na tela principal e na sidebar direita.
- Validar ativação por App, Profile, RecordType e Form Factor.

## Validation Rules

- Description deve explicar cenário e motivo.
- Mensagem deve ser clara e orientada à ação.
- Escopo restrito à finalidade.
- Avaliar impacto em integração, carga, Flow, Apex e testes.
- Usar Custom Permission para bypass governado quando aplicável.
- Rodar testes após criar/alterar.

## LWC

Usar LWC apenas se componentes padrão, App Builder, Dynamic Forms ou Screen Flow não atenderem.

Regras:

- Usar componentes base.
- Seguir SLDS.
- Ser acessível e responsivo.
- Tratar loading, error, empty e success.
- Não manter regra crítica apenas no front-end.
- Não expor dados indevidamente.
- Usar Custom Labels quando houver tradução.
