# 13 - Pendências e Próximos Pacotes

## Pendências identificadas neste pacote

Nenhuma pendência técnica em aberto. O pacote está completo após dry-run e deploy.

## Observações de design

1. **`Pausada` não está na picklist de StatusAtuacao__c** — A constante `STATUS_ATUACAO_PAUSADA = 'Pausada'` existe no helper e `isOpenStatus()` a inclui, mas o valor não está definido na picklist do campo. Se o status 'Pausada' for introduzido futuramente, o bloqueio já o cobriria via `BloqueiaFechamentoCaso__c = true` (setado pelo AreaParticipanteSLAService ao pausar).

2. **`EtapaAtendimento__c = 'Concluído'` não é detectado como fechamento** — O Pacote 20 detecta apenas `IsClosed = true` e `EtapaAtendimento__c = 'Cancelado'`. Se um Case puder ser "concluído" via `EtapaAtendimento__c = 'Concluído'` sem transicionar para `IsClosed = true`, esse path não seria bloqueado. Pela análise do projeto, a conclusão do Case vai por `Status = 'Fechado'` (IsClosed=true), então este caso não deve ocorrer.

3. **CaseTriggerHandler.beforeInsert está vazio** — Placeholder existente. Sem escopo neste pacote.

## Próximos pacotes recomendados

| Pacote | Objetivo sugerido |
|---|---|
| Pacote 21 | Orquestração: atualizar `EtapaAtendimento__c` automaticamente para 'Aguardando Área Interna' ao acionar Área Interna, e retornar à etapa anterior ao concluir/cancelar todas as APs |
| Pacote 22 | Rastreamento: histórico de mudanças de status de AreaParticipante__c para auditoria e relatório de SLA |
| Pacote 23 | Métricas SLA: campos calculados ou relatórios consolidados de tempo por Área Interna por Case |

## Decisões de negócio pendentes

- **Mapeamento de 'Atendimento N3' para TipoAreaParticipante__c** — Documentado como pendente desde o Pacote 19. Necessita decisão explícita se 'Atendimento N3' deve ser mapeado para 'Área Interna' ou outro tipo.
