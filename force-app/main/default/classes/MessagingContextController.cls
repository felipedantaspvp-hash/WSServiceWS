/**
 * @description       : Invocable para resolver contexto de canais digitais para Flow/Bot/Omni.
 * @author            : Triscal
 * @group             : Messaging
 * @last modified on  : 05-27-2026
 * @last modified by  : Codex
 **/
public inherited sharing class MessagingContextController {
    @InvocableMethod(label='Resolve Messaging Context')
    public static List<MessagingContextDTO.Response> resolve(List<MessagingContextDTO.Request> requests) {
        try {
            return MessagingContextService.resolve(requests);
        } catch (Exception ex) {
            MessagingContextDTO.Response out = new MessagingContextDTO.Response();
            out.success = false;
            out.requiresCustomerIdentification = true;
            out.fallbackReason = 'Erro inesperado ao resolver contexto de messaging.';
            return new List<MessagingContextDTO.Response>{ out };
        }
    }
}