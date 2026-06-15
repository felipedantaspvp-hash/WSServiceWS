# 02 - Inventario de Classes e Services

## Services utilizados pelo Health Check

| Classe | Responsabilidade relevante |
|--------|---------------------------|
| `AreaParticipanteSLAHelper` | Constantes de StatusSLA__c, StatusAtuacao__c, OrigemSLA__c, TipoAreaParticipante__c |
| `AreaParticipanteHelper` | Metodos: `isAbertaOuAndamento()`, `isConcluida()`, `isCancelada()`, `isOverdue()` |
| `AreaParticipanteService` | `addParticipation()`, `pauseParticipation()` — usados apenas nos testes |
| `AreaParticipanteSLAService` | `bypassBusinessHoursMathForTests` — flag de bypass para testes |
| `BusinessHoursResolverService` | `injectedByName` — mapa de bypass para testes |
| `AreaParticipanteTestDataFactory` | `commonAreaValues()`, `createCase()` — factory de dados de teste |

## Constantes relevantes de AreaParticipanteSLAHelper

```apex
TIPO_AREA_INTERNA      = 'Área Interna'
ORIGEM_SLA_CUSTOM      = 'Custom'
ORIGEM_SLA_STANDARD    = 'Standard'
STATUS_SLA_PAUSADO     = 'Pausado'
STATUS_SLA_VENCIDO     = 'Vencido'
STATUS_SLA_DENTRO_PRAZO = 'Dentro do Prazo'
STATUS_SLA_CONCLUIDO   = 'Concluído'
STATUS_SLA_CANCELADO   = 'Cancelado'
STATUS_ATUACAO_ABERTA  = 'Aberta'
```

## Padrao ja existente no projeto

Nao ha HealthCheck, Audit ou Diagnostic pattern pre-existente. O Pacote 24 cria o padrao.

Nao foi criado Controller pois nao ha padrao de Controller standalone no projeto para servicos internos de auditoria.
