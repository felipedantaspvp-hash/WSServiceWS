@IsTest
private class EmailDispatchHelperTest {
    @IsTest
    static void returnsSuccessWhenTestSkipIsEnabled() {
        Test.startTest();
        Boolean success = EmailDispatchHelper.isEmailSuccess(
            0,
            new List<Messaging.SendEmailResult>(),
            true,
            null
        );
        Test.stopTest();

        Assert.areEqual(true, success, 'O helper deve simular sucesso quando o teste pula efeitos externos.');
    }

    @IsTest
    static void returnsFailureWhenTestErrorExists() {
        Test.startTest();
        Boolean success = EmailDispatchHelper.isEmailSuccess(
            0,
            new List<Messaging.SendEmailResult>(),
            false,
            new Map<Integer, String>{ 0 => 'INVALID_ID_FIELD: Template inválido.' }
        );
        Test.stopTest();

        Assert.areEqual(false, success, 'O helper deve tratar índice com erro simulado como falha.');
    }

    @IsTest
    static void buildsMessageFromTestErrorMap() {
        Test.startTest();
        String message = EmailDispatchHelper.buildEmailErrorMessage(
            0,
            new List<Messaging.SendEmailResult>(),
            new Map<Integer, String>{ 0 => 'INVALID_ID_FIELD: Template inválido.' }
        );
        Test.stopTest();

        Assert.areEqual(
            'Erro ao enviar e-mail: INVALID_ID_FIELD: Template inválido.',
            message,
            'O helper deve reutilizar a mensagem simulada em testes.'
        );
    }

    @IsTest
    static void returnsSuccessFromPlatformResultWhenNotUsingTestOverrides() {
        List<Messaging.SendEmailResult> emailResults =
            (List<Messaging.SendEmailResult>) JSON.deserialize(
                '[{"success":true}]',
                List<Messaging.SendEmailResult>.class
            );

        Test.startTest();
        Boolean success = EmailDispatchHelper.isEmailSuccess(
            0,
            emailResults,
            false,
            null
        );
        Test.stopTest();

        Assert.areEqual(true, success, 'O helper deve respeitar o resultado real do Messaging.sendEmail.');
    }

    @IsTest
    static void buildsPrefixWhenPlatformResultHasNoDetailedErrors() {
        List<Messaging.SendEmailResult> emailResults =
            (List<Messaging.SendEmailResult>) JSON.deserialize(
                '[{"success":false}]',
                List<Messaging.SendEmailResult>.class
            );

        Test.startTest();
        String message = EmailDispatchHelper.buildEmailErrorMessage(
            0,
            emailResults,
            null
        );
        Test.stopTest();

        Assert.areEqual(
            'Erro ao enviar e-mail: ',
            message,
            'O helper deve manter o prefixo padrão mesmo quando o resultado real não trouxer detalhes de erro.'
        );
    }
}
