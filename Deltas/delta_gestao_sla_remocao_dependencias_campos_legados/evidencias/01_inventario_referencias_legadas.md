# Evidência 01 — Inventário Final de Referências aos Campos Legados

## Campos alvo

| Campo | Objeto |
|-------|--------|
| `Origem__c` | `RegrasSLACategorizacao__c` |
| `VigenciaInicio__c` | `RegrasSLACategorizacao__c` |
| `VigenciaFim__c` | `RegrasSLACategorizacao__c` |
| `TipoAtuacao__c` | `AreaParticipante__c` |

## Resultado do inventário — Classes Apex

Varredura executada em `force-app/main/default/classes/*.cls`
Padrão buscado: `Origem__c|VigenciaInicio__c|VigenciaFim__c|TipoAtuacao__c`
Excluindo campos preservados: `OrigemSLA__c`, `OrigemAtuacao__c`, `UsaOrigem__c`

**Resultado: 0 ocorrências funcionais.**

Ocorrências encontradas no inventário e sua natureza:

| Arquivo | Linha | Conteúdo | Natureza |
|---------|-------|----------|----------|
| `GestaoSLAService.cls` | 148 | `UsaOrigem__c` | Campo `MarcoSLA__c.UsaOrigem__c` — PRESERVADO (não legado) |
| `GestaoSLAService.cls` | 164 | `UsaOrigem__c` | Campo `MarcoSLA__c.UsaOrigem__c` — PRESERVADO (não legado) |

> Nota: `UsaOrigem__c` é campo de configuração do `MarcoSLA__c` que indica se um marco usa origem como critério. É distinto de `RegrasSLACategorizacao__c.Origem__c` (campo legado alvo de exclusão no 16B).

## Resultado do inventário — LWC

Varredura em `force-app/main/default/lwc/**/*.js`:
**Resultado: 0 ocorrências.**

## Resultado do inventário — Metadados (objects, recordTypes, profiles)

Varredura em `force-app/main/default/objects/` e `force-app/main/default/profiles/`:
- `Admin.profile-meta.xml`: fieldPermissions removidas dos 4 campos legados — sem referências remanescentes
- RecordTypes `AreaParticipante__c`: blocos `<picklistValues>TipoAtuacao__c</picklistValues>` removidos de 4 RecordTypes
- Field-meta.xml dos campos legados: arquivos mantidos intencionalmente (campos físicos existem; exclusão é escopo do 16B)

**Resultado: 0 referências funcionais remanescentes.**

## Código morto removido neste ajuste (além do escopo original do 16A)

| Classe | Artefato | Motivo da remoção |
|--------|----------|-------------------|
| `GestaoSLAService.cls` | Constante `ORIGEM_QUALQUER = 'Qualquer'` | Nunca referenciada fora de `normalizeOrigem` |
| `GestaoSLAService.cls` | Método `normalizeOrigem(String origem)` | Nunca chamado em nenhum método da classe |
