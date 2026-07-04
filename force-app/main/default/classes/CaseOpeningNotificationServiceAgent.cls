/**
 * @description       : ServiceAgent para envio de e-mail transacional de abertura do Case.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-17-2026
 * @last modified by  : Marllon Nascimento
 **/
public inherited sharing class CaseOpeningNotificationServiceAgent {
    @TestVisible static Map<Integer, String> testEmailErrorsByIndex;
    @TestVisible static List<CaseOpeningEnvelope> preparedEnvelopesForTest;

    public class CaseOpeningEnvelope {
        public Case caseRecord;
        public Id emailTemplateId;
        public Id orgWideEmailAddressId;
    }

    public class DispatchResult {
        public Id caseId;
        public Boolean success;
        public String message;
    }

    /**
     * @description Envia e-mail de abertura do Case usando o template configurado.
     * @param envelopes Dados necessários para envio.
     * @return Resultados por Case.
     */
    public static List<DispatchResult> sendCaseOpeningEmails(List<CaseOpeningEnvelope> envelopes) {
        List<DispatchResult> results = new List<DispatchResult>();
        if (envelopes == null || envelopes.isEmpty()) {
            return results;
        }

        if (Test.isRunningTest()) {
            preparedEnvelopesForTest = new List<CaseOpeningEnvelope>();
        }

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (CaseOpeningEnvelope envelope : envelopes) {
            if (Test.isRunningTest()) {
                preparedEnvelopesForTest.add(envelope);
            }
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(envelope.caseRecord.ContactId);
            message.setWhatId(envelope.caseRecord.Id);
            message.setTemplateId(envelope.emailTemplateId);
            if (envelope.orgWideEmailAddressId != null) {
                message.setOrgWideEmailAddressId(envelope.orgWideEmailAddressId);
            }
            message.setSaveAsActivity(false);
            message.setUseSignature(false);
            messages.add(message);
        }

        Boolean skipEmailForTest = ApexTestSeam.getBoolean('CaseOpeningNotificationServiceAgent.skipEmail');
        Messaging.SendEmailResult[] emailResults = new Messaging.SendEmailResult[]{};
        if (!skipEmailForTest) {
            emailResults = Messaging.sendEmail(messages, false);
        }

        for (Integer index = 0; index < envelopes.size(); index++) {
            DispatchResult result = new DispatchResult();
            result.caseId = envelopes[index].caseRecord.Id;
            result.success = EmailDispatchHelper.isEmailSuccess(index, emailResults, skipEmailForTest, testEmailErrorsByIndex);
            result.message = result.success
                ? CaseSurveyDispatchHelper.STATUS_CASE_OPENING_SENT
                : EmailDispatchHelper.buildEmailErrorMessage(index, emailResults, testEmailErrorsByIndex);
            results.add(result);
        }
        return results;
    }
}
