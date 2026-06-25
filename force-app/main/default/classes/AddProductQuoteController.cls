/**
* @Descrição               : 
* @Autor                   : 
* @Empresa:                : Everymind LTDA.
* @Ultima modificação em   : 03-08-2022/ 19-12-22
* @Ultima modificação por  : Luis Coêlho
**/
public class AddProductQuoteController {
    
    
    @AuraEnabled
    public static List<Quote_Text_Template__c> getQuoteTextTemplate(){
        return [Select Id,Name ,Text__c From Quote_Text_Template__c Where Active__c	= true];
    }
    
    @AuraEnabled
    public static List<Pricebook2> getPriceBooks() {
        return [SELECT id, Name, IsActive from Pricebook2 Where IsActive=true Order by name];
    }
    
    
    @AuraEnabled
    public static List<VesselWrapper> getSupportedPorts(String jsonVessels,Integer vesselIndex, String idPriceBook, String strDwtRange){
        
        List<VesselWrapper> vesselList = (List<VesselWrapper>)System.JSON.deserialize(JsonVessels, List<VesselWrapper>.class);       
        SuportedPortsWrapper returnSuportedPorts = new SuportedPortsWrapper();
        returnSuportedPorts.listPorts = new List<SuportedPortDivisionWrapper>();
        Set<String> setVesselDwtRange = new Set<String>();
        Map<Id, List<PricebookEntry>> mapPricebook = new Map<Id, List<PricebookEntry>>();
        Set<String> setIdPort = new Set<String>();
        Set<String> setIdDivision = new Set<String>();
        
        for(VesselWrapper vessel : vesselList){
            if(vessel.indexId == vesselIndex){
                setVesselDwtRange.add(vessel.dwtRangeSelect);
            }
        }
        
        List<PricebookEntry> pricebooks = [SELECT Id, Product2.Parent_Product__r.Parent_Product__c, Product2.Parent_Product__c, Product2.Parent_Product__r.Parent_Product__r.Name, Product2.Parent_Product__r.Parent_Product__r.DWT_Range__c 
        FROM PricebookEntry Where Product2.Parent_Product__r.Parent_Product__r.DWT_Range__c IN : setVesselDwtRange AND Pricebook2Id =: IdPriceBook
        AND (DWT_Range__c =: strDwtRange.substring(strDwtRange.indexOfAnyBut(' ')) OR Name =: strDwtRange.substring(strDwtRange.indexOfAnyBut(' ')))
        ORDER BY Product2.Parent_Product__r.Parent_Product__r.Name];
        
        for(PricebookEntry pricebook : pricebooks){
            
            //Preenche o mapa de Pricebook
            List<PricebookEntry> lstAux;
            if(!mapPricebook.containsKey(pricebook.Product2.Parent_Product__r.Parent_Product__r.DWT_Range__c)){   
                lstAux = new List<PricebookEntry>();
            }else{
                lstAux = mapPricebook.get(pricebook.Product2.Parent_Product__r.Parent_Product__r.DWT_Range__c);
            }
            lstAux.add(pricebook);
            mapPricebook.put(pricebook.Product2.Parent_Product__r.Parent_Product__r.DWT_Range__c, lstAux);
            setIdPort.add(pricebook.Product2.Parent_Product__r.Parent_Product__c);
            setIdDivision.add(pricebook.Product2.Parent_Product__c);
        }
        
        List<Product2> listPort = [SELECT Id, Name FROM Product2 WHERE Id IN : setIdPort ORDER BY Name ASC];
        List<Product2> listDivision = [SELECT Id, Name FROM Product2 WHERE Id IN : setIdDivision ORDER BY Name ASC];
        Map<Id, Product2> mapPort = new Map<Id, Product2>(listPort);
        Map<Id, Product2> mapDivision = new Map<Id, Product2>(listDivision);
        
        
        
        for(VesselWrapper vessel : vesselList){
            if(vessel.indexId == vesselIndex){
                
                //Listar os portos que atendem a faixa de DWT do Navio
                List<PricebookEntry> listPriceBooksEntry  = mapPricebook.get(vessel.dwtRangeSelect);
                
                Set<Id> listPorts = new Set<Id>();
                //Criando a lista de portos
                for(PricebookEntry entry : listPriceBooksEntry){
                    
                    if(!listPorts.contains(entry.Product2.Parent_Product__r.Parent_Product__c)){
                        //Adicionar no controle de portos
                        listPorts.add(entry.Product2.Parent_Product__r.Parent_Product__c);                
                        
                        SuportedPortDivisionWrapper newSuportedPort = new SuportedPortDivisionWrapper();
                        //newSuportedPort.port = [SELECT Id, Name FROM Product2 WHERE Id=: entry.Product2.Parent_Product__r.Parent_Product__c ORDER BY Name ASC];
                        newSuportedPort.port = mapPort.get(entry.Product2.Parent_Product__r.Parent_Product__c);
                        newSuportedPort.listDivisons = new List<Product2>();
                        
                        Set<Id> listDivisions = new Set<Id>();
                        
                        for(PricebookEntry portDivision : listPriceBooksEntry)
                        {
                            
                            if(portDivision.Product2.Parent_Product__r.Parent_Product__c == entry.Product2.Parent_Product__r.Parent_Product__c)
                            {
                                if(!listDivisions.contains(portDivision.Product2.Parent_Product__r.Parent_Product__c))
                                {
                                    //Product2 division = [Select Id,Name From Product2 Where Id=: portDivision.Product2.Parent_Product__c];
                                    Product2 division = mapDivision.get(portDivision.Product2.Parent_Product__c);
                                    newSuportedPort.listDivisons.add( division  );        
                                    
                                    listDivisions.add(portDivision.Product2.Parent_Product__c);
                                }       
                            }
                        }                
                        
                        returnSuportedPorts.listPorts.add(newSuportedPort);
                    }
                }
                
                vessel.suportedPorts = returnSuportedPorts;
            }
        }
        return vesselList;
    }
    
    @AuraEnabled
    public static ResponsePricebookQuote getPriceBookQuote(String IdQuote) {
        ResponsePricebookQuote resultQuotePriceBook = new ResponsePricebookQuote();
        System.debug('Quote Id :' + IdQuote);    
        Quote quote = [Select Id,Pricebook2Id From Quote Where Id=:IdQuote];
        
        if(quote != null){
            if(quote.Pricebook2Id != null){
                
                resultQuotePriceBook.existPricebook = true;
                resultQuotePriceBook.idPricebook = quote.Pricebook2Id ;
            }
            else
            {
                //Se nao existir um pricebook associado a QUOTE(se a quote nao estiver syncada) ele busca o pricebook na opportunidade pai
                
                List<Quote> parentOpportunityPricebookId = [SELECT Opportunity.Pricebook2Id FROM Quote WHERE Id =:IdQuote];
                if(!parentOpportunityPricebookId.isEmpty()){
                    Quote lstQuote = parentOpportunityPricebookId[0];
                    resultQuotePriceBook.existPricebook = false;
                    resultQuotePriceBook.idPricebook = lstQuote.Opportunity.Pricebook2Id;
                }   
                
                
            }
        }
        
        return resultQuotePriceBook;
        
    }
    
