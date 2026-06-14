# Pacote 15C — Migracao de Dados EscopoRegra__c

## Objetivo

Migrar registros existentes de `RegrasSLACategorizacao__c` substituindo valores
antigos de `EscopoRegra__c` pelos novos valores funcionais aprovados.

## Mapeamento

| Valor antigo | Valor novo |
|---|---|
| Por Categorizacao | Atendimento |
| Por Area Interna | Area Interna |
| Global | **NAO migrar — decisao manual** |

## Este pacote NAO contem metadata de deploy

O `package.xml` esta presente para manter o padrao do delta mas sem membros.
Nenhum Apex, LWC, campo ou objeto foi alterado.

## Ordem de execucao obrigatoria

1. Executar `scripts/01_diagnostico_pre_update.soql` e documentar em `evidencias/02_diagnostico_pre_update.txt`
2. Gerar backup via `scripts/02_backup_pre_update.soql` e documentar em `evidencias/03_backup.txt`
3. Executar `scripts/03_update_escopo_regra.apex` e documentar em `evidencias/04_update_executado.txt`
4. Executar `scripts/04_validacao_pos_update.soql` e documentar em `evidencias/05_validacao_pos_update.txt`
5. Documentar registros Global em `evidencias/06_registros_global_para_analise.txt`

## Sobre os registros Global

Registros com `EscopoRegra__c = 'Global'` **nao serao migrados automaticamente**.
O conceito de Global foi absorvido por `GestaoSLA__c`.
Cada registro deve ser analisado individualmente antes de qualquer acao.
Ver: `evidencias/06_registros_global_para_analise.txt`

## Rollback

O script `scripts/05_rollback_opcional.apex` e um template comentado.
**Nao executar diretamente.** Requer lista de Ids do backup CSV gerado na Etapa 2.

## Estrutura

```
delta_gestao_sla_tipo_regra_data_update/
├── README_EVIDENCIAS.md
├── package.xml
├── scripts/
│   ├── 01_diagnostico_pre_update.soql
│   ├── 02_backup_pre_update.soql
│   ├── 03_update_escopo_regra.apex
│   ├── 04_validacao_pos_update.soql
│   └── 05_rollback_opcional.apex
└── evidencias/
    ├── 01_plano_execucao.txt
    ├── 02_diagnostico_pre_update.txt       <- preencher
    ├── 03_backup.txt                       <- preencher
    ├── 04_update_executado.txt             <- preencher
    ├── 05_validacao_pos_update.txt         <- preencher
    ├── 06_registros_global_para_analise.txt <- preencher
    ├── 07_validacao_sem_metadata_codigo.txt
    ├── 08_validacao_utf8_sem_bom.txt
    └── 09_validacao_sem_mojibake.txt
```
