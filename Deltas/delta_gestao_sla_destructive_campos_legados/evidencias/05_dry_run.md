# Evidencia 05 - Dry-run

Comando executado para validacao com `RunLocalTests`:

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

Comando executado para validacao de metadata com status final `Succeeded`:

```powershell
sf project deploy start --manifest Deltas/delta_gestao_sla_destructive_campos_legados/package.xml --post-destructive-changes Deltas/delta_gestao_sla_destructive_campos_legados/destructiveChanges.xml --target-org WILSON_SERVICE --dry-run --test-level NoTestRun --wait 30
```

Resultado do segundo dry-run:

- Job ID: `0Afbe00000A9uWfCAJ`
- Status final: `Succeeded`
- `destructiveChanges.xml` aceito
- 4 componentes validados para exclusao
- Nenhuma falha de metadata
- Nenhum teste executado nesse modo

Conclusao consolidada:

- O delta 16B possui validacao bem-sucedida de metadata no org alvo.
- O gate com `RunLocalTests` continua bloqueado por falha global preexistente do ambiente e precisa de correcao do org ou aceite formal de governanca, que nao foi fornecido nesta execucao.