    @AuraEnabled
    public static String getLeadSource(String recordId) {
        Quote q = new Quote();
        
        q = [SELECT id, OpportunityId, Opportunity.leadsource FROM Quote WHERE Id =: recordId];
        
        return q.Opportunity.leadsource;
    }
    
    @AuraEnabled
    public static List<DWT_Range__c> getDwtRange(){
        return [SELECT Id, name, DWT__c from DWT_Range__c]; 
        
    }

    @AuraEnabled
    public static string getDefaultDwtRange(){
       TCS_Quote__c defaultQuote = TCS_Quote__c.getOrgDefaults();
    
        if (defaultQuote != null && defaultQuote.DefaultDWTRangeId__c != null) {
            return defaultQuote.DefaultDWTRangeId__c;
        }
        
        return '';
    }
    
    @AuraEnabled
    public static void saveQuoteLineItens(String IdQuote, String IdPriceBook , String JsonVessels , String JsonGenericRemarks){
        List<ResponseQuote> responseSaveQuote = new List<ResponseQuote>();
        List<String> listGenericRemarks = (List<String>)System.JSON.deserialize(JsonGenericRemarks, List<String>.class);
        List<VesselWrapper> vesselList = (List<VesselWrapper>)System.JSON.deserialize(JsonVessels, List<VesselWrapper>.class);
        System.debug('Quote :' + IdQuote);
        System.debug('VesselList'+ vesselList);
        Quote quoteCurrent = [Select Id, Texto_Template__c, Pricebook2Id From Quote Where Id =: IdQuote];
        List<QuoteLineItem> listQuoteLine = new List<QuoteLineItem>();
        List<Service__c> listServices = new List<Service__c>();
        List<Remark_Quote__c> listRemarks = new List<Remark_Quote__c>();
        List<Remark_Quote__c> listCustomRemarks = new List<Remark_Quote__c>();
        List<Remark_Quote__c> listGenericRemarksSelected = new List<Remark_Quote__c>();
        
        System.debug('Quote Pricebook2Id:' + quoteCurrent.Pricebook2Id);
        if(quoteCurrent != null)
        {
            //Definindo texto do template
            
            quoteCurrent.Pricebook2Id = IdPriceBook;
            
            List<Remark_Quote__c> remarkQuoteList = [
                SELECT Remark__c
                FROM Remark_Quote__c
                WHERE Quote__c = :quoteCurrent.Id
            ];

            Set<Id> remarksJaExistentes = new Set<Id>();

            for (Remark_Quote__c rq : remarkQuoteList) {
                if (rq.Remark__c != null) {
                    remarksJaExistentes.add(rq.Remark__c);
                }
            }


            for(VesselWrapper vessel : vesselList)
            {
                for(PortWrapper port : vessel.ports)
                {
                    QuoteLineItem newQuoteLineItem = new QuoteLineItem();
                    System.debug('port.pricebookEntryId : ' + port.pricebookEntryId);
                    
                    newQuoteLineItem.PricebookEntryId = port.pricebookEntryId;
                    newQuoteLineItem.Quantity = 1;
                    newQuoteLineItem.Product2Id = port.Id;
                    newQuoteLineItem.Port__c = port.Id;
                    newQuoteLineItem.Division__c = port.divisionId;
                    newQuoteLineItem.UnitPrice = port.priceWithDiscount;
                    //newQuoteLineItem.Discount = port.discount;
                    newQuoteLineItem.Discount_Moeda__c = port.discount;
                    newQuoteLineItem.QuoteId = quoteCurrent.Id;
                    newQuoteLineItem.Vessel__c = vessel.vesselName;
                    //listQuoteLine.add(newQuoteLineItem);
                    
                    //Montar estrutura de serviços
                    
                    Set<String> IdsPrimaryServicesSelected = new Set<String>();
                    for(String idPss :  port.primaryServicesSelected)
                    {
                        List<String> strSplited = String.valueOf(idPss).Split('-');
                        String strIdService = strSplited[0];
                        
                        System.debug('JP LINHA 171' + strIdService);
                        
                        if(!IdsPrimaryServicesSelected.contains(strIdService)){
                            IdsPrimaryServicesSelected.add(strIdService);
                            System.debug('JP LINHA 171' + IdsPrimaryServicesSelected);
                        }    
                    }
                    
                    System.debug('Total PrimaryServicesSelected : ' + port.primaryServicesSelected.size());
                    System.debug('Total IdsPrimaryServicesSelected : ' + IdsPrimaryServicesSelected.size());
                    
                    for(PrimaryServicesWrapper ps : port.primaryServices)
                    {
                        if(IdsPrimaryServicesSelected.contains(ps.Id))
                        {
                            /*
                            Service__c service = new Service__c();
                            service.Product__c = ps.Id;
                            service.Product_Description__c = ps.description;
                            service.Quote__c = quoteCurrent.Id;
                            service.Port__c = port.Id;
                            
                            listServices.add(service);
                            */
                            QuoteLineItem newQuoteLineItemSP = new QuoteLineItem();
                            newQuoteLineItemSP.PricebookEntryId = port.pricebookEntryId;
                            System.debug('pricebookEntryIdSP :' + port.pricebookEntryId);
                            newQuoteLineItemSP.Quantity = 1;
                            newQuoteLineItemSP.Service__c = ps.Id;
                            newQuoteLineItemSP.Product2Id = ps.Id;
                            newQuoteLineItemSP.Port__c = port.Id;
                            newQuoteLineItemSP.Division__c = port.divisionId;
                            newQuoteLineItemSP.UnitPrice = port.priceWithDiscount; //price
                            System.Debug('JP LINHA 204' + port.priceWithDiscount);
                            //newQuoteLineItemSP.Discount = port.discount;
                            newQuoteLineItemSP.Discount_Moeda__c = port.discount;
                            System.Debug('JP LINHA 206' + port.discount);
                            newQuoteLineItemSP.QuoteId = quoteCurrent.Id;
                            newQuoteLineItemSP.Vessel__c = vessel.vesselName;
                            newQuoteLineItemSP.Lineup_Id__c = port.leadId;
                            
                            listQuoteLine.add(newQuoteLineItemSP);
                            System.Debug('JP LINHA 212' + listQuoteLine);
                        }
                    }
                    
                    Set<String> IdsSecondaryServicesSelected = new Set<String>();
                    for(String idPs :  port.secondaryServicesSelected)
                    {
                        List<String> strSplited = String.valueOf(idPs).Split('-');
                        String strIdService = strSplited[0];
                        System.Debug('JP LINHA 221' + strIdService);
                        
                        if(!IdsSecondaryServicesSelected.contains(strIdService)){
                            IdsSecondaryServicesSelected.add(strIdService);
                        }    
                    }
                    
                    System.debug('Total SecondaryServicesSelected : ' + port.secondaryServicesSelected.size());
                    
                    for(SecondaryServicesWrapper pss : port.secondaryServices)
                    {
                        if(IdsSecondaryServicesSelected.contains(pss.Id))
                        {
                            /*
                            Service__c service = new Service__c();
                            service.Product__c = pss.Id;
                            service.Product_Description__c = pss.description;
                            service.Quote__c = quoteCurrent.Id;
                            service.Port__c = port.Id;
                            
                            listServices.add(service);
                            */
                            
                            QuoteLineItem newQuoteLineItemSS = new QuoteLineItem();
                            newQuoteLineItemSS.PricebookEntryId = port.pricebookEntryId;
                            newQuoteLineItemSS.Quantity = 1;
                            newQuoteLineItemSS.Service__c = pss.Id;
                            newQuoteLineItemSS.Product2Id = pss.Id;
                            newQuoteLineItemSS.Port__c = port.Id;
                            newQuoteLineItemSS.Division__c = port.divisionId;
                            newQuoteLineItemSS.UnitPrice = pss.priceWithDiscount;//price
                            System.debug('newQuoteLineItemSS :' + pss.price);
                            //newQuoteLineItemSS.Discount = pss.discount;
                            newQuoteLineItemSS.Discount_Moeda__c = pss.discount;
                            newQuoteLineItemSS.QuoteId = quoteCurrent.Id;
                            newQuoteLineItemSS.Vessel__c = vessel.vesselName;
                            newQuoteLineItemSS.Lineup_Id__c = port.leadId;
                            
                            listQuoteLine.add(newQuoteLineItemSS);
                        }
                    }
                    
                    //Remarks por cada porto
                    for(RemarksWrapper rem : port.remarks) {
                        System.debug('remarkWrapper rem : ' + rem);
                        if(rem != null){                      
                                if (rem.Id != '') {
                                    
                                    Remark_Quote__c newRemark = new Remark_Quote__c();
                                    newRemark.Port__c = port.Id;
                                    newRemark.Division__c = port.divisionId;
                                    newRemark.Quote__c = quoteCurrent.Id;
                                    newRemark.Remark__c = rem.Id;
                                    newRemark.Text_Remark__c = rem.description;
                                    newRemark.Service__c = rem.servicePrimary;
                                    newRemark.Applicable__c = rem.applicableStd;
                                    newRemark.Value__c = rem.value;
                                    newRemark.Operator__c = rem.operator;
                                    newRemark.Factor__c = rem.factor;
                                    newRemark.Table__c = rem.table;
                                    newRemark.Type__c = rem.type;
                                    newRemark.Adjustment_Type__c = rem.adjustment;
                                    newRemark.CurrencyIsoCode = 'USD';
                                    
                                    listRemarks.add(newRemark);
                                    System.debug('Remarks : ' + listRemarks);
                                }else {
                                    
                                    Remark_Quote__c newRemark = new Remark_Quote__c();
                                    newRemark.Port__c = port.Id;
                                    newRemark.Division__c = port.divisionId;
                                    newRemark.Quote__c = quoteCurrent.Id;
                                    newRemark.Text_Remark__c = rem.description;
                                    newRemark.Remark__c = rem.idRemark;
                                    newRemark.Service__c = rem.servicePrimary != null ? rem.servicePrimary : null;
                                    newRemark.Applicable__c = rem.applicableStd;
                                    newRemark.Value__c = rem.value;
                                    newRemark.Operator__c = rem.operator;
                                    newRemark.Factor__c = rem.factor;
                                    newRemark.Table__c = rem.table;
                                    newRemark.Type__c = rem.type;
                                    newRemark.Adjustment_Type__c = rem.adjustment;
                                    newRemark.CurrencyIsoCode = 'USD';
                                    
                                    listCustomRemarks.add(newRemark);
                                    System.debug('Custom Remarks : ' + listCustomRemarks); 
                                }
                        }
                    }
                }
            }
            
            if(listGenericRemarks.size() > 0){
                
                List<Product2> remarkGenericList = [SELECT Id, Name, Description, Family, Service_Primary__c, Value__c, Table__c, Type__c, ServiceType__c 
                FROM Product2 WHERE Family = 'Remark' And Parent_Product__c = ''];
                
                Set<String> controlRemarks = new Set<String>();

                //Montra controle para verificar remarks selecionados                
                for(String idRemark : listGenericRemarks)
                {
                    if(!controlRemarks.contains(idRemark) && idRemark != null ){
                        controlRemarks.add(idRemark);
                    }
                }
                System.debug('Tota lde Remarks Genericos :' + remarkGenericList.size());                
                System.debug('Tota lde Remarks Genericos Selecionados:' + listGenericRemarks.size());                
                
                for(Product2 rem : remarkGenericList){
                    if(rem != null){
                        if(controlRemarks.contains(rem.Id) && !remarksJaExistentes.contains(rem.Id))
                        {
                            Remark_Quote__c newGenericRemark = new Remark_Quote__c();
                            newGenericRemark.Quote__c = quoteCurrent.Id;
                            newGenericRemark.Remark__c = rem.Id;
                            newGenericRemark.Text_Remark__c = rem.Description;
                            //NEW
                            newGenericRemark.Service__c = rem.Service_Primary__c;
                            //newGenericRemark.Value__c = rem.ServiceType__c != 'TEMPO' ? rem.Value__c : listQuoteLine.get(0).UnitPrice; //Remark-Faina de tempo
                            
                            newGenericRemark.Value__c = rem !=null ? rem.Value__c : listQuoteLine.get(0).UnitPrice;
                            
                            
                            newGenericRemark.Table__c = rem.Table__c;
                            newGenericRemark.Type__c = rem.Type__c;
                            newGenericRemark.CurrencyIsoCode = 'USD';
                            
                            listGenericRemarksSelected.add(newGenericRemark);
                        }
                    }
                }
            }
            
            System.debug('Total de Itens da Cotação :' + listQuoteLine.size());
            
            if(listQuoteLine.size() > 0)
            {
                try
                {
                    if(!Test.isRunningTest()){
                        //Update QUOTE
                        update quoteCurrent;
                        
                        //Inserir os dados das linhas de cotação
                        upsert  listQuoteLine;
                        
                        if(listRemarks.size() > 0){
                            //Inserindo os remarks 
                            upsert listRemarks;
                        }
                        
                        if (listCustomRemarks.size() > 0) {
                            upsert listCustomRemarks;
                        }
                        
                        if (listGenericRemarksSelected.size() > 0) {
                            upsert listGenericRemarksSelected;
                        }
                        
                        if(listServices.size() > 0 ){
                            //Inserindo lista de serviços primarios e secundarios
                            upsert listServices;
                        }
                    }
                }
                catch (Exception ex){
                    throw new AuraHandledException(ex.getMessage() + '-Linha :' + ex.getLineNumber());
                    
                }
            }
            else{
                throw new AuraHandledException(Label.LbMsgErrorQuantityMainServices);
            }
        }
        
        //return responseSaveQuote;
        
    }
    
