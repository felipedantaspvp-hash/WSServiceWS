public inherited sharing class RegrasSLACategorizacaoService {
    public static void beforeSave(List<RegrasSLACategorizacao__c> rows){
        Set<String> hashes = new Set<String>();
        Set<Id> ids = new Set<Id>();
        for (RegrasSLACategorizacao__c r : rows){
            r.ChaveUnica__c = RegrasSLACategorizacaoHelper.buildKey(r);
            r.ChaveUnicaHash__c = RegrasSLACategorizacaoHelper.hash(r.ChaveUnica__c);

            if (!RegrasSLACategorizacaoHelper.isVigenciaValida(r)) {
                r.addError('VigenciaFim__c nao pode ser menor que VigenciaInicio__c.');
            }

            if (r.Ativo__c == true) {
                validateModeloNovo(r);
                hashes.add(r.ChaveUnicaHash__c);
            }
            if (r.Id != null) ids.add(r.Id);
        }

        Map<String, RegrasSLACategorizacao__c> existing = RegrasSLACategorizacaoSelector.getActiveByKey(hashes, ids);
        Set<String> local = new Set<String>();
        for (RegrasSLACategorizacao__c r : rows){
            if (r.Ativo__c != true) continue;
            if (existing.containsKey(r.ChaveUnicaHash__c)) r.addError('Ja existe regra ativa para essa combinacao.');
            if (local.contains(r.ChaveUnicaHash__c)) r.addError('Duplicidade de regra ativa no mesmo lote.');
            local.add(r.ChaveUnicaHash__c);
        }
    }

    private static void validateModeloNovo(RegrasSLACategorizacao__c r) {
        if (r.GestaoSLA__c == null) r.addError('GestaoSLA__c e obrigatorio para regra ativa no modelo novo.');
        if (String.isBlank(r.EscopoRegra__c)) r.addError('EscopoRegra__c e obrigatorio para regra ativa no modelo novo.');
        if (!RegrasSLACategorizacaoHelper.hasAnyTempoNovoPositivo(r)) {
            r.addError('Pelo menos um tempo (TempoBaixa__c, TempoMedia__c ou TempoAlta__c) deve ser maior que zero.');
        }

        Boolean isTipoAtendimento = RegrasSLACategorizacaoHelper.isEscopoAtendimento(r);
        Boolean isTipoAreaInterna = RegrasSLACategorizacaoHelper.isEscopoAreaInterna(r);

        Boolean escopoValido = isTipoAtendimento || isTipoAreaInterna;
        if (!escopoValido) {
            r.addError('EscopoRegra__c deve ser Atendimento ou Area Interna.');
            return;
        }

        if (isTipoAtendimento) {
            if (r.MarcoSLA__c == null) r.addError('MarcoSLA__c e obrigatorio para escopo Atendimento.');
            if (r.Categorizacao__c == null) r.addError('Categorizacao__c e obrigatorio para escopo Atendimento.');
        }
        if (isTipoAreaInterna) {
            if (r.Categorizacao__c == null) r.addError('Categorizacao__c e obrigatorio para escopo Area Interna.');
            if (String.isBlank(r.AreaAtendimento__c)) r.addError('AreaAtendimento__c e obrigatorio para escopo Area Interna.');
        }
    }
}