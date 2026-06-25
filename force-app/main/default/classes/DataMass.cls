/**
 * @description       : 
 * @author            : -
 * @group             : 
 * @last modified on  : 02-12-2026
 * @last modified by  : michelle.campello@wilsonsons.com.br
**/
@isTest 
public class DataMass {
    
    public static Account accountMass() {
        Account accTest = new Account(
            Name = 'Conta Teste',
            BillingCountry = 'Brasil',
            BillingStreet = 'Rua teste, 100',
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingPostalCode = '09700-000',
            ShippingStreet = 'Rua teste, 100',
            ShippingCity = 'São Paulo',
            ShippingState = 'SP',
            ShippingPostalCode = '09700-000',
            ShippingCountry = 'Brasil',
            Id_Tugsys_Commercial_Group__c = 01,
            Segmentacao_Especifica_Rebocadores__c = 'Liner',
            Status__c = 'Nova'
        );
        insert accTest;
        return accTest;
    }

    public static Opportunity oppMass(Id pb, Account acc){
        Atuacao__c atuacao = new Atuacao__c(
            Name = 'Teste',
            Segmentacao_de_Mercado__c = 'Aço',
            Conta__c = acc.Id,
            Categoria__c = 'Targets',
            Perfil__c = 'Afretador'
        );
        insert atuacao;

        Opportunity opp = new Opportunity(
            recordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Rebocadores').getRecordTypeId(),
            CurrencyIsoCode = 'USD',
            AccountId = acc.Id,
            Name = 'Teste',
            StageName = 'Draft',
            Data_Inicio_Contrato__c =  Date.today(),
            Client_Type__c = 'Tramp with Contract',
            Service_Type__c = 'Towage Operation',
            //Special_Operations__c = 'Bareboat Contract',
            Data_Fim_Contrato__c =  Date.today()+1,
            CloseDate = System.today(),
            Tipo_Contrato__c = 'Regular',
            ExchangeRate__c = 50,
            Pricebook2Id = pb,
            TCF_PO__c = false,
            Atuacao__c = atuacao.Id
        );
        insert opp;
        return opp;
    }

    public static Quote quoteMass(Pricebook2 pb, Opportunity opp){
        Quote quote = new Quote(
            Name = 'Teste',
            Pricebook2Id = pb.Id,
            OpportunityId = opp.Id
        );
        insert quote;
        return quote;
    }
        
    public static QuoteLineItem qliMass(Quote quote, PricebookEntry pbe, Product2 product){
        QuoteLineItem qli = new QuoteLineItem(
            Competing_Company__c = null,
            Reason_Loss_or_Gain__c = 'Price',
            QuoteId = quote.Id,
            PricebookEntryid = pbe.Id,
            Quantity = 1,
            UnitPrice = 7000,
            Vessel__c = 'Vessel test',
            Product2Id = product.Id,
            Contract_Period__c = 'P1'
        );
        insert qli;
        return qli;
    }

    public static DWT_Range__c dwtMass(){
        DWT_Range__c dwtRange = new DWT_Range__c(
            Name = 'DWT Geral',
            DWT__c = '0 to 10,10 to 20,20 to 30,30 to 40,40 to 50,50 to 60,60 to 70,70 to 80,80 to 90,90 to 100,100 to 110,110 to 120,120 to 130,130 to 180,180 to 200,200 to 270,270 to 365,over 365',
            Id_Tugsys_DWT__c = '1'
        );
        insert dwtRange;
        return dwtRange;
    }

