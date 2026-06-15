public class GestaoSLAHealthCheckDTO {

    public class HealthCheckResult {
        public Datetime executionDateTime;
        public Integer totalChecks;
        public Integer totalIssues;
        public Integer totalCritical;
        public Integer totalHigh;
        public Integer totalMedium;
        public Integer totalLow;
        public Integer totalInfo;
        public List<Issue> issues;

        public HealthCheckResult() {
            this.totalChecks    = 0;
            this.totalIssues    = 0;
            this.totalCritical  = 0;
            this.totalHigh      = 0;
            this.totalMedium    = 0;
            this.totalLow       = 0;
            this.totalInfo      = 0;
            this.issues         = new List<Issue>();
        }
    }

    public class Issue {
        public String severity;
        public String category;
        public String objectApiName;
        public Id     recordId;
        public String recordName;
        public String ruleCode;
        public String message;
        public String recommendation;
    }
}
