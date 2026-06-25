@isTest (seeAllData=true)
public class CloneQuoteControllerTest {
    static testMethod void CloneQuoteTest(){        
        Pricebook2 pricebookTest = new Pricebook2();
        pricebookTest.Name = 'teste';
        insert pricebookTest;
        
        Pricebook2 pricebookPadrao = [SELECT Id FROM Pricebook2 WHERE  IsStandard=True LIMIT 1];
        Account conta = [SELECT Id FROM Account WHERE Id = '0011N00001KOyU8QAL'];
        
        Product2 productTest = new Product2();
        productTest.Name = 'Teste';
        insert productTest;
        
        PricebookEntry priceTest2 = new PricebookEntry();
        priceTest2.UnitPrice = 1;
        priceTest2.Product2Id = productTest.Id;
        priceTest2.Pricebook2Id = pricebookPadrao.Id;
        priceTest2.IsActive = true;
        insert priceTest2;
        
        PricebookEntry priceTest = new PricebookEntry();
        priceTest.UnitPrice = 1;
        priceTest.Product2Id = productTest.Id;
        priceTest.Pricebook2Id = pricebookTest.Id;
        priceTest.UseStandardPrice = true;
        insert priceTest;
        
        Opportunity oppTest = new Opportunity();
        oppTest.Name = 'Teste Opp';
        oppTest.StageName = 'Fechamento da Oportunidade - Ganha';
        oppTest.CloseDate = System.today();
        oppTest.Faturamento_Fechado__c = 1000;
        oppTest.Pricebook2Id = pricebookPadrao.Id;
        oppTest.AccountId = conta.Id;
        insert oppTest;
        
        Quote cloneQuoteTest = new Quote();
        cloneQuoteTest.Name = 'Teste';
        cloneQuoteTest.OpportunityId = oppTest.Id;
        cloneQuoteTest.Pricebook2Id = pricebookPadrao.Id;
        insert cloneQuoteTest;
        
        QuoteLineItem quoteLineTest = new QuoteLineItem();
        quoteLineTest.QuoteId = cloneQuoteTest.Id;
        quoteLineTest.PricebookEntryId = priceTest2.Id;
        quoteLineTest.Quantity = 1;
        quoteLineTest.UnitPrice = 1;
        quoteLineTest.Product2Id = productTest.Id;
        
        insert quoteLineTest;

        //NEW
        DWT_Range__c dwt = DataMass.dwtMass();
        Product2 port = DataMass.portProductMass(dwt);
        Product2 division = DataMass.divisionProductMass(port);
        Product2 service = DataMass.mainServiceProductMass();
        Product2 crProduct = DataMass.contractRemarkProductMass();
        Product2 remarkProduct = DataMass.remarkProductMass();
        Contract_Remark__c cr = DataMass.contractRemarkMass(CloneQuoteTest, division, service, crProduct);
        Remark_Quote__c rq = DataMass.remarkQuoteMass(cloneQuoteTest, remarkProduct, port);
        
        try{
                CloneQuoteController.cloneQuote(cloneQuoteTest.Id);
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + ' - Line :' + ex.getLineNumber());
            
        }
    }
}