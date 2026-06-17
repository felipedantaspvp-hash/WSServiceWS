/**
 * @description       : DTOs de transferência de dados para o módulo GestaoSLA. Contém classes de request/response para operações do módulo.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class GestaoSLADTO {
    public class CreateGestaoRequest {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String entitlementProcessName { get; set; }
        @AuraEnabled public String businessHoursName { get; set; }
        @AuraEnabled public Integer tempoTriagemMinutos { get; set; }
        @AuraEnabled public Integer tempoRespostaChatMinutos { get; set; }
        @AuraEnabled public String descricao { get; set; }
        @AuraEnabled public String staticResourceName { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
    }

    public class UpdateGestaoRequest {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String unidadeNegocio { get; set; }
        @AuraEnabled public String entitlementProcessName { get; set; }
        @AuraEnabled public String businessHoursName { get; set; }
        @AuraEnabled public Integer tempoTriagemMinutos { get; set; }
        @AuraEnabled public Integer tempoRespostaChatMinutos { get; set; }
        @AuraEnabled public String descricao { get; set; }
        @AuraEnabled public String staticResourceName { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
    }

    public class PermissionInfo {
        @AuraEnabled public Boolean canAccessGestaoSLA;
        @AuraEnabled public Boolean canManageCategories;
        @AuraEnabled public Boolean canManageRules;
        @AuraEnabled public Boolean canAdminTechnicalSettings;
    }

    public class SummaryInfo {
        @AuraEnabled public Integer totalCategorias;
        @AuraEnabled public Integer totalMarcosAtivos;
        @AuraEnabled public Integer totalRegrasAtivas;
        @AuraEnabled public Integer totalAreasInternas;
    }

    public class GestaoResumo {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String unidadeNegocio;
        @AuraEnabled public Boolean ativo;
        @AuraEnabled public String descricao;
        @AuraEnabled public Decimal tempoTriagemMinutos;
        @AuraEnabled public Decimal tempoRespostaChatMinutos;
        @AuraEnabled public String staticResourceName;
        @AuraEnabled public String entitlementProcessName;
        @AuraEnabled public String businessHoursName;
    }

    public class CategoriaResumo {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String unidadeNegocio;
        @AuraEnabled public String tipoCaso;
        @AuraEnabled public String categoria;
        @AuraEnabled public String assunto;
        @AuraEnabled public String subassunto;
        @AuraEnabled public String prioridadeSugerida;
        @AuraEnabled public Boolean ativo;
        @AuraEnabled public Integer totalRegrasAtivas;
    }

    public class CategoriaRequest {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id gestaoSLAId { get; set; }
        @AuraEnabled public String tipoCaso { get; set; }
        @AuraEnabled public String categoria { get; set; }
        @AuraEnabled public String assunto { get; set; }
        @AuraEnabled public String subassunto { get; set; }
        @AuraEnabled public String prioridadeSugerida { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
    }

    public class MarcoResumo {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String nomeMarco;
        @AuraEnabled public String milestoneTypeName;
        @AuraEnabled public String fonteTempo;
        @AuraEnabled public Decimal ordem;
        @AuraEnabled public Boolean recorrente;
        @AuraEnabled public String tipoRecorrencia;
        @AuraEnabled public Boolean usaCategorizacao;
        @AuraEnabled public Boolean usaAreaInterna;
        @AuraEnabled public Boolean usaOrigem;
        @AuraEnabled public Boolean ativo;
    }

    public class RegraSLAResumo {
        @AuraEnabled public Id id;
        @AuraEnabled public Id gestaoSLAId;
        @AuraEnabled public Id categorizacaoId;
        @AuraEnabled public String categorizacaoNome;
        @AuraEnabled public Id marcoSLAId;
        @AuraEnabled public String marcoNome;
        @AuraEnabled public String escopoRegra;
        @AuraEnabled public String areaAtendimento;
        @AuraEnabled public Integer tempoBaixa;
        @AuraEnabled public Integer tempoMedia;
        @AuraEnabled public Integer tempoAlta;
        @AuraEnabled public Boolean ativo;
    }

    public class RegraSLARequest {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id gestaoSLAId { get; set; }
        @AuraEnabled public Id categorizacaoId { get; set; }
        @AuraEnabled public Id marcoSLAId { get; set; }
        @AuraEnabled public String escopoRegra { get; set; }
        @AuraEnabled public String areaAtendimento { get; set; }
        @AuraEnabled public Integer tempoBaixa { get; set; }
        @AuraEnabled public Integer tempoMedia { get; set; }
        @AuraEnabled public Integer tempoAlta { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
    }

    public class PicklistOptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    public class BootstrapResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public List<GestaoResumo> gestoes;
        @AuraEnabled public List<PicklistOptionDTO> unidadeNegocioOptions;
        @AuraEnabled public List<PicklistOptionDTO> tipoCasoOptions;
        @AuraEnabled public List<PicklistOptionDTO> categoriaPicklistOptions;
        @AuraEnabled public List<PicklistOptionDTO> assuntoOptions;
        @AuraEnabled public List<PicklistOptionDTO> subassuntoOptions;
    }

    public class GestaoDetailResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public GestaoResumo gestao;
        @AuraEnabled public SummaryInfo summary;
    }

    public class CategoriasResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public List<CategoriaResumo> categorias;
    }

    public class MarcosResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public List<MarcoResumo> marcos;
    }

    public class RegrasSLAResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public List<RegraSLAResumo> regras;
    }

    public class InactiveGestoesResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public List<GestaoResumo> gestoesInativas;
    }

    public class InactiveCategoriasResponse {
        @AuraEnabled public PermissionInfo permissions;
        @AuraEnabled public List<CategoriaResumo> categoriasInativas;
    }
}