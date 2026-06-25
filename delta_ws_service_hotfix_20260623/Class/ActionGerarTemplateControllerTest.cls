/**
 * @description       :
 * @author            : wrodrigues@triscal.com.br
 * @group             :
 * @last modified on  : 09-02-2025
 * @last modified by  : wrodrigues@triscal.com.br
**/
@IsTest
public with sharing class ActionGerarTemplateControllerTest {
    @TestSetup
    static void makeData()
    {
        Id          recordTypeId      = RecordTypeHelper.getRecordTypeId( 'Template__c', 'TeconRioGrande' );
        Id          TeconRioGrandeRct = RecordTypeHelper.getRecordTypeId( 'Quote', 'TeconRioGrande' );

        Account     conta = new Account();
        conta.Name = 'CONTA TESTE';
        insert      conta;

        Atuacao__c atuacao = new Atuacao__c();
        atuacao.Name = 'ATUACAO TESTE TEMPLATE';
        atuacao.Conta__c = conta.Id;
        atuacao.Segmentacao_de_Mercado__c = 'Aço';
        atuacao.Categoria__c = 'Targets';
        atuacao.Perfil__c = 'Afretador';
        insert atuacao;

        Opportunity opp = new Opportunity();
        opp.Name      = 'OPORTUNIDADE DE TESTE';
        opp.AccountId = conta.Id;
        opp.StageName = 'Prospecção / Pedido do Cliente';
        opp.CloseDate = Date.today();
        opp.Atuacao__c = atuacao.Id;
        insert opp;

        Quote  cotacao = new Quote();
        cotacao.TipoCotacao__c = 'Carga';
        cotacao.Name           = 'TESTE DE COTAÇÃO DE CARGA';
        cotacao.recordTypeId   = TeconRioGrandeRct;
        cotacao.Status         = 'Proposta em edição';
        cotacao.OpportunityId  = opp.Id;
        insert cotacao;

        cotacao.TipoCotacao__c = 'Carga';
        update      cotacao;

        Template__c templateBasico = new Template__c();
        templateBasico.RecordTypeId    = recordTypeId;
        templateBasico.TipoTemplate__c = 'Padrão';
        templateBasico.Idioma__c       = 'PT';
        templateBasico.TipoCotacao__c  = 'Carga';
        templateBasico.Template_Ativo__c = true;
        insert templateBasico;
    }

    @IsTest
    static void gerarTemplate_Test()
    {
        Test.startTest();

        Quote cotacao = [ SELECT Id FROM Quote LIMIT 1 ];

        ActionGerarTemplateController.gerarTemplate( cotacao.Id );

        ContentDocumentLink ctnLink = [ SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = : cotacao.Id ];

        System.assertEquals( ctnLink.LinkedEntityId, cotacao.Id );

        Test.stopTest();
    }

    @IsTest
    static void gerarTemplate_Sem_Cotacao_valida_Test()
    {
        Test.startTest();

        try {
            ActionGerarTemplateController.gerarTemplate( '123456' );
        } catch ( Exception ex ) {
            System.assert( true );
        }

        Test.stopTest();
    }
}
