/**
 * Helper and selector methods for the recurring Case schedule engine.
 */
public with sharing class CaseScheduleHelper {
    private static final Integer LOG_TEXT_LIMIT = 131000;

    /**
     * @param userIds User Ids referenced by schedules.
     * @return Active users by Id.
     */
    public static Map<Id, User> getActiveUsersById(Set<Id> userIds) {
        Map<Id, User> out = new Map<Id, User>();
        if (userIds == null || userIds.isEmpty()) {
            return out;
        }
        for (User row : [
            SELECT Id, Name
            FROM User
            WHERE Id IN :userIds
                AND IsActive = true
            WITH USER_MODE
        ]) {
            out.put(row.Id, row);
        }
        return out;
    }

    /**
     * @param developerNames Queue DeveloperNames referenced by schedules.
     * @return Queue groups by DeveloperName.
     */
    public static Map<String, Group> getQueuesByDeveloperName(Set<String> developerNames) {
        Map<String, Group> out = new Map<String, Group>();
        if (developerNames == null || developerNames.isEmpty()) {
            return out;
        }
        for (Group row : [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
                AND DeveloperName IN :developerNames
            WITH USER_MODE
        ]) {
            out.put(row.DeveloperName, row);
        }
        return out;
    }

    /**
     * @param queueIds Queue group Ids.
     * @return Queue Ids enabled for Case ownership.
     */
    public static Set<Id> getCaseEnabledQueueIds(Set<Id> queueIds) {
        Set<Id> out = new Set<Id>();
        if (queueIds == null || queueIds.isEmpty()) {
            return out;
        }
        for (QueueSobject row : [
            SELECT QueueId
            FROM QueueSobject
            WHERE QueueId IN :queueIds
                AND SobjectType = 'Case'
            WITH USER_MODE
        ]) {
            out.add(row.QueueId);
        }
        return out;
    }

    /**
     * @param developerNames Case Record Type DeveloperNames.
     * @return Active Case Record Types by DeveloperName.
     */
    public static Map<String, RecordType> getCaseRecordTypesByDeveloperName(Set<String> developerNames) {
        Map<String, RecordType> out = new Map<String, RecordType>();
        if (developerNames == null || developerNames.isEmpty()) {
            return out;
        }
        for (RecordType row : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Case'
                AND IsActive = true
                AND DeveloperName IN :developerNames
            WITH USER_MODE
        ]) {
            out.put(row.DeveloperName, row);
        }
        return out;
    }

    /**
     * @param scheduleIds Schedule Ids.
     * @param minWindowStart Earliest execution window start.
     * @param maxWindowEnd Latest execution window end.
     * @return Cases created for the supplied schedules within the broad window.
     */
    public static List<Case> getCasesCreatedForSchedules(Set<Id> scheduleIds, Datetime minWindowStart, Datetime maxWindowEnd) {
        if (scheduleIds == null || scheduleIds.isEmpty() || minWindowStart == null || maxWindowEnd == null) {
            return new List<Case>();
        }
        return [
            SELECT Id, Agendamento__c, CreatedDate
            FROM Case
            WHERE Agendamento__c IN :scheduleIds
                AND CreatedDate >= :minWindowStart
                AND CreatedDate <= :maxWindowEnd
            WITH USER_MODE
        ];
    }

    /**
     * @param records Log records represented dynamically to avoid hard dependency on local metadata.
     */
    public static void insertIntegrationLogs(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        Schema.SObjectType logType = Schema.getGlobalDescribe().get('LogIntegracao__c');
        if (logType == null || !logType.getDescribe().isCreateable()) {
            return;
        }
        Database.insert(records, false, AccessLevel.USER_MODE);
    }

    /**
     * @param schedule Schedule related to the failure.
     * @param technicalMessage Technical error detail.
     * @return Dynamic LogIntegracao__c row, or null when the object is unavailable.
     */
    public static SObject buildErrorLog(Agendamento__c schedule, String technicalMessage) {
        Schema.SObjectType logType = Schema.getGlobalDescribe().get('LogIntegracao__c');
        if (logType == null || !logType.getDescribe().isCreateable()) {
            return null;
        }
        SObject row = logType.newSObject();
        putIfFieldExists(row, 'Name', safeLeft('Motor Agendamento Case', 80));
        putIfFieldExists(row, 'MetodoCallout__c', 'CASE_SCHEDULE');
        putIfFieldExists(row, 'DescritivoErroLog__c', safeLeft(technicalMessage, 255));
        putIfFieldExists(row, 'ComentariosObservacoes__c', safeLeft(buildLogDetail(schedule, technicalMessage), LOG_TEXT_LIMIT));
        putIfFieldExists(row, 'Endpoint__c', 'CaseScheduleService');
        if (schedule != null) {
            putIfFieldExists(row, 'ObjetoRelacionamento__c', 'Agendamento__c');
            putIfFieldExists(row, 'IdRelacionamento__c', String.valueOf(schedule.Id));
        }
        return row;
    }

    /**
     * @param row Target sObject.
     * @param fieldApiName Field API name.
     * @param value Value to put when the field exists.
     */
    public static void putIfFieldExists(SObject row, String fieldApiName, Object value) {
        if (row == null || String.isBlank(fieldApiName)) {
            return;
        }
        Map<String, Schema.SObjectField> fields = row.getSObjectType().getDescribe().fields.getMap();
        if (fields.containsKey(fieldApiName) && fields.get(fieldApiName).getDescribe().isCreateable()) {
            row.put(fieldApiName, value);
        }
    }

    /**
     * @param value Text to trim.
     * @param maxLength Maximum length.
     * @return Safely trimmed text.
     */
    public static String safeLeft(String value, Integer maxLength) {
        if (value == null || maxLength == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    private static String buildLogDetail(Agendamento__c schedule, String technicalMessage) {
        List<String> lines = new List<String>();
        lines.add('Erro: ' + technicalMessage);
        if (schedule != null) {
            lines.add('Agendamento: ' + schedule.Id);
            lines.add('Nome: ' + schedule.Name);
            lines.add('Conta: ' + schedule.Conta__c);
            lines.add('Unidade: ' + schedule.UnidadeNegocio__c);
            lines.add('Frequencia: ' + schedule.Frequencia__c);
        }
        return String.join(lines, '\n');
    }
}