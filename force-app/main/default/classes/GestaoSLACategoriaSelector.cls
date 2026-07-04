/**
 * @description Selector de Categorizacao__c, extraído de GestaoSLASelector.cls (Pacote 44 — divisão do
 * God Object GestaoSLAService.cls em serviços por domínio).
 */
public inherited sharing class GestaoSLACategoriaSelector {
    /**
     * @description Retorna as categorizações de uma Gestão de SLA ordenadas por Name, com campos de distribuição.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de Categorizacao__c.
     **/
    public static List<Categorizacao__c> selectCategoriasByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT Id, Name, GestaoSLA__c, UnidadeNegocios__c, TipoCaso__c, Categoria__c, Assunto__c,
                   Subassunto__c, Prioridade__c, Ativo__c, DistribuirParaFila__c, PorCampoCustomizado__c,
                   FilaDeveloperName__c, NomeFilaDistribuicao__c, CampoDistribuicao__c, ValorDistribuicao__c,
                   LabelCampoDistribuicao__c, LabelValorDistribuicao__c, FilaDeveloperNameFallback__c,
                   FilaIdFallback__c, NomeFilaFallbackDistribuicao__c, PermiteAssumirComFilaParametrizada__c,
                   EtapaAtendimentoDistribuicao__c
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
                   LabelCampoDistribuicao__c, LabelValorDistribuicao__c, FilaDeveloperNameFallback__c,
                   FilaIdFallback__c, NomeFilaFallbackDistribuicao__c, PermiteAssumirComFilaParametrizada__c,
                   EtapaAtendimentoDistribuicao__c
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
                   LabelCampoDistribuicao__c, LabelValorDistribuicao__c, FilaDeveloperNameFallback__c,
                   FilaIdFallback__c, NomeFilaFallbackDistribuicao__c, PermiteAssumirComFilaParametrizada__c,
                   EtapaAtendimentoDistribuicao__c
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
    public static Integer countByGestaoSLA(Id gestaoSLAId) {
        return [SELECT Count() FROM Categorizacao__c WHERE GestaoSLA__c = :gestaoSLAId];
    }
}
