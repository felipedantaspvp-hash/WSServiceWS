# 10 - Validação UTF-8 Sem BOM

## Arquivos verificados neste pacote

| Arquivo | BOM detectado | Status |
|---|---|---|
| `force-app/main/default/classes/CaseTriggerHandler.cls` | Não | OK |
| `force-app/main/default/classes/CaseTriggerHandler.cls-meta.xml` | Não | OK |
| `force-app/main/default/classes/CaseTriggerHandlerTest.cls` | Não | OK |
| `force-app/main/default/classes/CaseTriggerHandlerTest.cls-meta.xml` | Não | OK |

## Método de verificação

Verificação via PowerShell:
```powershell
$bytes = [System.IO.File]::ReadAllBytes($file)
$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
```

## Resultado

Todos os arquivos estão em UTF-8 **sem BOM**. Nenhum arquivo com BOM foi criado ou alterado neste pacote.
