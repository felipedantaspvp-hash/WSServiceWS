# Evidencia 05 - Dry-run

Comando previsto para validacao:

```powershell
sf project deploy start --manifest Deltas/delta_gestao_sla_destructive_campos_legados/package.xml --post-destructive-changes Deltas/delta_gestao_sla_destructive_campos_legados/destructiveChanges.xml --target-org WILSON_SERVICE --dry-run --test-level RunLocalTests --wait 30
```

Resultado executado em `2026-06-13` contra `WILSON_SERVICE`:

- Job ID: `0Afbe00000A9uRpCAJ`
- `destructiveChanges.xml` aceito pela Metadata API.
- Os 4 `CustomField` alvo foram validados como exclusoes elegiveis:
  - `AreaParticipante__c.TipoAtuacao__c`
  - `RegrasSLACategorizacao__c.Origem__c`
  - `RegrasSLACategorizacao__c.VigenciaInicio__c`
  - `RegrasSLACategorizacao__c.VigenciaFim__c`
- Nenhuma falha de componente de metadata foi registrada.

Status final do dry-run:

- `Failed`, mas por motivo fora do escopo do pacote: `431` falhas em `RunLocalTests`.
- Causa-raiz recorrente nos testes/classes invalidas: `Method does not exist or incorrect signature: void remarkProductMass() from the type DataMass`.
- Conclusao: o pacote destrutivo esta tecnicamente valido; a org nao passou no gate global de testes por um problema preexistente e nao relacionado ao 16B.
