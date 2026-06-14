# Evidência 07 — Confirmação: campos removidos no 16B não usados

**Data:** 2026-06-14

## Campos removidos no Pacote 16B

| Campo | Objeto |
|-------|--------|
| `Origem__c` | `RegrasSLACategorizacao__c` |
| `VigenciaInicio__c` | `RegrasSLACategorizacao__c` |
| `VigenciaFim__c` | `RegrasSLACategorizacao__c` |
| `TipoAtuacao__c` | `AreaParticipante__c` |

## Verificação no componente caseAreasParticipantesPanel

O componente LWC não faz referência direta a campos de objetos Salesforce — toda leitura de dados ocorre
via DTOs retornados pelo backend (`AreaParticipanteController`).

| Campo removido | Presente no JS? | Presente no HTML? |
|----------------|-----------------|-------------------|
| `Origem__c` | Não | Não |
| `VigenciaInicio__c` | Não | Não |
| `VigenciaFim__c` | Não | Não |
| `TipoAtuacao__c` | Não | Não |

Nenhum campo removido no 16B é referenciado no componente. ✓

Os campos exibidos são propriedades dos DTOs (`areaLabel`, `statusLabel`, `statusSLA`, `tempoSLAMinutos`,
`tempoConsumidoMinutos`, `tempoRestanteMinutos`, `tempoPausadoMinutos`, `percentualDecorrido`,
`dataHoraInicio`, `dataHoraPrazo`, `comentarioSolicitacao`, `canClose`, `canManage`), todos computados
pelo backend sem dependência dos campos excluídos.
