# Seed de Parâmetros de Atendimento (Categorização / SLA / Marcos)

Repositório local de dados de **configuração** (não transacionais) do domínio de Atendimento, extraído da org **WILSON_SERVICE** (apelidada "WS_SERVICE" nas conversas/documentação), para popular rapidamente outras N orgs (sandboxes novas, orgs de homologação, etc.) sem precisar recriar manualmente a árvore de Categorização/SLA/Marcos.

## Escopo — o que é "dado de parâmetro" neste domínio

Levantamento feito em `docs/PROJECT_INDEX.md` / `AI_WORKQUEUE.md` + describe dos objetos. 4 custom objects reais (dados, via Data API):

| Objeto | Registros na WILSON_SERVICE (07/07/2026) | Papel |
|---|---|---|
| `GestaoSLA__c` | 4 | Um registro por Unidade de Negócio (Tecon Salvador, Tecon Rio Grande, Centro Logístico, Rebocadores). Configura Business Hours, Entitlement Process, Static Resource do banner, e quais marcos de tempo a unidade usa (Triagem/Resposta Chat/Fila Email). |
| `MarcoSLA__c` | 29 | Marcos de SLA (Triagem, Resposta Chat, Fila Email, etc.) filhos de `GestaoSLA__c` — lookup `GestaoSLA__c` (relationship `MarcosSLA__r`). |
| `Categorizacao__c` | 669 | Árvore de categorização (Assunto/Categoria/Subassunto) por Unidade de Negócio — lookup `GestaoSLA__c` (relationship `Categorizacoes__r`), com regras de distribuição para fila. |
| `RegrasSLACategorizacao__c` | 9.354 | Regra de tempo de SLA por Categorização (ou por Área Interna) e Marco — master-detail com `Categorizacao__c` (relationship `RegrasSLA__r`), mais lookups diretos a `GestaoSLA__c` e `MarcoSLA__c`. |

**Fora do escopo deste export (não são "dado", são metadado — já versionado em `force-app` e vai junto no deploy normal, não precisa de import de dados):**
- `ParametrosAtendimento__mdt` (Custom Metadata Type) — 4 registros em `force-app/main/default/customMetadata/ParametrosAtendimento.*.md-meta.xml`.
- `WS_EmailRoute__mdt` (Custom Metadata Type) — 4 registros em `force-app/main/default/customMetadata/WS_EmailRoute.*.md-meta.xml`.

Esses dois CMDTs bastam ser deployados como metadata (`sf project deploy start`) — não usam `sf data import`.

## Estrutura

```
data/seed-parametros-atendimento/
  query.soql          -> SOQL usada para o export (árvore completa, 1 query com subqueries)
  export/
    plan.json         -> plano de import (ordem: GestaoSLA__c -> MarcoSLA__c -> Categorizacao__c -> RegrasSLACategorizacao__c)
    GestaoSLA__c.json
    MarcoSLA__c.json
    Categorizacao__c.json
    RegrasSLACategorizacao__c.json
```

O export foi feito com `sf data export tree` (SObject Tree API). Os lookups cruzados (`RegrasSLACategorizacao__c.GestaoSLA__c`, `RegrasSLACategorizacao__c.MarcoSLA__c`, `RegrasSLACategorizacao__c.Categorizacao__c`, `MarcoSLA__c.GestaoSLA__c`, `Categorizacao__c.GestaoSLA__c`) foram automaticamente resolvidos como tokens `@GestaoSLA__cRefN` / `@MarcoSLA__cRefN` / `@Categorizacao__cRefN` — no import, o Salesforce recria os relacionamentos com os **novos Ids** gerados na org de destino. Não é necessário nenhum External Id para o import tree em si.

### External ID / IdExterno__c — chave de origem para upsert futuro

