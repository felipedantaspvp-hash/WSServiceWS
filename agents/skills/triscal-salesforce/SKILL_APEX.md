# SKILL_APEX.md — Regras Apex e Testes

> Carregar somente para tarefas: Apex, Trigger, Batch, Queueable, Schedulable, Invocable.

## Regras essenciais Apex

- Nunca SOQL em loop.
- Nunca DML em loop.
- Usar `List`, `Set` e `Map` para bulkificação.
- Bulkificar métodos — nunca assumir registro único.
- Evitar código monolítico; respeitar Controller/FlowAction → Service → ServiceAgent.
- Não usar IDs hardcoded.
- Não hardcodar ProfileName ou RecordTypeId.
- Usar Custom Metadata para regras configuráveis.
- Usar Named Credential para endpoint e autenticação.
- Tratar exceções com significado — nunca silenciar `catch` vazio.
- Não expor stack trace, token, senha ou API key em log ou resposta.
- Considerar sharing, CRUD e FLS em toda query e DML.

## Testes obrigatórios

- Criar/atualizar teste para todo Apex novo ou alterado.
- Não depender de dados reais — usar `@TestSetup` ou fábrica de dados.
- Usar mocks para callout (`HttpCalloutMock`).
- Usar `Test.startTest()` / `Test.stopTest()`.
- Preferir `Assert.areEqual`, `Assert.areNotEqual`, `Assert.isTrue`.
- Testar positivo, negativo, exceção e bulk quando aplicável.
- Buscar 95% de cobertura para código novo/alterado, salvo justificativa.

Detalhes: `docs/agent-reference/SALESFORCE_COMMENTS_TESTS_GUIDE.md`

## Comentários obrigatórios

Classes Apex novas ou alteradas de forma relevante devem ter cabeçalho:

```apex
/**
 * @description       : Responsabilidade principal da classe.
 * @author            : Triscal
 * @group             : Domínio ou módulo, quando aplicável.
 * @last modified on  : MM-DD-YYYY
 * @last modified by  : Responsável pela alteração
 **/
```

Métodos públicos, globais, invocable, aura-enabled, batch, schedulable, service, integração ou regra relevante devem ter `@description`, `@param` e `@return` quando aplicável.

Comentários devem explicar o **porquê**, não o óbvio. Código comentado temporário deve ter motivo e referência de chamado.