    @AuraEnabled
    public static List<VesselWrapper> createVesselList (Integer vesselQuantity){
        List<VesselWrapper> vesselList = new List<VesselWrapper>();
        
        List<DWT_Range__c> listDwtRange =  [SELECT Id, name, DWT__c from DWT_Range__c];
        List<DwtRangeWrapper> listDwtRangeWrapper = new List<DwtRangeWrapper>();
        
        for(DWT_Range__c range :  listDwtRange){
            DwtRangeWrapper newRange = new DwtRangeWrapper();
            newRange.Id = range.Id;
            newRange.Name = range.Name;
            newRange.DWT = range.DWT__c;
            
            listDwtRangeWrapper.add(newRange);
        }
        
        
        Map<Integer, String> mapIndexLetter = new Map<Integer, String>();
        mapIndexLetter.put(0, 'A');
        mapIndexLetter.put(1, 'B');
        mapIndexLetter.put(2, 'C');
        mapIndexLetter.put(3, 'D');
        mapIndexLetter.put(4, 'E');
        mapIndexLetter.put(5, 'F');
        mapIndexLetter.put(6, 'G');
        mapIndexLetter.put(7, 'H');
        mapIndexLetter.put(8, 'I');
        mapIndexLetter.put(9, 'J');
        mapIndexLetter.put(10, 'K');
        mapIndexLetter.put(11, 'L');
        mapIndexLetter.put(12, 'M');
        mapIndexLetter.put(13, 'N');
        
        for(integer i = 0; i < vesselQuantity; i++) {
            vesselList.add(new VesselWrapper());            
            vesselList[i].vesselName =  Label.LbVessel + ' ' + String.valueOf(i + 1);
            vesselList[i].vesselNameDefault = Label.LbVessel + ' ' + String.valueOf(i + 1);
            vesselList[i].showTable = false;
            vesselList[i].dwtRangeList = listDwtRangeWrapper;
            vesselList[i].indexId = i;
            vesselList[i].indexString = mapIndexLetter.get(i);
            
            vesselList[i].namePortSelect = 'VesselPort' + String.valueOf(i + 1);
            vesselList[i].nameDivisionSelect = 'VesselDivision' + String.valueOf(i + 1);
            
        }        
        
        return vesselList;
    }
    
