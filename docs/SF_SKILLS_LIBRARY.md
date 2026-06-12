# Salesforce Skills Library no Projeto

## Objetivo

Padronizar o uso da biblioteca oficial de skills Salesforce no projeto, com versionamento local e processo simples de atualização.

## Repositório avaliado

- Repositório oficial: `forcedotcom/sf-skills`
- URL: `https://github.com/forcedotcom/sf-skills`
- Branch implantada: `main`
- Commit implantado: `672707e0d70898f7c4673c4ce5089b3155491f0d`

## Conclusão da avaliação

- O repositório é a biblioteca oficial e curada de skills Salesforce para agentes de IA.
- A estrutura segue o padrão aberto de Agent Skills.
- O foco é desenvolvimento Salesforce com cobertura ampla:
  - Apex
  - LWC
  - Flow
  - objetos e campos
  - permission sets
  - integrações
  - Data Cloud
  - OmniStudio
  - Agentforce
  - deploy e testes

## Implantação realizada neste projeto

- A biblioteca oficial foi sincronizada em `.agents/skills/`.
- A versão implantada foi registrada em `.agents/SF_SKILLS_VERSION.json`.
- A skill local do projeto `triscal-salesforce` foi exposta também em `.agents/skills/triscal-salesforce/`.

## Estrutura adotada

```text
.agents/
├── SF_SKILLS_VERSION.json
└── skills/
    ├── generating-apex/
    ├── generating-lwc-components/
    ├── deploying-metadata/
    ├── handling-sf-data/
    ├── ...
    └── triscal-salesforce/
```

## Convenção de uso

- Skills oficiais: usar a biblioteca oficial sincronizada em `.agents/skills`.
- Skill local do projeto: usar `triscal-salesforce` como camada complementar com padrões Triscal, leitura seletiva e contexto do repositório.

## Atualização futura

Para atualizar a biblioteca oficial sem perder a skill local do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-sf-skills.ps1
```

## Material de apoio para o time

- Guia operacional rápido: `docs/SF_SKILLS_TEAM_CHECKLIST.md`

## Observação importante

- Existe também uma pasta `agents/skills/` no projeto com a skill histórica `triscal-salesforce`.
- A biblioteca ativa do agente foi padronizada em `.agents/skills/`.
- A skill histórica foi preservada e replicada para o caminho ativo, evitando quebra de compatibilidade.
