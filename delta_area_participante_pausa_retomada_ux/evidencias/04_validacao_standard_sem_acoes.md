# 04 - Validacao Standard sem acoes

Registros Standard espelhados de CaseMilestone recebem `canPause = false` e `canResume = false` no backend.

O LWC nao decide isso por `caseMilestoneId`; ele apenas respeita as flags derivadas do DTO.

Mesmo que a UI fosse manipulada, o backend do Pacote 22 rejeita registros que nao sejam Area Interna Custom.