    @AuraEnabled
    public static List<Product2> retrievePortsList() {
        List<Product2> prodList = new List<Product2>();
        
        prodList = [SELECT id, Name FROM Product2 WHERE Family = 'Porto' Order By Name Asc];
        
        return prodList;
    }      
    
    @AuraEnabled
    public static List<Product2> retrieveDivisionsList(String portId) {
        List<Product2> prodList = new List<Product2>();
        
        prodList = [SELECT id, Name FROM Product2 WHERE Family = 'Divisao' AND Parent_Product__c =: portId Order By Name Asc];
        
        return prodList;
    }
    
    @AuraEnabled
    public static List<VesselWrapper> updateValuesSecondaryServices(String JsonVessels, String jsonPortSecondaryDraft){
        List<VesselWrapper> vesselList = (List<VesselWrapper>)System.JSON.deserialize(JsonVessels, List<VesselWrapper>.class);
        List<SecondaryServicesWrapper> portWrapperlSecondaryListDraft = (List<SecondaryServicesWrapper>)System.JSON.deserialize(jsonPortSecondaryDraft, List<SecondaryServicesWrapper>.class);
        
        for(VesselWrapper vessel : vesselList){
            
            if(vessel.ports != null)
            {
                //Percorrer portos para achar o porto correto
                for(PortWrapper portWrapper : vessel.ports)
                {
                    //Percorrer os serviços secundários para atualizar os valores
                    for(SecondaryServicesWrapper serviceSecondary : portWrapper.secondaryServices){
                        
                        //Percorrer o drafty para atualizar os valores do serviços originais para os novos valores.
                        for(SecondaryServicesWrapper portWrapperSecondaryDraft : portWrapperlSecondaryListDraft)
                        {
                            List<String> strRowIdSplited = portWrapperSecondaryDraft.idServicePortIdDivisionId.split('-');
                            String idService = strRowIdSplited[0];
                            String idPort = strRowIdSplited[1];
                            String idDivision = strRowIdSplited[2];
                            String uniqueIdJS = strRowIdSplited[3];
                            
                            if(serviceSecondary.Id == idService && portWrapper.Id == idPort && portWrapper.divisionId == idDivision && portWrapper.uniqueIdJS == uniqueIdJS)
                            {
                                //Verifica se os os serviços estão batendo
                                if(serviceSecondary.idServicePortIdDivisionId == portWrapperSecondaryDraft.idServicePortIdDivisionId){
                                    
                                    //Se houver valor preenchido diferente de zero a atualizaçlão ira ocorrer
                                    if(portWrapperSecondaryDraft.discount > 0) {     
                                        
                                        Decimal priceDiscount = serviceSecondary.price - (serviceSecondary.price * (portWrapperSecondaryDraft.discount/100));
                                        serviceSecondary.discount = (portWrapperSecondaryDraft.discount < = 0 ? 0 : portWrapperSecondaryDraft.discount);
                                        serviceSecondary.priceWithDiscount = Math.round(priceDiscount);
                                    }
                                    if(portWrapperSecondaryDraft.discount <= 0)
                                    {
                                        serviceSecondary.discount = 0;
                                        serviceSecondary.priceWithDiscount = portWrapperSecondaryDraft.priceWithDiscount;
                                    }
                                    
                                }
                            }
                        }
                    }
                    
                }
            }
            
            
        }
        
        return vesselList;
    }
    
