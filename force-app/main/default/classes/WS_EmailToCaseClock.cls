/**
 * @description       : Classe do modulo Email-to-Case no padrao Triscal.
 * @author            : Triscal Salesforce Team
 * @group             :
 * @last modified on  : 05-19-2026
 * @last modified by  : jduarte@wilsonsons.com.br.service
**/
public virtual inherited sharing class WS_EmailToCaseClock {
    @TestVisible
    private static WS_EmailToCaseClock testClock;

    public virtual Datetime now() {
        return System.now();
    }

    public static WS_EmailToCaseClock get() {
        if (Test.isRunningTest() && testClock != null) {
            return testClock;
        }
        return new WS_EmailToCaseClock();
    }

    @TestVisible
    static void setTestClock(WS_EmailToCaseClock clock) {
        testClock = clock;
    }

    @TestVisible
    static void clearTestClock() {
        testClock = null;
    }
}