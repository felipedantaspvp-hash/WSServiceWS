# 14 - Pendencias e proximos pacotes

## Pendencias

- `StatusAtuacao__c` nao possui valor `Pausada`; por isso a pausa manual usa `StatusSLA__c = Pausado` e `DataHoraInicioPausa__c`.
- Nao existem `MotivoPausa__c` nem `DataHoraFimPausa__c`.
- Code Analyzer nao executou por dependencia local ausente de Python para engine `flow` e referencias `.claude/skills` inexistentes.

## Proximos pacotes recomendados

- Avaliar criacao governada de `MotivoPausa__c` ou historico de pausas.
- Avaliar UX no `caseAreasParticipantesPanel` para acionar `pauseParticipation` e `resumeParticipation`.
- Harmonizar metadata local de `StatusAtuacao__c` se a governanca decidir criar valor oficial `Pausada`.
