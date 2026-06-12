# SALESFORCE_FLOW_GUIDE.md

## Quando consultar

Leia este arquivo quando a tarefa envolver Flow, automação declarativa, Invocable Apex, reentrada, recursão ou bulk safety.

## Tipos permitidos

- Record-Triggered Flow.
- Screen Flow.
- Autolaunched Flow.
- Scheduled Flow.
- Platform Event-Triggered Flow.
- Subflow.

## Preferências

- Before-Save: atualização simples no próprio registro.
- After-Save: registros relacionados, notificações, ações dependentes de ID.
- Screen Flow: interação guiada.
- Autolaunched: lógica reutilizável.
- Scheduled: processamento programado.
- Platform Event: evento assíncrono.

## Bulk safety

Todo Record-Triggered Flow deve funcionar com múltiplos registros.

Considerar:

- Data Loader.
- Integrações.
- Atualizações em lote.
- Processos assíncronos.
- Reprocessamento.
- Recursão.

## Proibido dentro de Loop

- Get Records.
- Create Records.
- Update Records.
- Delete Records.
- Actions repetitivas sem necessidade.
- Subflows que executem DML sem controle.
- Chamadas externas repetitivas sem justificativa.

## Padrão correto

```text
Antes do Loop:
- Get Records necessários.
- Preparar coleções e variáveis.

Durante o Loop:
- Avaliar condições.
- Fazer Assignments.
- Montar coleções.

Depois do Loop:
- Executar DML uma única vez usando coleção.
```

## Validação de campos

Antes de Assignment/Create/Update, validar se o campo é editável e não é:

- Fórmula.
- Auto Number.
- Roll-Up Summary.
- Somente leitura.
- Calculado.
- Controlado pelo sistema.
- Sem FLS de escrita.

## Idempotência

Avaliar:

- Pode executar novamente?
- Pode criar duplicado?
- Pode enviar notificação duplicada?
- Pode atualizar repetidamente?
- Há chave/critério para saber se já executou?

Usar campos de controle, status, chave externa, Custom Metadata, critérios restritos e deduplicação quando necessário.

## Fault paths

Flows críticos devem ter Fault Path em DML/Actions, registro de erro quando aplicável e mensagem amigável sem stack trace ou dados sensíveis.

## Nomenclatura

Evitar `var1`, `record`, `temp`, `Decision1`, `Assignment1`.

Preferir nomes funcionais:

```text
varAccountId
recOpportunity
colCasesToUpdate
decHasActiveContract
asgPrepareCasesForUpdate
getActiveRecordTypeByDeveloperName
```

## Invocable Apex

Padrão:

```text
Flow → FlowAction/Invocable Apex → Service → ServiceAgent/Helper/Selector
```

Invocable deve ser fino, bulkificado, receber lista de requests, mapear DTO, chamar Service e retornar lista de responses.
