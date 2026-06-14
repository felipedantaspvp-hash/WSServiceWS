# Pacote 15B — Refactoring GestaoSLA: EscopoRegra Atendimento / Area Interna

## Objetivo

Refatorar a camada Apex e LWC de Gestao de SLA para operar exclusivamente com os
novos valores de EscopoRegra: `Atendimento` e `Area Interna`.

Os valores antigos (`Global`, `Por Categorizacao`, `Por Area Interna`) foram adicionados
ao picklist no Pacote 15A e serao removidos do picklist no Pacote 15D.
Este pacote (15B) para de escrever/exigir os valores antigos no servico e na UI.

## Escopo do pacote

| Artefato | Tipo de alteracao |
|---|---|
| GestaoSLAHelper.cls | Novas constantes TIPO_REGRA_* |
| RegrasSLACompatibilidadeService.cls | Novas constantes ESCOPO_ATENDIMENTO / ESCOPO_AREA_INTERNA |
| GestaoSLAService.cls | Validacao, duplicidade e DML por tipo de regra |
| GestaoSLAController.cls | Remocao do param origem do @AuraEnabled |
| GestaoSLAServiceTest.cls | Testes ajustados e novo teste Area Interna |
| GestaoSLAControllerTest.cls | Testes ajustados para nova assinatura |
| gestaoSLAWorkspace (LWC) | UI adaptada: constantes, form, filtros, tabela, modal |

## Nao alterado neste pacote

- RegrasSLACategorizacao__c.EscopoRegra__c — valores antigos mantidos no picklist
- AreaParticipante__c, OrigemSLA__c — sem alteracao
- Entitlement Process / CaseMilestoneTriggerTimeCalculator — sem alteracao
- GestaoSLADTO.cls — campos origem/vigencia mantidos no DTO para compatibilidade

## Evidencias

| Arquivo | Conteudo |
|---|---|
| evidencias/01_apex_servico.txt | Mudancas em GestaoSLAService |
| evidencias/02_apex_helper_e_compatibilidade.txt | Novas constantes |
| evidencias/03_apex_controller.txt | Mudanca de assinatura do controller |
| evidencias/04_apex_testes.txt | Alteracoes nos testes Apex |
| evidencias/05_lwc.txt | Alteracoes no LWC gestaoSLAWorkspace |

## Deploy

```
sf project deploy start --manifest delta_gestao_sla_tipo_regra_refactor/package.xml -o WILSON_SERVICE
```
