/**
 * @description       : Classe de suporte para o módulo WSWill.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseCreationInvocable {
    @InvocableMethod(label='WS Will - Criar Caso')
    public static List<WSWillCaseCreationDTO.Response> createCases(List<WSWillCaseCreationDTO.Request> requests) {
        return WSWillCaseCreationService.createCases(requests);
    }
}