    @AuraEnabled
    public static List<VesselWrapper> updateValuesPrimaryServices(String JsonVessels , String IdPort,String IdDivision, String IdService, String uniqueIdJS){
        List<VesselWrapper> vesselList = (List<VesselWrapper>)System.JSON.deserialize(JsonVessels, List<VesselWrapper>.class);
        
        System.debug('Id Porto :' + IdPort);
        System.debug('Id Service :' + IdService);
        
        
        for(VesselWrapper vessel : vesselList){
            
            if(vessel.ports != null)
            {
                for(PortWrapper portWrapper : vessel.ports)
                {
                    //indexVesselIdPortoIdDivision
                    if(portWrapper.Id == IdPort && portWrapper.divisionId == IdDivision &&  portWrapper.uniqueIdJS == uniqueIdJS){
                        
                        //Percorrer os servico primario para atualizar valores
                        for(PrimaryServicesWrapper primaryService : portWrapper.primaryServices)
                        {
                            
                            if(primaryService.Id == IdService)
                            {
                                System.debug('Desconto Porto :' + portWrapper.discount );
                                System.debug('Price :' + portWrapper.price );
                                System.debug('Desconto Valor :' + portWrapper.priceWithDiscount );
                                
                                if(portWrapper.discount < = 0)
                                {
                                    primaryService.discount = 0;
                                    primaryService.price = portWrapper.priceWithDiscount;
                                    primaryService.priceWithDiscount = portWrapper.priceWithDiscount;
                                }
                                else{
                                    primaryService.discount = portWrapper.discount;
                                    primaryService.price = portWrapper.price;
                                    primaryService.priceWithDiscount = portWrapper.priceWithDiscount;
                                }
                                
                                //idServicePortIdDivisionId
                                portWrapper.primaryServicesSelected = new List<String>();  
                                portWrapper.primaryServicesSelected.add(IdService + '-' + IdPort + '-' + portWrapper.divisionId + '-' + uniqueIdJS);
                                
                                
                            }
                        }
                        
                        //Percorrer todos os serviços secundários para atualizar os valores
                        for(SecondaryServicesWrapper secondaryService : portWrapper.secondaryServices)
                        {
                            secondaryService.price = portWrapper.priceWithDiscount;
                        }
                    }
                }
            }
        }
        return vesselList;
    }
    
    @AuraEnabled
    public static List<VesselWrapper> updateValuesPorts(String JsonVessels , String jsonPortWrapperDraft){
        List<VesselWrapper> vesselList = (List<VesselWrapper>)System.JSON.deserialize(JsonVessels, List<VesselWrapper>.class);
        List<PortWrapper> portWrapperlListDraft = (List<PortWrapper>)System.JSON.deserialize(jsonPortWrapperDraft, List<PortWrapper>.class);
        
        System.debug('Total de Navios :' + vesselList.size());
        
        for(VesselWrapper vessel : vesselList){
            
            if(vessel.ports != null)
            {
                for(PortWrapper portWrapper : vessel.ports)
                {
                    for(PortWrapper portWrapperDraft : portWrapperlListDraft)
                    {
                        if(portWrapperDraft.indexVesselIdPortoIdDivision == portWrapper.indexVesselIdPortoIdDivision)
                        {
                            
                            PricebookEntry priceBook = [SELECT Id,UnitPrice, DWT_Range__c FROM PricebookEntry Where Id =: portWrapper.pricebookEntryId];
                            
                            if(portWrapperDraft.discount > 0) {
                                
                                Decimal priceDiscount = priceBook.UnitPrice - (priceBook.UnitPrice * (portWrapperDraft.discount/100));
                                portWrapper.discount = portWrapperDraft.discount;
                                portWrapper.priceWithDiscount = Math.round(priceDiscount);
                            }
                            
                            //Calculo com valor maior que ZERO
                            if( portWrapperDraft.priceWithDiscount > 0) {
                                Decimal discount = 100 - ((portWrapperDraft.priceWithDiscount * 100) / priceBook.UnitPrice);
                                portWrapper.discount = Math.round(discount);
                                portWrapper.priceWithDiscount = portWrapperDraft.priceWithDiscount;
                            }
                            
                            //Calculo com desconto menor que ZERO
                            if(portWrapperDraft.discount <= 0)
                            {
                                Decimal priceDiscount = priceBook.UnitPrice - (priceBook.UnitPrice * (portWrapperDraft.discount/100));
                                portWrapper.discount = portWrapperDraft.discount;
                                portWrapper.priceWithDiscount = Math.round(priceDiscount);
                                
                                //portWrapper.discount = 0;
                                //portWrapper.priceWithDiscount = portWrapperDraft.priceWithDiscount;
                            }
                            
                            //Verifica o serviços selecionado para atualizar o valor
                            for(String IdPrimaryServiceSelected : portWrapper.primaryServicesSelected)
                            {
                                for(PrimaryServicesWrapper psw : portWrapper.primaryServices){
                                    if(psw.Id == IdPrimaryServiceSelected)
                                    {
                                        
                                        if(portWrapper.discount <= 0)
                                        {
                                            psw.discount = 0;
                                            psw.price = portWrapper.priceWithDiscount;
                                            psw.priceWithDiscount = portWrapper.priceWithDiscount;
                                        }
                                        else{
                                            psw.discount = portWrapper.discount;
                                            psw.price = portWrapper.price;
                                            psw.priceWithDiscount = portWrapper.priceWithDiscount;
                                        }
                                    }                                        
                                }	                                
                            }
                            
                            //Percorrer todos os serviços secundários para atualizar os valores
                            for(SecondaryServicesWrapper secondaryService : portWrapper.secondaryServices)
                            {
                                secondaryService.price = portWrapper.priceWithDiscount;
                                secondaryService.priceWithDiscount = portWrapper.priceWithDiscount;
                            }
                            
                            vessel.draftValues = null;
                        }
                    }    	    
                }
            }
            
        }
        
        return vesselList;
    }
    
