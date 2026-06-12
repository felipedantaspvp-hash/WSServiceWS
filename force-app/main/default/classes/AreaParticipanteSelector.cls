public inherited sharing class AreaParticipanteSelector {
    @TestVisible private static List<AreaParticipante__c> testAreas;
    @TestVisible private static Case testCase;
    private static final String AREA_FIELD = 'AreaAtendimento__c';

    public static Case getCaseById(Id caseId) {
        if (testCase != null) return testCase;
        List<Case> rows = [
            SELECT Id, CaseNumber, OwnerId, Status, Categorizacao__c, Priority, Origin,
                AreasParticipantes__c, AreasParticipantesSLA__c, EtapaAtendimento__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    public static List<AreaParticipante__c> getAreasByCase(Id caseId) {
        if (testAreas != null) return testAreas;
        String soql =
            'SELECT Id, Caso__c, ' + AREA_FIELD + ', StatusAtuacao__c,' +
            ' DataHoraInicio__c, DataHoraPrazo__c, DataHoraFim__c,' +
            ' ComentarioSolicitacao__c, ComentarioRetorno__c, SolucaoTomada__c,' +
            ' FinalizadoPor__c, FinalizadoPor__r.Name,' +
            ' ViolouSLA__c, NomeMarco__c, CaseMilestoneId__c,' +
            ' Responsavel__c, RequerRetornoCliente__c, BloqueiaFechamentoCaso__c,' +
            ' PercentualDecorrido__c, StatusSLA__c, TempoSLAMinutos__c, TempoPausadoMinutos__c, TempoConsumidoMinutos__c, TempoRestanteMinutos__c, SequenciaAcionamento__c, TipoAreaParticipante__c, RegraSLACategorizacao__c' +
            ' FROM AreaParticipante__c' +
            ' WHERE Caso__c = :caseId' +
            ' ORDER BY DataHoraPrazo__c ASC NULLS LAST, CreatedDate DESC';
        return (List<AreaParticipante__c>) Database.query(soql);
    }

    public static AreaParticipante__c getAreaById(Id areaId) {
        String soql =
            'SELECT Id, Caso__c, ' + AREA_FIELD + ', StatusAtuacao__c,' +
            ' DataHoraInicio__c, DataHoraPrazo__c, DataHoraFim__c,' +
            ' ComentarioSolicitacao__c, ComentarioRetorno__c, SolucaoTomada__c,' +
            ' FinalizadoPor__c, FinalizadoPor__r.Name,' +
            ' ViolouSLA__c, NomeMarco__c, CaseMilestoneId__c,' +
            ' Responsavel__c, RequerRetornoCliente__c, BloqueiaFechamentoCaso__c,' +
            ' PercentualDecorrido__c, StatusSLA__c, TempoSLAMinutos__c, TempoPausadoMinutos__c, TempoConsumidoMinutos__c, TempoRestanteMinutos__c, SequenciaAcionamento__c, TipoAreaParticipante__c, RegraSLACategorizacao__c' +
            ' FROM AreaParticipante__c' +
            ' WHERE Id = :areaId LIMIT 1';
        List<AreaParticipante__c> rows = (List<AreaParticipante__c>) Database.query(soql);
        return rows.isEmpty() ? null : rows[0];
    }

    public static Set<String> getEligibleAreaValuesForCase(Case caseRow) {
        Set<String> out = new Set<String>();
        if (caseRow == null || caseRow.Categorizacao__c == null) return out;

        Set<String> origins = new Set<String>{ AreaParticipanteSLAHelper.ORIGEM_REGRA_QUALQUER };
        if (!String.isBlank(caseRow.Origin)) origins.add(caseRow.Origin);

        for (RegrasSLACategorizacao__c rule : [
            SELECT AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
                AND Categorizacao__c = :caseRow.Categorizacao__c
                AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
                AND Origem__c IN :origins
                AND AreaAtendimento__c != null
        ]) {
            out.add(rule.AreaAtendimento__c);
        }
        return out;
    }

    public static Boolean hasEligibleAreaRule(Case caseRow, String areaValue) {
        if (String.isBlank(areaValue)) return false;
        return getEligibleAreaValuesForCase(caseRow).contains(areaValue);
    }
}