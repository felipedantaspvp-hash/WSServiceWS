# README — Pacote 15A: Preparação de Metadata EscopoRegra__c

## 1. Objetivo do Pacote

Preparar o metadata do campo `RegrasSLACategorizacao__c.EscopoRegra__c` para
representar funcionalmente o **Tipo de Regra SLA**, adicionando os novos valores
`Atendimento` e `Area Interna` e atualizando o label do campo.

Este pacote **não altera** código Apex, LWC, testes, dados ou regras de negócio.
Os valores antigos são mantidos temporariamente para compatibilidade com o código existente.

---

## 2. Campo Alterado

| Atributo    | Antes                  | Depois             |
|-------------|------------------------|--------------------|
| API Name    | `EscopoRegra__c`       | `EscopoRegra__c`   |
| Label       | Escopo da Regra        | Tipo de Regra SLA  |
| Tipo        | Picklist (inline)      | Picklist (inline)  |
| required    | false                  | false (inalterado) |

---

## 3. API Name Não Alterado

**CONFIRMADO.** O API Name `EscopoRegra__c` permanece inalterado.
O objeto pai `RegrasSLACategorizacao__c` permanece inalterado.

---

## 4. Valores Adicionados

| fullName (técnico) | label (exibição) | Observação                         |
|--------------------|------------------|------------------------------------|
| `Atendimento`      | Atendimento      | Novo — sem acento                  |
| `Area Interna`     | Área Interna     | Novo — fullName sem acento, label com acento |

**CONFIRMADO.** Ambos os valores foram adicionados ao campo.

---

## 5. Valores Antigos Mantidos

| fullName            | label               | Status         |
|---------------------|---------------------|----------------|
| `Global`            | Global              | Mantido temporariamente |
| `Por Categorizacao` | Por Categorizacao   | Mantido temporariamente |
| `Por Area Interna`  | Por Area Interna    | Mantido temporariamente |

**CONFIRMADO.** Nenhum valor antigo foi removido.
Remoção prevista somente em **Pacote 15D**, após migração de dados.

---

## 6. Nenhum Apex Alterado

**CONFIRMADO.** Nenhuma classe Apex foi criada, modificada ou removida.

---

## 7. Nenhum LWC Alterado

**CONFIRMADO.** Nenhum componente LWC foi criado, modificado ou removido.

---

## 8. Nenhum Dado Atualizado

**CONFIRMADO.** Este pacote é exclusivamente de metadata.
Migração de dados prevista em **Pacote 15C**.

---

## 9. Nenhum destructiveChanges Criado

**CONFIRMADO.** O delta não contém `destructiveChanges.xml` nem `destructiveChangesPre.xml`.

---

## 10. Nenhuma Permission Set Alterada

**CONFIRMADO.** As Permission Sets `GestaoSLAAdminTecnico` e `GestaoSLAConfigurador`
não foram alteradas neste pacote.

---

## 11. UTF-8 Sem BOM

**CONFIRMADO.** Todos os arquivos do delta estão em UTF-8 sem BOM.
O arquivo XML declara `encoding="UTF-8"` no cabeçalho.

---

## 12. Ausência de Mojibake

**CONFIRMADO.** Nenhum caractere corrompido detectado.
Caracteres especiais (acentos em labels e description) estão corretamente codificados em UTF-8.

---

## 13. Dry-Run

Dry-run não executado neste pacote — o delta contém apenas metadata de campo picklist,
sem código ou lógica executável, de baixo risco de regressão.

Para validação antes do deploy em produção, recomenda-se executar:

```bash
sf project deploy start \
  --metadata "CustomField:RegrasSLACategorizacao__c.EscopoRegra__c" \
  --target-org <SANDBOX> \
  --dry-run
```

---

## 14. Próximos Pacotes

| Pacote | Escopo                                                      |
|--------|-------------------------------------------------------------|
| 15B    | Atualizar Apex e LWC para usar `Atendimento` e `Area Interna` |
| 15C    | Migração de dados dos registros existentes                  |
| 15D    | Remover valores antigos (`Global`, `Por Categorizacao`, `Por Area Interna`) |
| Futuro | Remover campos legados (`OrigemSLA__c`, `VigenciaInicio__c`, etc.) |

---

## Estrutura do Delta

```
delta_gestao_sla_escopo_regra_metadata/
├── package.xml
├── README_EVIDENCIAS.md
├── evidencias/
│   ├── 01_arquivos_alterados.txt
│   ├── 02_resumo_tecnico.txt
│   ├── 03_validacao_valores_picklist.txt
│   ├── 04_validacao_escopo.txt
│   ├── 05_validacao_utf8_sem_bom.txt
│   └── 06_pendencias_proximos_pacotes.txt
└── objects/
    └── RegrasSLACategorizacao__c/
        └── fields/
            └── EscopoRegra__c.field-meta.xml
```