    @AuraEnabled
    public static List<Product2> getRemarksGenerics(Id quoteId){
        List<Product2> remarkGenericList = [
            SELECT Id, Name, Description, Family, Selected_On_Screen__c, Order_Remarks__c, TCF_TablesAvailable__c  
            FROM Product2 
            WHERE Family = 'Remark' And Parent_Product__c = ''
            ORDER BY Order_Remarks__c ASC
        ];

        try{
            Quote quote = [SELECT Id, Opportunity.Table__c FROM Quote WHERE Id = :quoteId];

            for(Product2 remark : remarkGenericList){
                if(remark.TCF_TablesAvailable__c == null){
                    continue;
                }else if (
                    (quote.Opportunity != null) && 
                    (!remark.TCF_TablesAvailable__c.contains(quote.Opportunity.Table__c))
                ) {
                    remark.Selected_On_Screen__c = false;
                }
            }      
        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());
        }
        return remarkGenericList;
    }
    
    @AuraEnabled
    public static List<Product2> getProductServices() {
        List<Product2> productServicesList = ProductDAO.getServiceByFamily();
        return productServicesList;
    }
    
    @AuraEnabled
    public static List<Product2> getServiceName(String serviceId) {
        List<Product2> serviceIdList = ProductDAO.getServiceNameById(serviceId);
        return serviceIdList;
    }
    
    @AuraEnabled
    public static List<String> getApplicableValues() {
        List<String> applicableValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Product2.Applicable_Standard__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry appValue : ple) {
            applicableValuesList.add(appValue.getLabel());
        }
        
        return applicableValuesList;    
    }
    
    @AuraEnabled
    public static List<String> getOperatorValues() {
        List<String> operatorValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Product2.Operator__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry appValue : ple) {
            operatorValuesList.add(appValue.getLabel());
        }
        
        return operatorValuesList;
    }
    
    @AuraEnabled
    public static List<Product2> getProductRemarks(){
        List<Product2> remarksList = ProductDAO.getRemarkByFamily();
        
        return remarksList;
    }
    
    @AuraEnabled
    public static List<String> getAdjustmentValues() {
        List<String> adjustmentValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Product2.Adjustment_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry adjustValue : ple) {
            adjustmentValuesList.add(adjustValue.getLabel());
        }
        
        return adjustmentValuesList;
    }
    @AuraEnabled
    public static List<Lead> getLineupLeads(String quoteId){
        List<Opportunity> oppList = OpportunityDAO.getOppByQuoteId(quoteId);
        
        List<QuoteLineItem> qlis = [SELECT Lineup_Id__c FROM QuoteLineItem WHERE Lineup_Id__c != null LIMIT 50000];
        
        Set<String> lineups = new Set<String>();
        for(QuoteLineItem qli : qlis) {
            lineups.add(qli.Lineup_Id__c);
        }
        
        List<Lead> leadList = [SELECT Id, LINEUP_DSC_NAVIO_CARGA__c, LINEUP_DSC_PORTO_CARGA__c, LINEUP_DSC_DWT_CARGA__c, Junction_Lineup__c, 
        Division__c, LINEUP_PROSPEC_ID__c  FROM Lead WHERE ConvertedOpportunityId IN: oppList AND Id NOT IN: lineups];
        System.debug('list Lead'+ leadList);
        
        if (leadList.size() > 0) {
            return leadList;    
        }else {
            return null;
        }
    }
    
    //NEW
    @AuraEnabled
    public static LineUpLeadTO getLineupLeadSelected(String leadId){
        LineUpLeadTO objTO = new LineUpLeadTO();
        List<Product2> divisionList = new List<Product2>();
        try{
            List<Lead> leadList = [SELECT Id, LINEUP_DSC_NAVIO_CARGA__c, LINEUP_DSC_PORTO_CARGA__c, LINEUP_DSC_DWT_CARGA__c, Junction_Lineup__c, 
            LINEUP_PROSPEC_ID__c,Division__c, PortDWTLineup__c, ProdutoRangeFaixa__r.Name, DWTRangeName_LineUp__r.Name FROM Lead WHERE Id =: leadId];
            
            if (leadList[0].Division__c != null) {
                divisionList = [
                SELECT Id, Name, Parent_Product__c, Parent_Product__r.Name 
                FROM Product2 
                WHERE Family = 'Divisao' 
                AND Name =: leadList[0].Division__c 
                AND Parent_Product__r.Name =: LeadList[0].LINEUP_DSC_PORTO_CARGA__c
                ];
                System.debug('list Lead'+ leadList);
            }
            
            if (divisionList.size() > 0) {
                objTO.lead = leadList[0];
                objTO.produto = divisionList[0];
                
                return objTO;
            }else {
                return null;
            }
        }catch(Exception ex){
            return null;
        }
    }
    
    public class LineUpLeadTO {
        @AuraEnabled
        public Lead lead {get;set;}
        @AuraEnabled
        public Product2 produto {get;set;}
    }
    
    @AuraEnabled
    public static List<VesselWrapper> addSelectedPortToVessel(String quoteId, Integer index, String vessels, String idPriceBook, String uniqueIdJS, String leadId) {
        List<VesselWrapper> vesselList = (List<VesselWrapper>)System.JSON.deserialize(vessels, List<VesselWrapper>.class);       
        List<Product2> primaryServiceList = new List<Product2>();
        List<Product2> secondaryServiceList = new List<Product2>();
        List<Product2> remarkList = new List<Product2>();
        
        List<Product2> listAllProductRelated  = new List<Product2>();
        Map<Id,Id> mapAllProductRelated = new Map<Id,Id>();
        Map<Id,PricebookEntry> mapAllPriceBookEntry = new Map<Id,PricebookEntry>();
        
        PortWrapper newPort = new PortWrapper();
        Product2 porto = new Product2();
        Product2 division = new Product2();
        PricebookEntry price = null;
        List<PricebookEntry> listPrice = new List<PricebookEntry>();
        List<PricebookEntry> listPriceBookAllProducts = new List<PricebookEntry>();
        
        system.debug('DivsionId : ' + vesselList[index].idDivisionSelect);
        system.debug('Faixa : ' +  vesselList[index].dwtRangeFaixaSelected);
        system.debug('IdPriceBook : ' +  idPriceBook);
        
        String strDwtRange = vesselList[index].dwtRangeFaixaSelected;
        
        //Lista todos os produtos de PRICEBOO ENTRY
        listPriceBookAllProducts = [SELECT Id,UnitPrice, DWT_Range__c FROM PricebookEntry WHERE Pricebook2Id =: idPriceBook And  Product2.Parent_Product__c =: vesselList[index].idDivisionSelect];
        
        System.debug('# vesselList[index].idDivisionSelect: ' + vesselList[index].idDivisionSelect);
        System.debug('# vesselList[index].idPortSelect: ' + vesselList[index].idPortSelect);
        System.debug('# strDwtRange: ' + strDwtRange);
        System.debug('# idPriceBook: ' + idPriceBook);
        
        //Lista somente o produto por faixa de DWT
        listPrice = [SELECT Id,UnitPrice, DWT_Range__c FROM PricebookEntry WHERE Pricebook2Id =: idPriceBook AND Product2.Parent_Product__c =: vesselList[index].idDivisionSelect AND isActive = TRUE AND (DWT_Range__c =: strDwtRange.substring(strDwtRange.indexOfAnyBut(' ')) Or  Name =: strDwtRange.substring(strDwtRange.indexOfAnyBut(' ')))];
        
        porto = [SELECT Name,Service_Primary__c FROM Product2 WHERE id =: vesselList[index].idPortSelect LIMIT 2];
        System.Debug(porto);
        division = [SELECT Name,Service_Primary__c FROM Product2 WHERE id =: vesselList[index].idDivisionSelect LIMIT 2];
        System.Debug(division);
        primaryServiceList = [SELECT id, Name, Description, Family FROM Product2 WHERE Family = 'Servico Principal' AND TCF_ActiveService__c = true Order By Name Asc];
        secondaryServiceList = [SELECT id, Name, Description, Family FROM Product2 WHERE Family = 'Servicos Secundarios' AND TCF_ActiveService__c = true Order By Name Asc];
        //NEW 
        remarkList = [SELECT Id, Name, Description, Family, Selected_On_Screen__c, Service_Primary__r.Name, Service_Primary__c,
        Parent_Product__r.Parent_Product__r.Dwt_Range__r.Name, Applicable_Standard__c, Value__c, Operator__c, Factor__c,
        Table__c, Type__c, Adjustment_Type__c
        FROM Product2 WHERE Family = 'Remark' AND (Parent_Product__c =: vesselList[index].idDivisionSelect)];
        
        listAllProductRelated = [SELECT id, Name, Description, Family FROM Product2 WHERE Parent_Product__c =: vesselList[index].idDivisionSelect];
        
        // Busca desconto do porto, caso possua
        List<PricebookEntry> lstEntradaDescontoPorto = [SELECT Id, Discount__c FROM PricebookEntry WHERE Product2Id = :porto.Id AND Pricebook2Id = :idPriceBook AND IsActive = true];
        System.debug('#lstEntradaDescontoPorto: ' + lstEntradaDescontoPorto);
        //NEW
        system.debug('ListPrice : ' + listPrice);
        
        //Popula lista de todos os produtos para chegar se existe produto principal e secundario vinculado
        for(Product2 pr : listAllProductRelated){
            if(!mapAllProductRelated.containsKey(pr.Id)){
                mapAllProductRelated.put(pr.Id,pr.Id);
            }
        }
        
        //Popula MAP para melhor controle dos PRICEBOOKSENTRYS vinculados a divisão
        for(PricebookEntry entry : listPriceBookAllProducts){
            if(!mapAllPriceBookEntry.containsKey(entry.Id)){
                mapAllPriceBookEntry.put(entry.Id,entry);
            }
        }
        
        
        System.debug('Total de Produtos :' + mapAllProductRelated.size());
        
        if(listPrice.size() == 1 ){
            price = listPrice[0];
        }
        //adding required attributes to the new port wrapper that will be added on selected vessel
        newPort.id = porto.id;
        newPort.indexVesselIdPortoIdDivision = index + '-' + porto.id + '-' + division.Id + '-' + uniqueIdJS;
        newPort.idTableSelected = newPort.indexVesselIdPortoIdDivision + '-One';
        newPort.uniqueIdJS = uniqueIdJS;
        newPort.name = porto.Name;
        newPort.division = division.Name;
        newPort.divisionId = division.Id; 
        newPort.leadId = leadId;
        System.debug('#quoteId: ' + quoteId);
        // Busca informação de origem da oportunidade
        Quote cotacao = [SELECT Id, Lead_Source__c FROM Quote WHERE Id = :quoteId];
        
        //Valida price book
        if(price != null) {
            // Verifica se o lead é agencia
            if(cotacao.Lead_Source__c == 'Agency') {
                newPort.discount = !lstEntradaDescontoPorto.isEmpty() ? lstEntradaDescontoPorto.get(0).Discount__c : null;
                newPort.price =  price != null ? price.UnitPrice : 0;
                newPort.pricebookEntryId = price != null ? String.valueOf(price.Id) : '';
                newPort.priceWithDiscount = price != null ? price.UnitPrice : 0;
                newPort.priceWithDiscount = newPort.discount != null ? newPort.price - (newPort.price * (newPort.discount / 100)) : newPort.price;
            } else {
                newPort.price =  price != null ? price.UnitPrice : 0;
                newPort.pricebookEntryId = price != null ? String.valueOf(price.Id) : '';
                newPort.priceWithDiscount = price != null ? price.UnitPrice : 0;
                newPort.priceWithDiscount = newPort.discount != null ? newPort.price - (newPort.price * (newPort.discount / 100)) : newPort.price;
                
            }
        }
        else{
            throw new AuraHandledException(Label.LbMsgDwtNotFound);
        }
        
        newPort.dwtRange = vesselList[index].dwtRangeFaixaSelected;
        newPort.primaryServices = new List<PrimaryServicesWrapper>();
        newPort.primaryServicesSelected = new List<String>();
        
        System.debug('Service Primario :' + division.Service_Primary__c);
        //Verificar se a divisão tem o serviço 
        if(division.Service_Primary__c != null)
        {
            //idServicePortIdDivisionId
            newPort.primaryServicesSelected.add(division.Service_Primary__c + '-' + porto.Id + '-' + division.Id + '-' + uniqueIdJS);
        }
        
        for(Product2 pp : primaryServiceList)
        {
            
            PrimaryServicesWrapper newPrimaryService = new PrimaryServicesWrapper();
            newPrimaryService.idServicePortIdDivisionId = pp.Id + '-' + porto.Id + '-' + division.Id + '-' + uniqueIdJS;
            newPrimaryService.id = pp.Id;
            newPrimaryService.name = pp.Name;
            newPrimaryService.description = pp.Description;
            newPrimaryService.family = pp.Family;
            newPrimaryService.checked = false;
            
            
            //Atualiza os valor do pricebook conforme serviços primario pré selecionado selecionado 
            if(division.Service_Primary__c == pp.Id){
                newPrimaryService.checked = true;
                //newPrimaryService.price = mapAllPriceBookEntry.get(division.Id).UnitPrice;   
                if(price !=null){
                    newPrimaryService.price =  price != null ? price.UnitPrice : 0;
                    newPrimaryService.pricebookEntryId = price != null ? String.valueOf(price.Id) : '';
                    newPrimaryService.priceWithDiscount = price != null ? price.UnitPrice : 0;
                }
                
            }
            
            //Controle o PRICE BOOK ENTRY do produto primario
            if(mapAllPriceBookEntry.containsKey(pp.Id))
            {
                newPrimaryService.pricebookEntryId = mapAllPriceBookEntry.get(pp.Id).Id;
            }
            
            newPort.primaryServices.add(newPrimaryService);
        }
        
        newPort.secondaryServices = new List<SecondaryServicesWrapper>();
        newPort.secondaryServicesSelected = new List<String>();
        for(Product2 ps : secondaryServiceList)
        {
            
            SecondaryServicesWrapper newSecondaryService = new SecondaryServicesWrapper();
            newSecondaryService.idServicePortIdDivisionId = ps.Id + '-' + porto.Id + '-' + division.Id + '-' + uniqueIdJS;
            newSecondaryService.id = ps.Id;
            newSecondaryService.name = ps.Name;
            newSecondaryService.description = ps.Description;
            newSecondaryService.family = ps.Family;
            newSecondaryService.checked = mapAllProductRelated.containsKey(ps.Id);
            newSecondaryService.discount = 0;
            newSecondaryService.price = 0;
            newSecondaryService.priceWithDiscount =0;
            
            
            if(division.Service_Primary__c != null){
                //newPrimaryService.price = mapAllPriceBookEntry.get(division.Id).UnitPrice;   
                if(price !=null){
                    newSecondaryService.price =  price != null ? price.UnitPrice : 0;
                    newSecondaryService.pricebookEntryId = price != null ? String.valueOf(price.Id) : '';
                    newSecondaryService.priceWithDiscount = price != null ? price.UnitPrice : 0;
                }
                
            }
            
            //Controle o PRICE BOOK ENTRY do produto secundário
            if(mapAllPriceBookEntry.containsKey(ps.Id))
            {
                newSecondaryService.pricebookEntryId = mapAllPriceBookEntry.get(ps.Id).Id;
            }
            
            //Controla as seleções dos produtos secundarios selecionados
            if(mapAllProductRelated.containsKey(ps.Id))
            {
                newPort.secondaryServicesSelected.add(ps.Id + '-' + porto.Id);
            }
            
            newPort.secondaryServices.add(newSecondaryService);
        }
        
        //Produtos Remark
        newPort.remarks = new List<RemarksWrapper>();
        newPort.remarksSelected = new List<String>();
        for(Product2 pr : remarkList)
        {
            
            RemarksWrapper newRemark = new RemarksWrapper();
            newRemark.idServicePortIdDivisionId = pr.Id + '-' + porto.Id + '-' + division.Id;
            newRemark.id = pr.Id;
            newRemark.name = pr.Name;
            newRemark.description = pr.Description;
            newRemark.family = pr.Family;
            newRemark.servicePrimaryName = pr.Service_Primary__r.Name;
            newRemark.servicePrimary = pr.Service_Primary__c;
            newRemark.dwtRange = newPort.dwtRange;
            newRemark.applicableStd = pr.Applicable_Standard__c;
            newRemark.value = pr.Value__c;
            newRemark.operator = pr.Operator__c;
            newRemark.factor = pr.Factor__c;
            newRemark.table = pr.Table__c;
            newRemark.type = pr.Type__c;
            newRemark.adjustment = pr.Adjustment_Type__c;
            
            newRemark.checked = mapAllProductRelated.containsKey(pr.Id);
            
            if(mapAllProductRelated.containsKey(pr.Id))
            {
                //newPort.remarksSelected.add(pr.Id + '-' + porto.Id);
                newPort.remarksSelected.add(pr.Id + '-' + porto.Id + '-' + division.Id); 
            }
            
            newPort.remarks.add(newRemark);
        }
        
        //attribute used to indicate to aura component when to display port details data table
        vesselList[index].showTable = true;
        
        //adding port details
        if(vesselList[index].ports == null) {
            vesselList[index].ports = new List<PortWrapper>();
        }
        vesselList[index].ports.add(newPort);
        vesselList[index].idPortSelect = '';
        vesselList[index].idDivisionSelect = '';
        
        
        return vesselList;
    }
    
    public class VesselWrapper {
        @AuraEnabled public list<PortWrapper> draftValues;
        @AuraEnabled public List<Object> errors;
        @AuraEnabled public Integer indexId;
        @AuraEnabled public String indexString;
        @AuraEnabled public String vesselName;
        @AuraEnabled public String vesselNameDefault;
        @AuraEnabled public Boolean showTable;
        @AuraEnabled public List<DwtRangeWrapper> dwtRangeList;
        @AuraEnabled public String dwtRangeSelect;
        @AuraEnabled public List<DwtFaixaWrapper> dwtRangeFaixas;
        @AuraEnabled public String dwtRangeFaixaSelected;
        @AuraEnabled public List<PortWrapper> ports;
        @AuraEnabled public SuportedPortsWrapper suportedPorts;
        @AuraEnabled public String idPortSelect;
        @AuraEnabled public String idDivisionSelect;
        @AuraEnabled public String namePortSelect;
        @AuraEnabled public String nameDivisionSelect;
    }
    
    public class DwtFaixaWrapper{
        
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;         
    }
    
    public class DwtRangeWrapper{
        
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;  
        @AuraEnabled public String DWT;  
        
    }
    
    public class SuportedPortsWrapper {
        
        @AuraEnabled public List<SuportedPortDivisionWrapper> listPorts;
        
    }
    
    public class SuportedPortDivisionWrapper {
        
        @AuraEnabled public Product2 port;
        @AuraEnabled public List<Product2> listDivisons;
        
    }
    
    
    public class PortWrapper {
        
        @AuraEnabled public String idTableSelected;
        @AuraEnabled public String uniqueIdJS;
        @AuraEnabled public String indexVesselIdPortoIdDivision;
        @AuraEnabled public String pricebookEntryId;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String division;
        @AuraEnabled public String divisionId;
        @AuraEnabled public String dwtRange;
        @AuraEnabled public String leadId;
        @AuraEnabled public Decimal discount;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal priceWithDiscount; 
        @AuraEnabled public List<PrimaryServicesWrapper> primaryServices; 
        @AuraEnabled public List<String> primaryServicesSelected; 
        @AuraEnabled public List<SecondaryServicesWrapper> secondaryServices;
        @AuraEnabled public List<String> secondaryServicesSelected; 
        @AuraEnabled public List<RemarksWrapper> remarks;
        @AuraEnabled public List<String> remarksSelected;
        @AuraEnabled public String customNameRemark;
        @AuraEnabled public List<SecondaryServicesWrapper> draftSecondaryServicesValues;
        
    }
    
    public class PrimaryServicesWrapper { 
        @AuraEnabled public String pricebookEntryId;
        @AuraEnabled public String idServicePortIdDivisionId;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String family;
        @AuraEnabled public Boolean checked;
        @AuraEnabled public Decimal discount;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal priceWithDiscount; 
    }
    
    public class RemarksWrapper {
        @AuraEnabled public String idServicePortIdDivisionId;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String family;
        @AuraEnabled public String servicePrimaryName;
        @AuraEnabled public String servicePrimary;
        @AuraEnabled public String dwtRange;
        @AuraEnabled public String applicableStd;
        @AuraEnabled public Decimal value;
        @AuraEnabled public String operator;
        @AuraEnabled public Decimal factor;
        @AuraEnabled public String table;
        @AuraEnabled public String type;
        @AuraEnabled public String adjustment;
        @AuraEnabled public String idRemark;
        @AuraEnabled public Boolean checked;
    }
    
    public class SecondaryServicesWrapper {
        @AuraEnabled public String pricebookEntryId;
        @AuraEnabled public String idServicePortIdDivisionId;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String family;
        @AuraEnabled public Boolean checked;
        @AuraEnabled public Decimal discount;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal priceWithDiscount;
    }
    
    public class ResponseQuote
    {
        @AuraEnabled public Boolean hasError;
        @AuraEnabled public String mensagemError;
        @AuraEnabled public String mensagemSuccess;
    }
    
    public class ResponsePricebookQuote
    {
        @AuraEnabled public Boolean existPricebook;
        @AuraEnabled public String idPricebook;
        
    }
}