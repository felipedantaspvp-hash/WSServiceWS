/**
 * @description       : Factory de dados de teste para o módulo CaseRecategorization. Cria registros e objetos relacionados para uso em testes.
 * @author            : Triscal
 * @group             : Case Recategorização
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
public inherited sharing class CaseRecategorizationTestDataFactory {
    public static Case buildCase(Id recordTypeId, String unidade, String tipo, String categoria, String assunto, String subassunto, String status) {
        return new Case(
            Subject = 'Caso Teste Recategorizacao',
            RecordTypeId = recordTypeId,
            UnidadeNegocio__c = unidade,
            TipoCaso__c = tipo,
            Categoria__c = categoria,
            Assunto__c = assunto,
            Subassunto__c = subassunto,
            Origin = 'Manual',
            Status = status
        );
    }

    public static Categorizacao__c catRow(Id categRtId, String unidade, String tipo, String categoria, String assunto, String subassunto, Boolean ativo) {
        Categorizacao__c row = new Categorizacao__c();
        row.RecordTypeId = categRtId;
        row.UnidadeNegocios__c = unidade;
        row.TipoCaso__c = tipo;
        row.Categoria__c = categoria;
        row.Assunto__c = assunto;
        row.Subassunto__c = subassunto;
        row.Ativo__c = ativo;
        return row;
    }
}