# Gestão de SLA — Escopo e Entendimento do Projeto

## Objetivo

Este documento consolida o entendimento funcional e técnico do projeto de Gestão de SLA da Wilson Sons dentro deste repositório Salesforce.

O objetivo é servir como referência futura para:

- continuidade de desenvolvimento;
- onboarding de novos consultores;
- análise de impacto;
- deploy/retrieve seguro;
- manutenção de dados e metadados;
- prevenção de regressões em org e source.

Este documento descreve o estado atual do projeto com base no source local e nas últimas validações feitas na org `WILSON_SERVICE`.

## Visão geral da solução

A solução de Gestão de SLA foi construída em pacotes pequenos e deltas isolados.

Ela introduz uma nova arquitetura para:

- modelar Gestões de SLA;
- modelar Marcos de SLA;
- relacionar Categorizações a uma Gestão de SLA;
- evoluir regras de SLA para suportar modelo legado e modelo novo;
- calcular SLA macro do Entitlement Process;
- calcular SLA individual do N3 customizado em `AreaParticipante__c`;
- disponibilizar uma tela administrativa em LWC para gestão funcional e técnica.

## Resumo por pacote

### Pacote 1

Criação da modelagem base:

- `GestaoSLA__c`
- `MarcoSLA__c`

### Pacote 2

Relacionamento entre categorização e gestão:

- `Categorizacao__c.GestaoSLA__c`

### Pacote 3

Evolução estrutural de `RegrasSLACategorizacao__c` com campos do modelo novo:

- `GestaoSLA__c`
- `MarcoSLA__c`
- `EscopoRegra__c`
- `TempoBaixa__c`
- `TempoMedia__c`
- `TempoAlta__c`
- `VigenciaInicio__c`
- `VigenciaFim__c`

### Pacote 4

Camada Apex de compatibilidade entre modelo legado e modelo novo:

- `RegrasSLACompatibilidadeService`
- `RegrasSLACategorizacaoSelector`

Responsabilidades principais:

- identificar se a regra está no modelo novo;
- resolver tempo por prioridade no modelo novo;
- resolver tempo legado por `TempoMinutos__c`;
- validar vigência;
- montar chave lógica nova e legada;
- aplicar fallback de origem específica para `Qualquer`.

### Pacote 5

Classe de cálculo de tempo para milestones macro do Entitlement:

- `CaseMilestoneTriggerTimeCalculator`

Responsabilidade:

- calcular minutos de milestones padrão com base em `Case`, `MarcoSLA__c`, `GestaoSLA__c` e `RegrasSLACategorizacao__c`.

### Pacote 6

Ajuste do motor N3 customizado:

- `AreaParticipanteSLAService`

Responsabilidade:

- tentar usar regra nova com `EscopoRegra__c = Por Area Interna`;
- se não encontrar, cair no fallback legado.

### Pacote 6.1

Reforço de testes do motor N3.

### Pacote 7

Consolidação técnica do `force-app`, incluindo:

- metadados faltantes;
- alinhamento do LWC legado da área participante;
- consolidação do Entitlement Process autoritativo.

### Pacote 8

Evolução das validações e da chave lógica de `RegrasSLACategorizacao__c`.

Classe central:

- `RegrasSLACategorizacaoService`

Responsabilidades:

- validar modelo legado;
- validar modelo novo;
- gerar chave única nova sem prioridade;
- preservar compatibilidade com o legado.

### Pacote 8.1

Reforço de cobertura de testes para classes dependentes.

### Pacote 9

Base de segurança e governança:

- Custom Permissions
- Permission Sets da solução

### Pacote 10

Backend Apex da futura LWC de Gestão de SLA:

- `GestaoSLAController`
- `GestaoSLAService`
- `GestaoSLAHelper`
- `GestaoSLADTO`

Depois disso, a solução evoluiu para uma LWC funcional completa de gestão.

## Arquitetura atual

Padrão predominante:

```text
LWC / Tab / App
        ↓
GestaoSLAController
        ↓
GestaoSLAService
        ↓
Helper / DTO / objetos Salesforce
```

Para SLA e N3:

```text
Entitlement Process / Trigger / Case / AreaParticipante
        ↓
CaseMilestoneTriggerTimeCalculator / AreaParticipanteSLAService
        ↓
RegrasSLACompatibilidadeService
        ↓
RegrasSLACategorizacao__c / MarcoSLA__c / GestaoSLA__c / Categorizacao__c
```

