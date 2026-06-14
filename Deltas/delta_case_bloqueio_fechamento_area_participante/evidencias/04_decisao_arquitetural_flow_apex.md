# 04 - Decisão Arquitetural: Flow vs. Apex

## Análise Flow-First obrigatória

### Flows de Case analisados

| Flow | Tipo | Evento | Relação com fechamento/cancelamento |
|---|---|---|---|
| Case_EntitlementAutoAssignment | Record-Triggered | Before Save — Create | Nenhuma — atribui Entitlement na criação |
| Route_from_Will | RoutingFlow | — | Nenhuma — roteamento de Messaging |
| Route_to_Will_Smoke | RoutingFlow | — | Nenhuma — roteamento de Messaging |

**Conclusão Flow:** Não existe Flow de Case para before-update, fechamento, cancelamento, validação de status ou orquestração de participações. Criar um Flow novo seria criar automação paralela onde o Trigger Handler já é o padrão oficial.

### Trigger Handler de Case analisado

- `CaseTrigger` já existe (before insert, before update, after update)
- `CaseTriggerHandler.beforeUpdate` já implementa parcialmente o bloqueio de fechamento
- O handler é o ponto único de orquestração para validações de Case before-update

## Decisão: Estender CaseTriggerHandler existente

**Opção escolhida:** Modificar `CaseTriggerHandler.cls` diretamente.

**Razões:**

1. **Padrão oficial já estabelecido** — O projeto usa Trigger → Handler para Case. Introduzir um Flow paralelo criaria duas fontes de verdade para a mesma regra.

2. **Lógica já parcialmente implementada** — `CaseTriggerHandler.beforeUpdate` já detecta `IsClosed = false → true` e já executa a query de bloqueio. O Pacote 20 adiciona:
   - Detecção de `EtapaAtendimento__c → 'Cancelado'`
   - Filtro `OrigemSLA__c = 'Custom'` na query
   - Mensagem funcional atualizada

3. **Flow puro não é adequado** — A validação requer uma query SOQL de agregação (`COUNT`) em `AreaParticipante__c` com múltiplos filtros. Flow Record-Triggered tem limitações de SOQL em before-save e seria mais frágil que o Apex Handler.

4. **Flow + Apex Invocable não é necessário** — A lógica é pequena e não precisa ser reutilizável externamente. Expor um Invocable apenas para ser chamado por um Flow que substitui um Handler já existente é complexidade desnecessária.

5. **Trigger nova não foi criada** — O `CaseTrigger` já existe; apenas o Handler foi estendido.

## Confirmação de ausência de automação paralela

- Nenhum novo Flow criado
- Nenhuma nova Trigger criada
- Nenhum Apex Invocable criado
- Nenhuma Validation Rule criada
- A regra vive em exatamente UM lugar: `CaseTriggerHandler.beforeUpdate`
