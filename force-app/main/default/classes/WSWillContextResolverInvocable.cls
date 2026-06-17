/**
 * @description       : Classe de suporte para o módulo WSWill.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillContextResolverInvocable {
    @InvocableMethod(label='WS Will - Resolver Contexto Inicial')
    public static List<WSWillContextResolverDTO.Response> resolve(List<WSWillContextResolverDTO.Request> requests) {
        try {
            return WSWillContextResolverService.resolve(requests);
        } catch (Exception ex) {
            WSWillContextResolverDTO.Response fallback = new WSWillContextResolverDTO.Response();
            fallback.success = false;
            fallback.statusCode = ex.getTypeName();
            fallback.message = ex.getMessage();
            fallback.shouldAskLanguage = true;
            fallback.businessUnitSource = 'UNRESOLVED';
            return new List<WSWillContextResolverDTO.Response>{ fallback };
        }
    }
}