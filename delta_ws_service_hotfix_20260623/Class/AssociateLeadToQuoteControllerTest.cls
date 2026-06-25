/**
 * @author            : Luis Coêlho
 * @last modified on  : 04-24-2025
 * @last modified by  : Luis Coêlho
**/
@isTest
public class AssociateLeadToQuoteControllerTest {
    @TestSetup
    static void makeData() {
        Account accountTest = new Account(
            Name = 'Conta AssociateLead Test'
        );
        insert accountTest;

        Atuacao__c atuacao = new Atuacao__c(
            Name = 'Atuacao AssociateLead Test',
            Conta__c = accountTest.Id,
            Segmentacao_de_Mercado__c = 'Aço',
            Categoria__c = 'Targets',
            Perfil__c = 'Afretador'
        );
        insert atuacao;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity AssociateLead Test',
            AccountId = accountTest.Id,
            StageName = 'Prospecção / Pedido do Cliente',
            CloseDate = Date.today(),
            Atuacao__c = atuacao.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opportunity;

        Quote quote = new Quote(
            Name = 'Quote AssociateLead Test',
            OpportunityId = opportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;

        Product2 product = new Product2(
            Name = 'Produto AssociateLead Test',
            IsActive = true
        );
        insert product;

        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardEntry;

        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = standardEntry.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert quoteLineItem;
    }
    
    static testMethod void getLineupLeadsTest(){
        QuoteLineItem QuoteLineItemId = [SELECT Id,Lineup_Id__c FROM QuoteLineItem LIMIT 1];
        test.StartTest();
        AssociateLeadToQuoteController.getLineupLeads(QuoteLineItemId.Id);
        test.StopTest();
    }

    static testMethod void getLineupLeadsTest2(){
        test.StartTest();
        AssociateLeadToQuoteController.getLineupLeads(null);
        test.StopTest();
    }

    static testMethod void updateQuoteLineItemTest(){
        QuoteLineItem QuoteLineItemId = [SELECT Id,Lineup_Id__c FROM QuoteLineItem LIMIT 1];
        test.StartTest();
        AssociateLeadToQuoteController.updateQuoteLineItem(QuoteLineItemId.Id,'1234');
        test.StopTest();
    }

    static testMethod void updateQuoteLineItemTest2(){
        test.StartTest();
        AssociateLeadToQuoteController.updateQuoteLineItem(null,'1234');
        test.StopTest();
    }
}
