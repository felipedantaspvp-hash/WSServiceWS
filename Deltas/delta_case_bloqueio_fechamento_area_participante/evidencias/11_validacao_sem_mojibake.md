# 11 - Validação: Ausência de Mojibake

## Definição

Mojibake ocorre quando texto UTF-8 com caracteres especiais (acentos, ç, ã) é gravado ou lido com encoding incorreto, gerando sequências ilegíveis como "ÃƒÂ©" no lugar de "é".

## Strings com caracteres especiais neste pacote

| String | Arquivo | Exibição esperada |
|---|---|---|
| `'Existem áreas internas abertas. Conclua ou cancele as áreas participantes antes de fechar ou cancelar o caso.'` | CaseTriggerHandler.cls | Mensagem legível em português |
| `'Área Interna'` | CaseTriggerHandler.cls (via constante TIPO_AREA_INTERNA) | Valor correto do picklist |
| `'Concluída'`, `'Cancelada'` | AreaParticipanteSLAHelper.cls | Constantes existentes, não alteradas |
| `'Em Atendimento'`, `'Em Acompanhamento'` | CaseTriggerHandlerTest.cls | Valores de picklist EtapaAtendimento__c |

## Verificação

Os arquivos foram escritos diretamente pela ferramenta Write do Claude Code (UTF-8 sem BOM). Os caracteres acentuados foram inseridos como UTF-8 válido. Não houve conversão de encoding intermediário.

## Resultado

Nenhuma ocorrência de mojibake detectada. Todos os caracteres especiais estão corretamente codificados em UTF-8.