    public static OpportunityLineItem oliMass(Opportunity opp, Product2 product){
        Opportunity currentOpp = [
            SELECT Id, Pricebook2Id, CurrencyIsoCode
            FROM Opportunity
            WHERE Id = :opp.Id
            LIMIT 1
        ];

        List<PricebookEntry> pbEntries = [
            SELECT Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id = :product.Id
            AND Pricebook2Id = :currentOpp.Pricebook2Id
            AND IsActive = true
            LIMIT 1
        ];

        PricebookEntry pbe;
        if (!pbEntries.isEmpty()) {
            pbe = pbEntries[0];
        } else {
            Id standardPbId = Test.getStandardPricebookId();

            List<PricebookEntry> standardEntries = [
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Product2Id = :product.Id
                AND Pricebook2Id = :standardPbId
                AND IsActive = true
                LIMIT 1
            ];

            if (standardEntries.isEmpty()) {
                insert new PricebookEntry(
                    Pricebook2Id = standardPbId,
                    Product2Id = product.Id,
                    CurrencyIsoCode = currentOpp.CurrencyIsoCode,
                    UnitPrice = 10000,
                    IsActive = true,
                    DWT_Range__c = '0 to 10',
                    UseStandardPrice = false
                );
                standardEntries = [
                    SELECT Id, UnitPrice
                    FROM PricebookEntry
                    WHERE Product2Id = :product.Id
                    AND Pricebook2Id = :standardPbId
                    AND IsActive = true
                    LIMIT 1
                ];
            }

            Decimal baseUnitPrice = standardEntries[0].UnitPrice;
            pbe = new PricebookEntry(
                Pricebook2Id = currentOpp.Pricebook2Id,
                Product2Id = product.Id,
                CurrencyIsoCode = currentOpp.CurrencyIsoCode,
                UnitPrice = baseUnitPrice,
                IsActive = true,
                DWT_Range__c = '0 to 10',
                UseStandardPrice = false
            );
            insert pbe;
        }

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = currentOpp.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = pbe.UnitPrice
        );

