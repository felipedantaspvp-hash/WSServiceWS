# 10 - Validacao de testes

## Dry-run anterior (Codex)

- Org: `WILSON_SERVICE`
- Job: `0Afbe00000AA5NGCA1`
- Status: `Succeeded`
- Test level: `RunSpecifiedTests`
- Testes: `AreaParticipanteServiceTest`, `AreaParticipanteControllerTest`
- Resultado: 39/39 testes, 0 falhas

## Ajustes pos-Codex (Claude)

- Hardcoded Id `01m000000000001AAA` removido de 3 locais; substituido por SOQL `[SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1]` injetando qualquer BH ativo sob a chave `Tecon Salvador` (bypass ativo, Id nunca e usado no calculo de datas).
- Novo teste `testResumeOverdueAreaKeepsVencidoStatus` adicionado em `AreaParticipanteServiceTest`: area vencida pausada e retomada com 30 min de pausa; prazo estendido ainda no passado; `StatusSLA__c` permanece `Vencido`.
- Versao do `package.xml` corrigida de `64.0` para `66.0`.

## Novo dry-run (Claude)

- Org: `WILSON_SERVICE`
- Job: `0Afbe00000AA2h8CAD`
- Status: `Succeeded`
- Test level: `RunSpecifiedTests`
- Testes: `AreaParticipanteServiceTest`, `AreaParticipanteControllerTest`
- Resultado: 40/40 testes, 0 falhas
