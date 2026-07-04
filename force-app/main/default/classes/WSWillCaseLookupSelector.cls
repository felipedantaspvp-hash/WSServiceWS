/**
 * @description       : Selector de queries SOQL para o módulo WSWillCaseLookup.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 07-04-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseLookupSelector {
    /**
     * @description Retorna Cases indexados por CaseNumber para os números informados.
     * @param caseNumbers Conjunto de números de caso já normalizados.
     * @return Mapa de CaseNumber → Case.
     **/
    public static Map<String, Case> selectCasesByCaseNumbers(Set<String> caseNumbers) {
        Map<String, Case> casesByNumber = new Map<String, Case>();
        if (caseNumbers == null || caseNumbers.isEmpty()) {
            return casesByNumber;
        }

        for (Case row : [
            SELECT Id, CaseNumber, Status, TipoCaso__c, Categoria__c, Assunto__c,
                   EtapaAtendimento__c, ContactId, AccountId
            FROM Case
            WHERE CaseNumber IN :caseNumbers
            WITH USER_MODE
        ]) {
            casesByNumber.put(row.CaseNumber, row);
        }
        return casesByNumber;
    }
}
