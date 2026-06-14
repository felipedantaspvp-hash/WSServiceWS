# Evidência 04 — Campos Mapeados de CaseMilestone para AreaParticipante__c

**Data:** 2026-06-14

## Mapeamento de campos (buildRecord)

| Campo AreaParticipante__c | Origem | Observação |
|---------------------------|--------|------------|
| `Caso__c` | `CaseMilestone.CaseId` | Lookup obrigatório |
| `CaseMilestoneId__c` | `CaseMilestone.Id` (string) | Chave de idempotência |
| `OrigemSLA__c` | Constante `'Standard'` | Diferencia de registros Custom |
| `TipoAreaParticipante__c` | Mapeado por MilestoneType.Name | Ver evidência 03 |
| `NomeMarco__c` | MilestoneType.Name (ou 'Tempo Total de Atendimento') | Campo de texto livre |
| `DataHoraInicio__c` | `CaseMilestone.StartDate` | — |
| `DataHoraPrazo__c` | `CaseMilestone.TargetDate` | — |
| `DataHoraFim__c` | `CaseMilestone.CompletionDate` | null se aberto |
| `StatusAtuacao__c` | `IsCompleted` → 'Concluída' / 'Aberta' | — |
| `StatusSLA__c` | Combinação IsCompleted + IsViolated | Ver tabela abaixo |
| `ViolouSLA__c` | `CaseMilestone.IsViolated` | — |
| `BloqueiaFechamentoCaso__c` | Constante `false` | Standard nunca bloqueia |
| `TempoConsumidoMinutos__c` | `ElapsedTimeInMins` | — |
| `TempoRestanteMinutos__c` | `TimeRemainingInMins` (0 se concluído) | — |
| `TempoSLAMinutos__c` | `elapsed + remaining` | null se ambos nulos |
| `PercentualDecorrido__c` | `elapsed / (elapsed+remaining) * 100` | 100% se concluído sem remaining |

## Lógica StatusSLA__c

| IsCompleted | IsViolated | StatusSLA__c |
|-------------|------------|--------------|
| false | false | Dentro do Prazo |
| false | true | Vencido |
| true | false | Concluído |
| true | true | Vencido |

## Campos NÃO mapeados

Os seguintes campos não recebem valor dos espelhos Standard (ficam null/default):
- `AreaAtendimento__c` — não há área interna equivalente nos milestones padrão (exceto Atendimento N3)
- `RegraSLACategorizacao__c` — regras são apenas para Custom
- `SequenciaAcionamento__c` — sequenciamento apenas para Custom
- `TempoPausadoMinutos__c` — pausa não existe em CaseMilestone
- `Responsavel__c`, `Solicitante__c`, `ComentarioSolicitacao__c`, etc.
