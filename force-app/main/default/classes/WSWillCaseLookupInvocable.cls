/**
 * @description       : Classe de suporte para o módulo WSWill.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseLookupInvocable {
    @InvocableMethod(label='WS Will - Consultar Caso')
    public static List<WSWillCaseLookupDTO.Response> lookup(List<WSWillCaseLookupDTO.Request> requests) {
        return WSWillCaseLookupService.lookup(requests);
    }
}