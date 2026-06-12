/**
 * @description       : Invocable action to send routing fault notifications by email.
 * @author            : Triscal
 * @last modified on  : 05-27-2026
 * @last modified by  : Codex
 **/
public with sharing class FlowRoutingErrorEmailInvocable {
    public class Request {
        @InvocableVariable(required=true)
        public String toAddress;

        @InvocableVariable
        public String subject;

        @InvocableVariable
        public String body;
    }

    @InvocableMethod(label='Send Routing Fault Email')
    public static void sendEmail(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Request requestItem : requests) {
            if (requestItem == null || String.isBlank(requestItem.toAddress)) {
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ requestItem.toAddress.trim() });
            email.setSubject(String.isBlank(requestItem.subject) ? 'Routing Flow Error' : requestItem.subject);
            email.setPlainTextBody(String.isBlank(requestItem.body) ? 'Flow fault without details.' : requestItem.body);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }
}