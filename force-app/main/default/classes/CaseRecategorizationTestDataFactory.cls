// Wrapper fino sobre TestDataFactory (Pacote 40): mantém as assinaturas históricas usadas
// pelas classes de teste chamadoras, mas a lógica de montagem do SObject vive só em
// TestDataFactory, evitando divergência entre implementações duplicadas.
@IsTest
public inherited sharing class CaseRecategorizationTestDataFactory {
    public static Case buildCase(Id recordTypeId, String unidade, String tipo, String categoria, String assunto, String subassunto, String status) {
        return TestDataFactory.buildCase(new Map<String, Object>{
            'RecordTypeId' => recordTypeId,
            'Subject' => 'Caso Teste Recategorizacao',
            'UnidadeNegocio__c' => unidade,
            'TipoCaso__c' => tipo,
            'Categoria__c' => categoria,
            'Assunto__c' => assunto,
            'Subassunto__c' => subassunto,
            'Origin' => 'Manual',
            'Status' => status
        });
    }

    public static Categorizacao__c catRow(Id categRtId, String unidade, String tipo, String categoria, String assunto, String subassunto, Boolean ativo) {
        return TestDataFactory.buildCategorizacao(new Map<String, Object>{
            'RecordTypeId' => categRtId,
            'UnidadeNegocios__c' => unidade,
            'TipoCaso__c' => tipo,
            'Categoria__c' => categoria,
            'Assunto__c' => assunto,
            'Subassunto__c' => subassunto,
            'Ativo__c' => ativo
        });
    }
}