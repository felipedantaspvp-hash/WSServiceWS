/**
 * @author            : Luis Coêlho
 * @last modified on  : 04-17-2025
 * @last modified by  : Luis Coêlho
**/
public without sharing class AssociateLeadToQuoteController {
    @AuraEnabled
    public static List<Lead> getLineupLeads(String id){
        try{
            Quote quote = [SELECT Id,OpportunityId FROM Quote WHERE Id IN(SELECT QuoteId FROM QuoteLineItem WHERE Id =: id) LIMIT 1];
            //Opportunity opp = [SELECT Id FROM Opportunity WHERE Id =:quote.OpportunityId LIMIT 1];

            List<QuoteLineItem> qlis = [SELECT Lineup_Id__c FROM QuoteLineItem WHERE Lineup_Id__c != null LIMIT 50000];

            Set<String> lineups = new Set<String>();
            for(QuoteLineItem qli : qlis) {
                lineups.add(qli.Lineup_Id__c);
            }

            List<Lead> leadList = [SELECT Id, LINEUP_DSC_NAVIO_CARGA__c, LINEUP_DSC_PORTO_CARGA__c, LINEUP_DSC_DWT_CARGA__c, Service__c  FROM Lead WHERE ConvertedOpportunityId =: quote.OpportunityId AND Id NOT IN: lineups];

            return leadList;    
        } catch (Exception e) { 
            return null;
        }
    }

    @AuraEnabled
    public static string updateQuoteLineItem(String id, String lineUpLeadId){
        try {
            QuoteLineItem quote = new QuoteLineItem(Id = id, Lineup_Id__c = lineUpLeadId, TCF_Lead__c = lineUpLeadId);
            update quote;
            return null;
        } catch (Exception e) {
            return e.getMessage();
        }
    }
}