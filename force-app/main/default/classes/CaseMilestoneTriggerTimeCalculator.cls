global inherited sharing class CaseMilestoneTriggerTimeCalculator implements Support.MilestoneTriggerTimeCalculator {
    @TestVisible private static final Integer DEFAULT_FALLBACK_MINUTES = 1;
    @TestVisible private static final String FONTE_TEMPO_GESTAO = 'GestaoSLA';
    @TestVisible private static final String FONTE_TEMPO_REGRA = 'RegraSLA';
    @TestVisible private static final String MARCO_TRIAGEM = 'triagem';
    @TestVisible private static final String MARCO_RESPOSTA_CHAT = 'resposta chat';

    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId) {
        if (String.isBlank(caseId) || String.isBlank(milestoneTypeId)) {
            return DEFAULT_FALLBACK_MINUTES;
        }
        List<Case> caseRows = [
            SELECT Id, Origin, Priority, Categorizacao__c, UnidadeNegocio__c, EntitlementId, EtapaAtendimento__c,
                   Categorizacao__r.GestaoSLA__c, Entitlement.SlaProcess.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        if (caseRows.isEmpty()) return DEFAULT_FALLBACK_MINUTES;

        List<MilestoneType> mtRows = [
            SELECT Id, Name
            FROM MilestoneType
            WHERE Id = :milestoneTypeId
            LIMIT 1
        ];
        if (mtRows.isEmpty()) return DEFAULT_FALLBACK_MINUTES;

        return calculateForCaseAndMilestone(caseRows[0], mtRows[0].Name, System.today());
    }

    @TestVisible
    private static Integer calculateForCaseAndMilestoneName(Id caseId, String milestoneTypeName, Date referenceDate) {
        if (caseId == null || String.isBlank(milestoneTypeName)) return DEFAULT_FALLBACK_MINUTES;
        List<Case> caseRows = [
            SELECT Id, Origin, Priority, Categorizacao__c, UnidadeNegocio__c, EntitlementId, EtapaAtendimento__c,
                   Categorizacao__r.GestaoSLA__c, Entitlement.SlaProcess.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        if (caseRows.isEmpty()) return DEFAULT_FALLBACK_MINUTES;
        return calculateForCaseAndMilestone(caseRows[0], milestoneTypeName, referenceDate);
    }

    @TestVisible
    private static Integer calculateForCaseAndMilestone(Case c, String milestoneTypeName, Date referenceDate) {
        if (c == null || String.isBlank(milestoneTypeName)) return DEFAULT_FALLBACK_MINUTES;

        GestaoSLA__c gestao = resolveGestao(c);
        if (gestao == null) return DEFAULT_FALLBACK_MINUTES;

        MarcoSLA__c marco = resolveMarco(gestao.Id, milestoneTypeName);
        if (marco == null) return DEFAULT_FALLBACK_MINUTES;

        if (marco.FonteTempo__c == FONTE_TEMPO_GESTAO) {
            return resolveTempoGestao(gestao, milestoneTypeName);
        }
        if (marco.FonteTempo__c == FONTE_TEMPO_REGRA) {
            return resolveTempoRegra(c, marco, referenceDate == null ? System.today() : referenceDate);
        }
        return DEFAULT_FALLBACK_MINUTES;
    }

    private static GestaoSLA__c resolveGestao(Case c) {
        if (c.Categorizacao__r != null && c.Categorizacao__r.GestaoSLA__c != null) {
            List<GestaoSLA__c> byId = [
                SELECT Id, UnidadeNegocio__c, EntitlementProcessName__c, TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, Ativo__c
                FROM GestaoSLA__c
                WHERE Id = :c.Categorizacao__r.GestaoSLA__c AND Ativo__c = true
                LIMIT 1
            ];
            if (!byId.isEmpty()) return byId[0];
        }

        if (!String.isBlank(c.UnidadeNegocio__c)) {
            List<GestaoSLA__c> byUnidade = [
                SELECT Id, UnidadeNegocio__c, EntitlementProcessName__c, TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, Ativo__c
                FROM GestaoSLA__c
                WHERE Ativo__c = true
                  AND UnidadeNegocio__c = :c.UnidadeNegocio__c
                LIMIT 2
            ];
            if (byUnidade.size() == 1) return byUnidade[0];
            if (byUnidade.size() > 1) return null;
        }

        String slaProcessName = (c.Entitlement != null && c.Entitlement.SlaProcess != null)
            ? c.Entitlement.SlaProcess.Name
            : null;
        if (!String.isBlank(slaProcessName)) {
            List<GestaoSLA__c> byEntitlement = [
                SELECT Id, UnidadeNegocio__c, EntitlementProcessName__c, TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, Ativo__c
                FROM GestaoSLA__c
                WHERE Ativo__c = true
                  AND EntitlementProcessName__c = :slaProcessName
                LIMIT 2
            ];
            if (byEntitlement.size() == 1) return byEntitlement[0];
        }
        return null;
    }

    private static MarcoSLA__c resolveMarco(Id gestaoId, String milestoneTypeName) {
        if (gestaoId == null || String.isBlank(milestoneTypeName)) return null;
        List<MarcoSLA__c> rows = [
            SELECT Id, GestaoSLA__c, NomeMarco__c, MilestoneTypeName__c, FonteTempo__c, Ativo__c, UsaCategorizacao__c, TempoFallbackMinutos__c
            FROM MarcoSLA__c
            WHERE GestaoSLA__c = :gestaoId
              AND MilestoneTypeName__c = :milestoneTypeName
              AND Ativo__c = true
            LIMIT 2
        ];
        if (rows.size() != 1) return null;
        return rows[0];
    }

    private static Integer resolveTempoGestao(GestaoSLA__c gestao, String milestoneTypeName) {
        String marco = normalize(milestoneTypeName);
        Decimal tempo;
        if (marco.contains(MARCO_TRIAGEM)) {
            tempo = gestao.TempoTriagemMinutos__c;
        } else if (marco.contains(MARCO_RESPOSTA_CHAT)) {
            tempo = gestao.TempoRespostaChatMinutos__c;
        } else {
            return DEFAULT_FALLBACK_MINUTES;
        }
        if (tempo == null || tempo <= 0) return DEFAULT_FALLBACK_MINUTES;
        return Integer.valueOf(String.valueOf(tempo.setScale(0)));
    }

    private static Integer resolveTempoRegra(Case c, MarcoSLA__c marco, Date referenceDate) {
        Integer marcoFallback = resolveMarcoFallback(marco);

        List<RegrasSLACategorizacao__c> rules = [
            SELECT Id, Ativo__c, GestaoSLA__c, MarcoSLA__c, EscopoRegra__c, Categorizacao__c,
                   TempoBaixa__c, TempoMedia__c, TempoAlta__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
              AND GestaoSLA__c = :marco.GestaoSLA__c
              AND MarcoSLA__c = :marco.Id
              AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_ATENDIMENTO
              AND Categorizacao__c = :c.Categorizacao__c
            LIMIT 1
        ];

        if (rules.isEmpty()) return marcoFallback;

        try {
            Integer tempo = RegrasSLACompatibilidadeService.resolveTempoCompativel(rules[0], c.Priority);
            return tempo == null || tempo <= 0 ? marcoFallback : tempo;
        } catch (Exception ex) {
            return marcoFallback;
        }
    }

    // Quando o Marco define um fallback próprio (TempoFallbackMinutos__c), ele é usado
    // sempre que não houver Regra de SLA correspondente para a Categorização do Case
    // (ex: Case ainda não categorizado). Em branco, mantém o fallback padrão do sistema.
    private static Integer resolveMarcoFallback(MarcoSLA__c marco) {
        if (marco.TempoFallbackMinutos__c == null || marco.TempoFallbackMinutos__c <= 0) {
            return DEFAULT_FALLBACK_MINUTES;
        }
        return Integer.valueOf(String.valueOf(marco.TempoFallbackMinutos__c.setScale(0)));
    }

    private static String normalize(String input) {
        if (String.isBlank(input)) return '';
        String s = input.trim().toLowerCase();
        s = s.replace('á', 'a').replace('à', 'a').replace('â', 'a').replace('ã', 'a').replace('ä', 'a');
        s = s.replace('é', 'e').replace('è', 'e').replace('ê', 'e').replace('ë', 'e');
        s = s.replace('í', 'i').replace('ì', 'i').replace('î', 'i').replace('ï', 'i');
        s = s.replace('ó', 'o').replace('ò', 'o').replace('ô', 'o').replace('õ', 'o').replace('ö', 'o');
        s = s.replace('ú', 'u').replace('ù', 'u').replace('û', 'u').replace('ü', 'u');
        s = s.replace('ç', 'c');
        return s;
    }
}