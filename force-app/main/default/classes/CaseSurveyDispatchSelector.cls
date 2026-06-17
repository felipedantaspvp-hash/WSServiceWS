/**
 * @description       : Selector de queries SOQL para o módulo CaseSurveyDispatch.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseSurveyDispatchSelector {

    /**
     * @description Retorna Cases com campos de contato necessários para o disparo de Survey.
     * @param caseIds Conjunto de Ids de Cases a consultar.
     * @return Mapa de Id → Case.
     **/
    public static Map<Id, Case> selectCasesById(Set<Id> caseIds) {
        return new Map<Id, Case>([
            SELECT Id, CaseNumber, Status, IsClosed, UnidadeNegocio__c, ContactId, Contact.Email, Contact.Idioma__c, ContactEmail,
                   SuppliedEmail, EnviarPesquisaSatisfacao__c, PesquisaEnviada__c, DataHoraEnvioPesquisa__c
            FROM Case
            WHERE Id IN :caseIds
        ]);
    }

    /**
     * @description Retorna SurveySubjects vinculados a Cases para verificar se Survey já foi enviada.
     * @param caseIds Conjunto de Ids de Cases a verificar.
     * @return Lista de SurveySubject com SubjectId.
     **/
    public static List<SurveySubject> selectSurveySubjectsByCaseIds(Set<Id> caseIds) {
        return [
            SELECT SubjectId
            FROM SurveySubject
            WHERE SubjectId IN :caseIds
              AND SubjectEntityType = 'Case'
        ];
    }

    /**
     * @description Retorna Surveys ativas pelos DeveloperNames.
     * @param developerNames Conjunto de DeveloperNames a consultar.
     * @return Lista de Survey com Id e DeveloperName.
     **/
    public static List<Survey> selectSurveysByDeveloperNames(Set<String> developerNames) {
        return [
            SELECT Id, DeveloperName
            FROM Survey
            WHERE DeveloperName IN :developerNames
              AND ActiveVersionId != null
        ];
    }

    /**
     * @description Retorna EmailTemplates pelos DeveloperNames.
     * @param developerNames Conjunto de DeveloperNames a consultar.
     * @return Lista de EmailTemplate com Id e DeveloperName.
     **/
    public static List<EmailTemplate> selectEmailTemplatesByDeveloperNames(Set<String> developerNames) {
        return [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName IN :developerNames
        ];
    }

    /**
     * @description Retorna OrgWideEmailAddresses pelos endereços de e-mail.
     * @param addresses Conjunto de endereços (em minúsculas) a consultar.
     * @return Lista de OrgWideEmailAddress com Id e Address.
     **/
    public static List<OrgWideEmailAddress> selectOrgWideEmailsByAddresses(Set<String> addresses) {
        return [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address IN :addresses
        ];
    }

    /**
     * @description Retorna Networks ativas pelos UrlPathPrefixes.
     * @param urlPathPrefixes Conjunto de prefixos de URL a consultar.
     * @return Lista de Network com Id e UrlPathPrefix.
     **/
    public static List<Network> selectNetworksByUrlPathPrefixes(Set<String> urlPathPrefixes) {
        return [
            SELECT Id, UrlPathPrefix
            FROM Network
            WHERE UrlPathPrefix IN :urlPathPrefixes
              AND Status = 'Live'
        ];
    }
}
