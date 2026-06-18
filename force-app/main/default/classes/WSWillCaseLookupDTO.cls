public inherited sharing class WSWillCaseLookupDTO {
    public class Request {
        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Contact Id')
        public Id contactId;

        @InvocableVariable(label='Account Id')
        public Id accountId;

        @InvocableVariable(label='Language')
        public String language;

        @InvocableVariable(label='Business Unit Name')
        public String businessUnitName;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Status Code')
        public String statusCode;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Case Id')
        public Id caseId;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Case Status')
        public String caseStatus;

        @InvocableVariable(label='Case Type')
        public String caseType;

        @InvocableVariable(label='Case Category')
        public String caseCategory;

        @InvocableVariable(label='Case Subject')
        public String caseSubject;

        @InvocableVariable(label='Case Stage')
        public String caseStage;

        @InvocableVariable(label='Case Business Unit')
        public String caseBusinessUnitName;

        @InvocableVariable(label='Can Show Case Data')
        public Boolean canShowCaseData;

        @InvocableVariable(label='Case Found')
        public Boolean caseFound;
    }
}