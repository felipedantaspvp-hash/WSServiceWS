---
name: triscal-salesforce
description: "CAMADA BASE OBRIGATÓRIA — SEMPRE ATIVE antes de qualquer skill sf-skills em qualquer tarefa Salesforce deste repositório Triscal. TRIGGER: Apex, LWC, Flow, Metadata, Deploy, Integração, Teste, Análise, Documentação ou Code Review Salesforce. NÃO SUBSTITUI sf-skills — elas complementam este padrão base. Impõe: PROJECT_INDEX.md antes de agir, arquitetura Controller→Service→ServiceAgent, declarative-first, segurança CRUD/FLS/Sharing, cobertura ≥95% em Apex alterado, UTF-8 em metadados."
---

# Skill: Triscal Salesforce

## Fluxo obrigatório

1. Consulte `docs/PROJECT_INDEX.md` (crie/atualize se ausente).
2. Identifique arquivos candidatos; abra somente os relevantes.
3. Aplique `AI_HANDLERS.md`.
4. Selecione skill(s) sf-skills pela matriz de roteamento em `AGENTS.md`.
5. Implemente a menor mudança que resolva o problema com segurança.

Não assuma nomes de classes, campos, objetos, RecordTypes, Flows, layouts ou permissões sem validar.

---

## Ordem de solução

```text
Configuração nativa > Flow > Apex > LWC
```

**Flow** quando: lógica declarável, ≤2000 registros simultâneos, sem callout externo, sem reuso entre canais.
**Apex** quando: volume alto, integração externa, transação, lógica complexa, assíncrono ou reuso entre canais.
**LWC** apenas quando componentes base, App Builder, Dynamic Forms ou Screen Flow não atenderem.

---

## Regras essenciais — Apex

- Nunca SOQL/DML em loop. Bulkificar métodos. Usar `List`, `Set`, `Map`.
- Sem IDs hardcoded, ProfileName ou RecordTypeId hardcoded.
- Custom Metadata para regras configuráveis; Named Credential para endpoint/auth.
- Tratar exceções com significado; não silenciar. Considerar sharing, CRUD e FLS.
- Criar/ajustar teste para todo Apex alterado; buscar ≥95% de cobertura.
- Cabeçalho JSDoc obrigatório em classes novas/relevantes: ver `docs/agent-reference/SALESFORCE_COMMENTS_TESTS_GUIDE.md`.

---

## Regras essenciais — Flow

- Record-Triggered Flow deve ser bulk safe.
- Get antes do Loop; DML uma vez após o Loop. Nunca Get/DML dentro de Loop.
- Fault Paths em flows críticos. Considerar idempotência e recursão.
- Ver `docs/agent-reference/SALESFORCE_FLOW_GUIDE.md`.

---

## Regras essenciais — LWC

- Componentes base Salesforce, SLDS, responsivo, acessível.
- Tratar loading / empty / error / success. Regra crítica vive no Apex, não no front-end.

---

## Fonte de metadados

| Necessidade | Fonte |
|---|---|
| Source versionado | Arquivos locais |
| Estrutura objeto/campo | Describe / sObject Describe |
| Dados de negócio | SOQL / REST |
| Diagnóstico técnico | Tooling API |
| XML / deploy / retrieve | Metadata API / SF CLI |
| Experiência por usuário | UI API |
| Execução e rastreabilidade | Logs / Auditoria |

Nunca assumir que campo, Flow, RecordType, layout, Permission Set ou Named Credential existe sem validar.  
Detalhes: `docs/agent-reference/SALESFORCE_METADATA_GUIDE.md`.

---

## Metadados declarativos

- Objetos e campos devem ter `Description`.
- Validation Rules: description é dev-facing; mensagem é orientada ao usuário (sem stack trace).
- Campos novos: considerar FLS, layout, Dynamic Forms, relatório, integração e tradução.
- Preferir Permission Sets a Profiles. Lightning Pages: Field Section > Record Detail; Highlights Panel com Dynamic Actions.
- Ver `docs/agent-reference/SALESFORCE_BUILD_GUIDELINES.md`.

---

## Segurança e DevOps

- CRUD / FLS / Sharing / Permission Sets / Custom Permissions / RecordType access.
- Dados sensíveis/LGPD. Logs sem dados confidenciais. Sem segredo/token em código/metadado.
- Flosum: branch, snapshot, predeploy fix, overwrite protection, peer review, pipeline, deploy, backpromotion.
- Ver `docs/agent-reference/SALESFORCE_SECURITY_DEVOPS_GUIDE.md`.

---

## Formato de resposta

Implementação/análise:
```text
Conclusão: ...
Arquivos analisados: ...
Alteração proposta/realizada: ...
Risco: Baixo/Médio/Alto — motivo.
Testes: ...
Próximo passo: ...
```
Correção simples: `Causa: ...  Correção: ...  Teste: ...`
