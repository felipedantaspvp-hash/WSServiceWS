/**
 * @description       : ServiceAgent para criação de Survey Invitation e envio de e-mail.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Codex
 **/
public inherited sharing class CaseSurveyDispatchServiceAgent {
    @TestVisible static Boolean skipDmlAndEmailForTest = false;
    @TestVisible static Id testInvitationId;
    @TestVisible static Map<Integer, String> testEmailErrorsByIndex;
    @TestVisible static List<SurveyInvitation> preparedInvitationsForTest;

    public class DispatchEnvelope {
        public Case caseRecord;
        public Id surveyId;
        public Id emailTemplateId;
        public Id orgWideEmailAddressId;
        public Id communityId;
    }

    public class CaseClosureEnvelope {
        public Case caseRecord;
        public Id emailTemplateId;
        public Id orgWideEmailAddressId;
    }

    public class DispatchResult {
        public Id caseId;
        public Id surveyInvitationId;
        public Boolean success;
        public String message;
    }

    /**
     * @description Cria convites padrão de Survey, vincula ao Case e envia o template configurado.
     * @param envelopes Dados necessários para envio.
     * @return Resultados por Case.
     */
    public static List<DispatchResult> send(List<DispatchEnvelope> envelopes) {
        List<DispatchResult> results = new List<DispatchResult>();
        if (envelopes == null || envelopes.isEmpty()) return results;

        Boolean skipExternalEffects = Test.isRunningTest() && skipDmlAndEmailForTest;

        List<SurveyInvitation> invitations = new List<SurveyInvitation>();
        for (DispatchEnvelope envelope : envelopes) {
            SurveyInvitation invitation = new SurveyInvitation();
            invitation.Name = 'Pesquisa de Satisfação - Caso ' + envelope.caseRecord.CaseNumber;
            invitation.SurveyId = envelope.surveyId;
            invitation.CommunityId = envelope.communityId;
            invitation.OptionsAllowGuestUserResponse = true;
            invitation.OptionsAllowParticipantAccessTheirResponse = false;
            invitation.OptionsCollectAnonymousResponse = false;
            invitations.add(invitation);
        }
        if (Test.isRunningTest()) {
            preparedInvitationsForTest = new List<SurveyInvitation>();
            for (SurveyInvitation invitation : invitations) {
                preparedInvitationsForTest.add(invitation.clone(false, false, false, false));
            }
        }
        if (!skipExternalEffects) insert invitations;

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Integer index = 0; index < envelopes.size(); index++) {
            DispatchEnvelope envelope = envelopes[index];
            SurveyInvitation invitation = invitations[index];
            Id invitationId = skipExternalEffects ? testInvitationId : invitation.Id;

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(envelope.caseRecord.ContactId);
            message.setWhatId(invitationId);
            message.setTemplateId(envelope.emailTemplateId);
            if (envelope.orgWideEmailAddressId != null) {
                message.setOrgWideEmailAddressId(envelope.orgWideEmailAddressId);
            }
            message.setSaveAsActivity(false);
            messages.add(message);
        }
        Messaging.SendEmailResult[] emailResults = new Messaging.SendEmailResult[]{};
        if (!skipExternalEffects) {
            emailResults = Messaging.sendEmail(messages, false);
        }

        List<SurveySubject> subjects = new List<SurveySubject>();
        List<Integer> successfulIndexes = new List<Integer>();
        for (Integer index = 0; index < envelopes.size(); index++) {
            if (!isEmailSuccess(index, emailResults)) {
                continue;
            }

            DispatchEnvelope envelope = envelopes[index];
            SurveyInvitation invitation = invitations[index];
            SurveySubject subject = new SurveySubject();
            subject.Name = 'Caso ' + envelope.caseRecord.CaseNumber;
            subject.ParentId = skipExternalEffects ? testInvitationId : invitation.Id;
            subject.SubjectId = envelope.caseRecord.Id;
            subjects.add(subject);
            successfulIndexes.add(index);
        }
        if (!skipExternalEffects && !subjects.isEmpty()) {
            insert subjects;
        }

        for (Integer index : successfulIndexes) {
            DispatchResult result = new DispatchResult();
            result.caseId = envelopes[index].caseRecord.Id;
            result.surveyInvitationId = skipExternalEffects ? testInvitationId : invitations[index].Id;
            result.success = true;
            result.message = CaseSurveyDispatchHelper.STATUS_SENT;
            results.add(result);
        }
        for (Integer index = 0; index < envelopes.size(); index++) {
            if (isEmailSuccess(index, emailResults)) {
                continue;
            }
            DispatchResult result = new DispatchResult();
            result.caseId = envelopes[index].caseRecord.Id;
            result.success = false;
            result.message = buildEmailErrorMessage(index, emailResults);
            results.add(result);
        }
        return results;
    }

    /**
     * @description Envia e-mail transacional de encerramento quando a Survey não for enviada.
     * @param envelopes Dados necessários para envio.
     * @return Resultados por Case.
     */
    public static List<DispatchResult> sendCaseClosureEmails(List<CaseClosureEnvelope> envelopes) {
        List<DispatchResult> results = new List<DispatchResult>();
        if (envelopes == null || envelopes.isEmpty()) return results;

        Boolean skipExternalEffects = Test.isRunningTest() && skipDmlAndEmailForTest;
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (CaseClosureEnvelope envelope : envelopes) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(envelope.caseRecord.ContactId);
            message.setWhatId(envelope.caseRecord.Id);
            message.setTemplateId(envelope.emailTemplateId);
            if (envelope.orgWideEmailAddressId != null) {
                message.setOrgWideEmailAddressId(envelope.orgWideEmailAddressId);
            }
            message.setSaveAsActivity(false);
            messages.add(message);
        }

        Messaging.SendEmailResult[] emailResults = new Messaging.SendEmailResult[]{};
        if (!skipExternalEffects) {
            emailResults = Messaging.sendEmail(messages, false);
        }

        for (Integer index = 0; index < envelopes.size(); index++) {
            DispatchResult result = new DispatchResult();
            result.caseId = envelopes[index].caseRecord.Id;
            result.success = isEmailSuccess(index, emailResults);
            result.message = result.success
                ? CaseSurveyDispatchHelper.STATUS_CASE_CLOSURE_SENT
                : buildEmailErrorMessage(index, emailResults);
            results.add(result);
        }
        return results;
    }

    private static Boolean isEmailSuccess(Integer index, Messaging.SendEmailResult[] emailResults) {
        if (Test.isRunningTest() && testEmailErrorsByIndex != null) {
            return !testEmailErrorsByIndex.containsKey(index);
        }
        if (Test.isRunningTest() && skipDmlAndEmailForTest) {
            return true;
        }
        return emailResults[index].isSuccess();
    }

    private static String buildEmailErrorMessage(Integer index, Messaging.SendEmailResult[] emailResults) {
        if (Test.isRunningTest() && testEmailErrorsByIndex != null && testEmailErrorsByIndex.containsKey(index)) {
            return 'Erro ao enviar e-mail: ' + testEmailErrorsByIndex.get(index);
        }
        List<String> messages = new List<String>();
        for (Messaging.SendEmailError error : emailResults[index].getErrors()) {
            messages.add(String.valueOf(error.getStatusCode()) + ': ' + error.getMessage());
        }
        return 'Erro ao enviar e-mail: ' + String.join(messages, ' | ');
    }

}