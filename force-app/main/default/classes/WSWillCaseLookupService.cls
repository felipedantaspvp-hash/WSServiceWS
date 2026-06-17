/**
 * @description       : Serviço de negócio para o módulo WSWillCaseLookup. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseLookupService {
    public static List<WSWillCaseLookupDTO.Response> lookup(List<WSWillCaseLookupDTO.Request> requests) {
        List<WSWillCaseLookupDTO.Response> out = new List<WSWillCaseLookupDTO.Response>();
        if (requests == null || requests.isEmpty()) return out;

        Set<String> caseNumberSet = new Set<String>();
        for (WSWillCaseLookupDTO.Request req : requests) {
            String normalized = WSWillCaseLookupHelper.normalizeCaseNumber(req == null ? null : req.caseNumber);
            if (!String.isBlank(normalized)) caseNumberSet.add(normalized);
        }
        List<String> caseNumbers = new List<String>(caseNumberSet);

        Map<String, Case> caseByNumber = new Map<String, Case>();
        if (!caseNumbers.isEmpty()) {
            List<String> quoted = new List<String>();
            for (String cn : caseNumbers) {
                quoted.add('\'' + String.escapeSingleQuotes(cn) + '\'');
            }
            String soql = 'SELECT Id, CaseNumber, Status, TipoCaso__c, Categoria__c, Assunto__c, EtapaAtendimento__c, ContactId, AccountId FROM Case WHERE CaseNumber IN (' + String.join(quoted, ',') + ')';
            for (Case c : Database.query(soql)) {
                caseByNumber.put(c.CaseNumber, c);
            }
        }

        for (WSWillCaseLookupDTO.Request req : requests) {
            WSWillCaseLookupDTO.Response res = new WSWillCaseLookupDTO.Response();
            res.success = false;
            res.canShowCaseData = false;
            res.caseFound = false;

            String requestedNumber = WSWillCaseLookupHelper.normalizeCaseNumber(req == null ? null : req.caseNumber);
            if (String.isBlank(requestedNumber)) {
                res.statusCode = 'INVALID_INPUT';
                res.message = 'Informe o número do caso.';
                out.add(res);
                continue;
            }

            Case found = caseByNumber.get(requestedNumber);
            if (found == null) {
                res.statusCode = 'CASE_NOT_FOUND';
                res.message = 'Caso não encontrado.';
                out.add(res);
                continue;
            }

            String lang = WSWillCaseLookupHelper.normalizeLang(req == null ? null : req.language);
            res.success = true;
            res.statusCode = 'SUCCESS';
            res.canShowCaseData = true;
            res.caseFound = true;
            res.caseId = found.Id;
            res.caseNumber = found.CaseNumber;
            res.caseStatus = WSWillCaseLookupHelper.translateValue('Status', found.Status, lang);
            res.caseType = WSWillCaseLookupHelper.translateValue('TipoCaso__c', found.TipoCaso__c, lang);
            res.caseCategory = WSWillCaseLookupHelper.translateValue('Categoria__c', found.Categoria__c, lang);
            res.caseSubject = WSWillCaseLookupHelper.translateValue('Assunto__c', found.Assunto__c, lang);
            res.caseStage = WSWillCaseLookupHelper.translateValue('EtapaAtendimento__c', found.EtapaAtendimento__c, lang);
            res.message = buildCaseSummary(new List<String>{ res.caseType, res.caseCategory, res.caseSubject });

            out.add(res);
        }

        return out;
    }

    @TestVisible
    private static String buildCaseSummary(List<String> parts) {
        if (parts == null || parts.isEmpty()) return null;
        List<String> cleaned = new List<String>();
        for (String part : parts) {
            if (!String.isBlank(part)) cleaned.add(part.trim());
        }
        return cleaned.isEmpty() ? null : String.join(cleaned, ' | ');
    }
}