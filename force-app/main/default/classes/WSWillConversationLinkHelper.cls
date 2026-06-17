/**
 * @description       : Funções utilitárias e helpers para o módulo WSWillConversationLink.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillConversationLinkHelper {
    public static String inferObjectApiName(Id recordId) {
        return AtendimentoContextResolverHelper.inferSObjectApiName(recordId);
    }
}