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
        @AuraEnabled public Boolean usaTempoTriagem { get; set; }
        @AuraEnabled public Integer tempoTriagemMinutos { get; set; }
        @AuraEnabled public Boolean usaTempoRespostaChat { get; set; }
        @AuraEnabled public Integer tempoRespostaChatMinutos { get; set; }
        @AuraEnabled public Boolean usaTempoFilaEmail { get; set; }
        @AuraEnabled public Integer tempoFilaEmailMinutos { get; set; }
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
        @AuraEnabled public Boolean usaTempoTriagem { get; set; }
        @AuraEnabled public Integer tempoTriagemMinutos { get; set; }
        @AuraEnabled public Boolean usaTempoRespostaChat { get; set; }
        @AuraEnabled public Integer tempoRespostaChatMinutos { get; set; }
        @AuraEnabled public Boolean usaTempoFilaEmail { get; set; }
        @AuraEnabled public Integer tempoFilaEmailMinutos { get; set; }
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
        @AuraEnabled public Boolean usaTempoTriagem;
        @AuraEnabled public Decimal tempoTriagemMinutos;
        @AuraEnabled public Boolean usaTempoRespostaChat;
        @AuraEnabled public Decimal tempoRespostaChatMinutos;
        @AuraEnabled public Boolean usaTempoFilaEmail;
        @AuraEnabled public Decimal tempoFilaEmailMinutos;
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
        // Distribuição para fila (espelha Categorizacao__c, conforme especificação 6.3.4/6.3.9).
        @AuraEnabled public Boolean distribuirParaFila;
        @AuraEnabled public Boolean porCampoCustomizado;
        @AuraEnabled public String filaDeveloperName;
        @AuraEnabled public String nomeFilaDistribuicao;
        @AuraEnabled public String campoDistribuicao;
        @AuraEnabled public String valorDistribuicao;
        @AuraEnabled public String labelCampoDistribuicao;
        @AuraEnabled public String labelValorDistribuicao;
        @AuraEnabled public String filaDeveloperNameFallback;
        @AuraEnabled public String nomeFilaFallbackDistribuicao;
        @AuraEnabled public Boolean permiteAssumirComFilaParametrizada;
        @AuraEnabled public String etapaAtendimentoDistribuicao;
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
        // Distribuição para fila — preenchidos pelo modal de Categoria do gestaoSLAWorkspace.
        @AuraEnabled public Boolean distribuirParaFila { get; set; }
        @AuraEnabled public Boolean porCampoCustomizado { get; set; }
        @AuraEnabled public String filaDeveloperName { get; set; }
        @AuraEnabled public String campoDistribuicao { get; set; }
        @AuraEnabled public String valorDistribuicao { get; set; }
        @AuraEnabled public String filaDeveloperNameFallback { get; set; }
        @AuraEnabled public Boolean permiteAssumirComFilaParametrizada { get; set; }
        @AuraEnabled public String etapaAtendimentoDistribuicao { get; set; }
    }

    public class MarcoResumo {
        @AuraEnabled public Id id;
        @AuraEnabled public Id gestaoSLAId;
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
        @AuraEnabled public Decimal tempoFallbackMinutos;
        @AuraEnabled public Boolean ativo;
    }

    public class MarcoSLARequest {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id gestaoSLAId { get; set; }
        @AuraEnabled public String nomeMarco { get; set; }
        @AuraEnabled public String milestoneTypeName { get; set; }
        @AuraEnabled public String fonteTempo { get; set; }
        @AuraEnabled public Decimal ordem { get; set; }
        @AuraEnabled public Boolean recorrente { get; set; }
        @AuraEnabled public String tipoRecorrencia { get; set; }
        @AuraEnabled public Boolean usaCategorizacao { get; set; }
        @AuraEnabled public Boolean usaAreaInterna { get; set; }
        @AuraEnabled public Boolean usaOrigem { get; set; }
        @AuraEnabled public Decimal tempoFallbackMinutos { get; set; }
        @AuraEnabled public Boolean ativo { get; set; }
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
        // Unidades de Negócio que o usuário corrente pode ver, derivadas do Record Type de Case dele.
        // Null = acesso irrestrito (ex.: Admin Técnico). Lista com 1 item = tela deve auto-selecionar e ocultar o seletor manual.
        @AuraEnabled public List<String> unidadesDisponiveis;
        @AuraEnabled public String unidadeUnica;
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