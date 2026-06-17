/**
 * @description       : DTOs de transferência de dados para o módulo CaseRecategorization. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : Case Recategorização
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseRecategorizationDTO {
    public class ErrorInfo {
        @AuraEnabled public String code { get; set; }
        @AuraEnabled public String message { get; set; }
    }

    public class PicklistOptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    public class CaseRecategorizationContextDTO {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String recordTypeDeveloperName { get; set; }
        @AuraEnabled public String recordTypeLabel { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String currentTipoCaso { get; set; }
        @AuraEnabled public String currentTipoCasoLabel { get; set; }
        @AuraEnabled public String currentCategoria { get; set; }
        @AuraEnabled public String currentCategoriaLabel { get; set; }
        @AuraEnabled public String currentAssunto { get; set; }
        @AuraEnabled public String currentAssuntoLabel { get; set; }
        @AuraEnabled public String currentSubassunto { get; set; }
        @AuraEnabled public String currentSubassuntoLabel { get; set; }
        @AuraEnabled public Boolean canRecategorize { get; set; }
        @AuraEnabled public String blockedReason { get; set; }
    }

    public class TreeRequestDTO {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String recordTypeDeveloperName { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String selectedTipoCaso { get; set; }
        @AuraEnabled public String selectedCategoria { get; set; }
        @AuraEnabled public String selectedAssunto { get; set; }
        @AuraEnabled public String selectedSubassunto { get; set; }
    }

    public class TreeOptionsDTO {
        @AuraEnabled public List<PicklistOptionDTO> tipoCasoOptions { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> categoriaOptions { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> assuntoOptions { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> subassuntoOptions { get; set; }
    }

    public class RecategorizationRequestDTO {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String tipoCaso { get; set; }
        @AuraEnabled public String categoria { get; set; }
        @AuraEnabled public String assunto { get; set; }
        @AuraEnabled public String subassunto { get; set; }
        @AuraEnabled public String destinationAction { get; set; }
        @AuraEnabled public String selectedQueueDeveloperName { get; set; }
    }

    public class RecategorizationResponseDTO {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<String> warnings { get; set; }
        @AuraEnabled public ErrorInfo error { get; set; }
    }
}