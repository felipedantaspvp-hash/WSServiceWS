/**
 * @description LWC controller for sending WhatsApp messages from Contact records.
 * @author Triscal
 * @group Atendimento
 * @last modified on 06-25-2026
 * @last modified by Marllon Nascimento
 */
public with sharing class ContactWhatsappMessageController {
    @TestVisible private static Boolean forceUnexpectedErrorForTest = false;

    /**
     * @description Loads the Contact WhatsApp action context.
     * @param contactId Contact identifier.
     * @return Contact context and eligible Messaging User candidates.
     */
    @AuraEnabled(cacheable=true)
    public static ContactWhatsappMessageDTO getContext(Id contactId) {
        try {
            if (Test.isRunningTest() && forceUnexpectedErrorForTest == true) {
                throw new UnexpectedControllerException('Forced test exception.');
            }
            return ContactWhatsappMessageService.getContext(contactId);
        } catch (ContactWhatsappMessageService.FunctionalException ex) {
            ContactWhatsappMessageDTO dto = new ContactWhatsappMessageDTO();
            dto.contactId = contactId;
            dto.errorMessage = ex.getMessage();
            return dto;
        } catch (Exception ex) {
            ContactWhatsappMessageDTO dto = new ContactWhatsappMessageDTO();
            dto.contactId = contactId;
            dto.errorMessage = Label.ContactWhatsApp_ErrorUnexpected;
            return dto;
        }
    }

    private class UnexpectedControllerException extends Exception {}
}