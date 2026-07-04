public inherited sharing class WSWillCaseCreationService {
    @TestVisible static Map<Id, MessagingSession> testMessagingById;
    @TestVisible static Map<Id, MessagingEndUser> testEndUserById;
    @TestVisible static List<AtendimentoConfigDTO> testChannelConfigs;
    @TestVisible static List<AtendimentoConfigDTO> testUnitConfigs;
    @TestVisible static Boolean bypassConversationWriteBack = false;

    private class WorkItem {
        public Integer index;
        public WSWillCaseCreationDTO.Request req;
        public WSWillCaseCreationDTO.Response res;
        public Id resolvedAccountId;
        public Id representativeAccountId;
        public Id resolvedContactId;
        public Contact pendingContact;
        public Case pendingCase;
        public Id messagingSessionId;
        public Id messagingEndUserId;
        public Id liveChatTranscriptId;
        public Id targetOwnerId;
        public Id targetQueueId;
        public Id targetRecordTypeId;
        public String targetQueueDeveloperName;
        public String targetRecordTypeDeveloperName;
        public String resolvedBusinessUnitName;
        public String normalizedOrigin;
        public String contactErrorMessage;
        public String queueErrorMessage;
        public String recordTypeErrorMessage;
        public Boolean canProceed = false;
    }

    private class QueueLookupResult {
        public Map<String, Id> idByDeveloperName = new Map<String, Id>();
    }

    public static List<WSWillCaseCreationDTO.Response> createCases(List<WSWillCaseCreationDTO.Request> requests) {
        List<WSWillCaseCreationDTO.Response> out = new List<WSWillCaseCreationDTO.Response>();
        if (requests == null || requests.isEmpty()) return out;

        Set<Id> contactIds = new Set<Id>();
        Set<String> emails = new Set<String>();
        Set<Id> conversationIds = new Set<Id>();
        Set<Id> endUserIds = new Set<Id>();

        for (WSWillCaseCreationDTO.Request req : requests) {
            if (req == null) continue;
            if (req.contactId != null) contactIds.add(req.contactId);
            if (!String.isBlank(req.customerEmail)) emails.add(req.customerEmail.trim().toLowerCase());
            if (req.conversationId != null) conversationIds.add(req.conversationId);
            if (req.endUserId != null) endUserIds.add(req.endUserId);
        }

        String representedAccountField = AtendimentoContextResolverHelper.firstExistingField(
            'Contact',
            new List<String>{ 'ContaRepresentadaAtual__c' }
        );

        Map<Id, Contact> contactById = queryContactsByIds(contactIds, representedAccountField);

        Map<String, Contact> contactByEmail = new Map<String, Contact>();
        if (!emails.isEmpty()) {
            for (Contact c : queryContactsByEmails(emails, representedAccountField)) {
                if (!String.isBlank(c.Email)) {
                    contactByEmail.put(c.Email.trim().toLowerCase(), c);
                }
            }
        }

        Set<Id> messagingSessionIds = new Set<Id>();
        Set<Id> liveChatTranscriptIds = new Set<Id>();
        for (Id convId : conversationIds) {
            if (convId == null) continue;
            String apiName = convId.getSObjectType().getDescribe().getName();
            if (apiName == 'MessagingSession') messagingSessionIds.add(convId);
            if (apiName == 'LiveChatTranscript') liveChatTranscriptIds.add(convId);
        }

        Map<Id, MessagingSession> messagingById = new Map<Id, MessagingSession>();
        if (!messagingSessionIds.isEmpty()) {
            if (Test.isRunningTest() && testMessagingById != null) {
                messagingById.putAll(testMessagingById);
            } else {
                messagingById = WSWillCaseCreationSelector.selectMessagingSessionsByIds(messagingSessionIds);
            }
        }

        Set<Id> allEndUserIds = new Set<Id>();
        allEndUserIds.addAll(endUserIds);
        for (MessagingSession ms : messagingById.values()) {
            if (ms.MessagingEndUserId != null) allEndUserIds.add(ms.MessagingEndUserId);
        }

        Map<Id, MessagingEndUser> endUserById = new Map<Id, MessagingEndUser>();
        if (!allEndUserIds.isEmpty()) {
            if (Test.isRunningTest() && testEndUserById != null) {
                endUserById.putAll(testEndUserById);
            } else {
                endUserById = WSWillCaseCreationSelector.selectMessagingEndUsersByIds(allEndUserIds);
            }
        }

        Set<Id> additionalContactIds = new Set<Id>();
        for (MessagingEndUser meu : endUserById.values()) {
            if (meu.ContactId != null && !contactById.containsKey(meu.ContactId)) {
                additionalContactIds.add(meu.ContactId);
            }
        }
        for (MessagingSession ms : messagingById.values()) {
            if (ms.EndUserContactId != null && !contactById.containsKey(ms.EndUserContactId)) {
                additionalContactIds.add(ms.EndUserContactId);
            }
        }
        if (!additionalContactIds.isEmpty()) {
            for (Contact c : queryContactsByIds(additionalContactIds, representedAccountField).values()) {
                contactById.put(c.Id, c);
                if (!String.isBlank(c.Email)) {
                    contactByEmail.put(c.Email.trim().toLowerCase(), c);
                }
            }
        }

        List<WorkItem> workItems = new List<WorkItem>();
        List<Contact> contactsToInsert = new List<Contact>();
        Map<Id, Contact> contactsToUpdateById = new Map<Id, Contact>();

        for (Integer i = 0; i < requests.size(); i++) {
            WSWillCaseCreationDTO.Request req = requests[i];
            WorkItem item = new WorkItem();
            item.index = i;
            item.req = req;
            item.res = new WSWillCaseCreationDTO.Response();
            item.res.success = false;
            item.res.statusCode = 'INVALID_INPUT';

            if (req == null) {
                item.res.message = 'Request não informado.';
                workItems.add(item);
                continue;
            }

            item.resolvedAccountId = req.accountId;
            item.res.accountId = req.accountId;

            if (req.conversationId != null) {
                String apiName = req.conversationId.getSObjectType().getDescribe().getName();
                if (apiName == 'MessagingSession' && messagingById.containsKey(req.conversationId)) {
                    item.messagingSessionId = req.conversationId;
                    MessagingSession ms = messagingById.get(req.conversationId);
                    if (req.endUserId == null && ms.MessagingEndUserId != null) {
                        req.endUserId = ms.MessagingEndUserId;
                    }
                } else if (apiName == 'LiveChatTranscript') {
                    item.liveChatTranscriptId = req.conversationId;
                }
            }
            if (req.endUserId != null) item.messagingEndUserId = req.endUserId;

            Contact resolvedContact;
            if (req.contactId != null && contactById.containsKey(req.contactId)) {
                resolvedContact = contactById.get(req.contactId);
            } else if (req.endUserId != null && endUserById.containsKey(req.endUserId) && endUserById.get(req.endUserId).ContactId != null) {
                Id mappedContactId = endUserById.get(req.endUserId).ContactId;
                if (contactById.containsKey(mappedContactId)) {
                    resolvedContact = contactById.get(mappedContactId);
                }
            } else if (!String.isBlank(req.customerEmail) && contactByEmail.containsKey(req.customerEmail.trim().toLowerCase())) {
                resolvedContact = contactByEmail.get(req.customerEmail.trim().toLowerCase());
            }

            if (resolvedContact != null) {
                item.resolvedContactId = resolvedContact.Id;
                item.res.contactId = resolvedContact.Id;
                applyResolvedContactAccounts(item, resolvedContact);
                String normalizedLanguage = WSWillContextResolverHelper.normalizePreferredLanguage(req.language);
                Contact contactToUpdate = contactsToUpdateById.containsKey(resolvedContact.Id)
                    ? contactsToUpdateById.get(resolvedContact.Id)
                    : new Contact(Id = resolvedContact.Id);

                Boolean hasChanges = false;
                if (!String.isBlank(normalizedLanguage) && normalizedLanguage != resolvedContact.Idioma__c) {
                    contactToUpdate.Idioma__c = normalizedLanguage;
                    hasChanges = true;
                }

                if (!String.isBlank(req.customerPhone) && String.isBlank(resolvedContact.Phone)) {
                    contactToUpdate.Phone = req.customerPhone;
                    hasChanges = true;
                }

                if (hasChanges) {
                    contactsToUpdateById.put(resolvedContact.Id, contactToUpdate);
                }
            } else {
                String[] nameParts = WSWillCaseCreationHelper.splitFullName(req.customerFullName);
                Id fallbackAccountId = item.resolvedAccountId;
                if (fallbackAccountId == null && req.endUserId != null && endUserById.containsKey(req.endUserId)) {
                    fallbackAccountId = endUserById.get(req.endUserId).AccountId;
                }
                Contact newContact = new Contact(
                    FirstName = nameParts[0],
                    LastName = nameParts[1],
                    Email = req.customerEmail,
                    Phone = req.customerPhone,
                    Idioma__c = WSWillContextResolverHelper.normalizePreferredLanguage(req.language)
                );
                putIfCreateable(newContact, Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap(), 'BypassValidationsFromBot__c', true);
                if (fallbackAccountId != null) {
                    newContact.AccountId = fallbackAccountId;
                    item.resolvedAccountId = fallbackAccountId;
                    item.res.accountId = fallbackAccountId;
                }
                item.pendingContact = newContact;
                contactsToInsert.add(newContact);
            }

            item.canProceed = true;
            workItems.add(item);
        }

        if (!contactsToUpdateById.isEmpty()) {
            update contactsToUpdateById.values();
        }

        if (!contactsToInsert.isEmpty()) {
            Database.SaveResult[] contactResults = Database.insert(contactsToInsert, false);
            Integer resultIndex = 0;
            for (WorkItem item : workItems) {
                if (item.pendingContact == null) continue;
                Database.SaveResult sr = contactResults[resultIndex];
                if (sr.isSuccess()) {
                    item.pendingContact.Id = sr.getId();
                } else {
                    item.contactErrorMessage = sr.getErrors().isEmpty() ? 'Falha ao criar contato.' : sr.getErrors()[0].getMessage();
                    item.res.contactId = null;
                    item.canProceed = true;
                    item.pendingContact = null;
                }
                resultIndex++;
            }
        }

        for (WorkItem item : workItems) {
            if (item.pendingContact != null) {
                item.resolvedContactId = item.pendingContact.Id;
                item.res.contactId = item.pendingContact.Id;
            }
        }

        List<SObject> conversationContactUpdates = new List<SObject>();
        for (WorkItem item : workItems) {
            if (item.resolvedContactId == null) continue;

            if (item.messagingSessionId != null && messagingById.containsKey(item.messagingSessionId)) {
                MessagingSession ms = messagingById.get(item.messagingSessionId);
                Id effectiveEndUserId = item.messagingEndUserId == null ? ms.MessagingEndUserId : item.messagingEndUserId;
                if (effectiveEndUserId != null && endUserById.containsKey(effectiveEndUserId)) {
                    MessagingEndUser meu = endUserById.get(effectiveEndUserId);
                    if (meu.ContactId != item.resolvedContactId) {
                        conversationContactUpdates.add(new MessagingEndUser(Id = meu.Id, ContactId = item.resolvedContactId));
                    }
                }
            } else if (item.messagingEndUserId != null && endUserById.containsKey(item.messagingEndUserId)) {
                MessagingEndUser meu = endUserById.get(item.messagingEndUserId);
                if (meu.ContactId != item.resolvedContactId) {
                    conversationContactUpdates.add(new MessagingEndUser(Id = meu.Id, ContactId = item.resolvedContactId));
                }
            }
        }

        if (!conversationContactUpdates.isEmpty() && !bypassConversationWriteBack) {
            Database.update(conversationContactUpdates, false);
        }

        List<MessagingEndUser> endUsersToUpdate = new List<MessagingEndUser>();
        for (WorkItem item : workItems) {
            if (item.messagingEndUserId == null || !endUserById.containsKey(item.messagingEndUserId)) continue;
            MessagingEndUser existingMeu = endUserById.get(item.messagingEndUserId);
            MessagingEndUser meuUpdate = new MessagingEndUser(Id = existingMeu.Id);
            Boolean hasMeuChanges = false;

            if (item.resolvedContactId != null && existingMeu.ContactId != item.resolvedContactId) {
                meuUpdate.ContactId = item.resolvedContactId;
                hasMeuChanges = true;
            }
            if (!String.isBlank(item.req.customerFullName) && existingMeu.Name != item.req.customerFullName) {
                meuUpdate.Name = item.req.customerFullName;
                hasMeuChanges = true;
            }
            String normalizedLanguage = WSWillContextResolverHelper.normalizePreferredLanguage(item.req.language);
            if (!String.isBlank(normalizedLanguage) && existingMeu.Language != normalizedLanguage) {
                meuUpdate.Language = normalizedLanguage;
                hasMeuChanges = true;
            }

            if (hasMeuChanges) {
                endUsersToUpdate.add(meuUpdate);
            }
        }

        if (!endUsersToUpdate.isEmpty() && !bypassConversationWriteBack) {
            Database.update(endUsersToUpdate, false);
        }

        List<Case> casesToInsert = new List<Case>();
        List<WorkItem> caseItems = new List<WorkItem>();

        resolveOwnershipTargets(workItems);

        for (WorkItem item : workItems) {
            if (item == null || item.res == null) continue;
            if (String.isBlank(item.recordTypeErrorMessage)) continue;
            item.res.success = false;
            item.res.statusCode = 'CONFIG_ERROR';
            item.res.message = item.recordTypeErrorMessage;
        }

        for (WorkItem item : workItems) {
            if (!item.canProceed || !String.isBlank(item.recordTypeErrorMessage)) continue;
            WSWillCaseCreationDTO.Request req = item.req;

            Case c = new Case();
            Map<String, Schema.SObjectField> caseFields = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
            putIfCreateable(c, caseFields, 'RecordTypeId', item.targetRecordTypeId);
            putIfCreateable(c, caseFields, 'AccountId', item.resolvedAccountId);
            putIfCreateable(c, caseFields, 'ContactId', item.resolvedContactId);
            putIfCreateable(c, caseFields, 'Representante__c', item.representativeAccountId);
            putIfCreateable(c, caseFields, 'Origin', item.normalizedOrigin);
            putIfValidPicklist(c, caseFields, 'OrigemDistribuicao__c', WSWillCaseCreationHelper.normalizeDistributionOrigin());
            putIfCreateable(c, caseFields, 'Subject', String.isBlank(req.caseType) ? 'Atendimento via Will' : req.caseType);
            putIfCreateable(c, caseFields, 'Description', req.description);
            putIfValidPicklist(c, caseFields, 'UnidadeNegocio__c', item.resolvedBusinessUnitName);
            putIfCreateable(c, caseFields, 'IdiomaAtendimento__c', WSWillCaseCreationHelper.normalizeLanguageForCase(req.language));
            putIfValidPicklist(c, caseFields, 'TipoCaso__c', req.caseType);
            putIfCreateable(c, caseFields, 'SuppliedName', req.customerFullName);
            putIfCreateable(c, caseFields, 'SuppliedEmail', req.customerEmail);
            putIfCreateable(c, caseFields, 'SuppliedPhone', req.customerPhone);
            putIfCreateable(c, caseFields, 'Status', 'Aberto');
            putIfCreateable(c, caseFields, 'OwnerId', item.targetOwnerId);
            if (!String.isBlank(item.targetQueueDeveloperName)) {
                putIfCreateable(c, caseFields, 'FilaDestinoDeveloperName__c', item.targetQueueDeveloperName);
            }
            if (item.targetQueueId != null) {
                putIfCreateable(c, caseFields, 'FilaDestinoId__c', String.valueOf(item.targetQueueId));
            }

            item.pendingCase = c;
            casesToInsert.add(c);
            caseItems.add(item);
        }

        if (!casesToInsert.isEmpty()) {
            Database.SaveResult[] caseResults = Database.insert(casesToInsert, false);
            for (Integer i = 0; i < caseItems.size(); i++) {
                WorkItem item = caseItems[i];
                Database.SaveResult sr = caseResults[i];
                if (sr.isSuccess()) {
                    item.pendingCase.Id = sr.getId();
                    Case createdCase = WSWillCaseCreationSelector.selectCasesById(new Set<Id>{ sr.getId() }).get(sr.getId());
                    item.res.success = true;
                    item.res.caseId = createdCase.Id;
                    item.res.caseNumber = createdCase.CaseNumber;
                    if (String.isBlank(item.contactErrorMessage) && String.isBlank(item.queueErrorMessage)) {
                        item.res.statusCode = 'SUCCESS';
                        item.res.message = 'Caso criado com sucesso.';
                    } else if (!String.isBlank(item.contactErrorMessage) && !String.isBlank(item.queueErrorMessage)) {
                        item.res.statusCode = 'SUCCESS_WITH_WARNINGS';
                        item.res.message = 'Caso criado com sucesso, mas houve pendencias: contato nao foi criado; fila nao foi aplicada.';
                    } else {
                        item.res.statusCode = String.isBlank(item.contactErrorMessage) ? 'SUCCESS_WITHOUT_QUEUE' : 'SUCCESS_WITHOUT_CONTACT';
                        item.res.message = String.isBlank(item.contactErrorMessage)
                            ? 'Caso criado com sucesso, mas fila nao foi aplicada: ' + item.queueErrorMessage
                            : 'Caso criado com sucesso, mas contato nao foi criado: ' + item.contactErrorMessage;
                    }
                } else {
                    item.res.success = false;
                    item.res.statusCode = 'CASE_CREATION_ERROR';
                    item.res.message = sr.getErrors().isEmpty() ? 'Falha ao criar caso.' : sr.getErrors()[0].getMessage();
                }
            }
        }

        List<SObject> caseLinkUpdates = new List<SObject>();
        for (WorkItem item : caseItems) {
            if (item.res.caseId == null) continue;
            if (item.messagingSessionId != null) {
                caseLinkUpdates.add(new MessagingSession(Id = item.messagingSessionId, CaseId = item.res.caseId));
            }
            if (item.liveChatTranscriptId != null) {
                caseLinkUpdates.add(new LiveChatTranscript(Id = item.liveChatTranscriptId, CaseId = item.res.caseId));
            }
        }
        if (!caseLinkUpdates.isEmpty() && !bypassConversationWriteBack) {
            update caseLinkUpdates;
        }

        Map<Integer, WSWillCaseCreationDTO.Response> responseByIndex = new Map<Integer, WSWillCaseCreationDTO.Response>();
        for (WorkItem item : workItems) {
            responseByIndex.put(item.index, item.res);
        }
        for (Integer idx = 0; idx < requests.size(); idx++) {
            out.add(responseByIndex.get(idx));
        }

        return out;
    }

    private static void resolveOwnershipTargets(List<WorkItem> workItems) {
        Set<String> requestedQueueDevNames = new Set<String>();
        List<AtendimentoConfigDTO> unitConfigs = fetchActiveUnitConfigs();
        List<AtendimentoConfigDTO> channelConfigs = fetchActiveChannelConfigs();
        Map<String, Schema.RecordTypeInfo> caseRecordTypesByDeveloperName = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getRecordTypeInfosByDeveloperName();

        for (WorkItem item : workItems) {
            if (item == null || item.req == null) continue;

            String channelBusinessUnitName = resolveBusinessUnitFromAtendimentoParams(item.req, channelConfigs);
            item.resolvedBusinessUnitName = channelBusinessUnitName;
            if (String.isBlank(channelBusinessUnitName)) {
                item.resolvedBusinessUnitName = item.req.businessUnitName;
            }

            AtendimentoConfigDTO cfg = resolveUnitConfig(item.resolvedBusinessUnitName, unitConfigs);
            if (String.isBlank(channelBusinessUnitName) && cfg != null && !String.isBlank(cfg.businessUnit)) {
                item.resolvedBusinessUnitName = cfg.businessUnit;
            }
            item.normalizedOrigin = WSWillCaseCreationHelper.normalizeOrigin(item.req.origin, item.req.channelName);

            if (cfg != null && !String.isBlank(cfg.caseRecordTypeDeveloperName)) {
                item.targetRecordTypeDeveloperName = resolveCaseRecordTypeDeveloperName(cfg);
                Schema.RecordTypeInfo rti = caseRecordTypesByDeveloperName.get(item.targetRecordTypeDeveloperName);
                if (rti != null) {
                    item.targetRecordTypeId = rti.getRecordTypeId();
                } else {
                    item.recordTypeErrorMessage = 'Record type nao encontrado ou nao habilitado para Case: ' + item.targetRecordTypeDeveloperName;
                }
            } else {
                item.recordTypeErrorMessage = 'Record type nao configurado para a unidade de negocio informada.';
            }

            if (!String.isBlank(item.recordTypeErrorMessage)) {
                item.canProceed = false;
            }

            if (item.normalizedOrigin == 'Bot') {
                item.targetQueueDeveloperName = cfg == null ? null : cfg.defaultQueueDeveloperName;
                if (String.isBlank(item.targetQueueDeveloperName)) {
                    item.targetQueueDeveloperName = resolveQueueDeveloperName(item.resolvedBusinessUnitName, unitConfigs);
                }
                if (!String.isBlank(item.targetQueueDeveloperName)) {
                    requestedQueueDevNames.add(item.targetQueueDeveloperName);
                } else {
                    item.queueErrorMessage = 'Fila nao configurada para a unidade de negocio informada.';
                }
            } else {
                item.targetOwnerId = UserInfo.getUserId();
            }
        }

        QueueLookupResult queueLookup = fetchCaseQueueLookup(requestedQueueDevNames);
        for (WorkItem item : workItems) {
            if (item == null || item.req == null || item.normalizedOrigin != 'Bot' || String.isBlank(item.targetQueueDeveloperName)) continue;

            Id queueId = queueLookup.idByDeveloperName.get(item.targetQueueDeveloperName);
            if (queueId == null) {
                item.queueErrorMessage = 'Fila nao encontrada ou nao habilitada para Case: ' + item.targetQueueDeveloperName;
            } else {
                item.targetQueueId = queueId;
                item.targetOwnerId = queueId;
            }
        }
    }

    private static AtendimentoConfigDTO resolveUnitConfig(String businessUnitName, List<AtendimentoConfigDTO> unitConfigs) {
        if (String.isBlank(businessUnitName) || unitConfigs == null) return null;

        String normalizedBusinessUnit = normalizeKey(businessUnitName);
        for (AtendimentoConfigDTO cfg : unitConfigs) {
            if (cfg == null || cfg.isActive != true) continue;
            if (matchesBusinessUnit(normalizedBusinessUnit, cfg)) return cfg;
        }
        return null;
    }

    private static String resolveQueueDeveloperName(String businessUnitName, List<AtendimentoConfigDTO> unitConfigs) {
        if (String.isBlank(businessUnitName) || unitConfigs == null) return null;

        String normalizedBusinessUnit = normalizeKey(businessUnitName);
        for (AtendimentoConfigDTO cfg : unitConfigs) {
            if (cfg == null || cfg.isActive != true || String.isBlank(cfg.defaultQueueDeveloperName)) continue;
            if (matchesBusinessUnit(normalizedBusinessUnit, cfg)) {
                return cfg.defaultQueueDeveloperName.trim();
            }
        }

        return null;
    }

    private static Boolean matchesBusinessUnit(String normalizedBusinessUnit, AtendimentoConfigDTO cfg) {
        if (String.isBlank(normalizedBusinessUnit) || cfg == null) return false;

        for (String candidate : new List<String>{
            cfg.businessUnit,
            cfg.caseRecordTypeDeveloperName,
            cfg.developerName,
            cfg.masterLabel
        }) {
            String normalizedCandidate = normalizeKey(candidate);
            if (String.isBlank(normalizedCandidate)) continue;
            if (normalizedBusinessUnit == normalizedCandidate) return true;
            if (normalizedBusinessUnit.contains(normalizedCandidate) || normalizedCandidate.contains(normalizedBusinessUnit)) return true;
        }
        return false;
    }

    private static String resolveCaseRecordTypeDeveloperName(AtendimentoConfigDTO cfg) {
        return cfg.caseRecordTypeDeveloperName.trim();
    }

    private static List<AtendimentoConfigDTO> fetchActiveUnitConfigs() {
        if (Test.isRunningTest() && testUnitConfigs != null) return testUnitConfigs;
        return AtendimentoConfigService.getActiveConfigs();
    }

    private static List<AtendimentoConfigDTO> fetchActiveChannelConfigs() {
        if (Test.isRunningTest() && testChannelConfigs != null) return testChannelConfigs;
        return AtendimentoConfigService.getActiveConfigs();
    }

    private static String resolveBusinessUnitFromAtendimentoParams(
        WSWillCaseCreationDTO.Request req,
        List<AtendimentoConfigDTO> channelConfigs
    ) {
        if (req == null || channelConfigs == null || channelConfigs.isEmpty()) return null;

        String normalizedChannel = normalizeKey(req.channelName);
        String normalizedBusinessUnit = normalizeKey(req.businessUnitName);

        for (AtendimentoConfigDTO cfg : channelConfigs) {
            if (!isUsableChannelConfig(cfg)) continue;
            if (matchesChannel(normalizedChannel, cfg)) return cfg.businessUnit.trim();
        }

        for (AtendimentoConfigDTO cfg : channelConfigs) {
            if (!isUsableChannelConfig(cfg)) continue;
            String cfgBusinessUnit = normalizeKey(cfg.businessUnit);
            if (String.isBlank(normalizedBusinessUnit) || String.isBlank(cfgBusinessUnit)) continue;
            if (normalizedBusinessUnit == cfgBusinessUnit) return cfg.businessUnit.trim();
            if (normalizedBusinessUnit.contains(cfgBusinessUnit) || cfgBusinessUnit.contains(normalizedBusinessUnit)) {
                return cfg.businessUnit.trim();
            }
        }

        return null;
    }

    private static Boolean isUsableChannelConfig(AtendimentoConfigDTO cfg) {
        return cfg != null && cfg.isActive == true && !String.isBlank(cfg.businessUnit);
    }

    private static Boolean matchesChannel(String normalizedChannel, AtendimentoConfigDTO cfg) {
        if (String.isBlank(normalizedChannel) || cfg == null) return false;
        for (String candidate : new List<String>{ cfg.messagingChannelDeveloperName, cfg.whatsAppChannelDeveloperName, cfg.developerName }) {
            String normalizedCandidate = normalizeKey(candidate);
            if (String.isBlank(normalizedCandidate)) continue;
            if (normalizedChannel == normalizedCandidate) return true;
        }
        return false;
    }

    private static QueueLookupResult fetchCaseQueueLookup(Set<String> developerNames) {
        QueueLookupResult out = new QueueLookupResult();
        if (developerNames == null || developerNames.isEmpty()) return out;

        for (QueueSobject queueObject : WSWillCaseCreationSelector.selectCaseQueuesBySobjectType()) {
            if (queueObject.Queue == null || String.isBlank(queueObject.Queue.DeveloperName)) continue;

            String developerName = queueObject.Queue.DeveloperName;
            if (developerNames != null && developerNames.contains(developerName)) {
                out.idByDeveloperName.put(developerName, queueObject.QueueId);
            }
        }
        return out;
    }

    private static String normalizeKey(String value) {
        return String.isBlank(value) ? null : value.trim().toLowerCase();
    }

    private static void applyResolvedContactAccounts(WorkItem item, Contact resolvedContact) {
        if (item == null || resolvedContact == null) return;

        Id representedAccountId = null;
        try {
            representedAccountId = (Id) resolvedContact.get('ContaRepresentadaAtual__c');
        } catch (Exception ex) {
            representedAccountId = null;
        }
        if (representedAccountId != null) {
            item.resolvedAccountId = representedAccountId;
            item.res.accountId = representedAccountId;
            if (resolvedContact.AccountId != null && resolvedContact.AccountId != representedAccountId) {
                item.representativeAccountId = resolvedContact.AccountId;
            }
            return;
        }

        if (resolvedContact.AccountId != null) {
            item.resolvedAccountId = resolvedContact.AccountId;
            item.res.accountId = resolvedContact.AccountId;
        }
    }

    private static Map<Id, Contact> queryContactsByIds(Set<Id> contactIds, String representedAccountField) {
        Map<Id, Contact> out = new Map<Id, Contact>();
        if (contactIds == null || contactIds.isEmpty()) return out;

        List<String> selectFields = new List<String>{ 'Id', 'AccountId', 'Name', 'Email', 'Phone', 'Idioma__c' };
        if (!String.isBlank(representedAccountField) &&
            Schema.SObjectType.Contact.fields.getMap().containsKey(representedAccountField.toLowerCase())) {
            selectFields.add(representedAccountField);
        }

        String soql = 'SELECT ' + String.join(selectFields, ',') + ' FROM Contact WHERE Id IN :contactIds';
        List<Contact> rows;
        try {
            rows = (List<Contact>) Database.query(soql);
        } catch (QueryException ex) {
            if (!ex.getMessage().contains('ContaRepresentadaAtual__c')) {
                throw ex;
            }
            List<String> fallbackFields = new List<String>();
            for (String fieldName : selectFields) {
                if (fieldName != 'ContaRepresentadaAtual__c') {
                    fallbackFields.add(fieldName);
                }
            }
            rows = (List<Contact>) Database.query(
                'SELECT ' + String.join(fallbackFields, ',') + ' FROM Contact WHERE Id IN :contactIds'
            );
        }

        for (Contact row : rows) {
            out.put(row.Id, row);
        }
        return out;
    }

    private static List<Contact> queryContactsByEmails(Set<String> emails, String representedAccountField) {
        List<Contact> out = new List<Contact>();
        if (emails == null || emails.isEmpty()) return out;

        List<String> selectFields = new List<String>{ 'Id', 'AccountId', 'Name', 'Email', 'Phone', 'Idioma__c' };
        if (!String.isBlank(representedAccountField) &&
            Schema.SObjectType.Contact.fields.getMap().containsKey(representedAccountField.toLowerCase())) {
            selectFields.add(representedAccountField);
        }

        String soql = 'SELECT ' + String.join(selectFields, ',') + ' FROM Contact WHERE Email IN :emails';
        List<Contact> rows;
        try {
            rows = (List<Contact>) Database.query(soql);
        } catch (QueryException ex) {
            if (!ex.getMessage().contains('ContaRepresentadaAtual__c')) {
                throw ex;
            }
            List<String> fallbackFields = new List<String>();
            for (String fieldName : selectFields) {
                if (fieldName != 'ContaRepresentadaAtual__c') {
                    fallbackFields.add(fieldName);
                }
            }
            rows = (List<Contact>) Database.query(
                'SELECT ' + String.join(fallbackFields, ',') + ' FROM Contact WHERE Email IN :emails'
            );
        }

        for (Contact row : rows) {
            out.add(row);
        }
        return out;
    }

    private static void putIfCreateable(SObject row, Map<String, Schema.SObjectField> fieldMap, String fieldApiName, Object value) {
        if (value == null || String.isBlank(fieldApiName) || fieldMap == null || !fieldMap.containsKey(fieldApiName)) return;
        if (fieldMap.get(fieldApiName).getDescribe().isCreateable()) {
            row.put(fieldApiName, value);
        }
    }

    private static void putIfValidPicklist(SObject row, Map<String, Schema.SObjectField> fieldMap, String fieldApiName, String value) {
        if (String.isBlank(value) || String.isBlank(fieldApiName) || fieldMap == null || !fieldMap.containsKey(fieldApiName)) return;
        Schema.DescribeFieldResult d = fieldMap.get(fieldApiName).getDescribe();
        if (!d.isCreateable() || d.getType() != Schema.DisplayType.Picklist) return;

        for (Schema.PicklistEntry entry : d.getPicklistValues()) {
            if (CaseCreationHelper.sameNormalizedValue(entry.getValue(), value) || CaseCreationHelper.sameNormalizedValue(entry.getLabel(), value)) {
                row.put(fieldApiName, entry.getValue());
                return;
            }
        }
    }
}