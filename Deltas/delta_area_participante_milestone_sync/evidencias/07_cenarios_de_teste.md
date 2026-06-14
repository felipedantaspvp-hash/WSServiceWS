# Evidência 07 — Cenários de Teste

**Data:** 2026-06-14 (revisado)

## AreaParticipanteMilestoneSyncServiceTest (22 cenários)

| # | Método de teste | Cenário | Validação |
|---|-----------------|---------|-----------|
| 01 | `buildRecord_triagem_mapsCategoriaInicial` | MilestoneType = Triagem | TipoAreaParticipante__c = 'Categorização Inicial', NomeMarco__c = 'Triagem' |
| 02 | `buildRecord_respostaChat_mapsCategoriaInicial` | MilestoneType = Resposta Chat | TipoAreaParticipante__c = 'Categorização Inicial' |
| 03 | `buildRecord_primeiraRespostaFilaN2_mapsTratamentoPrimario` | MilestoneType = Primeira Resposta (Fila N2) | TipoAreaParticipante__c = 'Tratamento Primário' (parênteses normalizados) |
| 04 | `buildRecord_atendimento_mapsTratamentoPrimario` | MilestoneType = Atendimento | TipoAreaParticipante__c = 'Tratamento Primário' |
| 05 | `buildRecord_atendimentoN3_naoMapeado_tipoNull` | MilestoneType = Atendimento N3 | TipoAreaParticipante__c = null (não mapeado sem decisão explícita) |
| 06 | `buildRecord_retornoN3_mapsRetornoCliente` | MilestoneType = Retorno N3 | TipoAreaParticipante__c = 'Retorno ao Cliente' |
| 07 | `buildRecord_slaTotal_mapsTempTotalDeAtendimentoComNomeMarco` | MilestoneType = SLA Total | TipoAreaParticipante__c = 'Tempo Total de Atendimento', NomeMarco__c = 'Tempo Total de Atendimento' |
| 08 | `buildRecord_aberto_dentroPrazo` | IsCompleted=false, IsViolated=false | StatusAtuacao='Aberta', StatusSLA='Dentro do Prazo', ViolouSLA=false, OrigemSLA='Standard' |
| 09 | `buildRecord_concluido_semViolacao` | IsCompleted=true, IsViolated=false | StatusAtuacao='Concluída', StatusSLA='Concluído', TempoRestante=0, DataHoraFim preenchida |
| 10 | `buildRecord_concluido_comViolacao` | IsCompleted=true, IsViolated=true | StatusSLA='Vencido' (violação prevalece sobre conclusão) |
| 11 | `buildRecord_aberto_comViolacao` | IsCompleted=false, IsViolated=true | StatusAtuacao='Aberta', StatusSLA='Vencido' |
| 12 | `buildRecord_calculaPercentualDecorrido` | elapsed=120, remaining=120 | TempoSLA=240, Percentual=50.00% |
| 13 | `buildRecord_updatePath_mantemId` | existing=null (path de insert) | r.Id deve ser null |
| 14 | `syncByCaseIds_insereNovoRegistro` | 1 milestone mock, Case real | 1 AreaParticipante__c criado com campos corretos |
| 15 | `syncByCaseIds_idempotencia_naoduplicaSegundaChamada` | 2 chamadas com mesmo milestone | Apenas 1 registro (segunda atualiza) |
| 16 | `syncByCaseIds_preservaRegistroCustom` | Registro Custom pré-existente com mesmo CaseMilestoneId__c | Custom intacto, sem novo registro |
| 17 | `syncByCaseIds_setVazio_naoFazNada` | Set<Id> vazio | Sem exceção |
| 18 | `syncByCaseIds_milestoneNaoMapeado_naoInsere` | Atendimento N3 (não mapeado) | 0 registros criados, sem erro |
| 19 | `syncByCaseMilestoneIds_inserePorMilestoneId` | SLA Total via syncByCaseMilestoneIds com Id formato CaseMilestone | TipoAreaParticipante='Tempo Total de Atendimento', NomeMarco=idem |
| 20 | `syncByCaseMilestoneIds_setVazio_naoFazNada` | Set<Id> vazio | Sem exceção |
| 21 | `syncByCaseIds_milestoneConcluidoComViolacao_statusVencido` | IsCompleted=true, IsViolated=true, update via trigger | StatusSLA permanece 'Vencido' após update (closeSLA não sobrescreve) |
| 22 | `syncByCaseIds_atualizaRegistroExistente` | Primeiro sync aberto, segundo sync concluído | StatusAtuacao atualiza para 'Concluída' |

## AreaParticipanteMilestoneSyncBatchTest (3 cenários)

| # | Método | Cenário | Validação |
|---|--------|---------|-----------|
| 01 | `batch_comCaseIds_sincronizaMilestones` | Batch com Set<Id> de Cases | Registro criado pelo batch |
| 02 | `batch_semCaseIds_executaSemErro` | Batch sem filtro (QueryLocator global) | Sem exceção |
| 03 | `scheduler_executaSemErro` | Schedule via cron | Job agendado sem exceção |

## Padrão de mock

Não é possível criar CaseMilestone via DML em testes sem Entitlement completo.
Padrão adotado: `@TestVisible private static List<CaseMilestone> mockMilestonesForSync`
(consistente com `AreaParticipanteSelector.testAreas`). Milestones construídos via `JSON.deserialize`.

Para `syncByCaseMilestoneIds`: o argumento `Set<Id>` usa `fakeMilestoneSfId(n)` que gera
um Id de 15 chars com o key prefix real de `CaseMilestone` (`Schema.SObjectType.CaseMilestone.getKeyPrefix()`).
