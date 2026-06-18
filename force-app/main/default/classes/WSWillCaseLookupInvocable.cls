public inherited sharing class WSWillCaseLookupInvocable {
    @InvocableMethod(label='WS Will - Consultar Caso')
    public static List<WSWillCaseLookupDTO.Response> lookup(List<WSWillCaseLookupDTO.Request> requests) {
        return WSWillCaseLookupService.lookup(requests);
    }
}