/**
 * @description       : Classe de Teste para ContractRemarkDAO
 * @author            : Jhonatan.pires@everymind.com.br
 * @group             : 
 * @last modified on  : 02-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class ContractRemarkDAOTest {

    @TestSetup
    static void makeData() {
        // 1. Estrutura Básica (Conta, Atuação, Oportunidade, Cotação)
        Account acc = new Account(Name = 'Conta Teste DAO');
        insert acc;

        // --- CORREÇÃO: Criação da Atuação Obrigatória ---
        Atuacao__c atuacao = new Atuacao__c(
            Name = 'Atuacao Teste',
            Conta__c = acc.Id,
            Segmentacao_de_Mercado__c = 'Aço', // Preenchendo campos comuns para evitar outros erros
            Categoria__c = 'Targets',
            Perfil__c = 'Afretador'
        );
        insert atuacao;

        Opportunity opp = new Opportunity(
            Name = 'Opp Teste DAO',
            AccountId = acc.Id,
            StageName = 'Draft',
            CloseDate = Date.today(),
            Atuacao__c = atuacao.Id // --- Vínculo Obrigatório ---
        );
        insert opp;

        Quote quote = new Quote(
            Name = 'Quote Teste DAO', 
            OpportunityId = opp.Id
        );
        insert quote;

        // 2. Estrutura de Produtos e DWT
        DWT_Range__c dwt = new DWT_Range__c(Name = '0 to 10');
        insert dwt;

        Product2 port = new Product2(Name = 'Porto Teste', Family = 'Porto', DWT_Range__c = dwt.Id, IsActive = true);
        insert port;

        Product2 division = new Product2(Name = 'Divisao Teste', Family = 'Divisao', IsActive = true);
        insert division;

        Product2 service = new Product2(Name = 'Service Teste', Family = 'Servico Principal', IsActive = true);
        insert service;
        
        // Serviço específico para o teste de Imbituba
        Product2 serviceShifting = new Product2(Name = 'Shifting in', Family = 'Servico Principal', IsActive = true);
        insert serviceShifting;

        // 3. Produtos do Tipo Remark (Crucial para os filtros)
        Product2 remarkProdGeneral = new Product2(Name = 'Remark Geral', Family = 'Remark', IsActive = true);
        insert remarkProdGeneral;

        // Nome exato exigido pela query getRemarksFainasIMBITUBA
        Product2 remarkProdImbituba = new Product2(
            Name = 'For direct shifting: 35% discount of a complete manoeuvre (unberthing and re-berthing);', 
            Family = 'Remark', 
            IsActive = true
        );
        insert remarkProdImbituba;

        // 4. Criação dos Contract Remarks
        List<Contract_Remark__c> remarksToInsert = new List<Contract_Remark__c>();

        // Remark de Reajuste
        remarksToInsert.add(new Contract_Remark__c(
            Quote__c = quote.Id,
            Type__c = 'Reajuste',
            Remark__c = remarkProdGeneral.Id,
            Port__c = port.Id,
            Division__c = division.Id,
            Service__c = service.Id,
            Value__c = 10
        ));

        // Remark de Faina (Geral)
        remarksToInsert.add(new Contract_Remark__c(
            Quote__c = quote.Id,
            Type__c = 'Faina',
            Remark__c = remarkProdGeneral.Id,
            Port__c = port.Id,
            Division__c = division.Id,
            Service__c = service.Id,
            Value__c = 20
        ));

        // Remark de Faina (Imbituba - Deve bater com os filtros específicos)
        remarksToInsert.add(new Contract_Remark__c(
            Quote__c = quote.Id,
            Type__c = 'Faina',
            Remark__c = remarkProdImbituba.Id, // Nome específico
            Service__c = serviceShifting.Id,   // Nome 'Shifting in'
            Port__c = port.Id,
            Division__c = division.Id,
            Value__c = 30
        ));

        insert remarksToInsert;
    }

    public static String getFakeId(Schema.SObjectType sot, Integer index) {
        String result = String.valueOf(index);
        return sot.getDescribe().getKeyPrefix() + 
            '0'.repeat(12 - result.length()) + 
            result + 'AAA';
    }

    /**
     * @description Testa a busca de Remarks do tipo 'Reajuste' via Query Real
     */
    @isTest
    static void testGetRemarksReajuste_RealQuery() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        // Garante que o mock está nulo
        ContractRemarkDAO.mockRemarksReajuste = null;
        List<Contract_Remark__c> results = ContractRemarkDAO.getRemarksReajuste(q.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Deveria retornar registros de Reajuste');
        System.assertEquals('Reajuste', results[0].Type__c, 'O tipo deveria ser Reajuste');
    }

    /**
     * @description Testa a busca de Remarks do tipo 'Faina' via Query Real
     * Verifica se o filtro "Different (!=)" da query está funcionando
     */
    @isTest
    static void testGetRemarksFainas_RealQuery() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        ContractRemarkDAO.mockRemarksFainas = null;
        List<Contract_Remark__c> results = ContractRemarkDAO.getRemarksFainas(q.Id);
        Test.stopTest();

        // Esperamos encontrar apenas o remark geral, pois o de Imbituba tem o nome que é excluído nesta query
        System.assert(!results.isEmpty(), 'Deveria retornar registros de Faina');
        for(Contract_Remark__c cr : results) {
            System.assertEquals('Faina', cr.Type__c);
            System.assertNotEquals('For direct shifting: 35% discount of a complete manoeuvre (unberthing and re-berthing);', 
                                   cr.Remark__r.Name, 'Não deveria retornar o remark específico de Imbituba');
        }
    }

    /**
     * @description Testa a busca específica de Imbituba via Query Real
     * Verifica os filtros de Nome do Remark e Nome do Serviço
     */
    @isTest
    static void testGetRemarksFainasIMBITUBA_RealQuery() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        ContractRemarkDAO.mockRemarksImbituba = null;
        List<Contract_Remark__c> results = ContractRemarkDAO.getRemarksFainasIMBITUBA(q.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Deveria retornar exatamente 1 registro de Imbituba');
        System.assertEquals('Shifting in', results[0].Service__r.Name, 'Deveria ser o serviço Shifting in');
    }

    /**
     * @description Testa a injeção de Mocks para garantir que a classe de Serviço
     * consiga rodar sem fazer queries no banco (evitando SOQL 101).
     */
    @isTest
    static void testAllMethods_WithMock() {
        // Preparação do Mock em memória
        Contract_Remark__c mockCR = new Contract_Remark__c(
            Id = getFakeId(Contract_Remark__c.SObjectType, 1),
            Value__c = 999
        );
        List<Contract_Remark__c> mockList = new List<Contract_Remark__c>{ mockCR };

        // Injeção nas variáveis estáticas
        ContractRemarkDAO.mockRemarksReajuste = mockList;
        ContractRemarkDAO.mockRemarksFainas = mockList;
        ContractRemarkDAO.mockRemarksImbituba = mockList;

        Test.startTest();
        
        // Chamada dos métodos passando um ID falso qualquer
        List<Contract_Remark__c> resReajuste = ContractRemarkDAO.getRemarksReajuste(getFakeId(Quote.SObjectType, 1));
        List<Contract_Remark__c> resFaina = ContractRemarkDAO.getRemarksFainas(getFakeId(Quote.SObjectType, 1));
        List<Contract_Remark__c> resImbituba = ContractRemarkDAO.getRemarksFainasIMBITUBA(getFakeId(Quote.SObjectType, 1));
        
        Test.stopTest();

        // Validações
        System.assertEquals(1, resReajuste.size(), 'Deveria retornar a lista mockada');
        System.assertEquals(999, resReajuste[0].Value__c, 'O valor deveria ser o do mock');
        
        System.assertEquals(1, resFaina.size());
        System.assertEquals(999, resFaina[0].Value__c);
        
        System.assertEquals(1, resImbituba.size());
        System.assertEquals(999, resImbituba[0].Value__c);
        
        // Limpeza dos mocks
        ContractRemarkDAO.mockRemarksReajuste = null;
        ContractRemarkDAO.mockRemarksFainas = null;
        ContractRemarkDAO.mockRemarksImbituba = null;
    }
}