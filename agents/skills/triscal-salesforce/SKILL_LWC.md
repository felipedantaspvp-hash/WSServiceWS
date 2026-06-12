# SKILL_LWC.md — Regras LWC

> Carregar somente para tarefas: Lightning Web Component, Aura, Screen Flow com componente customizado.

## Regras obrigatórias

- Usar componentes base Salesforce quando possível.
- Seguir SLDS — não customizar estilos que o SLDS já entrega.
- Ser responsivo e acessível (ARIA, labels, navegação por teclado).
- Tratar os quatro estados: `loading`, `empty`, `error` e `success`.
- Não manter regra crítica de negócio apenas no front-end.
- Apex deve validar segurança e regra de negócio.
- Usar Custom Labels quando houver texto traduzível.
- Não expor IDs técnicos ou dados sensíveis sem necessidade.
- Usar Wire quando possível; Imperative Apex só quando necessário.
- Separar lógica de apresentação de lógica de negócio.
