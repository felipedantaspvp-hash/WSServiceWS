/**
 * @description       : Helper de validações e consultas auxiliares do encerramento de Case com Survey.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseClosureSurveyHelper {
    @TestVisible private static Map<String, Boolean> testCustomerSurveyTodayByEmail;

    @TestVisible
    static void setTestCustomerSurveyTodayByEmail(Map<String, Boolean> valuesByEmail) {
        testCustomerSurveyTodayByEmail = valuesByEmail;
    }

    @TestVisible
    static void clearTestCustomerSurveyTodayByEmail() {
        testCustomerSurveyTodayByEmail = null;
    }

    /**
     * @description Retorna o e-mail preferencial do destinatário da pesquisa.
     * @param caseRecord Case consultado com Contact.Email.
     * @return E-mail do contato ou e-mail informado no Case.
     */
    public static String resolveRecipientEmail(Case caseRecord) {
        if (caseRecord == null) return null;
        if (caseRecord.Contact != null && !String.isBlank(caseRecord.Contact.Email)) return caseRecord.Contact.Email;
        if (!String.isBlank(caseRecord.SuppliedEmail)) return caseRecord.SuppliedEmail;
        if (!String.isBlank(caseRecord.ContactEmail)) return caseRecord.ContactEmail;
        return null;
    }

    /**
     * @description Verifica domínio interno bloqueado.
     * @param email E-mail do destinatário.
     * @param blockedDomains Domínios bloqueados separados por vírgula ou ponto e vírgula.
     * @return Verdadeiro quando o domínio deve impedir envio.
     */
    public static Boolean isBlockedInternalDomain(String email, String blockedDomains) {
        if (String.isBlank(email) || String.isBlank(blockedDomains) || !email.contains('@')) return false;
        String domain = email.substringAfter('@').trim().toLowerCase();
        for (String token : blockedDomains.split('[,;]')) {
            String blocked = token == null ? null : token.trim().toLowerCase();
            if (!String.isBlank(blocked) && domain == blocked) return true;
        }
        return false;
    }

    /**
     * @description Verifica se o cliente recebeu pesquisa no dia, usando SurveyInvitation quando disponível e fallback para Case.
     * @param caseRecord Case de referência.
     * @return Verdadeiro quando houver evidência de envio no dia.
     */
    public static Boolean customerReceivedSurveyToday(Case caseRecord) {
        String email = resolveRecipientEmail(caseRecord);
        if (Test.isRunningTest() && testCustomerSurveyTodayByEmail != null) {
            return testCustomerSurveyTodayByEmail.get(email) == true;
        }
        if (String.isBlank(email)) return false;
        if (hasSurveyInvitationTodayByEmail(email)) return true;
        return hasCaseSurveySentToday(caseRecord, email);
    }

    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static Boolean hasSurveyInvitationTodayByEmail(String email) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get('SurveyInvitation');
        if (objectType == null) return false;
        if (!objectType.getDescribe().isAccessible()) return false;

        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        String emailField = null;
        for (String candidate : new List<String>{ 'RecipientEmail', 'Email', 'ParticipantEmail' }) {
            if (fields.containsKey(candidate) && fields.get(candidate).getDescribe().isAccessible()) {
                emailField = candidate;
                break;
            }
        }
        if (emailField == null) return false;

        String queryText = 'SELECT Id FROM SurveyInvitation WHERE CreatedDate = TODAY AND ' + emailField + ' = :email WITH USER_MODE LIMIT 1';
        try {
            return !Database.query(queryText).isEmpty();
        } catch (Exception ex) {
            return false;
        }
    }

    private static Boolean hasCaseSurveySentToday(Case caseRecord, String email) {
        if (caseRecord == null) return false;
        Date today = Date.today();
        Datetime startOfDay = Datetime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        Datetime endOfDay = startOfDay.addDays(1);

        List<Case> cases = [
            SELECT Id
            FROM Case
            WHERE DataHoraEnvioPesquisa__c >= :startOfDay
            AND DataHoraEnvioPesquisa__c < :endOfDay
            AND Id != :caseRecord.Id
            AND (
                ContactId = :caseRecord.ContactId
                OR SuppliedEmail = :email
            )
            WITH USER_MODE
            LIMIT 1
        ];
        return !cases.isEmpty();
    }

    public static String buildDailySurveyMessage(Boolean receivedToday, Boolean allowSameDay) {
        if (receivedToday == true && allowSameDay != true) {
            return Label.CaseClosureSurvey_DailySurveyBlocked;
        }
        if (receivedToday == true) {
            return Label.CaseClosureSurvey_DailySurveyAllowed;
        }
        return Label.CaseClosureSurvey_DailySurveyNotSent;
    }
}