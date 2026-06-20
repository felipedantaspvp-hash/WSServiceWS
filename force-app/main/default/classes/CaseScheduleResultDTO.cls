/**
 * DTO returned by the recurring Case schedule engine for each processed schedule.
 */
public with sharing class CaseScheduleResultDTO {
    public Id scheduleId;
    public Boolean success;
    public Boolean skipped;
    public String message;
    public Id caseId;
    public String errorMessage;

    /**
     * @param scheduleId Agendamento__c Id.
     * @return Successful skipped result.
     */
    public static CaseScheduleResultDTO skipped(Id scheduleId, String message) {
        CaseScheduleResultDTO out = new CaseScheduleResultDTO();
        out.scheduleId = scheduleId;
        out.success = true;
        out.skipped = true;
        out.message = message;
        return out;
    }

    /**
     * @param scheduleId Agendamento__c Id.
     * @param errorMessage Functional error message.
     * @return Error result.
     */
    public static CaseScheduleResultDTO error(Id scheduleId, String errorMessage) {
        CaseScheduleResultDTO out = new CaseScheduleResultDTO();
        out.scheduleId = scheduleId;
        out.success = false;
        out.skipped = false;
        out.errorMessage = errorMessage;
        return out;
    }
}