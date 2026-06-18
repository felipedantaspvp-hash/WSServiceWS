public inherited sharing class WSWillCaseCreationInvocable {
    @InvocableMethod(label='WS Will - Criar Caso')
    public static List<WSWillCaseCreationDTO.Response> createCases(List<WSWillCaseCreationDTO.Request> requests) {
        return WSWillCaseCreationService.createCases(requests);
    }
}