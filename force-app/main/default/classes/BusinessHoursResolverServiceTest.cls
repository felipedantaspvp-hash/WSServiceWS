@IsTest
private class BusinessHoursResolverServiceTest {
    @IsTest
    static void testInjectedResolver() {
        clearState();
        Id fake = UserInfo.getUserId();
        BusinessHoursResolverService.injectedByName.put('Tecon Salvador', fake);
        Id outId = BusinessHoursResolverService.resolveActiveByName('Tecon Salvador');
        Assert.areEqual(fake, outId);
    }

    @IsTest
    static void testResolveActiveByNameQueriesRealBusinessHours() {
        clearState();

        BusinessHours bh = [SELECT Id, Name FROM BusinessHours WHERE IsActive = true LIMIT 1];
        Id resolvedId = BusinessHoursResolverService.resolveActiveByName(bh.Name);

        Assert.areEqual(bh.Id, resolvedId);
        Assert.areEqual(bh.Id, BusinessHoursResolverService.cacheByName.get(bh.Name));
    }

    @IsTest
    static void testResolveActiveByNameThrowsWhenNameIsBlank() {
        clearState();

        try {
            BusinessHoursResolverService.resolveActiveByName('   ');
            Assert.fail('Deveria lançar exceção para nome em branco.');
        } catch (BusinessHoursResolverService.FunctionalException ex) {
            Assert.areEqual(true, ex.getMessage().contains('não informado'));
        }
    }

    @IsTest
    static void testResolveActiveByNameThrowsWhenNoActiveBusinessHoursExists() {
        clearState();

        try {
            BusinessHoursResolverService.resolveActiveByName('BH Resolver Missing');
            Assert.fail('Deveria lançar exceção quando não encontra Business Hours ativo.');
        } catch (BusinessHoursResolverService.FunctionalException ex) {
            Assert.areEqual(true, ex.getMessage().contains('Nenhum Business Hours ativo encontrado'));
        }
    }

    @IsTest
    static void testResolveActiveByNameThrowsWhenMoreThanOneActiveBusinessHoursExists() {
        clearState();
        BusinessHoursResolverService.injectedQueryRowsByName.put(
            'BH Resolver Duplicate',
            new List<BusinessHours>{
                new BusinessHours(Id = '01m000000000001AAA', Name = 'BH Resolver Duplicate', IsActive = true),
                new BusinessHours(Id = '01m000000000002AAA', Name = 'BH Resolver Duplicate', IsActive = true)
            }
        );

        try {
            BusinessHoursResolverService.resolveActiveByName('BH Resolver Duplicate');
            Assert.fail('Deveria lançar exceção quando encontra mais de um Business Hours ativo.');
        } catch (BusinessHoursResolverService.FunctionalException ex) {
            Assert.areEqual(true, ex.getMessage().contains('Mais de um Business Hours ativo encontrado'));
        }
    }

    private static void clearState() {
        BusinessHoursResolverService.injectedByName.clear();
        BusinessHoursResolverService.injectedQueryRowsByName.clear();
        BusinessHoursResolverService.cacheByName.clear();
    }
}
