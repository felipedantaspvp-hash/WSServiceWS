/**
 * @description       : Factory de dados de teste para o módulo Categorizacao. Cria registros e objetos relacionados para uso em testes.
 * @author            : Triscal
 * @group             : Categorização
 * @last modified on  : 06-12-2026
 * @last modified by  : Jean Duarte
 **/
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
        c.PorCategorizacao__c = porCat ? 'Sim' : 'Não';
        return c;
    }

    public static Group createQueue(String devName) {
        Group g = new Group(Name = devName, DeveloperName = devName, Type = 'Queue');
        insert g;
        insert new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
        return g;
    }
}