public inherited sharing class WSWillConversationLinkInvocable {
    @InvocableMethod(label='WS Will - Vincular Case à Conversa')
    public static List<WSWillConversationLinkDTO.Response> link(List<WSWillConversationLinkDTO.Request> requests) {
        try {
            return WSWillConversationLinkService.link(requests);
        } catch (Exception ex) {
            WSWillConversationLinkDTO.Response fallback = new WSWillConversationLinkDTO.Response();
            fallback.success = false;
            fallback.statusCode = 'UNEXPECTED_ERROR';
            fallback.message = 'Erro inesperado ao vincular caso à conversa.';
            return new List<WSWillConversationLinkDTO.Response>{ fallback };
        }
    }
}