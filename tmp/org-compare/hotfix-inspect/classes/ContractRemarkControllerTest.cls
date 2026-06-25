@isTest
public class ContractRemarkControllerTest {
    @isTest
    public static void ContractRemarkControllerTest() {
        Test.startTest();
        //Massa de Dados
        Pricebook2 pb = DataMass.pbMass();
        Account acc = DataMass.accountMass();
        Opportunity opp = DataMass.oppMass(pb.Id, acc);
        Quote quote = DataMass.quoteMass(pb, opp);
        DWT_Range__c dwt = DataMass.dwtMass();
        Product2 port = DataMass.portProductMass(dwt);
        Product2 division = DataMass.divisionProductMass(port);
        Product2 service = DataMass.mainServiceProductMass();
        Product2 crProduct = DataMass.contractRemarkProductMass();
        Product2 crCustomValueProduct = DataMass.contractRemarkProductMass();
        crCustomValueProduct.Contract_Remark_Value_Custom__c = 2000;
        update crCustomValueProduct;
        Contract_Remark__c cr = DataMass.contractRemarkMass(quote, division, service, crProduct);     



        //Atribuições em Listas
        List<String> lstContractRemarks = new List<String>();
        lstContractRemarks.add(crProduct.Id);

        List<String> lstCustomValueContractRemarks = new List<String>();
        lstCustomValueContractRemarks.add(crCustomValueProduct.Id);

        List<Product2> lstProducts = new List<Product2>();
        lstProducts.add(crProduct);

        //Métodos - Gerais
        ContractRemarkController.getContractRemarks(quote.Id);
		ContractRemarkController.getAllContractRemarks();        
        ContractRemarkController.getProductPorts();
        ContractRemarkController.getProductDivisions(port.Id);
        ContractRemarkController.getProductServices();
        ContractRemarkController.getDwtRanges(division.Id);
        ContractRemarkController.getApplicableValues();
        ContractRemarkController.getTypeValues();
        ContractRemarkController.getOperatorValues();
        ContractRemarkController.getAdjustmentValues(false);
        ContractRemarkController.getTableValues();
        //Credit-Note
        ContractRemarkController.getAdjustmentValues(true);
        

        //Método de teste que salva contract remark baseado no produto contract remark que foi selecionado em tela
        ContractRemarkController.saveContractRemarks(quote.Id, JSON.serialize(lstContractRemarks));
        //Método de teste que salva contract remark baseado no produto contract remark que foi selecionado em tela, com valor customizado
        ContractRemarkController.saveContractRemarks(quote.Id, JSON.serialize(lstCustomValueContractRemarks));

        //Método de teste em atualização de valor no produto remark de contrato
        ContractRemarkController.updateContractRemarks(lstProducts);
        //Método de teste em atualização de valor do remark de contrato com valor nulo
        lstProducts.clear();
        ContractRemarkController.updateContractRemarks(lstProducts);

        //Método de teste em criação de remark customizado com remark já existente
        /*ContractRemarkController.createCustomContractRemark(quote.Id, port.Id, division.Id, service.Id, dwt.Id, cr.Applicable__c, cr.Type__c, cr.Operator__c, cr.Factor__c,
                                                            cr.Adjustment_Type__c, cr.Table__c, crProduct.Id, cr.Value__c, null);*/
        //Método de teste em criação de remark custom com remark novo
        ContractRemarkController.createCustomContractRemark(quote.Id, port.Id, division.Id, service.Id, dwt.Id, cr.Applicable__c, cr.Type__c, cr.Operator__c, cr.Factor__c,
                                                            cr.Adjustment_Type__c, cr.Table__c, null, cr.Value__c, 'Teste');
        Test.stopTest();
    }
}