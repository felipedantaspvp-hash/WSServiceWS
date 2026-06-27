/**
 * @description Finds WhatsApp Messaging Users linked to a Contact for the Contact quick action.
 * @author Triscal
 * @group Atendimento
 * @last modified on 06-25-2026
 * @last modified by Marllon Nascimento
 */
public with sharing class ContactWhatsappMessageService {
    private static final String MESSAGE_TYPE_WHATSAPP = 'WhatsApp';
    private static final String CONSENT_OPTED_OUT = 'OptedOut';
    private static final Integer MAX_CANDIDATES = 20;

    @TestVisible private static List<ContactWhatsappMessageDTO.Candidate> candidatesForTest;

    /**
     * @description Loads eligible WhatsApp Messaging Users for a Contact.
     * @param contactId Contact identifier.
     * @return Contact context and eligible WhatsApp candidates.
     * @throws FunctionalException when the Contact id is missing or inaccessible.
     */
    public static ContactWhatsappMessageDTO getContext(Id contactId) {
        if (contactId == null) {
            throw new FunctionalException(Label.ContactWhatsApp_ErrorContactRequired);
        }

        Contact contactRecord = getContact(contactId);
        ContactWhatsappMessageDTO dto = new ContactWhatsappMessageDTO();
        dto.contactId = contactRecord.Id;
        dto.contactName = contactRecord.Name;
        dto.candidates = Test.isRunningTest() && candidatesForTest != null
            ? candidatesForTest
            : getCandidates(contactId);
        dto.hasCandidates = !dto.candidates.isEmpty();
        return dto;
    }

    private static Contact getContact(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, Name
            FROM Contact
            WHERE Id = :contactId
            WITH USER_MODE
            LIMIT 1
        ];
        if (contacts.isEmpty()) {
            throw new FunctionalException(Label.ContactWhatsApp_ErrorContactNotFound);
        }
        return contacts[0];
    }

    private static List<ContactWhatsappMessageDTO.Candidate> getCandidates(Id contactId) {
        Set<String> allowedChannelDeveloperNames = getAllowedWhatsAppChannelDeveloperNames();
        if (allowedChannelDeveloperNames.isEmpty()) {
            return new List<ContactWhatsappMessageDTO.Candidate>();
        }

        List<ContactWhatsappMessageDTO.Candidate> candidates = new List<ContactWhatsappMessageDTO.Candidate>();
        for (MessagingEndUser endUser : [
            SELECT Id,
                   Name,
                   MessagingChannelId,
                   MessagingChannel.DeveloperName,
                   MessagingChannel.MasterLabel,
                   MessagingPlatformKey,
                   MessagingConsentStatus,
                   IsFullyOptedIn,
                   LastModifiedDate
            FROM MessagingEndUser
            WHERE ContactId = :contactId
              AND MessagingChannel.MessageType = :MESSAGE_TYPE_WHATSAPP
              AND MessagingChannel.DeveloperName IN :allowedChannelDeveloperNames
              AND MessagingConsentStatus != :CONSENT_OPTED_OUT
              AND MessagingPlatformKey != null
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT :MAX_CANDIDATES
        ]) {
            if (endUser.IsFullyOptedIn != true) {
                continue;
            }
            candidates.add(toCandidate(endUser, candidates.isEmpty()));
        }
        return candidates;
    }

    private static Set<String> getAllowedWhatsAppChannelDeveloperNames() {
        Set<String> allowedBusinessUnits = GestaoSLAHelper.getAllowedUnidadesNegocio();
        Set<String> channelDeveloperNames = new Set<String>();
        for (AtendimentoConfigDTO config : AtendimentoConfigService.getActiveConfigs()) {
            if (config == null || String.isBlank(config.whatsAppChannelDeveloperName)) {
                continue;
            }
            if (allowedBusinessUnits != null && !allowedBusinessUnits.contains(config.businessUnit)) {
                continue;
            }
            channelDeveloperNames.add(config.whatsAppChannelDeveloperName);
        }
        return channelDeveloperNames;
    }

    private static ContactWhatsappMessageDTO.Candidate toCandidate(MessagingEndUser endUser, Boolean recommended) {
        ContactWhatsappMessageDTO.Candidate candidate = new ContactWhatsappMessageDTO.Candidate();
        candidate.messagingEndUserId = endUser.Id;
        candidate.messagingEndUserName = endUser.Name;
        candidate.messagingChannelId = endUser.MessagingChannelId;
        candidate.messagingChannelDeveloperName = endUser.MessagingChannel.DeveloperName;
        candidate.messagingChannelName = endUser.MessagingChannel.MasterLabel;
        candidate.messagingPlatformKey = endUser.MessagingPlatformKey;
        candidate.messagingConsentStatus = endUser.MessagingConsentStatus;
        candidate.lastModifiedDate = endUser.LastModifiedDate;
        candidate.recommended = recommended;
        return candidate;
    }

    /**
     * @description Functional exception with a user-facing localized message.
     */
    public class FunctionalException extends Exception {}
}