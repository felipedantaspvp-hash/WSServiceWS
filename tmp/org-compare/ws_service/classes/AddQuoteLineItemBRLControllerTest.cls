/**
 * @description       : 
 * @author            : Isaac.batista@everymind.com.br
 * @group             : 
 * @last modified on  : 11-13-2023
 * @last modified by  : Isaac.batista@everymind.com.br
**/
@isTest
public with sharing class AddQuoteLineItemBRLControllerTest {
    @TestSetup
    static void makeData(){ 
        Id standardPb = Test.getStandardPricebookId();
        Pricebook2 pb = DataMass.pbMass();
        Pricebook2 pbOriginal = DataMass.pbWithOriginalMass(pb);
        Product2 product = DataMass.mainServiceProductMass();
        Product2 productRemark = DataMass.remarkProductMass();
        Product2 seconService = new Product2(
            Family = 'Servicos Secundarios',
            Name = 'Lumpsum In/Out'
        );
        Product2 remark = new Product2(
            Family = 'Remark',
            Name = 'Remark Test',
            Type__c = 'Reajuste',
            IsActive = true
        );

        insert remark;

        insert seconService;
        PricebookEntry standardPbe = DataMass.standardPbeMass(standardPb, product);
        PricebookEntry pbe = DataMass.pbeMass(pb, product, true);

        DWT_Range__c objDwt1 = new DWT_Range__c();
        DWT_Range__c objDwt2 = new DWT_Range__c();
        DWT_Range__c objDwt3 = new DWT_Range__c();
        DWT_Range__c objDwt4 = new DWT_Range__c();

        objDwt1.Name = 'DWT ARACAJU';
        objDwt1.DWT__c = '0 to 10,10 to 25,25 to 30,30 to 40,40 to 50,50 to 60,60 to 70';
        objDwt2.Name = 'Geral';
        objDwt2.DWT__c = '0 to 10,10 to 20,20 to 30,30 to 40,40 to 50,50 to 60,60 to 70,70 to 80,80 to 90,90 to 100,100 to 110,110 to 120,120 to 130,130 to 180,180 to 200,200 to 270,270 to 365,over 365';
        objDwt3.Name = 'DWT Sao Luis';
        objDwt3.DWT__c = '0 to 5,5 to 10,10 to 15,15 to 25,25 to 35,35 to 45,45 to 55,55 to 75,75 to 85,85 to 95,95 to 105,105 to 115,115 to 150,150 to 250,250 to 350,over 350';
        objDwt1.Name = 'DWT Açu';
        objDwt1.DWT__c = '0 to 10,10 to 15,15 to 20,20 to 25,25 to 35,35 to 45,45 to 50,50 to 70,70 to 75,75 to 85,85 to 115,115 to 150,150 to 250,250 to 350,over 350';

        insert objDwt1;
        insert objDwt2;
        insert objDwt3;
        insert objDwt4;

        Product2 port = new Product2(
            Family = 'Porto',
            Name = 'Port Test',
            Dwt_Range__c = objDwt2.Id,
            IsActive = true
        );

        insert port;
        Product2 division = new Product2(
            Family = 'Divisao',
            Name = 'Division Test',
            IsActive = true,
            Parent_Product__c = port.Id//,
            //Id_Tugsys_Division__c = 12
        );

        insert division;

        Product2 product0to10 = new Product2(
            Family = 'DWT',
            Name = '0 to 10',
            IsActive = true,
            Parent_Product__c = division.Id//,
            //Id_Tugsys_Division__c = 12
        );
        Product2 product10to20 = new Product2(
            Family = 'DWT',
            Name = '10 to 20',
            IsActive = true,
            Parent_Product__c = division.Id//,
            //Id_Tugsys_Division__c = 12
        );

        insert product0to10;
        insert product10to20;

        
        PricebookEntry pbe0to10 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product0to10.Id,
            UnitPrice = 10000,
            IsActive = true,
            DWT_Range__c = '0 to 10',
            UseStandardPrice = false
        );
        insert pbe0to10;

        PricebookEntry pbe0to10NonStandard = new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = product0to10.Id,
            UnitPrice = 10000,
            IsActive = true,
            DWT_Range__c = '0 to 10',
            UseStandardPrice = false
        );
        insert pbe0to10NonStandard;

        String pricebookBRLName = System.Label.PricebookTabelaBRL;
        Pricebook2 pricebookBRL = new Pricebook2(
            Name = pricebookBRLName,
            IsActive = true,
            IsLatestVersion__c = true
        );

        insert pricebookBRL;

        Account acc = DataMass.accountMass();
        Opportunity opp = DataMass.oppMass(pb.Id, acc);
        opp.ExchangeRate__c = 4;
        update opp;
        Quote quote = DataMass.quoteMass(pb, opp);

       
        
        Rebocador__c objRebocador = new Rebocador__c();
        objRebocador.name = 'ALPHARD';
        insert objRebocador;
    }

    @isTest 
    public static void getExchangeRateTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        Double objReturnTest = AddQuoteLineItemBRLController.getExchangeRate(objQuote.Id);
        System.assertEquals(true, objReturnTest > 0 );

        Test.stopTest();
    }
    @isTest 
    public static void getDwTRangesTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        Map<String,String> mapReturnTest = AddQuoteLineItemBRLController.getDwTRanges();
        System.assertEquals(true, mapReturnTest.values().size() > 0,'Should return the DWT ranges');

        Test.stopTest();
    }
    @isTest 
    public static void getPricebooksTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        List<String> lstReturnTest = AddQuoteLineItemBRLController.getPricebooks();
        System.assertEquals(true, lstReturnTest.size() > 0,'Should return the pricebooks names');

        Test.stopTest();
    }
    @isTest 
    public static void getProductOnSelectedRangeTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        List<Product2> lstReturnTest = AddQuoteLineItemBRLController.getProductOnSelectedRange('0 to 10','Geral');
        System.assertEquals(true, lstReturnTest.size() > 0,'Should return the division and port names');

        Test.stopTest();
    }

    @isTest 
    public static void getReferencePricebookentryTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        PricebookEntry objReturnTest = AddQuoteLineItemBRLController.getReferencePricebookentry('Tabela Referencial - 2020 Versão 04','0 to 10','Port Test','Division Test');
        System.assertEquals(true, objReturnTest != null,'Should return the Pricebook Entry');

        Test.stopTest();
    }

    @isTest 
    public static void getRemarksGenericsTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        List<Product2> remarkGenericList = AddQuoteLineItemBRLController.getRemarksGenerics();
        System.assertEquals(true, remarkGenericList.size() > 0,'Should return the Remarks.');

        Test.stopTest();
    }

    @isTest 
    public static void getPrimaryServiceTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        List<Product2> primaryServiceList = AddQuoteLineItemBRLController.getPrimaryService();
        System.assertEquals(true, primaryServiceList.size() > 0,'Should return the Remarks.');

        Test.stopTest();
    }

    @isTest 
    public static void getSecondaryServiceTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        List<Product2> secondaryServiceList = AddQuoteLineItemBRLController.getSecondaryService();
        System.assertEquals(true, secondaryServiceList.size() > 0,'Should return the Remarks.');

        Test.stopTest();
    }
    @isTest 
    public static void getProductRemarksTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();

        List<Product2> productRemarksList = AddQuoteLineItemBRLController.getProductRemarks();
        System.assertEquals(true, productRemarksList.size() > 0,'Should return the Remarks.');

        Test.stopTest();
    }
    @isTest 
    public static void getAdjustmentValuesTest() {
        Test.startTest();

        List<String> adjustmentValues = AddQuoteLineItemBRLController.getAdjustmentValues();
        System.assertEquals(true, adjustmentValues.size() > 0,'Should return the picklist.');

        Test.stopTest();
    }
    @isTest 
    public static void getApplicableValuesTest() {
        Test.startTest();

        List<String> applicableValues = AddQuoteLineItemBRLController.getApplicableValues();
        System.assertEquals(true, applicableValues.size() > 0,'Should return the picklist.');

        Test.stopTest();
    }
    @isTest 
    public static void getOperatorValuesTest() {
        Test.startTest();

        List<String> operatorValues = AddQuoteLineItemBRLController.getOperatorValues();
        System.assertEquals(true, operatorValues.size() > 0,'Should return the picklist.');

        Test.stopTest();
    }

    @isTest 
    public static void getDefaultPrimaryServiceTest() {
        Product2 objProduct = [SELECT Id,Parent_Product__c FROM Product2 WHERE Name = '0 to 10' LIMIT 1];
        Test.startTest();

        Product2 objPrimaryService = AddQuoteLineItemBRLController.getDefaultPrimaryService(objProduct.Parent_Product__c);
        System.assertEquals(true, objPrimaryService!=null,'Should return the Remark.');

        Test.stopTest();
    }

    @isTest 
    public static void getSpecificRemarksPerDivisionTest() {
        Product2 objProduct = [SELECT Id,Parent_Product__c FROM Product2 WHERE Name = '0 to 10' LIMIT 1];
        Test.startTest();

        List<Product2> lstSpecificRemarks = AddQuoteLineItemBRLController.getSpecificRemarksPerDivision(objProduct.Parent_Product__c);
        System.assertEquals(true, lstSpecificRemarks!=null,'Should return the Remark.');

        Test.stopTest();
    }

    @isTest 
    public static void createQuoteLineItensTest() {
        Quote objQuote = [SELECT Id FROM Quote LIMIT 1];
        Product2 objProductOnRange = [SELECT Id,Parent_Product__r.Parent_Product__r.Name,Parent_Product__r.Name,Parent_Product__c,Parent_Product__r.Parent_Product__c FROM Product2 Where Name ='10 to 20' ORDER BY Parent_Product__r.Parent_Product__r.Name LIMIT 1];
        Product2 primaryService = [SELECT Id, Name, Description, Family FROM Product2 WHERE Family = 'Servico Principal' Order By Name Asc LIMIT 1];
        Product2 secondaryService = [SELECT Id, Name, Description, Family FROM Product2 WHERE Family = 'Servicos Secundarios' Order By Name Asc LIMIT 1];
        Product2 remarkGeneric = [SELECT Id, Name, Description, Family, Selected_On_Screen__c, Order_Remarks__c FROM Product2 
                            WHERE Family = 'Remark' And Parent_Product__c = ''
                            ORDER BY Order_Remarks__c ASC LIMIT 1];

        List<String> lstPrimaryService = new List<String>();
        lstPrimaryService.add(primaryService.Id);
        List<AddQuoteLineItemBRLController.ParamsWrapper> lstToJSON = new List<AddQuoteLineItemBRLController.ParamsWrapper>();

        AddQuoteLineItemBRLController.RemarksWrapper objRemarksWrapper = new AddQuoteLineItemBRLController.RemarksWrapper();
        List<String> lstRemarksWrapper = new List<String>();
        objRemarksWrapper.Id = remarkGeneric.Id;
        lstRemarksWrapper.add(objRemarksWrapper.Id);
        List<AddQuoteLineItemBRLController.SecondaryServicesWrapper> lstSecondaryService = new List<AddQuoteLineItemBRLController.SecondaryServicesWrapper>();
        AddQuoteLineItemBRLController.SecondaryServicesWrapper secondaryServicesWrapper = new AddQuoteLineItemBRLController.SecondaryServicesWrapper();
        
        secondaryServicesWrapper.ServiceId = secondaryService.Id;
        secondaryServicesWrapper.Name = secondaryService.Name;
        secondaryServicesWrapper.Discount = 2;
        secondaryServicesWrapper.Price = '1000';
        secondaryServicesWrapper.DiscountPrice ='5000';
        lstSecondaryService.add(secondaryServicesWrapper);
        AddQuoteLineItemBRLController.ParamsWrapper qliWrapper = new AddQuoteLineItemBRLController.ParamsWrapper();
        
        List<AddQuoteLineItemBRLController.CustomRemarksWrapper> lstCustoRemarks = new  List<AddQuoteLineItemBRLController.CustomRemarksWrapper>();
        AddQuoteLineItemBRLController.CustomRemarksWrapper objCustomRemarksWrapper = new AddQuoteLineItemBRLController.CustomRemarksWrapper();


        List<String> lstSpecificRemarks = new List<String>();
        qliWrapper.quoteId = objQuote.Id;
        qliWrapper.productId = objProductOnRange.Id;
        qliWrapper.listPrice ='2000';
        qliWrapper.salesPrice ='5000';
        qliWrapper.discount ='10';
        qliWrapper.divisionId =objProductOnRange.Parent_Product__c;
        qliWrapper.portId =objProductOnRange.Parent_Product__r.Parent_Product__c;
        qliWrapper.defaultPrimaryService = lstPrimaryService;
        qliWrapper.specificRemarks =lstSpecificRemarks;
        qliWrapper.customSpecificRemarks =lstCustoRemarks;
        qliWrapper.secondaryServices = lstSecondaryService;
        lstToJSON.add(qliWrapper);
        Test.startTest();
        String jsonData = JSON.serialize(lstToJSON);
        String jsonRemarks = JSON.serialize(lstRemarksWrapper);

        Boolean objReturnTest = AddQuoteLineItemBRLController.createQuoteLineItens(jsonData,jsonRemarks);
        System.assertEquals(true, objReturnTest ,'Should create QLI');

        Test.stopTest();
    }
}