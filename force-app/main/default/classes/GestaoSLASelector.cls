/**
 * @description       : Selector de queries SOQL para o módulo Gestão de SLA. Centraliza todos os acessos a GestaoSLA__c, Categorizacao__c, MarcoSLA__c e RegrasSLACategorizacao__c.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-22-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class GestaoSLASelector {

    // ─── GestaoSLA__c ────────────────────────────────────────────────────────

    /**
     * @description Retorna todas as Gestões de SLA ativas ordenadas por nome.
     * @return Lista de GestaoSLA__c ativas.
     **/
    public static List<GestaoSLA__c> selectActive() {
        return [
            SELECT Id, Name, UnidadeNegocio__c, EntitlementProcessName__c, BusinessHoursName__c,
                   TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, TempoFilaEmailMinutos__c,
                   UsaTempoTriagem__c, UsaTempoRespostaChat__c, UsaTempoFilaEmail__c, StaticResourceName__c,
                   Ativo__c, Descricao__c
            FROM GestaoSLA__c
            WHERE Ativo__c = true
            ORDER BY Name
        ];
    }

    /**
     * @description Retorna as Gestões de SLA ativas restritas a um conjunto de Unidades de Negócio.
     * @param unidades Conjunto de valores de UnidadeNegocio__c permitidos.
     * @return Lista de GestaoSLA__c ativas dentro das unidades informadas.
     **/
    public static List<GestaoSLA__c> selectActiveByUnidades(Set<String> unidades) {
        return [
            SELECT Id, Name, UnidadeNegocio__c, EntitlementProcessName__c, BusinessHoursName__c,
                   TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, TempoFilaEmailMinutos__c,
                   UsaTempoTriagem__c, UsaTempoRespostaChat__c, UsaTempoFilaEmail__c, StaticResourceName__c,
                   Ativo__c, Descricao__c
            FROM GestaoSLA__c
            WHERE Ativo__c = true AND UnidadeNegocio__c IN :unidades
            ORDER BY Name
        ];
    }

    /**
     * @description Retorna todas as Gestões de SLA inativas ordenadas por nome.
     * @return Lista de GestaoSLA__c inativas.
     **/
    public static List<GestaoSLA__c> selectInactive() {
        return [
            SELECT Id, Name, UnidadeNegocio__c, EntitlementProcessName__c, BusinessHoursName__c,
                   TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, TempoFilaEmailMinutos__c,
                   UsaTempoTriagem__c, UsaTempoRespostaChat__c, UsaTempoFilaEmail__c, StaticResourceName__c,
                   Ativo__c, Descricao__c
            FROM GestaoSLA__c
            WHERE Ativo__c = false
            ORDER BY Name
        ];
    }

    /**
     * @description Retorna uma Gestão de SLA pelo Id com todos os campos de detalhe.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista com zero ou um registro GestaoSLA__c.
     **/
    public static List<GestaoSLA__c> selectById(Id gestaoSLAId) {
        return [
            SELECT Id, Name, UnidadeNegocio__c, EntitlementProcessName__c, BusinessHoursName__c,
                   TempoTriagemMinutos__c, TempoRespostaChatMinutos__c, TempoFilaEmailMinutos__c,
                   UsaTempoTriagem__c, UsaTempoRespostaChat__c, UsaTempoFilaEmail__c, StaticResourceName__c,
                   Ativo__c, Descricao__c
            FROM GestaoSLA__c
            WHERE Id = :gestaoSLAId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna apenas o Id da Gestão de SLA, para checagem de existência.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista com zero ou um registro (somente Id).
     **/
    public static List<GestaoSLA__c> selectGestaoIdById(Id gestaoSLAId) {
        return [SELECT Id FROM GestaoSLA__c WHERE Id = :gestaoSLAId LIMIT 1];
    }

    /**
     * @description Retorna os campos necessários para reativação/duplicidade de uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista com zero ou um registro (Id, Ativo__c, UnidadeNegocio__c, EntitlementProcessName__c).
     **/
    public static List<GestaoSLA__c> selectActivationFieldsById(Id gestaoSLAId) {
        return [
            SELECT Id, Ativo__c, UnidadeNegocio__c, EntitlementProcessName__c
            FROM GestaoSLA__c
            WHERE Id = :gestaoSLAId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna os campos editáveis pela tela de edição de Gestão de SLA (sem os tempos em minutos).
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista com zero ou um registro.
     **/
    public static List<GestaoSLA__c> selectEditableFieldsById(Id gestaoSLAId) {
        return [
            SELECT Id, Name, UnidadeNegocio__c, EntitlementProcessName__c, BusinessHoursName__c,
                   Descricao__c, StaticResourceName__c, Ativo__c,
                   UsaTempoTriagem__c, UsaTempoRespostaChat__c, UsaTempoFilaEmail__c
            FROM GestaoSLA__c
            WHERE Id = :gestaoSLAId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna somente a Unidade de Negócio de uma Gestão de SLA, para validação de referência.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista com zero ou um registro (Id, UnidadeNegocio__c).
     **/
    public static List<GestaoSLA__c> selectUnidadeById(Id gestaoSLAId) {
        return [SELECT Id, UnidadeNegocio__c FROM GestaoSLA__c WHERE Id = :gestaoSLAId LIMIT 1];
    }

    /**
     * @description Conta Gestões de SLA ativas com a mesma Unidade de Negócio.
     * @param unidade Valor de UnidadeNegocio__c a verificar.
     * @return Número de gestões ativas com a mesma unidade de negócio.
     **/
    public static Integer countActiveByUnidadeNegocio(String unidade) {
        return [
            SELECT Count()
            FROM GestaoSLA__c
            WHERE Ativo__c = true
              AND UnidadeNegocio__c = :unidade
        ];
    }

    /**
     * @description Conta Gestões de SLA ativas com a mesma Unidade de Negócio, excluindo um registro.
     * @param unidade Valor de UnidadeNegocio__c a verificar.
     * @param excludeId Id a excluir da contagem.
     * @return Número de gestões ativas com a mesma unidade de negócio.
     **/
    public static Integer countActiveByUnidadeNegocioExcluding(String unidade, Id excludeId) {
        return [
            SELECT Count()
            FROM GestaoSLA__c
            WHERE Ativo__c = true
              AND UnidadeNegocio__c = :unidade
              AND Id != :excludeId
        ];
    }

    /**
     * @description Conta Gestões de SLA ativas com o mesmo Entitlement Process.
     * @param entitlementProcess Valor de EntitlementProcessName__c a verificar.
     * @return Número de gestões ativas com o mesmo entitlement process.
     **/
    public static Integer countActiveByEntitlementProcess(String entitlementProcess) {
        return [
            SELECT Count()
            FROM GestaoSLA__c
            WHERE Ativo__c = true
              AND EntitlementProcessName__c = :entitlementProcess
        ];
    }

    /**
     * @description Conta Gestões de SLA ativas com o mesmo Entitlement Process, excluindo um registro.
     * @param entitlementProcess Valor de EntitlementProcessName__c a verificar.
     * @param excludeId Id a excluir da contagem.
     * @return Número de gestões ativas com o mesmo entitlement process.
     **/
    public static Integer countActiveByEntitlementProcessExcluding(String entitlementProcess, Id excludeId) {
        return [
            SELECT Count()
            FROM GestaoSLA__c
            WHERE Ativo__c = true
              AND EntitlementProcessName__c = :entitlementProcess
              AND Id != :excludeId
        ];
    }

    // ─── Categorizacao__c ────────────────────────────────────────────────────

    /**
     * @description Retorna todas as categorizações de uma Gestão de SLA ordenadas por nome, com campos de distribuição.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de Categorizacao__c.
     **/
    public static List<Categorizacao__c> selectCategoriasByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT Id, Name, GestaoSLA__c, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c,
                   Subassunto__c, Prioridade__c, Ativo__c, DistribuirParaFila__c, PorCampoCustomizado__c,
                   FilaDeveloperName__c, NomeFilaDistribuicao__c, CampoDistribuicao__c, ValorDistribuicao__c,
                   LabelCampoDistribuicao__c, LabelValorDistribuicao__c
            FROM Categorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
            ORDER BY Name
        ];
    }

    /**
     * @description Retorna as categorizações inativas de uma Gestão de SLA ordenadas por classificação, com campos de distribuição.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de Categorizacao__c inativas.
     **/
    public static List<Categorizacao__c> selectInactiveCategoriasByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT Id, Name, GestaoSLA__c, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c,
                   Subassunto__c, Prioridade__c, Ativo__c, DistribuirParaFila__c, PorCampoCustomizado__c,
                   FilaDeveloperName__c, NomeFilaDistribuicao__c, CampoDistribuicao__c, ValorDistribuicao__c,
                   LabelCampoDistribuicao__c, LabelValorDistribuicao__c
            FROM Categorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND Ativo__c = false
            ORDER BY TipoCaso__c, Categoria__c, Assunto__c, Subassunto__c, Name
        ];
    }

    /**
     * @description Retorna uma categorização pelo Id com todos os campos, incluindo distribuição.
     * @param categoriaId Id da Categorizacao__c.
     * @return Lista com zero ou um registro Categorizacao__c.
     **/
    public static List<Categorizacao__c> selectCategoriaById(Id categoriaId) {
        return [
            SELECT Id, Name, GestaoSLA__c, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c,
                   Subassunto__c, Prioridade__c, Ativo__c, DistribuirParaFila__c, PorCampoCustomizado__c,
                   FilaDeveloperName__c, NomeFilaDistribuicao__c, CampoDistribuicao__c, ValorDistribuicao__c,
                   LabelCampoDistribuicao__c, LabelValorDistribuicao__c
            FROM Categorizacao__c
            WHERE Id = :categoriaId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna somente o Id de uma categorização, para checagem de existência.
     * @param categoriaId Id da Categorizacao__c.
     * @return Lista com zero ou um registro (somente Id).
     **/
    public static List<Categorizacao__c> selectCategoriaIdById(Id categoriaId) {
        return [SELECT Id FROM Categorizacao__c WHERE Id = :categoriaId LIMIT 1];
    }

    /**
     * @description Verifica se uma categorização pertence a uma Gestão de SLA específica.
     * @param categoriaId Id da Categorizacao__c.
     * @param gestaoSLAId Id da Gestão de SLA esperada.
     * @return Lista com zero ou um registro (somente Id).
     **/
    public static List<Categorizacao__c> selectCategoriaByIdAndGestaoSLA(Id categoriaId, Id gestaoSLAId) {
        return [
            SELECT Id
            FROM Categorizacao__c
            WHERE Id = :categoriaId
              AND GestaoSLA__c = :gestaoSLAId
            LIMIT 1
        ];
    }

    /**
     * @description Verifica duplicidade de categorização ativa com a mesma combinação de campos.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param tipoCaso Valor de TipoCaso__c.
     * @param categoria Valor de Categoria__c.
     * @param assunto Valor de Assunto__c.
     * @param subassunto Valor de Subassunto__c.
     * @param excludeId Id a excluir da verificação (null para não excluir).
     * @return Lista com zero ou um registro duplicado.
     **/
    public static List<Categorizacao__c> selectDuplicateActiveCategoria(
        Id gestaoSLAId, String tipoCaso, String categoria, String assunto, String subassunto, Id excludeId
    ) {
        return [
            SELECT Id
            FROM Categorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND TipoCaso__c = :tipoCaso
              AND Categoria__c = :categoria
              AND Assunto__c = :assunto
              AND Subassunto__c = :subassunto
              AND Ativo__c = true
              AND Id != :excludeId
            LIMIT 1
        ];
    }

    /**
     * @description Conta o total de categorizações de uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Total de categorizações.
     **/
    public static Integer countCategoriasByGestaoSLA(Id gestaoSLAId) {
        return [SELECT Count() FROM Categorizacao__c WHERE GestaoSLA__c = :gestaoSLAId];
    }

    // ─── MarcoSLA__c ─────────────────────────────────────────────────────────

    /**
     * @description Retorna todos os marcos SLA de uma Gestão de SLA ordenados por ordem e nome.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de MarcoSLA__c.
     **/
    public static List<MarcoSLA__c> selectMarcosByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT Id, Name, GestaoSLA__c, NomeMarco__c, MilestoneTypeName__c, FonteTempo__c,
                   Ordem__c, Recorrente__c, TipoRecorrencia__c, UsaCategorizacao__c,
                   UsaAreaInterna__c, UsaOrigem__c, Ativo__c
            FROM MarcoSLA__c
            WHERE GestaoSLA__c = :gestaoSLAId
            ORDER BY Ordem__c, Name
        ];
    }

    /**
     * @description Verifica se um marco SLA pertence a uma Gestão de SLA específica.
     * @param marcoId Id do MarcoSLA__c.
     * @param gestaoSLAId Id da Gestão de SLA esperada.
     * @return Lista com zero ou um registro (somente Id).
     **/
    public static List<MarcoSLA__c> selectMarcoByIdAndGestaoSLA(Id marcoId, Id gestaoSLAId) {
        return [
            SELECT Id
            FROM MarcoSLA__c
            WHERE Id = :marcoId
              AND GestaoSLA__c = :gestaoSLAId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna o marco SLA único (Triagem/Resposta Chat/Fila Email) de uma Gestão de SLA pelo nome do MilestoneType.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param milestoneTypeName Nome do MilestoneType (MilestoneTypeName__c) a localizar.
     * @return Lista com zero ou um registro (Id, Ativo__c).
     **/
    public static List<MarcoSLA__c> selectMarcoByGestaoAndMilestoneTypeName(Id gestaoSLAId, String milestoneTypeName) {
        return [
            SELECT Id, Ativo__c
            FROM MarcoSLA__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND MilestoneTypeName__c = :milestoneTypeName
            LIMIT 1
        ];
    }

    /**
     * @description Conta marcos SLA ativos de uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Total de marcos ativos.
     **/
    public static Integer countActiveMarcosByGestaoSLA(Id gestaoSLAId) {
        return [SELECT Count() FROM MarcoSLA__c WHERE GestaoSLA__c = :gestaoSLAId AND Ativo__c = true];
    }

    // ─── RegrasSLACategorizacao__c ───────────────────────────────────────────

    /**
     * @description Retorna todas as regras SLA de uma Gestão de SLA com campos de relacionamento.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de RegrasSLACategorizacao__c com detalhe de Categorizacao e MarcoSLA.
     **/
    public static List<RegrasSLACategorizacao__c> selectRegrasByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT Id, GestaoSLA__c, Categorizacao__c, Categorizacao__r.Name,
                   Categorizacao__r.Categoria__c, Categorizacao__r.Assunto__c, Categorizacao__r.Subassunto__c,
                   MarcoSLA__c, MarcoSLA__r.Name, MarcoSLA__r.NomeMarco__c, MarcoSLA__r.Ordem__c,
                   EscopoRegra__c, AreaAtendimento__c,
                   TempoBaixa__c, TempoMedia__c, TempoAlta__c, Ativo__c
            FROM RegrasSLACategorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
            ORDER BY MarcoSLA__r.Ordem__c, Categorizacao__r.Name, AreaAtendimento__c
        ];
    }

    /**
     * @description Retorna uma regra SLA pelo Id com campos básicos de controle.
     * @param regraId Id da RegrasSLACategorizacao__c.
     * @return Lista com zero ou um registro (Id, GestaoSLA__c, Ativo__c).
     **/
    public static List<RegrasSLACategorizacao__c> selectRegraById(Id regraId) {
        return [
            SELECT Id, GestaoSLA__c, Ativo__c
            FROM RegrasSLACategorizacao__c
            WHERE Id = :regraId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna uma regra SLA pelo Id com todos os campos de detalhe e relacionamentos.
     * @param regraId Id da RegrasSLACategorizacao__c.
     * @return Lista com zero ou um registro completo.
     **/
    public static List<RegrasSLACategorizacao__c> selectRegraDetailById(Id regraId) {
        return [
            SELECT Id, GestaoSLA__c, Categorizacao__c, Categorizacao__r.Name,
                   Categorizacao__r.Categoria__c, Categorizacao__r.Assunto__c, Categorizacao__r.Subassunto__c,
                   MarcoSLA__c, MarcoSLA__r.Name, MarcoSLA__r.NomeMarco__c, MarcoSLA__r.Ordem__c,
                   EscopoRegra__c, AreaAtendimento__c,
                   TempoBaixa__c, TempoMedia__c, TempoAlta__c, Ativo__c
            FROM RegrasSLACategorizacao__c
            WHERE Id = :regraId
            LIMIT 1
        ];
    }

    /**
     * @description Retorna múltiplas regras SLA por conjunto de Ids com todos os campos de detalhe.
     * @param regraIds Conjunto de Ids a consultar.
     * @return Lista de RegrasSLACategorizacao__c ordenada por AreaAtendimento__c.
     **/
    public static List<RegrasSLACategorizacao__c> selectRegraDetailByIds(Set<Id> regraIds) {
        return [
            SELECT Id, GestaoSLA__c, Categorizacao__c, Categorizacao__r.Name,
                   Categorizacao__r.Categoria__c, Categorizacao__r.Assunto__c, Categorizacao__r.Subassunto__c,
                   MarcoSLA__c, MarcoSLA__r.Name, MarcoSLA__r.NomeMarco__c, MarcoSLA__r.Ordem__c,
                   EscopoRegra__c, AreaAtendimento__c,
                   TempoBaixa__c, TempoMedia__c, TempoAlta__c, Ativo__c
            FROM RegrasSLACategorizacao__c
            WHERE Id IN :regraIds
            ORDER BY AreaAtendimento__c
        ];
    }

    /**
     * @description Retorna somente os Ids de regras SLA por conjunto de Ids, para checagem de existência/exclusão.
     * @param regraIds Conjunto de Ids a consultar.
     * @return Lista de RegrasSLACategorizacao__c com somente Id.
     **/
    public static List<RegrasSLACategorizacao__c> selectByIds(Set<Id> regraIds) {
        return [SELECT Id FROM RegrasSLACategorizacao__c WHERE Id IN :regraIds];
    }

    /**
     * @description Retorna regras de Área Interna ativas de uma categorização dentro de uma Gestão de SLA, com os tempos de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param categorizacaoId Id da Categorizacao__c.
     * @return Lista de RegrasSLACategorizacao__c (Id, AreaAtendimento__c, TempoBaixa__c, TempoMedia__c, TempoAlta__c).
     **/
    public static List<RegrasSLACategorizacao__c> selectActiveAreaRulesByGestaoCategorizacao(Id gestaoSLAId, Id categorizacaoId) {
        return [
            SELECT Id, AreaAtendimento__c, TempoBaixa__c, TempoMedia__c, TempoAlta__c
            FROM RegrasSLACategorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND Categorizacao__c = :categorizacaoId
              AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
              AND Ativo__c = true
        ];
    }

    /**
     * @description Retorna regras ativas por Gestão de SLA, Marco SLA e escopo para validação de duplicidade.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param marcoSLAId Id do MarcoSLA__c.
     * @param escopoRegra Valor do escopo da regra.
     * @return Lista de RegrasSLACategorizacao__c ativas com Id e Categorizacao__c.
     **/
    public static List<RegrasSLACategorizacao__c> selectActiveByGestaoMarcoEscopo(Id gestaoSLAId, Id marcoSLAId, String escopoRegra) {
        return [
            SELECT Id, Categorizacao__c
            FROM RegrasSLACategorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND MarcoSLA__c = :marcoSLAId
              AND EscopoRegra__c = :escopoRegra
              AND Ativo__c = true
        ];
    }

    /**
     * @description Retorna regras ativas por Gestão de SLA, Categorização e escopo para validação de duplicidade.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param categorizacaoId Id da Categorizacao__c.
     * @param escopoRegra Valor do escopo da regra.
     * @return Lista de RegrasSLACategorizacao__c ativas com Id e AreaAtendimento__c.
     **/
    public static List<RegrasSLACategorizacao__c> selectActiveByGestaoCategorizacaoEscopo(Id gestaoSLAId, Id categorizacaoId, String escopoRegra) {
        return [
            SELECT Id, AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND Categorizacao__c = :categorizacaoId
              AND EscopoRegra__c = :escopoRegra
              AND Ativo__c = true
        ];
    }

    /**
     * @description Conta regras SLA ativas de uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Total de regras ativas.
     **/
    public static Integer countActiveRegrasByGestaoSLA(Id gestaoSLAId) {
        return [SELECT Count() FROM RegrasSLACategorizacao__c WHERE GestaoSLA__c = :gestaoSLAId AND Ativo__c = true];
    }

    /**
     * @description Retorna contagem de regras ativas agrupadas por Categorizacao__c.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de AggregateResult com categId e total.
     **/
    public static List<AggregateResult> countActiveRegrasByCategorizacao(Id gestaoSLAId) {
        return [
            SELECT Categorizacao__c categId, Count(Id) total
            FROM RegrasSLACategorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND Ativo__c = true
              AND Categorizacao__c != null
            GROUP BY Categorizacao__c
        ];
    }

    /**
     * @description Retorna áreas internas distintas ativas de uma Gestão de SLA agrupadas por área.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de AggregateResult agrupada por AreaAtendimento__c.
     **/
    public static List<AggregateResult> selectDistinctActiveAreasByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE GestaoSLA__c = :gestaoSLAId
              AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
              AND Ativo__c = true
              AND AreaAtendimento__c != null
            GROUP BY AreaAtendimento__c
        ];
    }
}