/**
 * Query and mapping helper for Account case schedule operations.
 */
public with sharing class AccountCaseScheduleHelper {
    private static final String AGENDAMENTO_OBJECT_API = 'Agendamento__c';

    /**
     * @return The API name of the existing schedule object used by this feature.
     */
    public static String getAgendamentoObjectApiName() {
        return AGENDAMENTO_OBJECT_API;
    }

    /**
     * @param accountId Account Id to query.
     * @return Account with fields required by the component.
     */
    public static Account getAccount(Id accountId) {
        List<Account> rows = [
            SELECT Id, Name
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    /**
     * @param accountId Account Id used as parent filter.
     * @return Schedule records related to the supplied Account.
     */
    public static List<Agendamento__c> getSchedulesByAccount(Id accountId) {
        return [
            SELECT Id, Name, Ativo__c, Conta__c, UnidadeNegocio__c, RecordTypeId,
                RecordType.DeveloperName, TipoCaso__c, Categoria__c, Assunto__c,
                Subassunto__c, Frequencia__c, DiasDaSemana__c, HorarioExecucao__c, DataInicio__c,
                PularFimDeSemana__c, DescricaoAtividade__c, OwnerType__c,
                OwnerUser__c, OwnerUser__r.Name, OwnerQueueDeveloperName__c,
                OwnerId, Owner.Name, UltimoErroExecucao__c,
                UltimaExecucao__c, ProximaExecucao__c,
                toLabel(UnidadeNegocio__c) UnidadeNegocioLabel,
                toLabel(TipoCaso__c) TipoCasoLabel,
                toLabel(Categoria__c) CategoriaLabel,
                toLabel(Assunto__c) AssuntoLabel,
                toLabel(Subassunto__c) SubassuntoLabel,
                toLabel(Frequencia__c) FrequenciaLabel,
                toLabel(OwnerType__c) OwnerTypeLabel
            FROM Agendamento__c
            WHERE Conta__c = :accountId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    /**
     * @param scheduleId Schedule Id.
     * @return Schedule record or null.
     */
    public static Agendamento__c getScheduleById(Id scheduleId) {
        List<Agendamento__c> rows = [
            SELECT Id, Conta__c, RecordTypeId, RecordType.DeveloperName
            FROM Agendamento__c
            WHERE Id = :scheduleId
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    /**
     * @param developerName Record Type DeveloperName.
     * @return Matching Agendamento record type Id.
     */
    public static Id getScheduleRecordTypeId(String developerName) {
        if (String.isBlank(developerName)) return null;
        List<RecordType> rows = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Agendamento__c'
                AND IsActive = true
                AND DeveloperName = :developerName
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0].Id;
    }

    /**
     * @param developerName Queue DeveloperName.
     * @return Queue group when enabled for Case, otherwise null.
     */
    public static Group getCaseQueueByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) return null;
        List<Group> groups = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
                AND DeveloperName = :developerName
            WITH USER_MODE
            LIMIT 1
        ];
        if (groups.isEmpty()) return null;

        List<QueueSobject> enabled = [
            SELECT QueueId
            FROM QueueSobject
            WHERE QueueId = :groups[0].Id
                AND SobjectType = 'Case'
            WITH USER_MODE
            LIMIT 1
        ];
        return enabled.isEmpty() ? null : groups[0];
    }

    /**
     * @param queueId Queue Id.
     * @return True when the queue can own Agendamento__c records.
     */
    public static Boolean isScheduleQueueEnabled(Id queueId) {
        if (queueId == null) return false;
        return ![
            SELECT Id
            FROM QueueSobject
            WHERE QueueId = :queueId
                AND SobjectType = 'Agendamento__c'
            WITH USER_MODE
            LIMIT 1
        ].isEmpty();
    }

    /**
     * @param userId User Id.
     * @return Active user or null.
     */
    public static User getActiveUser(Id userId) {
        if (userId == null) return null;
        List<User> rows = [
            SELECT Id, Name
            FROM User
            WHERE Id = :userId
                AND IsActive = true
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    /**
     * @param searchTerm User name search term.
     * @return Active users matching the supplied term.
     */
    public static List<User> searchActiveUsers(String searchTerm) {
        String term = String.isBlank(searchTerm) ? '%' : '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
                AND Name LIKE :term
            WITH USER_MODE
            ORDER BY Name
            LIMIT 20
        ];
    }

    /**
     * @param row Schedule sObject.
     * @return LWC-facing DTO.
     */
    public static AccountCaseScheduleDTO.ScheduleDTO toScheduleDTO(Agendamento__c row) {
        AccountCaseScheduleDTO.ScheduleDTO dto = new AccountCaseScheduleDTO.ScheduleDTO();
        dto.id = row.Id;
        dto.name = row.Name;
        dto.ativo = row.Ativo__c;
        dto.unidadeNegocio = row.UnidadeNegocio__c;
        dto.unidadeNegocioLabel = getLabelOrFieldValue(row, 'UnidadeNegocioLabel', 'UnidadeNegocio__c');
        dto.recordTypeId = row.RecordTypeId;
        dto.recordTypeDeveloperName = row.RecordType == null ? null : row.RecordType.DeveloperName;
        dto.tipoCaso = row.TipoCaso__c;
        dto.tipoCasoLabel = getLabelOrFieldValue(row, 'TipoCasoLabel', 'TipoCaso__c');
        dto.categoria = row.Categoria__c;
        dto.categoriaLabel = getLabelOrFieldValue(row, 'CategoriaLabel', 'Categoria__c');
        dto.assunto = row.Assunto__c;
        dto.assuntoLabel = getLabelOrFieldValue(row, 'AssuntoLabel', 'Assunto__c');
        dto.subassunto = row.Subassunto__c;
        dto.subassuntoLabel = getLabelOrFieldValue(row, 'SubassuntoLabel', 'Subassunto__c');
        dto.frequencia = row.Frequencia__c;
        dto.frequenciaLabel = getLabelOrFieldValue(row, 'FrequenciaLabel', 'Frequencia__c');
        dto.diasDaSemana = String.isBlank(row.DiasDaSemana__c) ? new List<String>() : row.DiasDaSemana__c.split(';');
        dto.horarioExecucao = formatTime(row.HorarioExecucao__c);
        dto.dataInicio = row.DataInicio__c;
        dto.pularFimDeSemana = row.PularFimDeSemana__c;
        dto.descricaoAtividade = row.DescricaoAtividade__c;
        dto.ownerType = row.OwnerType__c;
        dto.ownerTypeLabel = getLabelOrFieldValue(row, 'OwnerTypeLabel', 'OwnerType__c');
        dto.ownerUserId = row.OwnerUser__c;
        dto.ownerUserName = row.OwnerUser__r == null ? null : row.OwnerUser__r.Name;
        dto.ownerQueueDeveloperName = row.OwnerQueueDeveloperName__c;
        dto.ownerDisplay = row.Owner == null ? null : row.Owner.Name;
        dto.ultimoErroExecucao = row.UltimoErroExecucao__c;
        dto.ultimaExecucao = row.UltimaExecucao__c;
        dto.proximaExecucao = row.ProximaExecucao__c;
        return dto;
    }

    /**
     * @param fieldDescribe Picklist field describe.
     * @return Active picklist options.
     */
    public static List<AccountCaseScheduleDTO.OptionDTO> toOptions(Schema.DescribeFieldResult fieldDescribe) {
        List<AccountCaseScheduleDTO.OptionDTO> out = new List<AccountCaseScheduleDTO.OptionDTO>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (!entry.isActive()) continue;
            AccountCaseScheduleDTO.OptionDTO option = new AccountCaseScheduleDTO.OptionDTO();
            option.label = entry.getLabel();
            option.value = entry.getValue();
            out.add(option);
        }
        return out;
    }

    /**
     * @param businessUnitName Business unit value or alias.
     * @return Canonical value accepted by Agendamento__c.UnidadeNegocio__c.
     */
    public static String normalizeScheduleBusinessUnit(String businessUnitName) {
        if (String.isBlank(businessUnitName)) return null;
        String normalizedInput = CaseCreationHelper.normalizeText(businessUnitName);
        String caseCanonical = CaseCreationSelector.resolveCanonicalBusinessUnit(businessUnitName);
        String normalizedCaseCanonical = CaseCreationHelper.normalizeText(caseCanonical);
        for (Schema.PicklistEntry entry : Agendamento__c.UnidadeNegocio__c.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) continue;
            String normalizedEntry = CaseCreationHelper.normalizeText(entry.getValue());
            if (normalizedEntry == normalizedInput || normalizedEntry == normalizedCaseCanonical) return entry.getValue();
            if (!String.isBlank(normalizedInput) && normalizedEntry.contains(normalizedInput)) return entry.getValue();
            if (!String.isBlank(normalizedCaseCanonical) && normalizedEntry.contains(normalizedCaseCanonical)) return entry.getValue();
        }
        return businessUnitName.trim();
    }

    private static String formatTime(Time value) {
        if (value == null) return null;
        String hour = String.valueOf(value.hour()).leftPad(2, '0');
        String minute = String.valueOf(value.minute()).leftPad(2, '0');
        return hour + ':' + minute;
    }

    private static String getLabelOrFieldValue(SObject row, String labelAlias, String fieldApiName) {
        Map<String, Object> populated = row.getPopulatedFieldsAsMap();
        if (populated.containsKey(labelAlias) && populated.get(labelAlias) != null) return (String) populated.get(labelAlias);
        return (String) row.get(fieldApiName);
    }
}