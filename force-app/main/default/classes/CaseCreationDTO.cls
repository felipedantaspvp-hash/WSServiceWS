/**
 * @description       : DTOs de transferência de dados para o módulo CaseCreation. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : Case Creation
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseCreationDTO {
    public class ErrorInfo {
        @AuraEnabled public String code { get; set; }
        @AuraEnabled public String message { get; set; }
    }

    public class RecordTypeOptionDTO {
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public Boolean isDefault { get; set; }
    }

    public class PicklistOptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    public class QueueOptionDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String readonlyReason { get; set; }
    }

    public class InitialContextDTO {
        @AuraEnabled public Id userId { get; set; }
        @AuraEnabled public String userName { get; set; }
        @AuraEnabled public Id defaultRecordTypeId { get; set; }
        @AuraEnabled public String unidadeNegocioDefault { get; set; }
        @AuraEnabled public List<RecordTypeOptionDTO> recordTypes { get; set; }
    }

    public class TreeOptionsDTO {
        @AuraEnabled public List<PicklistOptionDTO> tipoCasoOptions { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> categoriaOptions { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> assuntoOptions { get; set; }
        @AuraEnabled public List<PicklistOptionDTO> subassuntoOptions { get; set; }
    }

    public class CategorizationRequestDTO {
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String recordTypeDeveloperName { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String tipoCaso { get; set; }
        @AuraEnabled public String categoria { get; set; }
        @AuraEnabled public String assunto { get; set; }
        @AuraEnabled public String subassunto { get; set; }
    }

    public class DestinationRequestDTO {
        @AuraEnabled public String action { get; set; }
        @AuraEnabled public String selectedQueueDeveloperName { get; set; }
        @AuraEnabled public Id selectedQueueId { get; set; }
    }

    public class BuildDefaultValuesRequestDTO {
        @AuraEnabled public CategorizationRequestDTO categorization { get; set; }
        @AuraEnabled public DestinationRequestDTO destination { get; set; }
        @AuraEnabled public Map<String, String> originalDefaults { get; set; }
        @AuraEnabled public Map<String, String> sourceContext { get; set; }
    }

    public class ResolveSelectionResponseDTO {
        @AuraEnabled public Boolean hasParametrizedQueue { get; set; }
        @AuraEnabled public Boolean queueReadOnly { get; set; }
        @AuraEnabled public QueueOptionDTO queue { get; set; }
        @AuraEnabled public String message { get; set; }
    }

    public class BuildDefaultValuesResponseDTO {
        @AuraEnabled public Map<String, String> defaultValues { get; set; }
        @AuraEnabled public List<String> warnings { get; set; }
        @AuraEnabled public List<String> errors { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public ErrorInfo error { get; set; }
    }
}