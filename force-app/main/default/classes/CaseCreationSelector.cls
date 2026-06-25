public inherited sharing class CaseCreationSelector {
    public class UnidadeConfig {
        public String recordTypeDeveloperName;
        public String unidadeNegocio;
        public String queueToken;
        public Boolean ativo;
    }

    @TestVisible private static Map<String, UnidadeConfig> testConfigs;
    @TestVisible private static List<Categorizacao__c> testCategorizacoes;

    public static User getCurrentUser() {
        return [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    public static List<RecordType> getCaseRecordTypes() {
        return [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType='Case' AND IsActive=true ORDER BY Name];
    }

    public static Map<String, UnidadeConfig> getUnidadeConfigByRtDevName() {
        if (testConfigs != null) return testConfigs;
        Map<String, UnidadeConfig> out = new Map<String, UnidadeConfig>();
        for (AtendimentoConfigDTO m : AtendimentoConfigService.getActiveConfigs()) {
            UnidadeConfig c = new UnidadeConfig();
            c.recordTypeDeveloperName = m.caseRecordTypeDeveloperName;
            c.unidadeNegocio = m.businessUnit;
            c.queueToken = m.queueDeveloperNamePrefix;
            c.ativo = m.isActive;
            if (String.isBlank(c.recordTypeDeveloperName)) continue;
            if (!out.containsKey(c.recordTypeDeveloperName) || (out.get(c.recordTypeDeveloperName).ativo != true && c.ativo == true)) {
                out.put(c.recordTypeDeveloperName, c);
            }
        }
        return out;
    }

    public static UnidadeConfig findConfigForCaseRecordType(String caseRtDeveloperName, String caseRtLabel) {
        Map<String, UnidadeConfig> cfg = getUnidadeConfigByRtDevName();
        List<UnidadeConfig> values = cfg.values();

        for (UnidadeConfig item : values) {
            if (item == null || item.ativo != true) continue;
            if (String.valueOf(item.recordTypeDeveloperName) == String.valueOf(caseRtDeveloperName)) return item;
        }
        for (UnidadeConfig item : values) {
            if (item == null || item.ativo != true) continue;
            if (CaseCreationHelper.keyMatches(caseRtDeveloperName, item.recordTypeDeveloperName)) return item;
            if (CaseCreationHelper.keyMatches(caseRtLabel, item.recordTypeDeveloperName)) return item;
            if (CaseCreationHelper.keyMatches(caseRtDeveloperName, item.unidadeNegocio)) return item;
            if (CaseCreationHelper.keyMatches(caseRtLabel, item.unidadeNegocio)) return item;
            if (CaseCreationHelper.keyMatches(caseRtDeveloperName, 'tecon' + item.unidadeNegocio)) return item;
            if (CaseCreationHelper.keyMatches(caseRtLabel, 'tecon' + item.unidadeNegocio)) return item;
            if (CaseCreationHelper.keyMatches(caseRtDeveloperName, 'centrologistico') && CaseCreationHelper.keyMatches(item.recordTypeDeveloperName, 'centrologistico')) return item;
            if (CaseCreationHelper.keyMatches(caseRtLabel, 'logistica') && CaseCreationHelper.keyMatches(item.recordTypeDeveloperName, 'centrologistico')) return item;
        }

        if (cfg.containsKey(caseRtDeveloperName) && cfg.get(caseRtDeveloperName).ativo == true) return cfg.get(caseRtDeveloperName);
        for (String key : cfg.keySet()) {
            UnidadeConfig item = cfg.get(key);
            if (item == null || item.ativo != true) continue;
            if (CaseCreationHelper.keyMatches(caseRtDeveloperName, key)) return item;
            if (CaseCreationHelper.keyMatches(caseRtLabel, key)) return item;
        }
        return null;
    }

    public static String resolveCanonicalBusinessUnit(String businessUnitName) {
        if (String.isBlank(businessUnitName)) return null;
        String normalizedInput = CaseCreationHelper.normalizeText(businessUnitName);
        for (UnidadeConfig item : getUnidadeConfigByRtDevName().values()) {
            if (item == null || item.ativo != true) continue;
            if (CaseCreationHelper.normalizeText(item.unidadeNegocio) == normalizedInput) return item.unidadeNegocio;
            if (CaseCreationHelper.normalizeText(item.recordTypeDeveloperName) == normalizedInput) return item.unidadeNegocio;
        }
        return CaseCreationHelper.normalizeBusinessUnitForCase(businessUnitName);
    }

    public static UnidadeConfig findConfigForBusinessUnit(String businessUnitName) {
        if (String.isBlank(businessUnitName)) return null;
        String normalizedInput = CaseCreationHelper.normalizeText(businessUnitName);
        for (UnidadeConfig item : getUnidadeConfigByRtDevName().values()) {
            if (item == null || item.ativo != true) continue;
            if (CaseCreationHelper.normalizeText(item.unidadeNegocio) == normalizedInput) return item;
            if (CaseCreationHelper.normalizeText(item.recordTypeDeveloperName) == normalizedInput) return item;
        }
        return null;
    }

    public static Set<Id> getCategorizacaoRecordTypeIdsForCaseRt(String caseRtDeveloperName, String unidadeNegocio) {
        Set<Id> out = new Set<Id>();
        UnidadeConfig cfg = findConfigForCaseRecordType(caseRtDeveloperName, unidadeNegocio);
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Categorizacao__c' AND IsActive=true]) {
            if (CaseCreationHelper.keyMatches(caseRtDeveloperName, rt.DeveloperName) || CaseCreationHelper.keyMatches(unidadeNegocio, rt.DeveloperName)) {
                out.add(rt.Id);
                continue;
            }
            if (cfg != null && CaseCreationHelper.keyMatches(cfg.recordTypeDeveloperName, rt.DeveloperName)) {
                out.add(rt.Id);
            }
        }
        return out;
    }

    public static List<Categorizacao__c> getActiveCategorizacoes(String caseRtDeveloperName, String unidadeNegocio) {
        if (testCategorizacoes != null) return testCategorizacoes;
        Set<Id> categRtIds = getCategorizacaoRecordTypeIdsForCaseRt(caseRtDeveloperName, unidadeNegocio);
        if (categRtIds.isEmpty()) return new List<Categorizacao__c>();
        Set<String> unidadesNegocio = getBusinessUnitAliases(unidadeNegocio);
        return [
            SELECT Id, TipoCaso__c, toLabel(TipoCaso__c) TipoCasoLabel,
                Categoria__c, toLabel(Categoria__c) CategoriaLabel,
                Assunto__c, toLabel(Assunto__c) AssuntoLabel,
                Subassunto__c, toLabel(Subassunto__c) SubassuntoLabel,
                Prioridade__c,
                RecordTypeId, UnidadeNegocios__c,
                DistribuirParaFila__c, PorCampoCustomizado__c, FilaDeveloperName__c,
                CampoDistribuicao__c, ValorDistribuicao__c,
                FilaDeveloperNameFallback__c, PermiteAssumirComFilaParametrizada__c,
                EtapaAtendimentoDistribuicao__c
            FROM Categorizacao__c
            WHERE Ativo__c = true
                AND RecordTypeId IN :categRtIds
                AND UnidadeNegocios__c IN :unidadesNegocio
        ];
    }

    @TestVisible
    private static Set<String> getBusinessUnitAliases(String unidadeNegocio) {
        Set<String> out = new Set<String>();
        if (!String.isBlank(unidadeNegocio)) out.add(unidadeNegocio);

        String canonical = CaseCreationHelper.normalizeBusinessUnitForCase(unidadeNegocio);
        if (!String.isBlank(canonical)) out.add(canonical);

        String normalized = CaseCreationHelper.normalizeText(canonical);
        if (normalized.contains('salvador')) {
            out.add('Salvador');
            out.add('Atendimento Salvador');
            out.add('Tecon Salvador');
        } else if (normalized.contains('riogrande')) {
            out.add('Rio Grande');
            out.add('RioGrande');
            out.add('Atendimento Rio Grande');
            out.add('Atendimento Tecon Rio Grande');
            out.add('Tecon Rio Grande');
        }
        return out;
    }

    public static Map<String, Group> getQueuesByDeveloperName(Set<String> developerNames) {
        Map<String, Group> out = new Map<String, Group>();
        if (developerNames.isEmpty()) return out;
        for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type='Queue' AND DeveloperName IN :developerNames]) out.put(g.DeveloperName, g);
        return out;
    }

    public static Set<Id> getCaseEnabledQueueIds(Set<Id> queueIds) {
        Set<Id> out = new Set<Id>();
        if (queueIds.isEmpty()) return out;
        for (QueueSobject qs : [SELECT QueueId FROM QueueSobject WHERE QueueId IN :queueIds AND SobjectType='Case']) out.add(qs.QueueId);
        return out;
    }

    public static List<Group> getCaseQueuesByToken(String token) {
        if (String.isBlank(token)) return new List<Group>();
        return [SELECT Id, Name, DeveloperName FROM Group WHERE Type='Queue' AND DeveloperName LIKE :('%' + token + '%') ORDER BY Name];
    }
}