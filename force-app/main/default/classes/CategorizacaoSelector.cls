public inherited sharing class CategorizacaoSelector {
    public class UnidadeConfig {
        public String recordTypeDeveloperName;
        public String unidadeNegocio;
        public String queuePrefix;
        public Boolean ativo;
    }

    public class QueueData {
        public Id id;
        public String name;
        public String developerName;
    }

    @TestVisible private static Map<String, UnidadeConfig> testConfigs;
    @TestVisible private static Map<String, QueueData> testQueuesByDevName;

    public static Categorizacao__c getById(Id id) {
        List<Categorizacao__c> rows = [
            SELECT Id, RecordTypeId, RecordType.DeveloperName, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c,
                Subassunto__c, Prioridade__c, Ativo__c, Descricao__c, MotivoInativacao__c, DistribuirParaFila__c, PorCampoCustomizado__c,
                NomeFilaDistribuicao__c, FilaDeveloperName__c, FilaId__c, CampoDistribuicao__c, LabelCampoDistribuicao__c,
                ValorDistribuicao__c, LabelValorDistribuicao__c, ChaveNatural__c, ChaveNaturalHash__c
            FROM Categorizacao__c WHERE Id = :id LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    public static Map<Id, RecordType> getRecordTypesById(Set<Id> recordTypeIds) {
        Map<Id, RecordType> out = new Map<Id, RecordType>();
        if (recordTypeIds.isEmpty()) return out;
        for (RecordType rt : [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Categorizacao__c' AND Id IN :recordTypeIds]) {
            out.put(rt.Id, rt);
        }
        return out;
    }

    public static List<RecordType> getAvailableRecordTypesForObject() {
        return [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Categorizacao__c' AND IsActive = true ORDER BY Name];
    }

    public static Map<String, UnidadeConfig> getUnidadeConfigsByRecordTypeDeveloperName() {
        if (testConfigs != null) return testConfigs;
        Map<String, UnidadeConfig> out = new Map<String, UnidadeConfig>();

        for (AtendimentoConfigDTO m : AtendimentoConfigService.getActiveConfigs()) {
            UnidadeConfig uc = new UnidadeConfig();
            uc.recordTypeDeveloperName = m.caseRecordTypeDeveloperName;
            uc.unidadeNegocio = m.businessUnit;
            uc.queuePrefix = m.queueDeveloperNamePrefix;
            uc.ativo = m.isActive;
            if (String.isBlank(uc.recordTypeDeveloperName)) continue;
            out.put(uc.recordTypeDeveloperName, uc);
        }

        if (out.isEmpty()) {
            out.put('Salvador', cfg('Salvador', 'Atendimento Salvador', 'TSV'));
            out.put('TeconSalvador', cfg('TeconSalvador', 'Atendimento Salvador', 'TSV'));
            out.put('RioGrande', cfg('RioGrande', 'Atendimento Rio Grande', 'TRG'));
            out.put('TeconRioGrande', cfg('TeconRioGrande', 'Atendimento Rio Grande', 'TRG'));
            out.put('CentroLogistico', cfg('CentroLogistico', 'Centro Logístico', 'CL'));
            out.put('Rebocadores', cfg('Rebocadores', 'Rebocadores', 'REB'));
        }
        return out;
    }

    private static UnidadeConfig cfg(String rt, String unidade, String prefix) {
        UnidadeConfig c = new UnidadeConfig();
        c.recordTypeDeveloperName = rt; c.unidadeNegocio = unidade; c.queuePrefix = prefix; c.ativo = true;
        return c;
    }

    public static Map<String, QueueData> getCaseQueuesByDeveloperName(Set<String> developerNames) {
        if (testQueuesByDevName != null) return testQueuesByDevName;
        Map<String, QueueData> out = new Map<String, QueueData>();
        if (developerNames.isEmpty()) return out;

        Set<Id> queueIds = new Set<Id>();
        for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :developerNames]) {
            queueIds.add(g.Id);
            QueueData d = new QueueData();
            d.id = g.Id; d.name = g.Name; d.developerName = g.DeveloperName;
            out.put(d.developerName, d);
        }

        if (!queueIds.isEmpty()) {
            Set<Id> enabledQueueIds = new Set<Id>();
            for (QueueSobject qs : [SELECT QueueId FROM QueueSobject WHERE QueueId IN :queueIds AND SobjectType = 'Case']) enabledQueueIds.add(qs.QueueId);
            for (String key : new List<String>(out.keySet())) if (!enabledQueueIds.contains(out.get(key).id)) out.remove(key);
        }
        return out;
    }

    public static List<QueueData> listCaseQueuesByPrefix(String prefix) {
        List<QueueData> out = new List<QueueData>();
        if (String.isBlank(prefix)) return out;
        if (testQueuesByDevName != null) return testQueuesByDevName.values();

        Set<Id> queueIds = new Set<Id>();
        String pattern = '%' + prefix + '%';
        for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE :pattern ORDER BY Name]) {
            QueueData d = new QueueData();
            d.id = g.Id; d.name = g.Name; d.developerName = g.DeveloperName;
            out.add(d); queueIds.add(g.Id);
        }

        if (queueIds.isEmpty()) return new List<QueueData>();

        Set<Id> enabled = new Set<Id>();
        for (QueueSobject qs : [SELECT QueueId FROM QueueSobject WHERE QueueId IN :queueIds AND SobjectType = 'Case']) enabled.add(qs.QueueId);

        List<QueueData> filtered = new List<QueueData>();
        for (QueueData q : out) if (enabled.contains(q.id)) filtered.add(q);
        return filtered;
    }

    public static Map<String, Categorizacao__c> getExistingByHash(Set<String> hashes, Set<Id> ignoreIds) {
        Map<String, Categorizacao__c> out = new Map<String, Categorizacao__c>();
        if (hashes.isEmpty()) return out;
        for (Categorizacao__c row : [SELECT Id, ChaveNaturalHash__c FROM Categorizacao__c WHERE ChaveNaturalHash__c IN :hashes]) {
            if (ignoreIds.contains(row.Id)) continue;
            out.put(row.ChaveNaturalHash__c, row);
        }
        return out;
    }

    public static List<RegrasSLACategorizacao__c> getRegrasSlaByCategorizacao(Id categorizacaoId) {
        if (categorizacaoId == null) return new List<RegrasSLACategorizacao__c>();
        return [
            SELECT Id, Categorizacao__c, TipoAreaParticipante__c, AreaAtendimento__c,
                BusinessHoursName__c, Ativo__c,
                GestaoSLA__c, MarcoSLA__c, EscopoRegra__c, TempoBaixa__c, TempoMedia__c, TempoAlta__c
            FROM RegrasSLACategorizacao__c
            WHERE Categorizacao__c = :categorizacaoId
            ORDER BY TipoAreaParticipante__c, AreaAtendimento__c
        ];
    }
}