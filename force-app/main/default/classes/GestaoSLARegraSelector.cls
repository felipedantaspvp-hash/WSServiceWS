/**
 * @description Selector de RegrasSLACategorizacao__c, extraído de GestaoSLASelector.cls (Pacote 44 —
 * divisão do God Object GestaoSLAService.cls em serviços por domínio).
 */
public inherited sharing class GestaoSLARegraSelector {
    /**
     * @description Conta Regras de SLA (qualquer status) que ainda referenciam um Marco SLA, usado para
     * bloquear exclusão definitiva do Marco e evitar que o lookup seja silenciosamente nulificado
     * (deleteConstraint SetNull).
     * @param marcoSLAId Id do MarcoSLA__c.
     * @return Total de RegrasSLACategorizacao__c vinculadas.
     **/
    public static Integer countByMarcoSLA(Id marcoSLAId) {
        return [SELECT Count() FROM RegrasSLACategorizacao__c WHERE MarcoSLA__c = :marcoSLAId];
    }

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
    public static Integer countActiveByGestaoSLA(Id gestaoSLAId) {
        return [SELECT Count() FROM RegrasSLACategorizacao__c WHERE GestaoSLA__c = :gestaoSLAId AND Ativo__c = true];
    }

    /**
     * @description Retorna contagem de regras ativas agrupadas por Categorizacao__c.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de AggregateResult com categId e total.
     **/
    public static List<AggregateResult> countActiveByCategorizacao(Id gestaoSLAId) {
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
