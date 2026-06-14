# Pacote 16B - Destructive de campos legados Gestao SLA

## Objetivo do pacote

Excluir fisicamente, via `destructiveChanges.xml`, os 4 campos legados que tiveram suas dependencias funcionais removidas no pacote 16A.

## Campos que serao removidos

- `RegrasSLACategorizacao__c.Origem__c`
- `RegrasSLACategorizacao__c.VigenciaInicio__c`
- `RegrasSLACategorizacao__c.VigenciaFim__c`
- `AreaParticipante__c.TipoAtuacao__c`

## Confirmacoes obrigatorias

1. O 16A deve estar implantado antes do 16B.
2. Nao ha dependencias funcionais ativas no projeto.
3. `OrigemSLA__c` nao foi alterado.
4. `TipoAreaParticipante__c` nao foi alterado.
5. Nenhum Apex foi alterado.
6. Nenhuma LWC foi alterada.
7. Nenhum dado foi alterado.

## Busca pre-destructive

Ver evidencia: `evidencias/02_busca_referencias_pre_destructive.md`

## Scripts de backup criados

- `scripts/01_backup_regras_sla_campos_legados.soql`
- `scripts/02_backup_area_participante_tipo_atuacao.soql`

## Conteudo do destructiveChanges.xml

Contem somente os 4 `CustomField` alvo e nenhum outro metadata.

## package.xml

Arquivo minimo com versao `64.0`, sem wildcard e sem metadados adicionais.

## Dry-run

Ver evidencia: `evidencias/05_dry_run.md`

Comando recomendado para dry-run:

```powershell
sf project deploy start --manifest Deltas/delta_gestao_sla_destructive_campos_legados/package.xml --post-destructive-changes Deltas/delta_gestao_sla_destructive_campos_legados/destructiveChanges.xml --target-org WILSON_SERVICE --dry-run --test-level RunLocalTests --wait 30
```

## Comando recomendado para deploy real

Nao executar sem aprovacao explicita:

```powershell
sf project deploy start --manifest Deltas/delta_gestao_sla_destructive_campos_legados/package.xml --post-destructive-changes Deltas/delta_gestao_sla_destructive_campos_legados/destructiveChanges.xml --target-org WILSON_SERVICE --test-level RunLocalTests --wait 30
```

## Roteiro de validacao pos-deploy

Ver script: `scripts/03_validacao_pos_destructive.md`

## Arquivos do repositorio para remocao apos deploy destrutivo bem-sucedido

Ver script: `scripts/04_arquivos_repositorio_para_remover.md`

## UTF-8 sem BOM

Validado sem BOM em todos os arquivos do pacote.

## Ausencia de mojibake

Validado sem ocorrencias de mojibake no pacote.

## Proximo pacote recomendado

Remover do repositorio principal os `field-meta.xml` dos 4 campos alvo somente apos a exclusao fisica estar concluida e validada no org.