## Objetos principais

### `GestaoSLA__c`

Objeto principal de configuração da gestão.

Campos relevantes identificados no projeto:

- `Name`
- `UnidadeNegocio__c`
- `EntitlementProcessName__c`
- `BusinessHoursName__c`
- `TempoTriagemMinutos__c`
- `TempoRespostaChatMinutos__c`
- `StaticResourceName__c`
- `Descricao__c`
- `Ativo__c`

Uso:

- cabeçalho da tela de Gestão de SLA;
- tempos globais de Triagem e Resposta Chat;
- associação com `MarcoSLA__c`;
- associação com `RegrasSLACategorizacao__c`;
- associação indireta com categorização.

### `MarcoSLA__c`

Objeto que representa os marcos administráveis por Gestão de SLA.

Campos relevantes:

- `GestaoSLA__c`
- `NomeMarco__c`
- `MilestoneTypeName__c`
- `FonteTempo__c`
- `Ordem__c`
- `Recorrente__c`
- `TipoRecorrencia__c`
- `UsaCategorizacao__c`
- `UsaAreaInterna__c`
- `UsaOrigem__c`
- `Ativo__c`

Uso:

- mapeamento entre milestone do Entitlement e regra configurável;
- definição da fonte do tempo:
  - `GestaoSLA`
  - `RegraSLA`

### `Categorizacao__c`

Objeto existente, expandido para a nova arquitetura.

Campos relevantes para a solução:

- `GestaoSLA__c`
- `ExternalId__c`
- `UnidadeNegocios__c`
- `TipoCaso__c`
- `Categoria__c`
- `Assunto__c`
- `Subassunto__c`
- `Prioridade__c`
- `Ativo__c`

Observações importantes:

- o campo canônico usado pela solução para unidade na categorização é `UnidadeNegocios__c`;
- `ExternalId__c` foi criado para viabilizar cargas e upserts seguros;
- a categorização é usada tanto na tela quanto nas regras SLA.

### `RegrasSLACategorizacao__c`

Objeto central de regra.

Modelo legado:

- `Categorizacao__c`
- `Marco__c`
- `TipoAreaParticipante__c`
- `AreaAtendimento__c`
- `Prioridade__c`
- `Origem__c`
- `TempoMinutos__c`
- `Ativo__c`

Modelo novo:

- `GestaoSLA__c`
- `MarcoSLA__c`
- `EscopoRegra__c`
- `TempoBaixa__c`
- `TempoMedia__c`
- `TempoAlta__c`
- `VigenciaInicio__c`
- `VigenciaFim__c`
- `Ativo__c`

Escopos reconhecidos:

- `Global`
- `Por Categorizacao`
- `Por Area Interna`

## Regras de prioridade

A solução foi construída considerando somente:

- `Baixa`
- `Média`
- `Alta`

Mapeamentos aceitos na compatibilidade:

- `Baixa` / `Low`
- `Média` / `Media` / `Medium`
- `Alta` / `High`

Não existe suporte funcional para prioridade crítica.

## Compatibilidade legado x novo

A classe-chave é:

- `force-app/main/default/classes/RegrasSLACompatibilidadeService.cls`

Responsabilidades:

- detectar modelo novo;
- resolver tempo correto por prioridade;
- manter fallback legado;
- validar vigência;
- montar chaves lógicas;
- aplicar fallback de origem para `Qualquer`.

Decisão importante:

- no modelo novo, prioridade não entra na chave lógica;
- a prioridade apenas escolhe entre:
  - `TempoBaixa__c`
  - `TempoMedia__c`
  - `TempoAlta__c`

## Cálculo de SLA macro

Classe:

- `force-app/main/default/classes/CaseMilestoneTriggerTimeCalculator.cls`

Usada no Entitlement Process autoritativo:

- `force-app/main/default/entitlementProcesses/atendimento salvador_v2.entitlementProcess-meta.xml`

Marcos macro configurados:

- `Triagem`
- `Resposta Chat`
- `Primeira Resposta (Fila N2)`
- `Atendimento`
- `Atendimento N3`
- `Retorno N3`
- `Acompanhamento`
- `SLA Total`

Fonte do tempo:

