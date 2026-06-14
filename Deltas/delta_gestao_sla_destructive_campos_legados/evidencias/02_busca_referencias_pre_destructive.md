# Evidencia 02 - Busca de referencias pre-destructive

Comando executado no projeto:

```powershell
rg -n "Origem__c|VigenciaInicio__c|VigenciaFim__c|TipoAtuacao__c" force-app/main/default
```

Resultado consolidado:

- Nenhuma referencia funcional encontrada em Apex, LWC, Flow, Permission Set, Profile, Layout, Report, Dashboard, Field Set, Record Type, DTO, Selector, Service, Helper ou testes.
- Ocorrencias esperadas:
  - os proprios arquivos `field-meta.xml` dos 4 campos alvo;
  - campo ativo `MarcoSLA__c.UsaOrigem__c`;
  - campo ativo `ParametrosAtendimento__mdt.CanalOrigem__c`.

Conclusao:

- O projeto nao apresenta dependencia funcional ativa dos 4 campos alvo.
- O destructive pode seguir para validacao em dry-run.
