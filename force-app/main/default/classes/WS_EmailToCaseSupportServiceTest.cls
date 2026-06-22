@IsTest
private class WS_EmailToCaseSupportServiceTest {
    @TestSetup
    static void setupData() {
        Group queue = new Group(Name = 'WS SUPPORT TEST', DeveloperName = 'WS_SUPPORT_TEST', Type = 'Queue');
        insert queue;
        insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
    }

    @IsTest
    static void shouldReturnZero_WhenAttachmentInputIsIncomplete() {
        WS_EmailToCaseAttachmentService service = new WS_EmailToCaseAttachmentService();

        Assert.areEqual(0, service.publishAttachmentsToCase(null, null), 'Sem email e sem case deve retornar zero.');
        Assert.areEqual(0, service.publishAttachmentsToCase(new Messaging.InboundEmail(), null), 'Sem Case alvo deve retornar zero.');
    }

    @IsTest
    static void shouldPublishOnlyValidAttachments_WhenEmailContainsMixedPayloads() {
        Case caseRecord = createCase();
        Messaging.InboundEmail email = new Messaging.InboundEmail();

        Messaging.InboundEmail.BinaryAttachment validBinary = new Messaging.InboundEmail.BinaryAttachment();
        validBinary.fileName = 'binary.bin';
        validBinary.body = Blob.valueOf('binary');

        Messaging.InboundEmail.BinaryAttachment emptyBinary = new Messaging.InboundEmail.BinaryAttachment();
        emptyBinary.fileName = 'ignored.bin';

        Messaging.InboundEmail.TextAttachment validText = new Messaging.InboundEmail.TextAttachment();
        validText.fileName = ' ';
        validText.body = 'text-body';

        Messaging.InboundEmail.TextAttachment emptyText = new Messaging.InboundEmail.TextAttachment();
        emptyText.fileName = 'ignored.txt';

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[]{ validBinary, emptyBinary };
        email.textAttachments = new Messaging.InboundEmail.TextAttachment[]{ validText, emptyText };

        Integer published = new WS_EmailToCaseAttachmentService().publishAttachmentsToCase(email, caseRecord.Id);

        List<ContentVersion> versions = [
            SELECT Title, PathOnClient, FirstPublishLocationId
            FROM ContentVersion
            WHERE FirstPublishLocationId = :caseRecord.Id
            ORDER BY Title
        ];

        Assert.areEqual(2, published, 'Apenas anexos com conteúdo devem ser publicados.');
        Assert.areEqual(2, versions.size(), 'Devem existir duas ContentVersions vinculadas ao Case.');
        Assert.areEqual('binary', versions[0].Title, 'O título deve usar o nome do arquivo sem extensão.');
        Assert.areEqual('binary.bin', versions[0].PathOnClient, 'O path deve manter o nome original do arquivo.');
        Assert.areEqual('email-text-attachment', versions[1].Title, 'Sem nome útil, o fallback de título deve ser aplicado.');
        Assert.areEqual('email-text-attachment.txt', versions[1].PathOnClient, 'Sem nome útil, o fallback de path deve ser aplicado.');
    }

    @IsTest
    static void shouldNotCreateLog_WhenPersistAuditIsFalse() {
        Integer beforeCount = [SELECT count() FROM LogIntegracao__c WHERE MetodoCallout__c = 'EMAIL'];

        new WS_EmailToCaseLogService().logError(buildContext(null), 'Erro sem auditoria', false);

        Integer afterCount = [SELECT count() FROM LogIntegracao__c WHERE MetodoCallout__c = 'EMAIL'];
        Assert.areEqual(beforeCount, afterCount, 'Sem persistência habilitada, o log não deve ser criado.');
    }

    @IsTest
    static void shouldCreateDetailedLog_WhenPersistAuditIsTrue() {
        Case caseRecord = createCase();
        WS_EmailToCaseContext ctx = buildContext(caseRecord.Id);
        ctx.processingKey = 'pk-123';
        ctx.messageIdentifier = 'mid-123';
        ctx.actionTaken = WS_EmailToCaseConstants.ACTION_ERROR;
        ctx.threadedRecordId = caseRecord.Id;
        ctx.originalCaseId = caseRecord.Id;

        new WS_EmailToCaseLogService().logError(ctx, 'Falha controlada', true);

        LogIntegracao__c row = [
            SELECT MetodoCallout__c, Endpoint__c, ObjetoRelacionamento__c, IdRelacionamento__c,
                   DescritivoErroLog__c, ComentariosObservacoes__c, RequestBody__c
            FROM LogIntegracao__c
            WHERE MetodoCallout__c = 'EMAIL'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Assert.areEqual('EMAIL', row.MetodoCallout__c, 'O tipo do log deve identificar o módulo de e-mail.');
        Assert.areEqual('Case', row.ObjetoRelacionamento__c, 'Com Case resolvido, o relacionamento deve ser preenchido.');
        Assert.areEqual(caseRecord.Id, row.IdRelacionamento__c, 'O Case do contexto deve ser vinculado ao log.');
        Assert.areEqual(true, row.Endpoint__c.contains('route=route@company.com'), 'O endpoint deve registrar a rota aplicada.');
        Assert.areEqual(true, row.Endpoint__c.contains('action=ERROR'), 'O endpoint deve registrar a ação tomada.');
        Assert.areEqual(true, row.ComentariosObservacoes__c.contains('Processing Key: pk-123'), 'O detalhamento deve registrar a processing key.');
        Assert.areEqual(true, row.ComentariosObservacoes__c.contains('Envelope To: route@company.com'), 'O detalhamento deve registrar o envelope.');
        Assert.areEqual(true, row.RequestBody__c.contains('PlainTextBody:'), 'O snapshot deve conter o corpo em texto.');
        Assert.areEqual(true, row.RequestBody__c.contains('Body text'), 'O snapshot deve carregar o conteúdo do corpo.');
    }

    private static Case createCase() {
        Group queue = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'WS_SUPPORT_TEST'
            LIMIT 1
        ];
        return WS_EmailToCaseTestDataFactory.createCase(
            queue.Id,
            WS_EmailToCaseTestDataFactory.getAnyOpenStatus(),
            null
        );
    }

    private static WS_EmailToCaseContext buildContext(Id caseId) {
        Messaging.InboundEmail email = WS_EmailToCaseTestDataFactory.buildEmail(
            '<support@id>',
            'route@company.com',
            'sender@example.com',
            'Subject',
            'Body text',
            '<p>Body html</p>'
        );
        Messaging.InboundEnvelope envelope = WS_EmailToCaseTestDataFactory.buildEnvelope('route@company.com', 'sender@example.com');
        WS_EmailToCaseContext ctx = new WS_EmailToCaseContext(email, envelope);
        ctx.caseId = caseId;
        ctx.route = WS_EmailToCaseTestDataFactory.buildRoute(
            'route@company.com',
            WS_EmailToCaseConstants.OWNER_TYPE_QUEUE,
            'WS_SUPPORT_TEST',
            WS_EmailToCaseConstants.BEHAVIOR_REOPEN,
            30
        );
        return ctx;
    }
}