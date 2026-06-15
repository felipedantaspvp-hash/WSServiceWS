# 09 - Validacao de Testes

## Testes definidos

| # | Nome | O que valida |
|---|------|-------------|
| 1 | `testRunHealthCheckSemErro` | Execucao sem excecao, DTO nao nulo, executionDateTime preenchido |
| 2 | `testDtoPreenchido` | totalChecks=4, totalIssues = issues.size(), soma severidades = totalIssues |
| 3 | `testDetectaPausadoSemDataInicioPausa` | Detecta `PAUSADO_SEM_DATA_INICIO_PAUSA` para AP com StatusSLA=Pausado sem DataHoraInicioPausa |
| 4 | `testDetectaDataInicioPausaIndevidaAposRetomada` | Verifica que pausa correta NAO gera issue (teste negativo) |
| 5 | `testDetectaStandardComPausa` | Detecta `STANDARD_COM_PAUSA` para Standard inserido diretamente com DataHoraInicioPausa |
| 6 | `testSemDmlCorrecao` | Campos de AP nao mudam apos execucao do health check |
| 7 | `testBulkSegurancaMultiplosRegistros` | Execucao com multiplos registros sem erro, totalChecks=4 |
| 8 | `testMaxRecordsNuloEZeroUsaLimitePadrao` | null e 0 usam limite padrao (totalChecks=4 em ambos) |
| 9 | `testContagemSeveridadesCorreta` | soma(Critical+High+Medium+Low+Info) = totalIssues; Critical>=1; Info>=1 |
| 10 | `testIssueCamposPreenchidos` | Issue tem severity, category, objectApiName, ruleCode, message, recommendation preenchidos |

## Dry-run

- Org: `WILSON_SERVICE`
- Job: `0Afbe00000AAH8HCAX`
- Status: `Succeeded`
- Test level: `RunSpecifiedTests`
- Testes: `GestaoSLAHealthCheckServiceTest`
- Resultado: 16/16 testes, 0 falhas
- Dry-run: 3 componentes validados (DTO, Service, ServiceTest)

## Deploy real

- Org: `WILSON_SERVICE`
- Job: `0Afbe00000AAHcvCAH`
- Status: `Succeeded`
- Test level: `RunSpecifiedTests`
- Testes: `GestaoSLAHealthCheckServiceTest`
- Resultado: 16/16 testes, 0 falhas
- Componentes: 3/3 criados (GestaoSLAHealthCheckDTO, GestaoSLAHealthCheckService, GestaoSLAHealthCheckServiceTest)

## Regras seguidas

- `Assert.areEqual` em todos os asserts (sem `System.assert`)
- Sem `@IsTest(SeeAllData=true)`
- Sem hardcoded Id
- Sem SOQL em loop
- `enableBhBypass()` / `criarAreaCustom()` como helpers reutilizaveis
- Standard APs inseridos diretamente (trigger nao processa Standard)
