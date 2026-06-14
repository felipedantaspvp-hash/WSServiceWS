# 01 - Inventário de Flows para AreaParticipante__c

## Resultado da busca

Comando: `Glob *AreaParticipante*.flow-meta.xml`

**Resultado: nenhum arquivo encontrado.**

Não existe nenhum Flow (Record-Triggered, Screen Flow, Autolaunched) para o objeto `AreaParticipante__c` no repositório local.

## Implicação

A orquestração de `EtapaAtendimento__c` não está implementada via Flow. Toda a lógica existente está no Apex Service (`AreaParticipanteService.cls`), com lógica parcial em `closeParticipation()`.

## Decisão

Estender o Service existente — não criar Flow. Ver `04_decisao_arquitetural.md`.
