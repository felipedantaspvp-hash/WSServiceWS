/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public inherited sharing class WS_EmailToCaseOwnerService {
    private Map<String, Id> queueOwnerCache = new Map<String, Id>();
    private Map<String, Id> userOwnerCache = new Map<String, Id>();

    public Id resolveOwnerId(WS_EmailToCaseRouteConfig route) {
        if (route == null) {
            throw new WS_EmailToCaseConfigException('Rota não informada para resolução de proprietário.');
        }
        if (route.ownerType == WS_EmailToCaseConstants.OWNER_TYPE_QUEUE) {
            return resolveQueueOwner(route.ownerKey);
        }
        if (route.ownerType == WS_EmailToCaseConstants.OWNER_TYPE_USER) {
            return resolveUserOwner(route.ownerKey);
        }
        throw new WS_EmailToCaseConfigException('Owner_Type__c inválido na rota ' + route.routeKey + ': ' + route.ownerType);
    }

    private Id resolveQueueOwner(String developerName) {
        if (String.isBlank(developerName)) {
            throw new WS_EmailToCaseConfigException('Owner_Key__c obrigatório para Owner_Type__c = QUEUE.');
        }
        String key = developerName.trim();
        if (queueOwnerCache.containsKey(key)) {
            return queueOwnerCache.get(key);
        }

        List<Group> groups = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = :key
            LIMIT 1
        ];
        if (groups.isEmpty()) {
            throw new WS_EmailToCaseConfigException('Fila não encontrada para Owner_Key__c: ' + key);
        }

        List<QueueSobject> queueCaseAccess = [
            SELECT Id
            FROM QueueSobject
            WHERE QueueId = :groups[0].Id
              AND SobjectType = 'Case'
            LIMIT 1
        ];
        if (queueCaseAccess.isEmpty()) {
            throw new WS_EmailToCaseConfigException('Fila ' + key + ' não está habilitada para o objeto Case.');
        }

        queueOwnerCache.put(key, groups[0].Id);
        return groups[0].Id;
    }

    private Id resolveUserOwner(String username) {
        if (String.isBlank(username)) {
            throw new WS_EmailToCaseConfigException('Owner_Key__c obrigatório para Owner_Type__c = USER.');
        }
        String key = username.trim().toLowerCase();
        if (userOwnerCache.containsKey(key)) {
            return userOwnerCache.get(key);
        }

        List<User> users = [
            SELECT Id, Username
            FROM User
            WHERE Username = :username
            LIMIT 1
        ];
        if (users.isEmpty()) {
            throw new WS_EmailToCaseConfigException('Usuário não encontrado para Owner_Key__c: ' + username);
        }

        userOwnerCache.put(key, users[0].Id);
        return users[0].Id;
    }
}