Os 4 objetos ganharam um campo `externalId=true` + `unique=true` (`GestaoSLA__c.IdExterno__c`, `MarcoSLA__c.IdExterno__c`, `Categorizacao__c.ExternalId__c`, `RegrasSLACategorizacao__c.IdExterno__c`), populado com o **próprio Id de 18 caracteres do registro na WILSON_SERVICE** (backfill em `scripts/apex/backfill_id_externo_*.apex`). Esse valor:
- **não** é usado pelo `sf data export/import tree` (que já resolve tudo por referência, como descrito acima);
- serve como **fingerprint estável de origem**: como o export/refresh é sempre feito a partir da mesma org (WILSON_SERVICE) e o Id de um registro lá não muda, esse campo permite fazer **upsert via Bulk/Data API** (`sf data upsert bulk --external-id IdExterno__c`/`ExternalId__c`) numa org de destino já populada, sem duplicar registros em reimportações futuras — diferente do `import tree`, que sempre insere.

## Como popular uma nova org

Pré-requisitos na org de destino:
1. Metadata do domínio já deployada (objetos `GestaoSLA__c`, `MarcoSLA__c`, `Categorizacao__c`, `RegrasSLACategorizacao__c` com todos os campos, os Global Value Sets/picklists de Unidade de Negócio, Categoria, Subassunto etc., e os **4 Record Types de `Categorizacao__c`** — `AtendimentoTeconSalvador`/`AtendimentoTeconRioGrande`/`AtendimentoCentroLogistico`/`AtendimentoRebocadores` — com os mesmos valores de picklist habilitados por Record Type que na WILSON_SERVICE. Se a org de destino tiver picklists restritas desatualizadas em relação à WILSON_SERVICE, o import falha com `bad value for restricted picklist field` — comparar `force-app/main/default/objects/Categorizacao__c/recordTypes/*.recordType-meta.xml` contra a org de destino antes de importar).
2. `ParametrosAtendimento__mdt` e `WS_EmailRoute__mdt` deployados (fazem parte do deploy normal de `force-app`).
3. Campo `IdExterno__c` (`GestaoSLA__c`/`MarcoSLA__c`/`RegrasSLACategorizacao__c`) e `ExternalId__c` (`Categorizacao__c`) deployados **e com FLS** para o usuário que vai rodar a carga — o `sf data import tree`/`sf data create record` roda em contexto de usuário real (diferente de Apex anônimo, que roda em modo sistema e não pega gap de FLS). Se o `Admin.profile-meta.xml` completo do repo não deployar na org de destino (ex.: permissão `EditTranslation` desconhecida — depende do Translation Workbench estar habilitado lá, Setup → Translation Workbench → Enable), fazer retrieve do profile Admin **real** daquela org, adicionar o FLS desses 4 campos nele, e deployar essa versão à parte (não sobrescrever o `Admin.profile-meta.xml` do repo, que é específico da WILSON_SERVICE).
4. Org **vazia** desses 4 objetos (ou aceitar duplicar — não há dedupe automático no import tree; ver seção "Reimport / atualização" abaixo).

Comando:

```bash
sf data import tree --plan "data/seed-parametros-atendimento/export/plan.json" --target-org <alias-da-nova-org>
```

O CLI já lida com o limite de 200 registros por requisição da Tree API automaticamente (só funciona com `--plan`, não com `--files` soltos).

### Pegadinhas reais encontradas na primeira carga (WS_QATRISCAL, 07/07/2026)

