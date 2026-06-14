# Validacao pos-deploy 16B

1. Confirmar no org que os campos abaixo nao existem mais:
   - `RegrasSLACategorizacao__c.Origem__c`
   - `RegrasSLACategorizacao__c.VigenciaInicio__c`
   - `RegrasSLACategorizacao__c.VigenciaFim__c`
   - `AreaParticipante__c.TipoAtuacao__c`
2. Confirmar que os campos preservados seguem ativos:
   - `AreaParticipante__c.OrigemSLA__c`
   - `AreaParticipante__c.TipoAreaParticipante__c`
3. Rodar os testes relacionados a Gestao SLA e Area Participante no ambiente alvo.
4. Validar a tela de Gestao SLA:
   - regras de Atendimento funcionando;
   - regras de Area Interna funcionando;
   - Origem e Vigencia nao aparecem.
5. Validar Area Participante:
   - `TipoAreaParticipante__c` continua sendo a classificacao oficial;
   - `TipoAtuacao__c` nao aparece.