- `Triagem` e `Resposta Chat`: tempo direto em `GestaoSLA__c`
- demais: `RegrasSLACategorizacao__c` via compatibilidade

## Motor N3 customizado

Classe central:

- `force-app/main/default/classes/AreaParticipanteSLAService.cls`

Regras principais:

- tenta regra nova primeiro;
- exige `EscopoRegra__c = Por Area Interna` para N3 individual;
- usa `Categorizacao__c.GestaoSLA__c`;
- resolve `MarcoSLA__c` de Atendimento N3;
- usa fallback legado quando necessário.

Importante:

- o milestone macro `Atendimento N3` não substitui o SLA individual do N3;
- o macro é tratado pelo calculator de milestone;
- o individual é tratado por `AreaParticipanteSLAService`.

## Backend da tela Gestão de SLA

### Controller

Classe:

- `force-app/main/default/classes/GestaoSLAController.cls`

Métodos públicos identificados:

- `getBootstrap()`
- `getGestaoDetail(Id gestaoSLAId)`
- `getCategorias(Id gestaoSLAId, String searchTerm, String tipoCaso, String categoria, Boolean ativo)`
- `getMarcos(Id gestaoSLAId)`
- `getRegrasSLA(...)`
- `getInactiveGestoes()`
- `getInactiveCategorias(Id gestaoSLAId)`
- `createGestaoSLA(...)`
- `updateGestaoSLA(...)`
- `reactivateGestaoSLA(Id gestaoSLAId)`
- `createCategoria(...)`
- `updateCategoria(...)`
- `deactivateCategoria(Id categoriaId)`
- `reactivateCategoria(Id categoriaId)`
- `createRegraSLA(...)`
- `updateRegraSLA(...)`
- `deactivateRegraSLA(Id regraSLAId)`

### Service

Classe:

- `force-app/main/default/classes/GestaoSLAService.cls`

Responsabilidades:

- autorização;
- queries de gestão, categoria, marco e regra;
- montagem de DTO;
- criação, edição, reativação e inativação;
- normalização de filtros;
- tratamento de erro funcional via `FunctionalException`.

### Helper

Classe:

- `force-app/main/default/classes/GestaoSLAHelper.cls`

Responsabilidades:

- nomes das Custom Permissions;
- verificação por `FeatureManagement.checkPermission`;
- override de permissão para testes;
- normalização básica de texto.

### DTO

Classe:

- `force-app/main/default/classes/GestaoSLADTO.cls`

DTOs identificados:

- `CreateGestaoRequest`
- `UpdateGestaoRequest`
- `PermissionInfo`
- `SummaryInfo`
- `GestaoResumo`
- `CategoriaResumo`
- `CategoriaRequest`
- `MarcoResumo`
- `RegraSLAResumo`
- `RegraSLARequest`
- `BootstrapResponse`
- `GestaoDetailResponse`
- `CategoriasResponse`
- `MarcosResponse`
- `RegrasSLAResponse`
- `InactiveGestoesResponse`
- `InactiveCategoriasResponse`

## LWC principal

Componente:

- `force-app/main/default/lwc/gestaoSLAWorkspace/`

Tab:

- `force-app/main/default/tabs/GestaoSLA.tab-meta.xml`

Descrição:

- a tab `Gestão de SLA` carrega a LWC `gestaoSLAWorkspace`

Capacidades atuais identificadas:

- lista de gestões;
- seleção de gestão;
- visão detalhada da gestão;
- filtros de categorização;
- paginação;
- criação e edição de Gestão de SLA;
- reativação de gestão inativa;
- criação, edição, inativação e reativação de categorização;
- listagem e manutenção de regras SLA;
- listagem de marcos;
- ocultação de recursos por permissão;
- labels traduzíveis por `Custom Labels` e `Translation`.

Outro LWC relevante no projeto:

- `force-app/main/default/lwc/caseAreasParticipantesPanel/`

Esse componente é relacionado ao acompanhamento de áreas participantes no contexto operacional do Case.

## Segurança e permissões

### Custom Permissions

Arquivos:

- `AcessarGestaoSLA`
- `GerenciarCategoriasGestaoSLA`
- `GerenciarRegrasSLA`
- `AdministrarConfiguracoesGestaoSLA`

### Permission Sets

Arquivos:

- `GestaoSLAConfigurador.permissionset-meta.xml`
- `GestaoSLAAdminTecnico.permissionset-meta.xml`

