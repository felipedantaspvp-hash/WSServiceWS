/**
 * @description       : Serviço de negócio para o módulo BusinessHoursResolver. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : Business Hours
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class BusinessHoursResolverService {
    public class FunctionalException extends Exception {}
    @TestVisible private static Map<String, Id> cacheByName = new Map<String, Id>();
    @TestVisible private static Map<String, Id> injectedByName = new Map<String, Id>();

    /**
     * @description Resolve o Id de um registro BusinessHours ativo pelo nome, usando cache em memória para evitar SOQLs repetidos.
     *              Suporta injeção de dependência para testes via injectedByName.
     * @param bhName Nome exato do Business Hours a localizar.
     * @return Id do BusinessHours ativo correspondente.
     **/
    public static Id resolveActiveByName(String bhName) {
        if (String.isBlank(bhName)) throw new FunctionalException('Business Hours Name não informado.');
        if (injectedByName.containsKey(bhName)) return injectedByName.get(bhName);
        if (cacheByName.containsKey(bhName)) return cacheByName.get(bhName);
        List<BusinessHours> rows = [SELECT Id, Name, IsActive FROM BusinessHours WHERE Name = :bhName AND IsActive = true];
        if (rows.isEmpty()) throw new FunctionalException('Nenhum Business Hours ativo encontrado para: ' + bhName);
        if (rows.size() > 1) throw new FunctionalException('Mais de um Business Hours ativo encontrado para: ' + bhName);
        cacheByName.put(bhName, rows[0].Id);
        return rows[0].Id;
    }
}