# Evidência 07 — Pendências para o Pacote 16B

## Status do Pacote 16A

Deploy real: **Succeeded** — ID `0Afbe00000A9tXNCAZ` (2026-06-12)
Ajuste 16A: **dry-run Succeeded** — ID `0Afbe00000A9u3dCAB` (2026-06-13)

## Campos prontos para exclusão física no 16B

Os campos abaixo não possuem mais nenhuma referência funcional em código, metadados de configuração ou interfaces de usuário. O pacote 16A removeu todas as dependências.

| Campo | Objeto | Condição para 16B |
|-------|--------|-------------------|
| `Origem__c` | `RegrasSLACategorizacao__c` | Pronto — sem referências ativas |
| `VigenciaInicio__c` | `RegrasSLACategorizacao__c` | Pronto — sem referências ativas |
| `VigenciaFim__c` | `RegrasSLACategorizacao__c` | Pronto — sem referências ativas |
| `TipoAtuacao__c` | `AreaParticipante__c` | Pronto — sem referências ativas |

## Escopo do Pacote 16B

1. Criar `destructiveChanges.xml` com os 4 campos acima
2. Criar `package.xml` vazio (apenas com versão) para acompanhar o destructiveChanges
3. Executar dry-run antes do deploy real
4. Verificar que não há dados nos campos antes da exclusão (recomendado, mas não bloqueante — Salesforce bloqueia exclusão apenas se houver dependências de metadados, não de dados)

## Campos que NÃO devem entrar no 16B

| Campo | Motivo |
|-------|--------|
| `AreaParticipante__c.OrigemSLA__c` | Campo ativo — usado em `AreaParticipanteSLAService.cls` L41 |
| `AreaParticipante__c.TipoAreaParticipante__c` | Campo oficial de classificação — não legado |
| `MarcoSLA__c.UsaOrigem__c` | Campo de configuração ativo — usado em `GestaoSLAService.getMarcos` |
| `AreaParticipante__c.OrigemAtuacao__c` | Campo ativo — não referenciado no escopo do 16A |

## Pré-condição recomendada antes do 16B

- Verificar se os 2494 registros de `RegrasSLACategorizacao__c` ainda têm valores em `Origem__c` (dados históricos, não impactam a exclusão, mas é bom registrar)
- Confirmar com o negócio que nenhum relatório, Flow ou processo externo ainda referencia esses campos