        insert oli;
        return oli;
    }

    public static Product2 mainServiceProductMass(){
        Product2 mainService = new Product2(
            Family = 'Servico Principal',
            Name = 'Lumpsum In/Out',
            IsActive = true,
            Id_Tugsys_Service__c = 1
        );
        insert mainService;
        return mainService;
    }

    public static Product2 remarkProductMass(){
        Product2 remark = new Product2(
            Family = 'Remark',
            Name = 'Remark Test',
            Type__c = 'Reajuste',
            IsActive = true
        );
        insert remark;
        return remark;
    }

    public static Remark_Quote__c remarkQuoteMass(Quote quote, Product2 remarkProduct, Product2 port){
        Remark_Quote__c remarkQuote = new Remark_Quote__c(
            Quote__c = quote.Id,
            Remark__c = remarkProduct.Id,
            Text_Remark__c = remarkProduct.Name,
            Port__c = port.Id,
            Type__c = remarkProduct.Type__c
        );
        insert remarkQuote;
        return remarkQuote;
    }

    public static Product2 portProductMass(Dwt_Range__c dwt){
        Product2 port = new Product2(
            Family = 'Porto',
            Name = 'Port Test',
            Dwt_Range__c = dwt.Id,
            IsActive = true,
            Id_Tugsys_Index_DWT__c = '1'
        );
        insert port;
        return port;
    }

    public static Product2 divisionProductMass(Product2 port){
        Product2 division = new Product2(
            Family = 'Divisao',
            Name = 'Division Test',
            IsActive = true,
            Parent_Product__c = port.Id,
            Id_Tugsys_Division__c = 12
        );
        insert division;
        return division;
    }

    public static Product2 contractRemarkProductMass(){
        Product2 crProduct = new Product2(
            Family = 'Contract Remark',
            Name = 'CR Test',
            Contract_Remark_Value_Standard__c = 3000,
            Contract_Remark_Value_Custom__c = null,
            Applicable_Standard__c = 'In Price',
            Type__c = 'Reajuste',
            Operator__c = '>',
            Factor__c = 3,
            Adjustment_Type__c = 'Ajuste $ na Fatura',
            Table__c = 'Lumpsum',
            IsActive = true,
            Id_Tugsys_Index_DWT__c = '1'
        );
        insert crProduct;
        return crProduct;
    }

    public static Contract_Remark__c contractRemarkMass(Quote quote, Product2 division, Product2 service, Product2 crProduct){
        Contract_Remark__c cr = new Contract_Remark__c(
            Remark__c = crProduct.Id,
            Text_Remark__c = crProduct.Name,
            Port__c = division.Parent_Product__r.Id,
            Division__c = division.Id,
            Service__c = service.Id,
            Dwt_Range__c = division.Parent_Product__r.Dwt_Range__r.Id,
            Type__c = crProduct.Type__c,
            Operator__c = crProduct.Operator__c,
            Factor__c = crProduct.Factor__c,
            Adjustment_Type__c = crProduct.Adjustment_Type__c,
            Table__c = crProduct.Table__c,
            Applicable__c = crProduct.Applicable_Standard__c,
            Value__c = crProduct.Contract_Remark_Value_Standard__c,
            Quote__c = quote.Id
        );
        insert cr;
        return cr;
    }
    
    public static SpecialRemark__c specialRemarkMass(Quote quote){
        SpecialRemark__c sr = new SpecialRemark__c(
            Quote__c = quote.Id,
            AdjustmentType__c = 'Ajuste %',
            ApplicableStandard__c = 'In discount note',
            OperationCountStart__c = 1,
            OperationCountEnd__c = 4,
            Operator__c = '-',
            ServiceType__c = 'LUMPSUM',
            Table__c = 'Lumpsum',
            Tariff__c = 10,
            Type__c = 'Reajuste'
        );
        insert sr;
        return sr;
    }

    public static Draft_Contract__c draftContractMass(Quote quote, Product2 service, Product2 product){
        Draft_Contract__c dc = new Draft_Contract__c(
            index__c = 1,
            description__c = 'test',
            quote__c = quote.Id,
            Type__c = 'Faina',
            Service__c = service.Id, // Porto
            Product__c = product.Id, // Produto auxiliar
            Service_Product_Aux__c = service.Id,
            Period__c = 1,
            Pro_Rata__c = true,
            Displacement__c = true,
            TCF_PO__c = true
        );
        insert dc;
        return dc;
    }

    public static Commercial_Agrement__c commercialAgreementMass(Quote quote, Product2 service, Product2 product, String type) {
        Commercial_Agrement__c ca = new Commercial_Agrement__c(
            Quote__c = quote.Id,
            Service__c = service.Id,
            Product__c = product.Id,
            Type__c = type,           
            Value__c = '500'
        );
        insert ca;
        return ca;
    }

    public static Pricebook2 pbMass(){
        Pricebook2 pricebook = new Pricebook2(
            Name = 'Tabela Referencial - 2020 Versão 04',
            CurrencyIsoCode = 'USD',
            IsActive = true,
            IsLatestVersion__c = true
        );
        insert pricebook;
        return pricebook;
    }

    public static Pricebook2 pbWithOriginalMass(Pricebook2 pb){
        Pricebook2 pbOriginal = new Pricebook2(
            Name = 'Tabela Referencial - 2020 Versão 05',
            CurrencyIsoCode = 'USD',
            IsActive = true,
            IsLatestVersion__c = true,
            OriginalPriceBook__c = pb.Id
        );
        insert pbOriginal;
        return pbOriginal;
    }

    public static PricebookEntry standardPbeMass(Id standardPb, Product2 mainService){
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPb,
            Product2Id = mainService.Id,
            CurrencyIsoCode = 'USD',
            UnitPrice = 10000,
            IsActive = true,
            DWT_Range__c = '0 to 10',
            UseStandardPrice = false
        );
        insert standardPbe;
        return standardPbe;
    }

    public static PricebookEntry pbeMass(Pricebook2 pricebook, Product2 mainService, boolean useStandardPrice){
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebook.Id,
            Product2Id = mainService.Id,
            UnitPrice = 10000,
            CurrencyIsoCode = 'USD',
            IsActive = true,
            DWT_Range__c = '0 to 10',
            UseStandardPrice = useStandardPrice
        );
        insert pbe;
        return pbe;
    }
}