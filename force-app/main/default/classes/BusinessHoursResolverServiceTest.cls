/**
 * @description       : Testes unitários de BusinessHoursResolverService.
 * @author            : Triscal
 * @group             : Business Hours
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class BusinessHoursResolverServiceTest {
    @IsTest
    static void testInjectedResolver() {
        Id fake = UserInfo.getUserId();
        BusinessHoursResolverService.injectedByName.put('Tecon Salvador', fake);
        Id outId = BusinessHoursResolverService.resolveActiveByName('Tecon Salvador');
        Assert.areEqual(fake, outId);
    }
}