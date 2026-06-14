# Evidencia 03 - Backup pre-destructive

Foram criados scripts de backup logico, sem executar alteracoes de dados:

- `scripts/01_backup_regras_sla_campos_legados.soql`
- `scripts/02_backup_area_participante_tipo_atuacao.soql`

Backups CSV exportados e armazenados no delta:

- `backups/01_backup_regras_sla_campos_legados.csv`
- `backups/02_backup_area_participante_tipo_atuacao.csv`

Levantamento executado no org `WILSON_SERVICE`:

- `RegrasSLACategorizacao__c` com pelo menos um dos campos legado preenchido: `2494` registros.
- `AreaParticipante__c` com `TipoAtuacao__c` preenchido: `17` registros.

Objetivo:

- Permitir exportacao dos valores historicos antes da exclusao fisica dos campos.
- Nao houve `update`, `delete` ou qualquer outra alteracao de dados.
- O backup de `AreaParticipante__c` foi exportado com campos realmente disponiveis no org alvo. Os campos `TipoAreaParticipante__c` e `OrigemSLA__c` existem no repositorio local, mas nao estao presentes no schema atual do org `WILSON_SERVICE`.
