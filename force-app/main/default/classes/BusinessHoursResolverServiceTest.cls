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