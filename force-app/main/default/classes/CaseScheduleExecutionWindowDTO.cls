/**
 * DTO that describes the idempotency window for one recurring Case schedule execution.
 */
public with sharing class CaseScheduleExecutionWindowDTO {
    public Id scheduleId;
    public Date windowStartDate;
    public Date windowEndDate;
    public String frequency;
    public String executionKey;

    /**
     * @return Start of the window as a Datetime in the running user's timezone.
     */
    public Datetime startDateTime() {
        return Datetime.newInstance(windowStartDate, Time.newInstance(0, 0, 0, 0));
    }

    /**
     * @return End of the window as a Datetime in the running user's timezone.
     */
    public Datetime endDateTime() {
        return Datetime.newInstance(windowEndDate, Time.newInstance(23, 59, 59, 999));
    }
}