Estado atual importante:

- o desenho inicial do pacote previa apenas Custom Permissions;
- o estado atual do source mostra que esses permission sets evoluíram e hoje incluem, além das custom permissions:
  - `classAccesses`
  - `tabSettings`
  - em pelo menos um caso, `fieldPermissions`, `objectPermissions` e `recordTypeVisibilities`

Portanto, qualquer futura alteração nesses permission sets deve considerar o estado real atual da org/source, e não apenas a intenção original do pacote 9.

### Lógica de autorização

A LWC e o backend usam flags derivadas de:

- `canAccessGestaoSLA`
- `canManageCategories`
- `canManageRules`
- `canAdminTechnicalSettings`

## Aplicação e navegação

Aplicação relevante:

- `force-app/main/default/applications/Atendimento_Tecon_Salvador.app-meta.xml`

Características:

- app console;
- inclui a tab `GestaoSLA`;
- inclui `Categorizacao__c`;
- usa utility bar específica.

## Entitlement Process autoritativo

Arquivo:

- `force-app/main/default/entitlementProcesses/atendimento salvador_v2.entitlementProcess-meta.xml`

Pontos importantes:

- é o arquivo autoritativo para Atendimento Salvador;
- usa `CaseMilestoneTriggerTimeCalculator` em todos os 8 marcos macro;
- mantém `isDisplayedOnLinkedEntity=false` nos marcos onde isso já existia;
- hoje o critério de `Resposta Chat` ainda aparece como valor literal `Whatsapp, Chat`.

Isso é uma pendência conhecida porque o comportamento funcional desejado é `Whatsapp OU Chat`, e o metadata não ficou com representação OR nativa confiável.

## Static Resources e imagem da gestão

Há static resources relacionados no projeto, incluindo:

- `img_atendimento_salvador`
- `AtendimentoSalvador`

A tela usa o campo:

- `GestaoSLA__c.StaticResourceName__c`

para resolver a imagem/bandeira visual da gestão.

Regra visual consolidada:

- quando houver static resource configurado, a imagem da gestão deve prevalecer sobre o layout genérico.

## Record Types e padronização

Record types identificados para `Categorizacao__c`:

- `CentroLogistico`
- `Rebocadores`
- `TeconRioGrande`
- `TeconSalvador`

Decisão recente importante:

- houve padronização de nomes de Record Type para refletir melhor o domínio;
- mudanças de label/name em record type podem impactar:
  - metadata de `recordTypeVisibilities`
  - custom metadata
  - filtros e validações Apex
  - cargas de dados
  - integrações e automações futuras

## Cargas de dados e governança

### Regra prática consolidada

Para cargas de `Categorizacao__c`:

- usar `ExternalId__c` como chave de upsert;
- preservar textos de negócio de:
  - `TipoCaso__c`
  - `Categoria__c`
  - `Assunto__c`
  - `Subassunto__c`
- se um valor não existir na org:
  - criar/habilitar o valor na picklist / record type
  - não substituir por valor “parecido”

### Campo de unidade na categorização

Na solução atual, para `Categorizacao__c`, o campo usado na tela e nas cargas é:

- `UnidadeNegocios__c`

Foi adotada a normalização para valores como:

- `Atendimento Salvador`
- `Atendimento Rio Grande`

### Situação recente de carga

Foi criada uma chave externa válida:

- `Categorizacao__c.ExternalId__c`

Isso permitiu:

- backfill de chaves externas em registros existentes equivalentes;
- upsert seguro de novas categorizações;
- reconciliação entre source CSV e base já existente.

## Testes e cobertura

Há diversas classes de teste já ajustadas para aumentar cobertura das classes mais críticas.

Áreas mais trabalhadas recentemente:

- `MessagingContextService`
- `CategorizacaoController`
- `CategorizacaoService`
- `CategorizacaoSelector`
- `CaseEntitlementAssignmentService`
- `AtendimentoContextResolverService`
- `CaseRecategorizationService`
- `AreaParticipanteSLABatch`
- `AreaParticipanteSLAScheduler`
- classes de compatibilidade e SLA

Ao continuar a evolução do projeto:

- evitar regressão de cobertura;
- preservar testes existentes;
- validar cobertura especialmente em classes de backend e compatibilidade.

## Estado operacional atual

### O que já existe funcionalmente

