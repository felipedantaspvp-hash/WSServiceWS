/**
 * @Descrição               : 
 * @Autor                   : 
 * @Empresa:                : Everymind LTDA.
 * @Ultima modificação em   : 03-08-2022
 * @Ultima modificação por  : C. Vinícius Santos (carlos.santos@everymind.com.br)
**/
@isTest(SeeAllData=true)
public class AddProductQuoteControllerTest { 
    
    
    static testMethod void TestGeral(){       
        Account accountTest = new Account(
            Name = 'Conta AddProductQuote Test'
        );
        insert accountTest;

        Atuacao__c atuacao = new Atuacao__c(
            Name = 'Atuacao AddProductQuote Test',
            Conta__c = accountTest.Id,
            Segmentacao_de_Mercado__c = 'Aço',
            Categoria__c = 'Targets',
            Perfil__c = 'Afretador'
        );
        insert atuacao;
        
        //DWT Range
        DWT_Range__c range = new DWT_Range__c();
        range.Name = 'Geral';
        range.DWT__c = '0 to 10,10 to 20,20 to 30,30 to 40,40 to 50,50 to 60,60 to 70,70 to 80,80 to 90,90 to 100,100 to 110,110 to 120,120 to 130,130 to 180,180 to 200,200 to 270,270 to 365,over 365';
        insert range;
       
        //Servico primario
        Product2 servicoP = new Product2();
        servicoP.Family = 'Servico Principal';
        servicoP.Name = 'Lumpsum In/Out';
        insert servicoP;
        
        //Servico secundario
        Product2 servicoS = new Product2();
        servicoS.Family = 'Servicos Secundarios';
        servicoS.Name = 'Lumpsum In/Out';
        insert servicoS;

        //Adicionar produtos
        Product2 porto = new Product2();
        porto.Family = 'Porto';
        porto.Name = 'Fortaliza';
        porto.DWT_Range__c = range.Id;
        insert porto;

        //Inserindo divisao
        Product2 divisao = new Product2();
        divisao.Family = 'Divisao';
        divisao.Name = 'Fortaliza';
        divisao.Parent_Product__c = porto.Id;
        divisao.Service_Primary__c = servicoP.Id;
        insert divisao;
        
        //Servico remark
        Product2 remark = new Product2();
        remark.Family = 'Remark';
        remark.Name = 'Lumpsum In/Out';
        remark.Parent_Product__c = divisao.Id;
        insert remark;
        
        //Inserindo DWT        
        Product2 dwt = new Product2();
        dwt.Family = 'DWT';
        dwt.Name = '0 to 10';
        dwt.Parent_Product__c = divisao.Id;
        insert dwt;
        
        //Inserindo Pricebook
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Name = 'Tabela Referencial - 2020 Versão 04';
        pricebook.IsActive = true;
        pricebook.IsLatestVersion__c = true;
        insert pricebook;
        
        Pricebook2 standard = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
        
        //Inserindo entrada do pricebook
        PricebookEntry entry = new PricebookEntry();
        entry.Pricebook2Id = standard.Id;
        entry.Product2Id = dwt.Id;
        entry.UnitPrice = 10000;
        entry.IsActive = true;
        entry.DWT_Range__c = '0 to 10';
        
        insert entry;

        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Opportunity AddProductQuote Test';
        opportunity.AccountId = accountTest.Id;
        opportunity.StageName = 'Prospecção / Pedido do Cliente';
        opportunity.CloseDate = Date.today();
        opportunity.Atuacao__c = atuacao.Id;
        opportunity.Pricebook2Id = standard.Id;
        insert opportunity;

        Quote quote = new Quote();
        quote.Name = 'Quote AddProductQuote Test';
        quote.OpportunityId = opportunity.Id;
        quote.Pricebook2Id = standard.Id;
        insert quote;

        Quote quote2 = new Quote();
        quote2.Name = 'Quote AddProductQuote Test Without PB';
        quote2.OpportunityId = opportunity.Id;
        insert quote2;
        
        AddProductQuoteController controller = new AddProductQuoteController();
        AddProductQuoteController.getDwtRange();
        List<Pricebook2> listPriceBook = AddProductQuoteController.getPriceBooks();
        AddProductQuoteController.getQuoteTextTemplate();
        AddProductQuoteController.getRemarksGenerics(quote.Id);          
		AddProductQuoteController.retrieveDivisionsList(divisao.Id); 
        
        AddProductQuoteController.getLeadSource(quote.Id);
        AddProductQuoteController.getPriceBookQuote(quote.Id);
        AddProductQuoteController.getPriceBookQuote(quote2.Id);
        
        
        List<AddProductQuoteController.VesselWrapper> listVessel = AddProductQuoteController.createVesselList(1);
        
        AddProductQuoteController.retrievePortsList();
        
        listVessel[0].idPortSelect = porto.Id;
        listVessel[0].idDivisionSelect = divisao.Id;
        listVessel[0].dwtRangeFaixaSelected = '0 to 10';
        listVessel[0].dwtRangeSelect = range.Id;
            
        listVessel = AddProductQuoteController.addSelectedPortToVessel(quote.Id,0, JSON.serialize(listVessel), (String)standard.Id, 'sadads55656', quote.Id);
        AddProductQuoteController.getSupportedPorts(JSON.serialize(listVessel), 0, standard.Id, '0 to 10');
        List<Product2> ps = AddProductQuoteController.getProductServices();
        List<Product2> sn = AddProductQuoteController.getServiceName(servicoS.Id);
        List<String> av = AddProductQuoteController.getApplicableValues();
        List<String> ov = AddProductQuoteController.getOperatorValues();
        
        List<AddProductQuoteController.PortWrapper> portWrapperlListDraft = new List<AddProductQuoteController.PortWrapper>();
        system.debug(portWrapperlListDraft);
        AddProductQuoteController.PortWrapper portWrapperDraft = listVessel[0].ports[0];
        portWrapperDraft.discount = 10;
        portWrapperDraft.primaryServicesSelected = new List<String>();
        portWrapperDraft.primaryServicesSelected.add(servicoP.Id);
        portWrapperlListDraft.add(portWrapperDraft);
        
        
        AddProductQuoteController.updateValuesPorts(JSON.serialize(listVessel), JSON.serialize(portWrapperlListDraft));
        
        AddProductQuoteController.updateValuesPrimaryServices(JSON.serialize(listVessel), porto.Id, divisao.Id ,servicoP.Id, 'd4455');
        
        List<AddProductQuoteController.SecondaryServicesWrapper> secondaryServicesWrapper = new List<AddProductQuoteController.SecondaryServicesWrapper>();
        
        
        AddProductQuoteController.SecondaryServicesWrapper portWrapperSecondaryDraft = new AddProductQuoteController.SecondaryServicesWrapper();
        portWrapperSecondaryDraft.discount = 10;
        portWrapperSecondaryDraft.idServicePortIdDivisionId = servicoS.Id + '-' + porto.Id + '-' + divisao.Id  + '-d44552S';
        secondaryServicesWrapper.add(portWrapperSecondaryDraft);
        
        AddProductQuoteController.updateValuesSecondaryServices(JSON.serialize(listVessel), JSON.serialize(secondaryServicesWrapper));
        

        List<String> listGenericRemarks = new List<String>();
        listGenericRemarks.add('Teste');
        
        
        AddProductQuoteController.saveQuoteLineItens(quote.Id, standard.Id, JSON.serialize(listVessel), JSON.serialize(listGenericRemarks));
        //NEW
        AddProductQuoteController.getAdjustmentValues();
        AddProductQuoteController.getProductRemarks();

    }
}