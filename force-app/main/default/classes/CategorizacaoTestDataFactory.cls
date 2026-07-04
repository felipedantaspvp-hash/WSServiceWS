// Wrapper fino sobre TestDataFactory (Pacote 40): mantém as assinaturas históricas usadas
// pelas classes de teste chamadoras, mas a lógica de montagem do SObject vive só em
// TestDataFactory, evitando divergência entre implementações duplicadas.
@IsTest
public inherited sharing class CategorizacaoTestDataFactory {
    public static RecordType getAnyRt() {
        return TestDataFactory.anyActiveRecordType('Categorizacao__c');
    }

    // Mantém a assinatura/semântica histórica do chamador: porCat=true significa "distribuição
    // direta pela categorização, sem campo/valor extra" — o oposto do novo PorCampoCustomizado__c.
    public static Categorizacao__c base(Boolean distribuir, Boolean porCat) {
        Map<String, Object> overrides = new Map<String, Object>{
            'DistribuirParaFila__c' => distribuir ? 'Sim' : 'Não',
            'PorCampoCustomizado__c' => porCat ? 'Não' : 'Sim'
        };
        if (distribuir) overrides.put('EtapaAtendimentoDistribuicao__c', 'Em Triagem');
        return TestDataFactory.buildCategorizacao(overrides);
    }

    public static Group createQueue(String devName) {
        return TestDataFactory.createQueue(devName);
    }
}