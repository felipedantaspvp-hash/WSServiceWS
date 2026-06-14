# Pacote 17A — Regra SLA Área Interna (acionamento manual)

**Branch:** feat/claude/entitlement-rio-grande-centro-logistico-rebocadores
**Data:** 2026-06-14
**Deploy ID (real):** 0Afbe00000A9vnhCAB

## Objetivo
Habilitar o acionamento manual de AreaParticipante__c com aplicação automática da regra de SLA de Área Interna. Quando o usuário adiciona uma área participante manualmente via `AreaParticipanteService.addParticipation()`, o sistema deve:
1. Buscar regra ativa com `EscopoRegra__c = 'Area Interna'` + categorização + área de atendimento
2. Calcular prazo com business hours da regra
3. Gravar `TipoAreaParticipante__c = 'Área Interna'` e `OrigemAtuacao__c = 'Manual'`
4. Bloquear fechamento do caso enquanto área estiver aberta

## Classes modificadas
| Classe | Mudança |
|--------|---------|
| AreaParticipanteSLAService | findRule() usa EscopoRegra__c; erro distingue prioridade inválida vs. tempo nulo |
| AreaParticipanteSelector | getEligibleAreaValuesForCase() usa EscopoRegra__c |
| AreaParticipanteService | addParticipation() seta TipoAreaParticipante__c e OrigemAtuacao__c; mensagem de erro sem "origem" |
| AreaParticipanteSLAServiceTest | 6 novos testes do 17A |
| AreaParticipanteServiceTest | 1 novo teste + 4 pré-existentes corrigidos com BH bypass |
| AreaParticipanteControllerTest | 3 pré-existentes corrigidos com BH bypass |

## Evidências
| Arquivo | Conteúdo |
|---------|---------|
| 01_dryrun.md | Dry-run ID 0Afbe00000A9vm5CAB — Succeeded |
| 02_deploy_real.md | Deploy real ID 0Afbe00000A9vnhCAB — Succeeded |
| 03_testes.md | Test Run 707be00000VPGnc — 42/42 Pass (100%) |
| 04_mudancas_apex.md | Detalhamento das mudanças Apex e decisões de design |

## Resultado
100% dos testes passando. Backend pronto. LWC será entregue em pacote separado.
