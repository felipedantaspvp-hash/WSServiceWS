@IsTest
private class ReclamacaoServiceTest {
    private static final String UNIDADE = 'Atendimento Tecon Salvador';

    private static Id makeFakeCaseId(Integer n) {
        String pfx = Schema.SObjectType.Case.getKeyPrefix();
        return Id.valueOf(pfx + String.valueOf(n).leftPad(12, '0'));
    }

    private static Case fakeCase(Id caseId, Boolean isClosed, String tipoCaso, Boolean reclamacaoGerada, String unidadeNegocio) {
        Map<String, Object> data = new Map<String, Object>{
            'Id' => caseId,
            'IsClosed' => isClosed,
            'TipoCaso__c' => tipoCaso,
            'ReclamacaoGerada__c' => reclamacaoGerada,
            'UnidadeNegocio__c' => unidadeNegocio,
            'Categoria__c' => 'Acesso ao Porto',
            'Assunto__c' => 'Acesso',
            'Subassunto__c' => 'Acesso indisponível'
        };
        return (Case) JSON.deserialize(JSON.serialize(data), Case.class);
    }

    private static void setupConfig(Boolean gerarReclamacao, String rtDeveloperName, String areaValue) {
        AtendimentoConfigDTO cfg = new AtendimentoConfigDTO();
        cfg.businessUnit = UNIDADE;
        cfg.isActive = true;
        cfg.gerarReclamacaoNoEncerramento = gerarReclamacao;
        cfg.reclamacaoRecordTypeDeveloperName = rtDeveloperName;
        cfg.reclamacaoAreaValue = areaValue;
        AtendimentoConfigService.setTestSurveyConfigs(new List<AtendimentoConfigDTO>{ cfg });
    }

    private static void clearInjections() {
        AtendimentoConfigService.clearTestSurveyConfigs();
        ReclamacaoService.testRecordTypeIdByDeveloperName = null;
    }

