public inherited sharing class WSWillConversationLinkDTO {
    public class Request {
        @InvocableVariable(label='Conversation Id')
        public Id conversationId;

        @InvocableVariable(label='Case Id')
        public Id caseId;

        @InvocableVariable(label='Channel Name')
        public String channelName;

        @InvocableVariable(label='Routable Id')
        public Id routableId;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Status Code')
        public String statusCode;

        @InvocableVariable(label='Message')
        public String message;
    }
}