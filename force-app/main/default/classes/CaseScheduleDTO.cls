/**
 * DTO that represents an Agendamento__c record during recurring Case generation.
 */
public with sharing class CaseScheduleDTO {
    public Id scheduleId;
    public Id accountId;
    public String scheduleName;
    public String businessUnit;
    public String caseType;
    public String category;
    public String subjectCategory;
    public String subSubject;
    public String description;
    public String frequency;
    public Time executionTime;
    public Date startDate;
    public Boolean skipWeekend;
    public String ownerType;
    public Id ownerUserId;
    public String ownerQueueDeveloperName;

    /**
     * @param schedule Source schedule.
     * @return DTO populated from Agendamento__c.
     */
    public static CaseScheduleDTO fromSchedule(Agendamento__c schedule) {
        CaseScheduleDTO out = new CaseScheduleDTO();
        if (schedule == null) {
            return out;
        }
        out.scheduleId = schedule.Id;
        out.accountId = schedule.Conta__c;
        out.scheduleName = schedule.Name;
        out.businessUnit = schedule.UnidadeNegocio__c;
        out.caseType = schedule.TipoCaso__c;
        out.category = schedule.Categoria__c;
        out.subjectCategory = schedule.Assunto__c;
        out.subSubject = schedule.Subassunto__c;
        out.description = schedule.DescricaoAtividade__c;
        out.frequency = schedule.Frequencia__c;
        out.executionTime = schedule.HorarioExecucao__c;
        out.startDate = schedule.DataInicio__c;
        out.skipWeekend = schedule.PularFimDeSemana__c;
        out.ownerType = schedule.OwnerType__c;
        out.ownerUserId = schedule.OwnerUser__c;
        out.ownerQueueDeveloperName = schedule.OwnerQueueDeveloperName__c;
        return out;
    }
}