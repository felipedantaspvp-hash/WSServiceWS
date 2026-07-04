# 03 - Decisao Arquitetural

## Pergunta: Flow ou Apex?

**Decisao: Apex puro (Service + DTO).**

| Criterio | Flow | Apex Service |
|----------|------|--------------|
| Logica condicional multi-campo | Complexo | Simples |
| Leitura de multiplos objetos | Penalizado (loop subotimo) | SOQL direto |
| Sem DML necessario | Suportado | Suportado |
| Retorno estruturado (DTO) | Inviavel | Nativo |
| Testabilidade granular | Limitada | Total |
| Padrao do projeto | Nao e padrao | Padrao existente |

## Pergunta: Controller necessario?

**Decisao: Nao.**

O projeto nao tem padrao de Controller standalone para servicos de auditoria interna. O Health Check e invocado diretamente pelo service layer. Se houver necessidade de expor via LWC no futuro, um Controller pode ser criado no Pacote 25+.

## Pergunta: Batch ou service sincrono?

**Decisao: Service sincrono com limite de registros.**

O Health Check e diagnóstico pontual, nao processamento em massa. O parametro `maxRecords` (padrao 200) garante seguranca de governors. Para auditorias em massa, um Batch pode ser adicionado em pacote futuro sem alterar o servico.

## Estrutura de classes

```
GestaoSLAHealthCheckDTO      — tipos de dados (HealthCheckResult, Issue)
GestaoSLAHealthCheckService  — logica de verificacao (4 checks, 7 SOQL, 0 DML)
GestaoSLAHealthCheckServiceTest — 10 testes unitarios
```
