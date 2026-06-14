# 04 - Decisão Arquitetural

## Opções avaliadas

| Opção | Prós | Contras | Decisão |
|---|---|---|---|
| Flow Record-Triggered em AreaParticipante__c | Declarativo | Nenhum Flow existe; criar seria duplicar lógica do Service; não consegue orquestrar em `addParticipation` porque o insert é feito pelo Service | ❌ Descartado |
| Flow + Apex Invocable | Reutilizável por outros flows | Over-engineering para 2 métodos em Service existente | ❌ Descartado |
| Estender `AreaParticipanteService` | Consistente com arquitetura; Service já é ponto central do ciclo de vida; lógica parcial já existia em `closeParticipation()` | — | ✅ Escolhido |
| Estender `AreaParticipanteTriggerHandler` | Cobre todos os caminhos de insert/update | Trigger Handler não tem contexto da diferença Custom vs. Standard com segurança; Service é quem cria e fecha Custom APs | ❌ Descartado |

## Justificativa

1. O projeto adota padrão `Trigger → Handler → Service → Selector`. A lógica de negócio vive no Service.
2. `addParticipation()` e `closeParticipation()` já são os únicos pontos de entrada para o ciclo de vida manual das Áreas Internas.
3. `closeParticipation()` já tinha lógica parcial de orquestração — coerente estendê-la em vez de criar automação paralela.
4. Nenhum Flow de `AreaParticipante__c` existe no projeto.
5. A abordagem Trigger Handler teria que duplicar a lógica de filtragem Custom vs Standard (já presente no Service via `BloqueiaFechamentoCaso__c`).
