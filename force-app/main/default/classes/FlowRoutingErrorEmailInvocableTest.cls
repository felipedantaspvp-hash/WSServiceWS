/**
 * @description       : Testes unitários de FlowRoutingErrorEmailInvocable.
 * @author            : Triscal
 * @group             : Flow
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class FlowRoutingErrorEmailInvocableTest {
    @IsTest
    static void shouldSendEmailWhenRequestIsValid() {
        FlowRoutingErrorEmailInvocable.Request requestItem = new FlowRoutingErrorEmailInvocable.Request();
        requestItem.toAddress = 'mnascimento@triscal.com.br';
        requestItem.subject = 'Test Subject';
        requestItem.body = 'Test Body';

        Test.startTest();
        FlowRoutingErrorEmailInvocable.sendEmail(new List<FlowRoutingErrorEmailInvocable.Request>{ requestItem });
        Test.stopTest();

        Assert.areEqual(0, Limits.getEmailInvocations());
    }

    @IsTest
    static void shouldNotSendEmailWhenAddressIsBlank() {
        FlowRoutingErrorEmailInvocable.Request requestItem = new FlowRoutingErrorEmailInvocable.Request();
        requestItem.toAddress = ' ';
        requestItem.subject = 'Test Subject';
        requestItem.body = 'Test Body';

        Test.startTest();
        FlowRoutingErrorEmailInvocable.sendEmail(new List<FlowRoutingErrorEmailInvocable.Request>{ requestItem });
        Test.stopTest();

        Assert.areEqual(0, Limits.getEmailInvocations());
    }
}