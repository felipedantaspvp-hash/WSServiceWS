# Evidência 02 — Confirmação de Ausência de Uso Funcional dos Campos Legados

## Critério de verificação

Um campo é considerado sem uso funcional quando não aparece em:
- SELECT, WHERE, ORDER BY, GROUP BY de nenhum SOQL
- Atribuições de escrita (`r.Campo__c = ...`) em DML
- Leituras de valor (`variavel = r.Campo__c`) em lógica de negócio
- Condicionais, filtros ou cálculos baseados em seu valor
- Interfaces externas (LWC, DTO, Controller)

## `RegrasSLACategorizacao__c.Origem__c`

| Verificação | Resultado |
|------------|-----------|
| SELECT em qualquer Selector | Removido de todos (RegrasSLACategorizacaoSelector, AreaParticipanteSLAService, CategorizacaoSelector, GestaoSLAService) |
| WHERE/filtro em Selector | Removido de `findActiveRules`, `findActiveRulesNovoN3`, `AreaParticipanteSelector.findRule` |
| Chave única (`buildKeyNovo`) | Removido — chave passou de 6 para 5 parâmetros |
| DTO exposto ao front-end | Removido de `GestaoSLADTO.RegraSLAResumo` e `RegraSLARequest` |
| Escrita em DML | Removido de `CategorizacaoService.saveRegrasSla` |
| Lógica de fallback | Métodos `resolveByOrigemFallback` e `resolveByOrigemFallbackNovo` removidos |
| **Conclusão** | **Sem uso funcional** |

## `RegrasSLACategorizacao__c.VigenciaInicio__c` e `VigenciaFim__c`

| Verificação | Resultado |
|------------|-----------|
| SELECT em qualquer Selector | Removido de todos os Selectors |
| Validação de vigência | `isVigenciaValida` removido de `RegrasSLACategorizacaoHelper` e `RegrasSLACategorizacaoService` |
| Método `isVigente` | Removidos ambos os overloads de `RegrasSLACompatibilidadeService` |
| Filtro de data em Selectors | Removidos filtros `VigenciaInicio__c <= TODAY` e `VigenciaFim__c >= TODAY` |
| **Conclusão** | **Sem uso funcional** |

## `AreaParticipante__c.TipoAtuacao__c`

| Verificação | Resultado |
|------------|-----------|
| SELECT em qualquer Selector | Nenhuma referência encontrada no inventário |
| Lógica de classificação | `TipoAreaParticipante__c` é o campo oficial; `TipoAtuacao__c` nunca apareceu em lógica de negócio ativa |
| RecordTypes | Blocos `<picklistValues>TipoAtuacao__c</picklistValues>` removidos de 4 RecordTypes |
| Profile Admin | `fieldPermissions` removidas |
| **Conclusão** | **Sem uso funcional** |
