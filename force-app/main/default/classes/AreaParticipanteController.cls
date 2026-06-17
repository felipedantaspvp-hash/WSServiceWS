/**
 * @description       : Controller Aura/LWC para operações de AreaParticipante__c. Expõe endpoints @AuraEnabled
 *                      para leitura, adição (unitária e bulk), encerramento, pausa e retomada de participações.
 *                      Toda lógica de negócio é delegada a AreaParticipanteService.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteController {
    @TestVisible static Exception testException;

    private static Boolean isEnglish() {
        String lang = UserInfo.getLanguage();
        return !String.isBlank(lang) && lang.toLowerCase().startsWith('en');
    }

    private static String msg(String pt, String en) {
        return isEnglish() ? en : pt;
    }

    /**
     * @description Retorna dados do painel de áreas participantes para um Case.
     *              Inclui lista de itens, opções de área disponíveis e permissões do usuário.
     * @param caseId Id do Case pai.
     * @return PanelDTO com itens, opções e metadados do painel.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.PanelDTO getPanelData(Id caseId) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.getPanelData(caseId);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao carregar áreas participantes.', 'Unexpected error while loading participant areas.'));
        }
    }

    /**
     * @description Versão sem cache de getPanelData. Aceita refreshToken para forçar recarga do painel pelo LWC.
     * @param caseId Id do Case pai.
     * @param refreshToken Token aleatório para contornar cache do wire.
     * @return PanelDTO atualizado com dados mais recentes.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.PanelDTO getPanelDataFresh(Id caseId, String refreshToken) {
        return getPanelData(caseId);
    }

    /**
     * @description Encerra a participação de uma área, registrando comentário e solução de retorno.
     *              Atualiza status, campos multipicklist e EtapaAtendimento__c do Case.
     * @param request CloseRequestDTO com id da área, comentário e solução de retorno.
     * @return CloseResponseDTO com sucesso, área removida e nova etapa de atendimento.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.CloseResponseDTO closeParticipation(AreaParticipanteDTO.CloseRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.closeParticipation(request);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao encerrar participação.', 'Unexpected error while closing participation.'));
        }
    }

    /**
     * @description Pausa o cronômetro de SLA de uma área participante, registrando DataHoraInicioPausa__c.
     * @param request PauseResumeRequestDTO com o id da área participante.
     * @return PauseResumeResponseDTO com novo status e horário de início de pausa.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.PauseResumeResponseDTO pauseParticipation(AreaParticipanteDTO.PauseResumeRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.pauseParticipation(request);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao pausar participação.', 'Unexpected error while pausing participation.'));
        }
    }

    /**
     * @description Retoma o cronômetro de SLA de uma área participante pausada, acumulando tempo de pausa.
     * @param request PauseResumeRequestDTO com o id da área participante.
     * @return PauseResumeResponseDTO com novo status e tempo pausado acumulado.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.PauseResumeResponseDTO resumeParticipation(AreaParticipanteDTO.PauseResumeRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.resumeParticipation(request);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao retomar participação.', 'Unexpected error while resuming participation.'));
        }
    }

    /**
     * @description Retorna detalhes completos de uma área participante específica para exibição no painel.
     * @param areaParticipanteId Id do registro AreaParticipante__c.
     * @return DetailDTO com todos os campos do item incluindo tempos de SLA calculados.
     **/
    @AuraEnabled(cacheable=true)
    public static AreaParticipanteDTO.DetailDTO getParticipationDetails(Id areaParticipanteId) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.getParticipationDetails(areaParticipanteId);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao carregar detalhes da participação.', 'Unexpected error while loading participation details.'));
        }
    }

    /**
     * @description Adiciona uma única área participante a um Case com comentário de solicitação.
     *              Valida permissões, unicidade e existência de regra de SLA antes de inserir.
     * @param request AddRequestDTO com caseId, área e comentário de solicitação.
     * @return AddResponseDTO com id do novo registro e campos multipicklist atualizados.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.AddResponseDTO addParticipation(AreaParticipanteDTO.AddRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.addParticipation(request);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao adicionar participação.', 'Unexpected error while adding participation.'));
        }
    }

    /**
     * @description Adiciona múltiplas áreas participantes a um Case em uma única operação,
     *              cada uma com seu próprio comentário de solicitação. Delega para AreaParticipanteService.
     * @param request AddBulkRequestDTO contendo caseId e lista de itens (área + comentário).
     * @return AddBulkResponseDTO com sucesso, contagem e mensagem.
     **/
    @AuraEnabled
    public static AreaParticipanteDTO.AddBulkResponseDTO addParticipationBulk(AreaParticipanteDTO.AddBulkRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return AreaParticipanteService.addParticipationBulk(request);
        } catch (AreaParticipanteService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(msg('Erro inesperado ao adicionar participações.', 'Unexpected error while adding participations.'));
        }
    }
}
