/**
 * @description       :
 * @author            : Matheus Hubes
 * @group             :
 * @last modified on  : 08-04-2026
 * @last modified by  : wrodrigues@triscal.com.br
**/
@isTest(SeeAllData=true)
public class CreateQliControllerTest {

    @isTest
    static void testGetProductsByQuote() {
        Id standardPb = Test.getStandardPricebookId();
        Product2 product = DataMass.mainServiceProductMass();
        Pricebook2 pb = DataMass.pbMass();
        DataMass.standardPbeMass(standardPb, product);
        DataMass.pbeMass(pb, product, true);

        Account acc = DataMass.accountMass();
        Opportunity opp = DataMass.oppMass(pb.Id, acc);
        Quote testQuote = DataMass.quoteMass(pb, opp);

        Test.startTest();
        List<CreateQliController.ProductWrapper> productWrappers =
            CreateQliController.getProductsByQuote(testQuote.Id);
        Test.stopTest();

        System.assertNotEquals(null, productWrappers, 'A lista de produtos nao deve ser nula.');
    }

    @isTest
    static void testGetQuoteInformations() {
        Id standardPb = Test.getStandardPricebookId();
        Product2 product = DataMass.mainServiceProductMass();
        Pricebook2 pb = DataMass.pbMass();
        DataMass.standardPbeMass(standardPb, product);
        DataMass.pbeMass(pb, product, true);

        Account acc = DataMass.accountMass();
        Opportunity opp = DataMass.oppMass(pb.Id, acc);
        Quote testQuote = DataMass.quoteMass(pb, opp);

        Test.startTest();
        Quote retrievedQuote = CreateQliController.getQuoteInformations(testQuote.Id);
        Test.stopTest();

        System.assertEquals(testQuote.Id, retrievedQuote.Id, 'Quote Id should match');
    }

    @isTest
    static void testCreateQlis() {
        Id standardPb = Test.getStandardPricebookId();
        Product2 product = DataMass.mainServiceProductMass();
        Pricebook2 pb = DataMass.pbMass();
        DataMass.standardPbeMass(standardPb, product);
        DataMass.pbeMass(pb, product, true);

        Account acc = DataMass.accountMass();
        Opportunity opp = DataMass.oppMass(pb.Id, acc);
        Quote testQuote = DataMass.quoteMass(pb, opp);

        List<CreateQliController.QliWrapper> qliWrappers = new List<CreateQliController.QliWrapper>();
        CreateQliController.QliWrapper qliWrapper = new CreateQliController.QliWrapper();
        qliWrapper.productId = product.Id;
        qliWrapper.quantidade = 10;
        qliWrapper.isencaoDeServico = false;
        qliWrapper.cobrancaDePeriodos = false;
        qliWrapper.converterFreeTime = false;
        qliWrapper.franquiaEmDias = false;
        qliWrapper.diasDeIsencao = 7;
        qliWrapper.isencaoEmDias = false;
        qliWrapper.precoBaseDeVenda = 10;
        qliWrappers.add(qliWrapper);

        String jsonQlis = JSON.serialize(qliWrappers);

        Test.startTest();
        CreateQliController.createQlis(testQuote.Id, jsonQlis);
        Test.stopTest();

        System.assert(true, 'Metodo executado sem excecao.');
    }
}