/**
 * @description DTO used by the Contact WhatsApp quick action.
 * @author Triscal
 * @group Atendimento
 * @last modified on 06-25-2026
 * @last modified by Marllon Nascimento
 */
public inherited sharing class ContactWhatsappMessageDTO {
    @AuraEnabled public Id contactId { get; set; }
    @AuraEnabled public String contactName { get; set; }
    @AuraEnabled public Boolean hasCandidates { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
    @AuraEnabled public List<Candidate> candidates { get; set; }

    public ContactWhatsappMessageDTO() {
        this.hasCandidates = false;
        this.candidates = new List<Candidate>();
    }

    /**
     * @description One eligible Messaging User option for the Contact.
     */
    public class Candidate {
        @AuraEnabled public Id messagingEndUserId { get; set; }
        @AuraEnabled public String messagingEndUserName { get; set; }
        @AuraEnabled public Id messagingChannelId { get; set; }
        @AuraEnabled public String messagingChannelName { get; set; }
        @AuraEnabled public String messagingChannelDeveloperName { get; set; }
        @AuraEnabled public String messagingPlatformKey { get; set; }
        @AuraEnabled public String messagingConsentStatus { get; set; }
        @AuraEnabled public Datetime lastModifiedDate { get; set; }
        @AuraEnabled public Boolean recommended { get; set; }
    }
}