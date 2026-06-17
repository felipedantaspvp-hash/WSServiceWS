/**
 * @description       : Serviço de negócio para o módulo WSWillConversationLink. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-12-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillConversationLinkService {
    @TestVisible static Map<Id, Case> testCaseById;
    @TestVisible static Map<Id, MessagingSession> testMessagingById;
    @TestVisible static Map<Id, LiveChatTranscript> testLiveChatById;
    @TestVisible static Boolean bypassDmlInTests = false;
    @TestVisible static Boolean throwExceptionForTest = false;

    public static List<WSWillConversationLinkDTO.Response> link(List<WSWillConversationLinkDTO.Request> requests) {
        if (Test.isRunningTest() && throwExceptionForTest) {
            throw new IllegalArgumentException('Simulated exception for coverage');
        }
        List<WSWillConversationLinkDTO.Response> out = new List<WSWillConversationLinkDTO.Response>();
        if (requests == null || requests.isEmpty()) return out;

        Set<Id> caseIds = new Set<Id>();
        Set<Id> messagingIds = new Set<Id>();
        Set<Id> liveChatIds = new Set<Id>();

        for (WSWillConversationLinkDTO.Request req : requests) {
            Id convId = req == null ? null : (req.conversationId == null ? req.routableId : req.conversationId);
            String api = WSWillConversationLinkHelper.inferObjectApiName(convId);
            if (api == 'MessagingSession') messagingIds.add(convId);
            if (api == 'LiveChatTranscript') liveChatIds.add(convId);
            if (req != null && req.caseId != null) caseIds.add(req.caseId);
        }

        Map<Id, Case> caseById = testCaseById != null ? testCaseById : (caseIds.isEmpty() ? new Map<Id, Case>() : new Map<Id, Case>([
            SELECT Id
            FROM Case
            WHERE Id IN :caseIds
        ]));

        Map<Id, MessagingSession> messagingById = testMessagingById != null ? testMessagingById : (messagingIds.isEmpty() ? new Map<Id, MessagingSession>() : new Map<Id, MessagingSession>([
            SELECT Id, CaseId
            FROM MessagingSession
            WHERE Id IN :messagingIds
        ]));

        Map<Id, LiveChatTranscript> liveById = testLiveChatById != null ? testLiveChatById : (liveChatIds.isEmpty() ? new Map<Id, LiveChatTranscript>() : new Map<Id, LiveChatTranscript>([
            SELECT Id, CaseId
            FROM LiveChatTranscript
            WHERE Id IN :liveChatIds
        ]));

        List<SObject> updates = new List<SObject>();

        for (WSWillConversationLinkDTO.Request req : requests) {
            WSWillConversationLinkDTO.Response res = new WSWillConversationLinkDTO.Response();
            res.success = false;

            Id convId = req == null ? null : (req.conversationId == null ? req.routableId : req.conversationId);
            Id caseId = req == null ? null : req.caseId;
            if (convId == null) {
                res.statusCode = 'CONVERSATION_NOT_FOUND';
                res.message = 'Conversa não informada.';
                out.add(res);
                continue;
            }
            if (caseId == null || !caseById.containsKey(caseId)) {
                res.statusCode = 'CASE_NOT_FOUND';
                res.message = 'Caso não encontrado para vincular.';
                out.add(res);
                continue;
            }

            String api = WSWillConversationLinkHelper.inferObjectApiName(convId);
            if (api == 'MessagingSession') {
                MessagingSession ms = messagingById.get(convId);
                if (ms == null) {
                    res.statusCode = 'CONVERSATION_NOT_FOUND';
                    res.message = 'Messaging Session não encontrada.';
                } else {
                    ms.CaseId = caseId;
                    updates.add(ms);
                    res.success = true;
                    res.statusCode = 'SUCCESS';
                    res.message = 'Caso vinculado à Messaging Session.';
                }
            } else if (api == 'LiveChatTranscript') {
                LiveChatTranscript lct = liveById.get(convId);
                if (lct == null) {
                    res.statusCode = 'CONVERSATION_NOT_FOUND';
                    res.message = 'Live Chat Transcript não encontrado.';
                } else {
                    lct.CaseId = caseId;
                    updates.add(lct);
                    res.success = true;
                    res.statusCode = 'SUCCESS';
                    res.message = 'Caso vinculado ao Live Chat Transcript.';
                }
            } else {
                res.statusCode = 'UNSUPPORTED_CONVERSATION_OBJECT';
                res.message = 'Objeto de conversa não suportado para vínculo.';
            }

            out.add(res);
        }

        if (!updates.isEmpty() && !(Test.isRunningTest() && bypassDmlInTests)) {
            update updates;
        }

        return out;
    }
}