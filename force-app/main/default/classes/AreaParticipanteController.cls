public inherited sharing class AreaParticipanteController {
    @TestVisible static Exception testException;

    private static Boolean isEnglish() {
        String lang = UserInfo.getLanguage();
        return !String.isBlank(lang) && lang.toLowerCase().startsWith('en');
    }

    private static String msg(String pt, String en) {
        return isEnglish() ? en : pt;
    }

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

    @AuraEnabled
    public static AreaParticipanteDTO.PanelDTO getPanelDataFresh(Id caseId, String refreshToken) {
        return getPanelData(caseId);
    }

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
}