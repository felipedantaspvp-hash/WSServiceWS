public inherited sharing class CategorizacaoDTO {
    public class ErrorInfo {
        @AuraEnabled public String code;
        @AuraEnabled public String message;
    }

    public class RecordTypeOption {
        @AuraEnabled public Id recordTypeId;
        @AuraEnabled public String developerName;
        @AuraEnabled public String label;
    }

    public class PicklistOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
    }

    public class CasePicklistField {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public List<PicklistOption> values;
    }

    public class QueueOption {
        @AuraEnabled public Id id;
        @AuraEnabled public String developerName;
        @AuraEnabled public String name;
    }

    public class CategorizacaoView {
        @AuraEnabled public Id id;
        @AuraEnabled public Id recordTypeId;
        @AuraEnabled public String recordTypeDeveloperName;
        @AuraEnabled public String unidadeNegocio;
        @AuraEnabled public String tipoCaso;
        @AuraEnabled public String categoria;
        @AuraEnabled public String assunto;
        @AuraEnabled public String subassunto;
        @AuraEnabled public String prioridade;
        @AuraEnabled public Boolean ativo;
        @AuraEnabled public String descricao;
        @AuraEnabled public String motivoInativacao;
        @AuraEnabled public Boolean distribuirParaFila;
        @AuraEnabled public Boolean porCategorizacao;
        @AuraEnabled public String nomeFilaDistribuicao;
        @AuraEnabled public String filaDeveloperName;
        @AuraEnabled public String filaId;
        @AuraEnabled public String campoDistribuicao;
        @AuraEnabled public String labelCampoDistribuicao;
        @AuraEnabled public String valorDistribuicao;
        @AuraEnabled public String labelValorDistribuicao;
        @AuraEnabled public String chaveNatural;
        @AuraEnabled public String chaveNaturalHash;
    }

    public class RegraSLAView {
        @AuraEnabled public Id id;
        @AuraEnabled public String tipoAreaParticipante;
        @AuraEnabled public String areaAtendimento;
        @AuraEnabled public String origem;
        @AuraEnabled public String businessHoursName;
        @AuraEnabled public Boolean ativo;
    }

    public class InitialState {
        @AuraEnabled public CategorizacaoView registro;
        @AuraEnabled public List<RecordTypeOption> availableRecordTypes;
        @AuraEnabled public List<PicklistOption> tipoCasoOptions;
        @AuraEnabled public List<PicklistOption> categoriaOptions;
        @AuraEnabled public List<PicklistOption> assuntoOptions;
        @AuraEnabled public List<PicklistOption> subassuntoOptions;
        @AuraEnabled public List<PicklistOption> prioridadeOptions;
        @AuraEnabled public List<CasePicklistField> casePicklistFields;
        @AuraEnabled public List<QueueOption> queueOptions;
        @AuraEnabled public List<RegraSLAView> regrasSla;
        @AuraEnabled public List<PicklistOption> regraTipoAreaOptions;
        @AuraEnabled public List<PicklistOption> regraAreaAtendimentoOptions;
        @AuraEnabled public List<PicklistOption> regraOrigemOptions;
        @AuraEnabled public Boolean canViewTechnicalSummary;
    }

    public class RegraSLARequest {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String tipoAreaParticipante { get; set; }
        @AuraEnabled public String areaAtendimento { get; set; }
        @AuraEnabled public String origem { get; set; }
        @AuraEnabled public String businessHoursName { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
        @AuraEnabled public Boolean markedForDelete { get; set; }
    }

    public class Request {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id recordTypeId { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String tipoCaso { get; set; }
        @AuraEnabled public String categoria { get; set; }
        @AuraEnabled public String assunto { get; set; }
        @AuraEnabled public String subassunto { get; set; }
        @AuraEnabled public String prioridade { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
        @AuraEnabled public String descricao { get; set; }
        @AuraEnabled public String motivoInativacao { get; set; }
        @AuraEnabled public Boolean distribuirParaFila { get; set; }
        @AuraEnabled public Boolean porCategorizacao { get; set; }
        @AuraEnabled public String filaDeveloperName { get; set; }
        @AuraEnabled public String campoDistribuicao { get; set; }
        @AuraEnabled public String valorDistribuicao { get; set; }
        @AuraEnabled public List<RegraSLARequest> regrasSla { get; set; }
    }

    public class Response {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public CategorizacaoView registro;
        @AuraEnabled public ErrorInfo error;
    }
}