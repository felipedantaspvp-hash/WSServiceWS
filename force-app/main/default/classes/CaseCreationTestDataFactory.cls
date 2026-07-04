// Wrapper fino sobre TestDataFactory (Pacote 40) para catRow: a lógica de montagem do
// SObject vive só em TestDataFactory, evitando divergência entre implementações duplicadas.
@IsTest
public inherited sharing class CaseCreationTestDataFactory {
    public static RecordType anyCaseRt() {
        return TestDataFactory.anyActiveRecordType('Case');
    }

    public static CaseCreationDTO.CategorizationRequestDTO baseCategorization() {
        RecordType rt = anyCaseRt();
        CaseCreationDTO.CategorizationRequestDTO c = new CaseCreationDTO.CategorizationRequestDTO();
        c.recordTypeId = rt.Id;
        c.recordTypeDeveloperName = rt.DeveloperName;
        c.unidadeNegocio = 'Salvador';
        c.tipoCaso = 'Solicitação';
        c.categoria = 'Operação';
        c.assunto = 'Acesso';
        c.subassunto = 'Acesso indisponível';
        return c;
    }

    // Mantém a assinatura/semântica histórica do chamador: porCat=true significa "distribuição
    // direta pela categorização, sem campo/valor extra" — o oposto do novo PorCampoCustomizado__c.
    public static Categorizacao__c catRow(Boolean distribuir, Boolean porCat, String filaDevName, Id rtId) {
        return TestDataFactory.buildCategorizacao(new Map<String, Object>{
            'RecordTypeId' => rtId,
            'UnidadeNegocios__c' => 'Salvador',
            'TipoCaso__c' => 'Solicitação',
            'Categoria__c' => 'Operação',
            'Assunto__c' => 'Acesso',
            'Subassunto__c' => 'Acesso indisponível',
            'Ativo__c' => true,
            'DistribuirParaFila__c' => distribuir ? 'Sim' : 'Não',
            'PorCampoCustomizado__c' => porCat ? 'Não' : 'Sim',
            'FilaDeveloperName__c' => filaDevName
        });
    }
}