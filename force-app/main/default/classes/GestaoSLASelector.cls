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

}