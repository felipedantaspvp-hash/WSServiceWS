/**
 * @description       : Invocable de resolução de contexto inicial de atendimento para Bot/Flow.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 05-27-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AtendimentoContextResolverInvocable {
    /**
     * @description Resolve contexto inicial para cada request recebido pelo Flow.
     * @param requests Lista de entradas vindas do Flow/Bot.
     * @return List<AtendimentoContextResolverDTO.Response> Resultado por request.
     **/
    @InvocableMethod(label='Resolver Contexto Inicial de Atendimento')
    public static List<AtendimentoContextResolverDTO.Response> resolve(List<AtendimentoContextResolverDTO.Request> requests) {
        try {
            return AtendimentoContextResolverService.resolve(requests);
        } catch (Exception ex) {
            AtendimentoContextResolverDTO.Response fallback = new AtendimentoContextResolverDTO.Response();
            fallback.success = false;
            fallback.statusCode = 'UNEXPECTED_ERROR';
            fallback.message = 'Erro inesperado ao resolver o contexto inicial.';
            fallback.needsCustomerInput = true;
            fallback.nextAction = 'TRANSFER_TO_SPECIALIST';
            fallback.missingInformation = 'Contact,BusinessUnit';
            fallback.channelName = 'Unknown';
            return new List<AtendimentoContextResolverDTO.Response>{ fallback };
        }
    }
}