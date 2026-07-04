/**
 * @description Selector de MarcoSLA__c, extraído de GestaoSLASelector.cls (Pacote 44 — divisão do
 * God Object GestaoSLAService.cls em serviços por domínio).
 */
public inherited sharing class GestaoSLAMarcoSelector {
    /**
     * @description Retorna todos os marcos SLA de uma Gestão de SLA ordenados por ordem e nome.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return Lista de MarcoSLA__c.
     **/
    public static List<MarcoSLA__c> selectMarcosByGestaoSLA(Id gestaoSLAId) {
        return [
            SELECT Id, Name, GestaoSLA__c, NomeMarco__c, MilestoneTypeName__c, FonteTempo__c,
                   Ordem__c, Recorrente__c, TipoRecorrencia__c, UsaCategorizacao__c,
                   UsaAreaInterna__c, UsaOrigem__c, TempoFallbackMinutos__c, Ativo__c
            FROM MarcoSLA__c
            WHERE GestaoSLA__c = :gestaoSLAId
            ORDER BY Ordem__c, Name
        ];
    }

    /**
     * @description Retorna um marco SLA com todos os campos administráveis pelo Id, para edição na tela de Manutenção de Marcos.
     * @param marcoId Id do MarcoSLA__c.
     * @return Lista com zero ou um registro.
     **/
    public static List<MarcoSLA__c> selectMarcoFullById(Id marcoId) {
        return [
            SELECT Id, Name, GestaoSLA__c, NomeMarco__c, MilestoneTypeName__c, FonteTempo__c,
                   Ordem__c, Recorrente__c, TipoRecorrencia__c, UsaCategorizacao__c,
                   UsaAreaInterna__c, UsaOrigem__c, TempoFallbackMinutos__c, Ativo__c
            FROM MarcoSLA__c
            WHERE Id = :marcoId
            LIMIT 1
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
    public static Integer countActiveByGestaoSLA(Id gestaoSLAId) {
        return [SELECT Count() FROM MarcoSLA__c WHERE GestaoSLA__c = :gestaoSLAId AND Ativo__c = true];
    }
}
