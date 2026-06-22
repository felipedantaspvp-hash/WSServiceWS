/**
 * DTOs used by the Account Case Schedule manager.
 */
public with sharing class AccountCaseScheduleDTO {
    public class OptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String developerName { get; set; }
    }

    public class ScheduleDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String unidadeNegocioLabel { get; set; }
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String recordTypeDeveloperName { get; set; }
        @AuraEnabled public String tipoCaso { get; set; }
        @AuraEnabled public String tipoCasoLabel { get; set; }
        @AuraEnabled public String categoria { get; set; }
        @AuraEnabled public String categoriaLabel { get; set; }
        @AuraEnabled public String assunto { get; set; }
        @AuraEnabled public String assuntoLabel { get; set; }
        @AuraEnabled public String subassunto { get; set; }
        @AuraEnabled public String subassuntoLabel { get; set; }
        @AuraEnabled public String frequencia { get; set; }
        @AuraEnabled public String frequenciaLabel { get; set; }
        @AuraEnabled public List<String> diasDaSemana { get; set; }
        @AuraEnabled public String horarioExecucao { get; set; }
        @AuraEnabled public Date dataInicio { get; set; }
        @AuraEnabled public Boolean pularFimDeSemana { get; set; }
        @AuraEnabled public String descricaoAtividade { get; set; }
        @AuraEnabled public String ownerType { get; set; }
        @AuraEnabled public String ownerTypeLabel { get; set; }
        @AuraEnabled public Id ownerUserId { get; set; }
        @AuraEnabled public String ownerUserName { get; set; }
        @AuraEnabled public String ownerQueueDeveloperName { get; set; }
        @AuraEnabled public String ownerDisplay { get; set; }
        @AuraEnabled public String ultimoErroExecucao { get; set; }
        @AuraEnabled public Datetime ultimaExecucao { get; set; }
        @AuraEnabled public Datetime proximaExecucao { get; set; }
    }

    public class InitialStateDTO {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public List<ScheduleDTO> schedules { get; set; }
        @AuraEnabled public CaseCreationDTO.InitialContextDTO caseContext { get; set; }
        @AuraEnabled public List<OptionDTO> frequenciaOptions { get; set; }
        @AuraEnabled public List<OptionDTO> diasDaSemanaOptions { get; set; }
        @AuraEnabled public List<OptionDTO> ownerTypeOptions { get; set; }
        @AuraEnabled public String agendamentoObjectApiName { get; set; }
    }

    public class IndicatorDTO {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Integer totalSchedules { get; set; }
        @AuraEnabled public Integer activeSchedules { get; set; }
        @AuraEnabled public Integer inactiveSchedules { get; set; }
    }

    public class SaveRequestDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
        @AuraEnabled public CaseCreationDTO.CategorizationRequestDTO categorization { get; set; }
        @AuraEnabled public String frequencia { get; set; }
        @AuraEnabled public List<String> diasDaSemana { get; set; }
        @AuraEnabled public String horarioExecucao { get; set; }
        @AuraEnabled public Date dataInicio { get; set; }
        @AuraEnabled public Boolean pularFimDeSemana { get; set; }
        @AuraEnabled public String descricaoAtividade { get; set; }
        @AuraEnabled public String ownerType { get; set; }
        @AuraEnabled public Id ownerUserId { get; set; }
        @AuraEnabled public String ownerQueueDeveloperName { get; set; }
    }
}