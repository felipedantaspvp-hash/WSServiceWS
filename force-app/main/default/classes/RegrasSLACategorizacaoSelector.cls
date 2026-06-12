public inherited sharing class RegrasSLACategorizacaoSelector {
    public static Map<String, RegrasSLACategorizacao__c> getActiveByKey(Set<String> keys, Set<Id> ignoreIds){
        Map<String, RegrasSLACategorizacao__c> out = new Map<String, RegrasSLACategorizacao__c>();
        if (keys.isEmpty()) return out;
        for (RegrasSLACategorizacao__c r : [SELECT Id,Categorizacao__c,TipoAreaParticipante__c,AreaAtendimento__c,Origem__c,Ativo__c,ChaveUnicaHash__c FROM RegrasSLACategorizacao__c WHERE Ativo__c = true AND ChaveUnicaHash__c IN :keys]) {
            if (ignoreIds != null && ignoreIds.contains(r.Id)) continue;
            out.put(r.ChaveUnicaHash__c, r);
        }
        return out;
    }

    public static List<RegrasSLACategorizacao__c> findActiveRules(Set<Id> categIds, Set<String> tipos, Set<String> areas, Set<String> origens){
        return [
            SELECT Id,Categorizacao__c,TipoAreaParticipante__c,AreaAtendimento__c,Origem__c,BusinessHoursName__c,Ativo__c,
                   GestaoSLA__c,MarcoSLA__c,EscopoRegra__c,TempoBaixa__c,TempoMedia__c,TempoAlta__c,VigenciaInicio__c,VigenciaFim__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
              AND Categorizacao__c IN :categIds
              AND TipoAreaParticipante__c IN :tipos
              AND AreaAtendimento__c IN :areas
              AND Origem__c IN :origens
        ];
    }

    public static List<RegrasSLACategorizacao__c> findAllActiveForCompatibility() {
        return [
            SELECT Id,Categorizacao__c,TipoAreaParticipante__c,AreaAtendimento__c,Origem__c,
                   BusinessHoursName__c,Ativo__c,ChaveUnica__c,ChaveUnicaHash__c,
                   GestaoSLA__c,MarcoSLA__c,EscopoRegra__c,TempoBaixa__c,TempoMedia__c,TempoAlta__c,
                   VigenciaInicio__c,VigenciaFim__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
        ];
    }

    public static List<RegrasSLACategorizacao__c> findActiveRulesNovoN3(
        Set<Id> gestaoIds,
        Set<Id> marcoIds,
        Set<Id> categIds,
        Set<String> areas,
        Set<String> origens
    ) {
        if (gestaoIds.isEmpty() || marcoIds.isEmpty() || categIds.isEmpty() || areas.isEmpty() || origens.isEmpty()) {
            return new List<RegrasSLACategorizacao__c>();
        }
        return [
            SELECT Id,Categorizacao__c,AreaAtendimento__c,Origem__c,Ativo__c,BusinessHoursName__c,
                   GestaoSLA__c,MarcoSLA__c,EscopoRegra__c,TempoBaixa__c,TempoMedia__c,TempoAlta__c,
                   VigenciaInicio__c,VigenciaFim__c,TipoAreaParticipante__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
              AND GestaoSLA__c IN :gestaoIds
              AND MarcoSLA__c IN :marcoIds
              AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_POR_AREA_INTERNA
              AND Categorizacao__c IN :categIds
              AND AreaAtendimento__c IN :areas
              AND Origem__c IN :origens
        ];
    }
}