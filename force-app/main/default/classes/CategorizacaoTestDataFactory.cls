@IsTest
public inherited sharing class CategorizacaoTestDataFactory {
    private static String unidadeFromRecordType(String rtDevName) {
        String canonical = CaseCreationSelector.resolveCanonicalBusinessUnit(rtDevName);
        return String.isBlank(canonical)
            ? CaseCreationSelector.resolveCanonicalBusinessUnit('Tecon Salvador')
            : canonical;
    }

    public static RecordType getAnyRt() {
        return [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Categorizacao__c' LIMIT 1];
    }

    // Mantém a assinatura/semântica histórica do chamador: porCat=true significa "distribuição
    // direta pela categorização, sem campo/valor extra" — o oposto do novo PorCampoCustomizado__c.
    public static Categorizacao__c base(Boolean distribuir, Boolean porCat) {
        RecordType rt = getAnyRt();
        Categorizacao__c c = new Categorizacao__c();
        c.RecordTypeId = rt.Id;
        c.UnidadeNegocios__c = unidadeFromRecordType(rt.DeveloperName);
        c.TipoCaso__c = 'Solicitação';
        c.Categoria__c = 'Solicitação';
        c.Assunto__c = 'Cadastro';
        c.Subassunto__c = 'Alteração';
        c.Ativo__c = true;
        c.DistribuirParaFila__c = distribuir ? 'Sim' : 'Não';
        c.PorCampoCustomizado__c = porCat ? 'Não' : 'Sim';
        if (distribuir) c.EtapaAtendimentoDistribuicao__c = 'Em Triagem';
        return c;
    }

    public static Group createQueue(String devName) {
        Group g = new Group(Name = devName, DeveloperName = devName, Type = 'Queue');
        insert g;
        insert new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
        return g;
    }
}