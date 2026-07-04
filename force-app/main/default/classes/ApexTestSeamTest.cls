@IsTest
private class ApexTestSeamTest {
    @IsTest
    static void shouldReturnDefaultsWhenNoOverrideSet() {
        Test.startTest();
        Boolean flag = ApexTestSeam.getBoolean('ApexTestSeamTest.unset');
        Boolean nullable = ApexTestSeam.getNullableBoolean('ApexTestSeamTest.unset');
        Exception ex = ApexTestSeam.getException('ApexTestSeamTest.unset');
        Test.stopTest();

        Assert.areEqual(false, flag, 'getBoolean deve retornar false quando não há override.');
        Assert.areEqual(null, nullable, 'getNullableBoolean deve retornar null quando não há override.');
        Assert.areEqual(null, ex, 'getException deve retornar null quando não há override.');
    }

    @IsTest
    static void shouldReturnOverriddenValues() {
        ApexTestSeam.set('ApexTestSeamTest.flag', true);
        ApexTestSeam.set('ApexTestSeamTest.nullable', false);
        DmlException injected = new DmlException('erro forçado');
        ApexTestSeam.set('ApexTestSeamTest.exception', injected);

        Test.startTest();
        Boolean flag = ApexTestSeam.getBoolean('ApexTestSeamTest.flag');
        Boolean nullable = ApexTestSeam.getNullableBoolean('ApexTestSeamTest.nullable');
        Exception ex = ApexTestSeam.getException('ApexTestSeamTest.exception');
        Test.stopTest();

        Assert.areEqual(true, flag);
        Assert.areEqual(false, nullable);
        Assert.areEqual(injected, ex);

        ApexTestSeam.clear('ApexTestSeamTest.flag');
        ApexTestSeam.clear('ApexTestSeamTest.nullable');
        ApexTestSeam.clear('ApexTestSeamTest.exception');
        Assert.areEqual(false, ApexTestSeam.getBoolean('ApexTestSeamTest.flag'), 'clear deve remover o override.');
    }

    @IsTest
    static void shouldClearAllOverrides() {
        ApexTestSeam.set('ApexTestSeamTest.a', true);
        ApexTestSeam.set('ApexTestSeamTest.b', true);

        Test.startTest();
        ApexTestSeam.clearAll();
        Test.stopTest();

        Assert.areEqual(false, ApexTestSeam.getBoolean('ApexTestSeamTest.a'));
        Assert.areEqual(false, ApexTestSeam.getBoolean('ApexTestSeamTest.b'));
    }
}
