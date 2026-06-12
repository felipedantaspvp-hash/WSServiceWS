public inherited sharing class AreaParticipanteDTO {
    public class ErrorInfo {
        @AuraEnabled public String code { get; set; }
        @AuraEnabled public String message { get; set; }
    }

    public class PanelDTO {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String etapaAtendimento { get; set; }
        @AuraEnabled public String areasAtivasMultipicklist { get; set; }
        @AuraEnabled public Integer totalAbertas { get; set; }
        @AuraEnabled public Integer totalVencidas { get; set; }
        @AuraEnabled public Integer totalConcluidas { get; set; }
        @AuraEnabled public Datetime proximoPrazo { get; set; }
        @AuraEnabled public List<AreaItemDTO> items { get; set; }
        @AuraEnabled public Boolean canManage { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> areaOptions { get; set; }
        @AuraEnabled public List<String> warnings { get; set; }
        @AuraEnabled public ErrorInfo error { get; set; }
    }

    public class PicklistOptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    public class AreaItemDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String area { get; set; }
        @AuraEnabled public String areaLabel { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String statusLabel { get; set; }
        @AuraEnabled public Datetime dataHoraInicio { get; set; }
        @AuraEnabled public Datetime dataHoraPrazo { get; set; }
        @AuraEnabled public Datetime dataHoraFim { get; set; }
        @AuraEnabled public Decimal percentualDecorrido { get; set; }
        @AuraEnabled public String tempoTexto { get; set; }
        @AuraEnabled public String prazoTexto { get; set; }
        @AuraEnabled public Boolean isAberta { get; set; }
        @AuraEnabled public Boolean isVencida { get; set; }
        @AuraEnabled public Boolean isConcluida { get; set; }
        @AuraEnabled public Boolean isCancelada { get; set; }
        @AuraEnabled public Boolean violouSLA { get; set; }
        @AuraEnabled public String statusSLA { get; set; }
        @AuraEnabled public Decimal tempoSLAMinutos { get; set; }
        @AuraEnabled public Decimal tempoPausadoMinutos { get; set; }
        @AuraEnabled public Decimal tempoConsumidoMinutos { get; set; }
        @AuraEnabled public Decimal tempoRestanteMinutos { get; set; }
        @AuraEnabled public Decimal sequenciaAcionamento { get; set; }
        @AuraEnabled public String responsavelNome { get; set; }
        @AuraEnabled public String comentarioSolicitacao { get; set; }
        @AuraEnabled public String comentarioRetorno { get; set; }
        @AuraEnabled public String solucaoRetorno { get; set; }
        @AuraEnabled public String nomeMarco { get; set; }
        @AuraEnabled public String caseMilestoneId { get; set; }
        @AuraEnabled public Boolean canClose { get; set; }
        @AuraEnabled public Boolean canCancel { get; set; }
        @AuraEnabled public String cssClass { get; set; }
        @AuraEnabled public String progressClass { get; set; }
    }

    public class CloseRequestDTO {
        @AuraEnabled public Id areaParticipanteId { get; set; }
        @AuraEnabled public String comentarioRetorno { get; set; }
        @AuraEnabled public String solucaoRetorno { get; set; }
        @AuraEnabled public Boolean requerRetornoCliente { get; set; }
    }

    public class CloseResponseDTO {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String removedArea { get; set; }
        @AuraEnabled public String remainingAreas { get; set; }
        @AuraEnabled public Boolean etapaAtualizada { get; set; }
        @AuraEnabled public String novaEtapa { get; set; }
        @AuraEnabled public List<String> warnings { get; set; }
        @AuraEnabled public ErrorInfo error { get; set; }
    }

    public class DetailDTO {
        @AuraEnabled public AreaItemDTO item { get; set; }
        @AuraEnabled public List<String> warnings { get; set; }
    }

    public class AddRequestDTO {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String area { get; set; }
        @AuraEnabled public Datetime dataHoraPrazo { get; set; }
        @AuraEnabled public String comentarioSolicitacao { get; set; }
    }

    public class AddResponseDTO {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public Id areaParticipanteId { get; set; }
        @AuraEnabled public String updatedAreas { get; set; }
    }
}