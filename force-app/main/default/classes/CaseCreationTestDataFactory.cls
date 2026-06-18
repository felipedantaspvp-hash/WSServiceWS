@IsTest
public inherited sharing class CaseCreationTestDataFactory {
    public static RecordType anyCaseRt() {
        return [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Case' AND IsActive=true LIMIT 1];
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

    public static Categorizacao__c catRow(Boolean distribuir, Boolean porCat, String filaDevName, Id rtId) {
        Categorizacao__c row = new Categorizacao__c();
        row.RecordTypeId = rtId;
        row.UnidadeNegocios__c = 'Salvador';
        row.TipoCaso__c = 'Solicitação';
        row.Categoria__c = 'Operação';
        row.Assunto__c = 'Acesso';
        row.Subassunto__c = 'Acesso indisponível';
        row.Ativo__c = true;
        row.DistribuirParaFila__c = distribuir ? 'Sim' : 'Não';
        row.PorCategorizacao__c = porCat ? 'Sim' : 'Não';
        row.FilaDeveloperName__c = filaDevName;
        return row;
    }
}