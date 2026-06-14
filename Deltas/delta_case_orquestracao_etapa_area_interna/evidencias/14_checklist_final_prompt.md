# 14 - Checklist Final do Prompt

## Checklist obrigatório

| # | Item | Status | Observação |
|---|---|---|---|
| 1 | Objetivo do pacote atendido | ✅ | addParticipation → 'Aguardando Área Interna'; closeParticipation → 'Preparando Retorno ao Cliente' ou manter; guard terminal; Standard excluído; IsClosed protegido |
| 2 | Arquitetura Flow-first avaliada | ✅ | Nenhum Flow de AreaParticipante__c existe (evidência 01); Service estendido |
| 3 | Flows existentes analisados | ✅ | Case_EntitlementAutoAssignment (não aplicável), Route_from_Will / Route_to_Will_Smoke (não aplicável); zero flows para AP |
| 4 | Decisão arquitetural documentada | ✅ | evidência 04 |
| 5 | Fora do escopo respeitado | ✅ | caseAreasParticipantesPanel não alterado; acionamento manual não alterado; Milestones não alterados; SLA/Entitlement não alterados |
| 6 | Campos removidos no 16B não usados | ✅ | Origem__c, VigenciaInicio__c, VigenciaFim__c, TipoAtuacao__c — ausentes nos arquivos alterados |
| 7 | Valores antigos de EscopoRegra__c não usados | ✅ | Global, Por Categorizacao, Por Area Interna — não referenciados |
| 8 | Pacote 20 não impactado | ✅ | Testes SLACoverageCore passaram; evidência 13 |
| 9 | Standard APs não afetam EtapaAtendimento__c | ✅ | `rowIsCustomInterna` + filtro `BloqueiaFechamentoCaso__c=true`; testado em #5 e #7 |
| 10 | Guard para Case terminal implementado | ✅ | addParticipation e closeParticipation: `caseRow.IsClosed \|\| conclu \|\| cancel` |
| 11 | Testes obrigatórios executados | ✅ | 8 novos + 12 de regressão = 20 testes; 0 falhas |
| 12 | package.xml mínimo e sem wildcard | ✅ | ApexClass: AreaParticipanteSelector + AreaParticipanteService + AreaParticipanteServiceTest |
| 13 | UTF-8 sem BOM | ✅ | evidência 11 |
| 14 | Sem mojibake | ✅ | evidência 12 |
| 15 | Selector atualizado (IsClosed + OrigemSLA__c) | ✅ | getCaseById() + IsClosed; getAreaById() + OrigemSLA__c |
| 16 | Escopo de cancelamento documentado | ✅ | evidência 16 — cancelParticipation() não existe; apenas closeParticipation() |
| 17 | Prompt relido antes da finalização | ✅ | Todos os itens verificados |

## Pendências antes de declarar pronto

- [x] Dry-run v1 executado — Deploy ID `0Afbe00000AA2ysCAD`, Succeeded, 18/18 testes
- [x] Dry-run v2 executado — Deploy ID `0Afbe00000AA3rhCAD`, Succeeded, 20/20 testes, 0 falhas
- [x] BOM check executado — todos os arquivos OK
- [x] Evidências 06–10 atualizadas para v2
- [x] Evidências 15 e 16 criadas
- [x] ZIP a gerar — `delta_case_orquestracao_etapa_area_interna.zip` na raiz do projeto
- [ ] Commit e push realizados
- [ ] Deploy definitivo executado
