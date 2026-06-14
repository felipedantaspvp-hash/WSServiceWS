# README Evidências — Delta: Área Participante Case Component (Existing Fix)

**Pacote:** 18 (reformulado) — Ajuste no componente existente caseAreasParticipantesPanel
**Branch:** feat/claude/area-participante-existing-fix
**Data:** 2026-06-14

---

## 1. Contexto e Motivação

O Pacote 18 original criou um novo LWC `caseAreaParticipantePanel` (singular).
Este foi descartado porque a tela real `LP_Atendimento_Salvador` já usa o componente
`caseAreasParticipantesPanel` (plural), criado por Marllon Nascimento em 2026-05-25, com
funcionalidades superiores (bilíngue, modal de detalhes, agrupamento, status pills).

Este pacote reformulado:
- Ajusta o componente **existente** `caseAreasParticipantesPanel`
- Descarta e exclui `caseAreaParticipantePanel` do source
- Mantém e preserva todas as funcionalidades superiores do componente existente

---

## 2. Ajustes Aplicados

| Arquivo | Mudança |
|---------|---------|
| `caseAreasParticipantesPanel.js` | Adicionado getter `canManage`, método `handleRefresh`, label `refresh` em PT+EN |
| `caseAreasParticipantesPanel.html` | Botão Atualizar adicionado; botão Adicionar gateado por `if:true={canManage}` |
| `caseAreasParticipantesPanel.js-meta.xml` | Adicionado `<masterLabel>Áreas Participantes SLA</masterLabel>` |

---

## 3. Funcionalidades Preservadas

| Funcionalidade | Status |
|----------------|--------|
| Bilíngue PT + EN (`@salesforce/i18n/lang`) | ✓ preservado |
| Modal de Detalhes (`getParticipationDetails`) | ✓ preservado |
| Agrupamento Aberto / Concluídas (colapsável) | ✓ preservado |
| 8 variações de status pills (`buildClassificationPills`) | ✓ preservado |
| Presença na `LP_Atendimento_Salvador` | ✓ sem alteração na FlexiPage |
| Ordenação por status rank | ✓ preservado |
| Barra de progresso com `percentualDecorrido` | ✓ preservado |
| Exibição de tempos SLA (consumido, restante, total, pausado) | ✓ preservado |

---

## 4. Melhorias Aplicadas

| Melhoria | Descrição |
|----------|-----------|
| `canManage` | Botão Adicionar agora responde ao flag `PanelDTO.canManage` do backend (CRUD/FLS) |
| Botão Atualizar | Permite ao atendente recarregar o painel manualmente sem sair da página |
| `masterLabel` | Identificação amigável no App Builder: "Áreas Participantes SLA" |

---

## 5. Componente Descartado

| Artefato | Ação |
|----------|------|
| `force-app/main/default/lwc/caseAreaParticipantePanel/` | `git rm -r` — 4 arquivos excluídos |
| `Deltas/delta_area_participante_case_component/` | Não promover — substituído pelo presente pacote |

---

## 6. Estrutura do ZIP

```
delta_area_participante_case_component_existing_fix/
├── package.xml
├── README_EVIDENCIAS.md
├── evidencias/
│   ├── 01_confirmacao_lp_atendimento_salvador.md
│   ├── 02_confirmacao_componente_novo_descartado.md
│   ├── 03_arquivos_alterados.md
│   ├── 04_metodos_apex_consumidos.md
│   ├── 05_confirmacao_bilingue.md
│   ├── 06_confirmacao_modal_agrupamento.md
│   ├── 07_confirmacao_campos_removidos_16b.md
│   └── 08_validacao_utf8_sem_mojibake.md
└── lwc/
    └── caseAreasParticipantesPanel/
        ├── caseAreasParticipantesPanel.html
        ├── caseAreasParticipantesPanel.js
        ├── caseAreasParticipantesPanel.css
        └── caseAreasParticipantesPanel.js-meta.xml
```

---

## 7. Dry-Run

| Campo | Valor |
|-------|-------|
| Deploy ID | `0Afbe00000A9ydVCAR` |
| Status | **Succeeded** |
| Componentes | 1/1 (100%) |
| Elapsed | 5.61s |
| Org | jduarte@wilsonsons.com.br.service |

Componentes validados:

| Ação | Componente | Tipo |
|------|-----------|------|
| Changed | `caseAreasParticipantesPanel` | LightningComponentBundle (.css) |
| Changed | `caseAreasParticipantesPanel` | LightningComponentBundle (.html) |
| Changed | `caseAreasParticipantesPanel` | LightningComponentBundle (.js) |
| Changed | `caseAreasParticipantesPanel` | LightningComponentBundle (.js-meta.xml) |

---

## 8. Regras Respeitadas

| Regra | Status |
|-------|--------|
| Não incluir caseAreaParticipantePanel | ✓ |
| Não alterar lógica Apex | ✓ |
| Não alterar metadata (objetos, campos, PS) | ✓ |
| Não usar campos removidos no 16B | ✓ |
| Não calcular SLA no JavaScript | ✓ |
| Não criar destructiveChanges | ✓ |
| Não alterar FlexiPage | ✓ |
| ZIP salvo na raiz do projeto | ✓ (a executar) |