    private static Id anyReclamacaoRecordTypeId() {
        List<RecordType> rts = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Reclamacao__c' AND IsActive = true LIMIT 1];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    private static Case insertOpenReclamacaoCase() {
        RecordType caseRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'AtendimentoTeconSalvador' AND IsActive = true LIMIT 1];
        Account account = new Account(Name = 'Cliente Reclamacao');
        insert account;
        Contact contact = new Contact(
            LastName = 'Solicitante Reclamacao',
            AccountId = account.Id,
            MobilePhone = '11999999999'
        );
        insert contact;
        Case c = new Case(
            Subject = 'Case Reclamação Teste',
            RecordTypeId = caseRt.Id,
            Status = AreaParticipanteTestDataFactory.pickValue('Case', 'Status', 0),
            Origin = AreaParticipanteTestDataFactory.pickValue('Case', 'Origin', 0),
            Priority = AreaParticipanteTestDataFactory.pickValue('Case', 'Priority', 0),
            AccountId = account.Id,
            ContactId = contact.Id,
            TipoCaso__c = 'Reclamação',
            UnidadeNegocio__c = UNIDADE,
            Modalidade__c = 'Cabotagem Descarga',
            Categoria__c = 'Acesso ao Porto',
            Assunto__c = 'Acesso',
            Subassunto__c = 'Acesso indisponível'
        );
        insert c;
        return c;
    }

    @IsTest
    static void testHandleClosureGeneratesReclamacaoAndStampsCaseWhenEligible() {
        Id rtId = anyReclamacaoRecordTypeId();
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        ReclamacaoService.testRecordTypeIdByDeveloperName = new Map<String, Id>{ 'TeconSalvador' => rtId };

        Case c = insertOpenReclamacaoCase();
        Case oldC = fakeCase(c.Id, false, 'Reclamação', false, UNIDADE);
        Case newC = fakeCase(c.Id, true, 'Reclamação', false, UNIDADE);

        Test.startTest();
        ReclamacaoService.handleClosure(new Map<Id, Case>{ c.Id => newC }, new Map<Id, Case>{ c.Id => oldC });
        Test.stopTest();

        Case updated = [SELECT ReclamacaoGerada__c, DtGeracaoReclamacao__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, updated.ReclamacaoGerada__c);
        Assert.isNotNull(updated.DtGeracaoReclamacao__c);

        List<Reclamacao__c> created = [
            SELECT Id, Caso__c, Categoria__c, Assunto__c, Subassunto__c, Area__c, Unidade__c,
                   RecordTypeId, Cliente__c, Modalidade__c, QuemReclamou__c, StatusRegistro__c,
                   CarimboDataHora__c, DataInicioTicket__c, SemanaRecebimento__c
            FROM Reclamacao__c
            WHERE Caso__c = :c.Id
        ];
        Assert.areEqual(1, created.size());
        Assert.areEqual('Acesso ao Porto', created[0].Categoria__c);
        Assert.areEqual('Acesso', created[0].Assunto__c);
        Assert.areEqual('Acesso indisponível', created[0].Subassunto__c);
        Assert.areEqual('Tecon Salvador', created[0].Area__c);
        Assert.areEqual('Tecon Salvador', created[0].Unidade__c);
        Assert.areEqual(rtId, created[0].RecordTypeId);
        Assert.areEqual(c.AccountId, created[0].Cliente__c);
        Assert.areEqual('Cabotagem', created[0].Modalidade__c);
        Assert.areEqual('Solicitante Reclamacao', created[0].QuemReclamou__c);
        Assert.areEqual('Aberta', created[0].StatusRegistro__c);
        Assert.isNotNull(created[0].CarimboDataHora__c);
        Assert.areEqual(Date.today(), created[0].DataInicioTicket__c);
        Assert.isNotNull(created[0].SemanaRecebimento__c);
        clearInjections();
    }

    @IsTest
    static void testBuildReclamacaoFallsBackToSuppliedNameAndNormalizesModalidade() {
        RecordType caseRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'AtendimentoTeconSalvador' AND IsActive = true LIMIT 1];
        Account account = new Account(Name = 'Cliente Fallback');
        insert account;
        Case c = new Case(
            Subject = 'Case Reclamação Fallback',
            RecordTypeId = caseRt.Id,
            Status = AreaParticipanteTestDataFactory.pickValue('Case', 'Status', 0),
            Origin = AreaParticipanteTestDataFactory.pickValue('Case', 'Origin', 0),
            Priority = AreaParticipanteTestDataFactory.pickValue('Case', 'Priority', 0),
            AccountId = account.Id,
            SuppliedName = 'Nome Fornecido',
            TipoCaso__c = 'Reclamação',
            UnidadeNegocio__c = UNIDADE,
            Modalidade__c = 'Operação de Navio',
            Categoria__c = 'Acesso ao Porto',
            Assunto__c = 'Acesso',
            Subassunto__c = 'Acesso indisponível'
        );
        insert c;

        AtendimentoConfigDTO cfg = new AtendimentoConfigDTO();
        cfg.reclamacaoAreaValue = 'Tecon Salvador';
        cfg.reclamacaoRecordTypeDeveloperName = 'TeconSalvador';

        Reclamacao__c created = ReclamacaoService.buildReclamacao([
            SELECT Id, AccountId, Contact.Name, SuppliedName, CreatedDate, Modalidade__c,
                   Categoria__c, Assunto__c, Subassunto__c
            FROM Case
            WHERE Id = :c.Id
        ], cfg);

        Assert.areEqual(c.AccountId, created.Cliente__c);
        Assert.areEqual('Outro', created.Modalidade__c);
        Assert.areEqual('Nome Fornecido', created.QuemReclamou__c);
        Assert.areEqual('Aberta', created.StatusRegistro__c);
        Assert.isNotNull(created.CarimboDataHora__c);
        Assert.areEqual(Date.today(), created.DataInicioTicket__c);
        Assert.isNotNull(created.SemanaRecebimento__c);
    }

    @IsTest
    static void testHandleClosureSkipsWhenFlagDisabled() {
        setupConfig(false, 'TeconSalvador', 'Tecon Salvador');
        Id caseId = makeFakeCaseId(1);
        Case oldC = fakeCase(caseId, false, 'Reclamação', false, UNIDADE);
        Case newC = fakeCase(caseId, true, 'Reclamação', false, UNIDADE);

        ReclamacaoService.handleClosure(new Map<Id, Case>{ caseId => newC }, new Map<Id, Case>{ caseId => oldC });

        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :caseId]);
        clearInjections();
    }

    @IsTest
    static void testHandleClosureSkipsWhenNotReclamacaoType() {
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        Id caseId = makeFakeCaseId(2);
        Case oldC = fakeCase(caseId, false, 'Solicitação', false, UNIDADE);
        Case newC = fakeCase(caseId, true, 'Solicitação', false, UNIDADE);

        ReclamacaoService.handleClosure(new Map<Id, Case>{ caseId => newC }, new Map<Id, Case>{ caseId => oldC });

        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :caseId]);
        clearInjections();
    }

    @IsTest
    static void testHandleClosureSkipsWhenAlreadyGenerated() {
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        Id caseId = makeFakeCaseId(3);
        Case oldC = fakeCase(caseId, false, 'Reclamação', true, UNIDADE);
        Case newC = fakeCase(caseId, true, 'Reclamação', true, UNIDADE);

        ReclamacaoService.handleClosure(new Map<Id, Case>{ caseId => newC }, new Map<Id, Case>{ caseId => oldC });

        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :caseId]);
        clearInjections();
    }

    @IsTest
    static void testHandleClosureSkipsWhenNotAClosingTransition() {
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        Id caseId = makeFakeCaseId(4);
        Case oldC = fakeCase(caseId, true, 'Reclamação', false, UNIDADE);
        Case newC = fakeCase(caseId, true, 'Reclamação', false, UNIDADE);

        ReclamacaoService.handleClosure(new Map<Id, Case>{ caseId => newC }, new Map<Id, Case>{ caseId => oldC });

        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :caseId]);
        clearInjections();
    }

    @IsTest
    static void testHandleClosureSkipsWhenManualDecisionAlreadyRegistered() {
        // Mesmo com a unidade habilitada via metadado e todas as outras condições satisfeitas,
        // se a tela assistida (caseClosureSurvey) já registrou a decisão nesta transação, o motor
        // automático não deve decidir de novo - inclusive quando o usuário escolheu não gerar.
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        Id caseId = makeFakeCaseId(5);
        Case oldC = fakeCase(caseId, false, 'Reclamação', false, UNIDADE);
        Map<String, Object> data = new Map<String, Object>{
            'Id' => caseId,
            'IsClosed' => true,
            'TipoCaso__c' => 'Reclamação',
            'ReclamacaoGerada__c' => false,
            'ReclamacaoDecisaoManual__c' => true,
            'UnidadeNegocio__c' => UNIDADE
        };
        Case newC = (Case) JSON.deserialize(JSON.serialize(data), Case.class);

        ReclamacaoService.handleClosure(new Map<Id, Case>{ caseId => newC }, new Map<Id, Case>{ caseId => oldC });

        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :caseId]);
        clearInjections();
    }

    @IsTest
    static void testCaseTriggerHandlerEndToEndGeneratesReclamacaoOnClosure() {
        Id rtId = anyReclamacaoRecordTypeId();
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        ReclamacaoService.testRecordTypeIdByDeveloperName = new Map<String, Id>{ 'TeconSalvador' => rtId };

        Case c = insertOpenReclamacaoCase();

        Test.startTest();
        update new Case(Id = c.Id, Status = 'Fechado', MotivoEncerramento__c = 'Resolvido', SolucaoCaso__c = 'Concluído.');
        Test.stopTest();

        Case updated = [SELECT ReclamacaoGerada__c, DtGeracaoReclamacao__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, updated.ReclamacaoGerada__c);
        Assert.isNotNull(updated.DtGeracaoReclamacao__c);

        List<Reclamacao__c> created = [SELECT Id FROM Reclamacao__c WHERE Caso__c = :c.Id];
        Assert.areEqual(1, created.size());
        clearInjections();
    }

    @IsTest
    static void testCaseTriggerHandlerEndToEndDoesNotGenerateWhenFlagDisabled() {
        setupConfig(false, 'TeconSalvador', 'Tecon Salvador');
        Case c = insertOpenReclamacaoCase();

        Test.startTest();
        update new Case(Id = c.Id, Status = 'Fechado', MotivoEncerramento__c = 'Resolvido', SolucaoCaso__c = 'Concluído.');
        Test.stopTest();

        Case updated = [SELECT ReclamacaoGerada__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(false, updated.ReclamacaoGerada__c);
        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :c.Id]);
        clearInjections();
    }

    @IsTest
    static void testHandleClosureOnInsertGeneratesReclamacaoForAlreadyClosedCase() {
        // Cobre carga via Data Loader/API: o Case nasce já fechado (sem transição
        // aberto->fechado dentro de um update), então só o afterInsert pode capturar isso -
        // afterUpdate nunca dispara para um insert.
        Id rtId = anyReclamacaoRecordTypeId();
        setupConfig(true, 'TeconSalvador', 'Tecon Salvador');
        ReclamacaoService.testRecordTypeIdByDeveloperName = new Map<String, Id>{ 'TeconSalvador' => rtId };

        Case c = insertClosedReclamacaoCase();

        Case updated = [SELECT ReclamacaoGerada__c, DtGeracaoReclamacao__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, updated.ReclamacaoGerada__c);
        Assert.isNotNull(updated.DtGeracaoReclamacao__c);
        Assert.areEqual(1, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :c.Id]);
        clearInjections();
    }

    @IsTest
    static void testHandleClosureOnInsertSkipsWhenFlagDisabled() {
        setupConfig(false, 'TeconSalvador', 'Tecon Salvador');

        Case c = insertClosedReclamacaoCase();

        Case updated = [SELECT ReclamacaoGerada__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(false, updated.ReclamacaoGerada__c);
        Assert.areEqual(0, [SELECT COUNT() FROM Reclamacao__c WHERE Caso__c = :c.Id]);
        clearInjections();
    }

    private static Case insertClosedReclamacaoCase() {
        RecordType caseRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'AtendimentoTeconSalvador' AND IsActive = true LIMIT 1];
        Account account = new Account(Name = 'Cliente Reclamacao Carga');
        insert account;
        Case c = new Case(
            Subject = 'Case Reclamação já fechado (carga)',
            RecordTypeId = caseRt.Id,
            Status = 'Fechado',
            Origin = AreaParticipanteTestDataFactory.pickValue('Case', 'Origin', 0),
            Priority = AreaParticipanteTestDataFactory.pickValue('Case', 'Priority', 0),
            AccountId = account.Id,
            SuppliedName = 'Solicitante Carga',
            TipoCaso__c = 'Reclamação',
            UnidadeNegocio__c = UNIDADE,
            Modalidade__c = 'Importação',
            Categoria__c = 'Acesso ao Porto',
            Assunto__c = 'Acesso',
            Subassunto__c = 'Acesso indisponível',
            MotivoEncerramento__c = 'Resolvido',
            SolucaoCaso__c = 'Carga histórica.'
        );
        insert c;
        return c;
    }
}