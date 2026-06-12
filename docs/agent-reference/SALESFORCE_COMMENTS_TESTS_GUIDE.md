# SALESFORCE_COMMENTS_TESTS_GUIDE.md

## Quando consultar

Leia este arquivo quando criar/alterar Apex, LWC, testes, DTOs, ServiceAgents, Batch, Queueable ou precisar documentar código.

## Cabeçalho Apex

```apex
/**
 * @description       : Responsabilidade principal da classe.
 * @author            : Triscal
 * @group             : Domínio ou módulo, quando aplicável.
 * @last modified on  : MM-DD-YYYY
 * @last modified by  : Responsável pela alteração
 **/
```

Preservar padrão existente. Não alterar autoria original sem motivo. Não preencher informação falsa.

## Métodos Apex

Métodos públicos, globais, invocable, aura-enabled, batch, schedulable, queueable, service, integração ou regra relevante devem ter:

```apex
/**
 * @description Método responsável por explicar o que faz e por que existe.
 * @param nomeParametro Descrição do parâmetro.
 * @return TipoRetorno Descrição do retorno.
 **/
```

Método privado simples e autoexplicativo pode não precisar; método privado com regra de negócio deve ser comentado.

## Comentários de regra

Comentários explicam o porquê, não o óbvio.

Bom:

```apex
// Somente propostas ativas devem seguir para geração de contrato.
```

Ruim:

```apex
// Faz if
```

## Pendências e chamados

Código comentado temporário deve ter motivo e referência:

```apex
// Melhoria solicitada - Aguardando confirmação do chamado [TRSCL-9461]
// Campos abaixo dependem de validação funcional.
```

Sem motivo, remover código morto.

## LWC

Comentar métodos relevantes, transformações e chamadas Apex:

```javascript
/**
 * @description Carrega contratos relacionados e prepara dados para renderização.
 */
async carregarContratos() {}
```

## Testes Apex

Sempre que alterar Apex:

- Criar/atualizar teste.
- Não depender de dados reais.
- Usar mocks para callout.
- Usar `Test.startTest()` e `Test.stopTest()`.
- Preferir `Assert.areEqual`, `Assert.areNotEqual`, `Assert.isTrue`.
- Usar `Test.setCreatedDate()` quando necessário.
- Testar positivo, negativo, exceção e bulk quando aplicável.
- Validar comportamento, não apenas cobertura.
- Buscar 95% de cobertura para código novo/alterado, salvo justificativa.

## Arrange / Act / Assert

```apex
@IsTest
static void deveExecutarComSucesso() {
    // Arrange - cria massa mínima necessária.

    Test.startTest();
    // Act - executa método em teste.
    Test.stopTest();

    // Assert - valida comportamento esperado.
}
```
