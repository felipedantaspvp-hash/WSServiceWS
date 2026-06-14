# Pacote 15B Fix — Correcao da Refatoracao Tipo de Regra SLA

## Objetivo

Corrigir os pontos reprovados do Pacote 15B sem alterar dados existentes,
sem remover valores antigos do picklist e sem criar destructiveChanges.

## Pontos corrigidos

| # | Ponto | Correcao |
|---|---|---|
| 1 | Metadata EscopoRegra__c ausente no delta 15B | Incluido com descricao corrigida |
| 2 | LWC exibia Marco SLA para Area Interna | Marco SLA visivel apenas via isTipoAtendimento |
| 3 | Apex gravava AreaAtendimento__c para Atendimento | Forcado null para Atendimento |
| 4 | Apex nao garantia MarcoSLA__c = null para Area Interna | Forcado null para Area Interna + teste |
| 5 | Duplicidade Area Interna nao considerava Categorizacao__c | SOQL corrigido com filtro por Categorizacao__c |
| 6 | Validacao de vigencia ainda existia no Apex | Bloco removido de validateRegraSLARequest |
| 7 | Residuos de Origem/Vigencia na LWC | Getters e mapeamentos removidos |
| 8 | Evidencias confundiam Origem__c com OrigemSLA__c | evidencias/07 diferencia explicitamente |

## Arquivos alterados

- `objects/RegrasSLACategorizacao__c/fields/EscopoRegra__c.field-meta.xml`
- `classes/GestaoSLAService.cls`
- `classes/GestaoSLAServiceTest.cls`
- `lwc/gestaoSLAWorkspace/gestaoSLAWorkspace.js`
- `lwc/gestaoSLAWorkspace/gestaoSLAWorkspace.html`

## Metadata EscopoRegra__c

- API Name: `EscopoRegra__c` (nao alterado)
- Label: `Tipo de Regra SLA`
- Descricao corrigida: "Define o tipo funcional da regra de SLA: Atendimento ou Area Interna."
- Valores novos mantidos: Atendimento, Area Interna
- Valores antigos mantidos: Global, Por Categorizacao, Por Area Interna

## Confirmacoes

| Item | Status |
|---|---|
| Descricao de EscopoRegra__c corrigida | OK |
| API Name nao alterado | OK |
| Valores antigos mantidos no picklist | OK |
| Marco SLA oculto para Area Interna | OK |
| Area Interna oculta para Atendimento | OK |
| Atendimento: AreaAtendimento__c = null | OK |
| Area Interna: MarcoSLA__c = null | OK |
| Duplicidade Area Interna considera Categorizacao__c | OK |
| Validacao de vigencia removida | OK |
| Origem__c nao exposta na LWC | OK |
| Vigencia nao exposta na LWC | OK |
| Global nao exposto na LWC | OK |
| Dados existentes nao atualizados | OK |
| Nenhum destructiveChanges criado | OK |
| Permission Sets nao alteradas | OK |
| AreaParticipante__c nao alterado | OK |
| OrigemSLA__c nao alterado | OK |
| Sem hardcoded Id | OK |
| Sem SeeAllData=true | OK |
| Sem System.assert | OK |
| UTF-8 sem BOM | OK |
| Sem mojibake | OK |

## Origem__c x OrigemSLA__c

- `Origem__c` — campo legado de `RegrasSLACategorizacao__c`, nao usado funcionalmente neste fluxo.
- `OrigemSLA__c` — pertence ao contexto de `AreaParticipante__c`, nao alterado neste pacote.

## Testes adicionados

- `testAtendimentoNaoGravaAreaAtendimento`
- `testAreaInternaNaoGravaMarcoSLA`
- `testAreaInternaDuplicidadeConsideraCategorizacao`
- `testVigenciaNaoValidada`

## Deploy

```
sf project deploy start --manifest delta_gestao_sla_tipo_regra_refactor_fix/package.xml -o WILSON_SERVICE
```

## Proximos pacotes

- **15D**: remocao dos valores antigos do picklist; exclusao fisica de Origem__c,
  VigenciaInicio__c, VigenciaFim__c; remocao das constantes antigas em RegrasSLACompatibilidadeService.
