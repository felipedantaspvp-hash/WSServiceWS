public inherited sharing class WS_EmailToCaseCustomerResolutionService {
    public class Resolution {
        public Id accountId;
        public Id contactId;
        public Id representativeAccountId;
        public Boolean matchedByEmail = false;
        public Boolean matchedByDomain = false;
        public Boolean createdContact = false;
    }

    public Resolution resolveOrCreate(Messaging.InboundEmail email) {
        Resolution out = new Resolution();
        String fromAddress = WS_EmailToCaseUtils.normalize(email == null ? null : email.fromAddress);
        if (String.isBlank(fromAddress)) {
            return out;
        }

        Contact matchedContact = findUniqueContactByEmail(fromAddress);
        if (matchedContact != null) {
            out.matchedByEmail = true;
            applyContactResolution(out, matchedContact);
            return out;
        }

        String emailDomain = extractDomain(fromAddress);
        if (String.isBlank(emailDomain)) {
            return out;
        }

        Account matchedAccount = findUniqueAccountByDomain(emailDomain);
        if (matchedAccount == null) {
            return out;
        }

        out.matchedByDomain = true;
        out.accountId = matchedAccount.Id;

        Contact createdContact = createContactForAccount(email, fromAddress, matchedAccount.Id);
        if (createdContact != null) {
            out.contactId = createdContact.Id;
            out.createdContact = true;
        }
        return out;
    }

    @TestVisible
    private static Contact findUniqueContactByEmail(String emailAddress) {
        if (String.isBlank(emailAddress) || !AtendimentoContextResolverHelper.canQueryObject('Contact')) {
            return null;
        }

        List<Contact> rows = [
            SELECT Id, AccountId, Email, ContaRepresentadaAtual__c
            FROM Contact
            WHERE Email = :emailAddress
            LIMIT 2
        ];
        return rows.size() == 1 ? rows[0] : null;
    }

    @TestVisible
    private static Account findUniqueAccountByDomain(String emailDomain) {
        if (String.isBlank(emailDomain) || !AtendimentoContextResolverHelper.canQueryObject('Account')) {
            return null;
        }

        String likeValue = '%' + emailDomain + '%';
        List<Account> candidates = [
            SELECT Id, DominiosEmail__c
            FROM Account
            WHERE DominiosEmail__c LIKE :likeValue
            LIMIT 50
        ];

        List<Account> exactMatches = new List<Account>();
        for (Account row : candidates) {
            if (containsDomain(row.DominiosEmail__c, emailDomain)) {
                exactMatches.add(row);
            }
        }
        return exactMatches.size() == 1 ? exactMatches[0] : null;
    }

    @TestVisible
    private static Boolean containsDomain(String configuredDomains, String expectedDomain) {
        if (String.isBlank(configuredDomains) || String.isBlank(expectedDomain)) {
            return false;
        }

        String normalizedExpected = WS_EmailToCaseUtils.normalize(expectedDomain);
        for (String token : configuredDomains.split('[,;\\s]+')) {
            String normalizedToken = WS_EmailToCaseUtils.normalize(token);
            if (!String.isBlank(normalizedToken) && normalizedToken == normalizedExpected) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    private static String extractDomain(String emailAddress) {
        if (String.isBlank(emailAddress) || !emailAddress.contains('@')) {
            return null;
        }
        String domain = emailAddress.substringAfter('@');
        return WS_EmailToCaseUtils.normalize(domain);
    }

    private static void applyContactResolution(Resolution target, Contact matchedContact) {
        target.contactId = matchedContact.Id;
        Id representedAccountId = (Id) matchedContact.get('ContaRepresentadaAtual__c');
        if (representedAccountId != null) {
            target.accountId = representedAccountId;
            if (matchedContact.AccountId != null && matchedContact.AccountId != representedAccountId) {
                target.representativeAccountId = matchedContact.AccountId;
            }
            return;
        }
        target.accountId = matchedContact.AccountId;
    }

    private static Contact createContactForAccount(Messaging.InboundEmail email, String fromAddress, Id accountId) {
        if (accountId == null || !Schema.sObjectType.Contact.isCreateable()) {
            return null;
        }

        String displayName = email == null ? null : email.fromName;
        if (String.isBlank(displayName)) {
            displayName = fromAddress.substringBefore('@').replace('.', ' ');
        }

        String[] nameParts = WSWillCaseCreationHelper.splitFullName(displayName);
        Map<String, Schema.SObjectField> fieldMap = Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();

        Contact contactRow = new Contact();
        putIfCreateable(contactRow, fieldMap, 'FirstName', nameParts[0]);
        putIfCreateable(contactRow, fieldMap, 'LastName', nameParts[1]);
        putIfCreateable(contactRow, fieldMap, 'Email', fromAddress);
        putIfCreateable(contactRow, fieldMap, 'AccountId', accountId);
        if (fieldMap.containsKey('BypassValidationsFromBot__c')) {
            contactRow.put('BypassValidationsFromBot__c', true);
        }

        Database.SaveResult saveResult = Database.insert(contactRow, false);
        if (!saveResult.isSuccess()) {
            return null;
        }

        contactRow.Id = saveResult.getId();
        return contactRow;
    }

    private static void putIfCreateable(SObject row, Map<String, Schema.SObjectField> fieldMap, String fieldApiName, Object value) {
        if (row == null || fieldMap == null || String.isBlank(fieldApiName) || value == null || !fieldMap.containsKey(fieldApiName)) {
            return;
        }
        if (fieldMap.get(fieldApiName).getDescribe().isCreateable()) {
            row.put(fieldApiName, value);
        }
    }
}