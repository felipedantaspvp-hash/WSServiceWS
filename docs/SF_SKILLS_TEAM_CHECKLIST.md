# Checklist de Uso das Salesforce Skills

## Objetivo

Dar ao time um guia rápido de uso da biblioteca oficial de skills Salesforce já implantada no projeto.

## Onde estão as skills

- Biblioteca oficial ativa: `.agents/skills/`
- Skill complementar do projeto: `.agents/skills/triscal-salesforce/SKILL.md`
- Skill histórica preservada: `agents/skills/triscal-salesforce/SKILL.md`

## Checklist rápido antes de pedir algo ao agente

1. Confirmar se a demanda é Salesforce.
2. Conferir se o contexto do projeto está em:
   - `AGENTS.md`
   - `docs/PROJECT_INDEX.md`
   - `AI_HANDLERS.md`
3. Verificar se existe skill específica para o tipo de tarefa.
4. Pedir o menor escopo possível.
5. Informar org alvo, pacote/delta e restrições quando houver.

## Skills mais úteis para o dia a dia deste projeto

### Desenvolvimento Apex

- `generating-apex`
- `generating-apex-test`
- `running-apex-tests`
- `debugging-apex-logs`

Use quando:
- criar ou alterar classes Apex
- ajustar testes
- analisar cobertura
- depurar logs

### Metadados Salesforce

- `deploying-metadata`
- `generating-custom-object`
- `generating-custom-field`
- `generating-permission-set`
- `generating-validation-rule`
- `generating-flexipage`
- `generating-custom-tab`

Use quando:
- criar ou alterar metadata
- fazer deploy/retrieve
- ajustar permission sets
- trabalhar com objetos/campos/layouts

### LWC

- `generating-lwc-components`
- `uplifting-components-to-slds2`
- `reviewing-lwc-mobile-offline`

Use quando:
- criar ou alterar componentes LWC
- revisar SLDS
- avaliar comportamento mobile/offline

### Dados e consultas

- `querying-soql`
- `handling-sf-data`

Use quando:
- montar SOQL
- fazer carga, update, limpeza ou correção de dados

### Arquitetura do projeto

- `triscal-salesforce`

Use sempre como complemento quando a tarefa envolver:
- padrões da Triscal
- leitura seletiva do projeto
- arquitetura Controller > Service > Helper/Selector
- resposta no padrão do repositório

## Como pedir melhor para o agente

Prefira pedidos assim:

```text
Alterar somente o Apex X.
Não alterar LWC.
Não alterar metadata fora do escopo.
Fazer dry-run antes do deploy.
Depois fazer retrieve.
```

Ou:

```text
Criar delta isolado para o objeto Y.
Usar UTF-8 sem BOM.
Sem wildcard no package.xml.
Atualizar evidências.
```

## Checklist antes de deploy

1. Confirmar org alvo.
2. Confirmar que a org foi tratada como fonte da verdade quando houver mudanças manuais.
3. Validar preview/dry-run quando aplicável.
4. Validar UTF-8 sem BOM.
5. Validar ausência de mojibake.
6. Confirmar escopo do delta.
7. Fazer retrieve após deploy, quando solicitado.

## Checklist antes de aceitar entrega

1. O escopo pedido foi respeitado.
2. Não houve alteração fora do pacote.
3. O agente informou testes executados.
4. O agente informou risco.
5. O source local ficou sincronizado com a org.
6. O tracking foi validado quando relevante.

## Atualização da biblioteca oficial

Quando precisar atualizar a biblioteca oficial:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-sf-skills.ps1
```

## Observação

Se existir conflito entre a skill oficial e a convenção do projeto:

- prevalece a convenção do projeto documentada em `AGENTS.md`
- a skill `triscal-salesforce` deve complementar a skill oficial