- tab de Gestão de SLA;
- app console com navegação para a solução;
- backend Apex;
- LWC funcional para gestão;
- marcos macro configurados;
- motor N3 custom compatível com nova arquitetura;
- segurança baseada em Custom Permission;
- estrutura para regras novas em `RegrasSLACategorizacao__c`;
- chave externa para cargas de categorização.

### O que requer cuidado contínuo

- diferenças entre source e org devido a ajustes manuais;
- trabalho paralelo de outros consultores;
- picklists restritas por Global Value Set + Record Type;
- permissões que evoluíram além da proposta original;
- critério de `Resposta Chat` no Entitlement Process;
- necessidade de retrieve antes de novos deploys quando houver dúvida.

## Regras operacionais para futuras mudanças

### Org como fonte mais atual

Quando houver alterações manuais na org ou trabalho paralelo:

- considerar a org como fonte mais atual;
- fazer retrieve seletivo antes de novo deploy;
- evitar sobrescrever mudanças de terceiros.

### Boas práticas de deploy/retrieve

Antes de deploy:

- validar tracking;
- fazer retrieve seletivo do escopo;
- evitar deploy amplo sem necessidade;
- preservar UTF-8 sem BOM;
- validar ausência de mojibake.

### Boas práticas para dados

Antes de carga:

- validar se os valores existem na picklist global;
- validar se o record type permite os valores;
- validar duplicidade funcional;
- preferir `upsert` por `ExternalId__c`.

## Pendências e pontos de atenção conhecidos

### Pendência 1

Critério `Resposta Chat` no Entitlement Process:

- o desejado é `Origin = Whatsapp OU Chat`
- o metadata atual ainda está com `Whatsapp, Chat`

### Pendência 2

`PROJECT_INDEX.md` ainda está muito raso e não reflete todo o estado atual do projeto.

### Pendência 3

Permission Sets de Gestão de SLA já não refletem somente o desenho original do pacote 9; hoje precisam ser tratados como metadados vivos do projeto.

## Arquivos-chave para futuras análises

### Backend Gestão de SLA

- [GestaoSLAController.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/GestaoSLAController.cls)
- [GestaoSLAService.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/GestaoSLAService.cls)
- [GestaoSLAHelper.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/GestaoSLAHelper.cls)
- [GestaoSLADTO.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/GestaoSLADTO.cls)

### LWC

- [gestaoSLAWorkspace](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/lwc/gestaoSLAWorkspace)
- [caseAreasParticipantesPanel](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/lwc/caseAreasParticipantesPanel)

### Compatibilidade e cálculo

- [RegrasSLACompatibilidadeService.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/RegrasSLACompatibilidadeService.cls)
- [CaseMilestoneTriggerTimeCalculator.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/CaseMilestoneTriggerTimeCalculator.cls)
- [AreaParticipanteSLAService.cls](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/classes/AreaParticipanteSLAService.cls)

### Metadados relevantes

- [atendimento salvador_v2.entitlementProcess-meta.xml](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/entitlementProcesses/atendimento%20salvador_v2.entitlementProcess-meta.xml)
- [GestaoSLA.tab-meta.xml](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/tabs/GestaoSLA.tab-meta.xml)
- [Atendimento_Tecon_Salvador.app-meta.xml](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/applications/Atendimento_Tecon_Salvador.app-meta.xml)
- [GestaoSLAConfigurador.permissionset-meta.xml](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/permissionsets/GestaoSLAConfigurador.permissionset-meta.xml)
- [GestaoSLAAdminTecnico.permissionset-meta.xml](c:/WILSONSONS/SERVICE/WS_SERVICE/force-app/main/default/permissionsets/GestaoSLAAdminTecnico.permissionset-meta.xml)

## Conclusão

Este projeto já ultrapassou a fase de prova de conceito e possui uma base funcional relevante, com:

- modelagem nova;
- compatibilidade com legado;
- cálculo macro;
- cálculo N3;
- backend Apex;
- tela administrativa;
- segurança por permissão;
- governança mínima para cargas de dados.

O principal cuidado daqui para frente não é apenas implementar novas funcionalidades, mas preservar coerência entre:

- org;
- source;
- picklists e record types;
- permissões;
- dados já carregados;
- regras legadas e novas.

Se este documento for mantido atualizado a cada pacote relevante, ele pode se tornar a referência principal de continuidade da solução.