1. **`Categorizacao__c.Name` e `RegrasSLACategorizacao__c.Name` são AutoNumber** (não createável) — por isso a query em `query.soql` **não** seleciona `Name` desses 2 objetos (só `Id` + campos de negócio). Se algum refresh futuro da query reintroduzir `Name` nesses 2 SELECTs, o import falha com `INVALID_FIELD_FOR_INSERT_UPDATE`.
2. **`RecordTypeId` não é portável entre orgs** — o Id de Record Type da WILSON_SERVICE não existe (ou aponta para outro registro) na org de destino. A query inclui `RecordTypeId` **e** `RecordType.DeveloperName` só para `Categorizacao__c` (único dos 4 objetos com mais de 1 Record Type — os outros 3 têm só `Mestre`). Antes de importar numa org nova, é necessário **traduzir** o `RecordTypeId` de cada registro do `Categorizacao__c.json` para o Id real da org de destino, casando pelo `RecordType.DeveloperName` (os 4 nomes são iguais entre orgs, só o Id de 15/18 char muda). Sem essa tradução, o import falha com `Record Type incompatível com Unidade de Negócio` (ou pior: insere tudo no Record Type errado/default, sem erro nenhum).
3. **Tokens `@GestaoSLA__cRefN`/`@MarcoSLA__cRefN` só resolvem dentro da mesma chamada de import** — se `GestaoSLA__c`/`MarcoSLA__c` já existirem na org de destino (ex.: carga em 2 etapas, ou reimport parcial após corrigir um erro), não dá para reimportar só `Categorizacao__c.json`/`RegrasSLACategorizacao__c.json` mantendo os tokens: eles precisam ser substituídos pelos **Ids reais já existentes** na org de destino antes do import (usar `IdExterno__c` do registro já existente para casar com o `IdExterno__c` do JSON de origem). Não há como misturar tokens `@Ref` com registros pré-existentes na mesma chamada.

Se a query for atualizada no futuro (novos campos, novos objetos), reconferir os pontos 1 e 2 contra a org de destino antes de qualquer carga real.

## Atualizar o snapshot (refresh a partir da WS_SERVICE)

Sempre que a configuração mudar na org de origem e o snapshot precisar ser atualizado:

```bash
sf data export tree --query "data/seed-parametros-atendimento/query.soql" --plan --output-dir "data/seed-parametros-atendimento/export" --target-org WILSON_SERVICE
```

Isso sobrescreve os 5 arquivos em `export/`. Commitar a atualização normalmente.

**Limite da SObject Tree API**: a query raiz (`GestaoSLA__c`) pode retornar no máximo 2.000 registros de topo — não é um problema aqui (são só 4), mas não usar essa mesma query para outro objeto-raiz com muitos registros sem revisar esse limite.

## Reimport / atualização de uma org já populada

O `sf data import tree` sempre **insere** registros novos — não faz upsert/dedupe contra o que já existe na org de destino. Se for reaplicar o seed numa org que já tem alguns desses registros, duas opções:
- **Limpar antes** (`sf data delete bulk` / Apex anônimo) nos 4 objetos, respeitando a ordem inversa de dependência (`RegrasSLACategorizacao__c` → `Categorizacao__c` → `MarcoSLA__c` → `GestaoSLA__c`), e reimportar com `import tree` normalmente; ou
- **Upsert real via Bulk API**, usando o `IdExterno__c`/`ExternalId__c` (já preenchido com o Id de origem da WILSON_SERVICE, ver seção acima) como External ID — permite reaplicar o seed várias vezes na mesma org de destino sem duplicar. Nesse caso os JSON de `export/` não servem diretamente (são formato Tree, sem CSV plano); gerar CSV a partir deles (ou re-exportar via `sf data export bulk`/SOQL para CSV) na ordem `GestaoSLA__c` → `MarcoSLA__c` → `Categorizacao__c` → `RegrasSLACategorizacao__c`, e rodar `sf data upsert bulk --sobject <Objeto> --file <csv> --external-id IdExterno__c --target-org <alias>` (ou `ExternalId__c` para `Categorizacao__c`).

## Verificação pós-import

```bash
sf data query --query "SELECT COUNT(Id) cnt FROM GestaoSLA__c" --target-org <alias>
sf data query --query "SELECT COUNT(Id) cnt FROM MarcoSLA__c" --target-org <alias>
sf data query --query "SELECT COUNT(Id) cnt FROM Categorizacao__c" --target-org <alias>
sf data query --query "SELECT COUNT(Id) cnt FROM RegrasSLACategorizacao__c" --target-org <alias>
```

Esperado (snapshot atual, 07/07/2026): 4 / 29 / 669 / 9.354.

## Histórico de cargas reais

| Data | Org de destino | Resultado |
|---|---|---|
| 07/07/2026 | WS_QATRISCAL | ✅ 4 / 29 / 669 / 9.354 — primeira carga real, revelou as 3 pegadinhas documentadas acima (corrigidas na query/processo) |
