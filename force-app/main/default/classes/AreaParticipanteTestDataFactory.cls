// Wrapper fino sobre TestDataFactory (Pacote 40): mantém as assinaturas históricas usadas
// pelas classes de teste chamadoras, mas a lógica de montagem do SObject vive só em
// TestDataFactory, evitando divergência entre implementações duplicadas.
@IsTest
public inherited sharing class AreaParticipanteTestDataFactory {
    public static String pickValue(String objectApiName, String fieldApiName, Integer index) {
        return TestDataFactory.pickValue(objectApiName, fieldApiName, index);
    }

    public static RecordType anyCaseRt() {
        return TestDataFactory.anyActiveRecordType('Case');
    }

    public static List<String> commonAreaValues() {
        return TestDataFactory.commonAreaValues();
    }

    public static Case createCase(String area1, String area2) {
        return TestDataFactory.createCaseWithSlaChain(null, null, null, new List<String>{ area1, area2 });
    }

    public static Case createCaseWithoutSla(String area1, String area2) {
        List<String> allowed = TestDataFactory.pickAllValues('Case', 'AreasParticipantesSLA__c');
        if (allowed.isEmpty()) allowed.add('A definir');
        String a1 = String.isBlank(area1) || !allowed.contains(area1) ? allowed[0] : area1;
        String a2 = String.isBlank(area2) || !allowed.contains(area2) ? null : area2;
        String mp = String.isBlank(a2) ? a1 : a1 + ';' + a2;
        return TestDataFactory.createCase(new Map<String, Object>{
            'AreasParticipantesSLA__c' => mp,
            'EtapaAtendimento__c' => 'Aguardando Área Interna'
        });
    }

    public static AreaParticipante__c createArea(Id caseId, String area, String status, Integer prazoOffsetHours) {
        List<String> allowed = TestDataFactory.pickAllValues('AreaParticipante__c', 'AreaAtendimento__c');
        String chosenArea = (String.isBlank(area) || !allowed.contains(area)) ? (allowed.isEmpty() ? null : allowed[0]) : area;
        return TestDataFactory.createAreaParticipante(caseId, new Map<String, Object>{
            'StatusAtuacao__c' => status,
            'DataHoraInicio__c' => System.now().addHours(-2),
            'DataHoraPrazo__c' => System.now().addHours(prazoOffsetHours),
            'ComentarioSolicitacao__c' => 'Solicitacao de teste',
            'AreaAtendimento__c' => chosenArea
        });
    }

    public static String openStatus() {
        return TestDataFactory.openStatus();
    }

    public static String closedStatus() {
        return TestDataFactory.closedStatus();
    }
}