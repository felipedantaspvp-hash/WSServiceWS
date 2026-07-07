/**
 * @description       : Testes unitários de AreaParticipanteRegiaoAtendimentoService.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
@IsTest
private class AreaParticipanteRegiaoAtendimentoTest {
    private static final String AREA_CHINA = 'Atendimento China';

    private static User createTestUser(String aliasSeed, String regiao) {
        Profile profile = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String uniq = String.valueOf(DateTime.now().getTime()) + String.valueOf(Math.mod(Crypto.getRandomInteger(), 100000));
        User u = new User(
            Alias = aliasSeed.left(8),
            Email = aliasSeed + uniq + '@wilsonsons.com.br',
            EmailEncodingKey = 'UTF-8',
            LastName = 'WS ' + aliasSeed,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            Username = aliasSeed + uniq + '@wilsonsons.com.br',
            RegiaoAtendimentoSecundaria__c = regiao
        );
        List<User> wsAdmins = [
            SELECT Id FROM User
            WHERE IsActive = true AND Email LIKE '%wilsonsons.com.br%' AND Profile.PermissionsManageUsers = true
            LIMIT 1
        ];
        User runAsUser = wsAdmins.isEmpty() ? new User(Id = UserInfo.getUserId()) : wsAdmins[0];
        System.runAs(runAsUser) {
            insert u;
        }
        return u;
    }

    // Constrói um Case de Rebocadores com Regra de SLA de Área Interna "Atendimento China",
    // já marcada para usar o Business Hours secundário. Não reaproveita
    // AreaParticipanteTestDataFactory.createCase porque ele usa um RecordType de Case
    // arbitrário (anyCaseRt), e o valor "Atendimento China" só está liberado no RecordType
    // AtendimentoRebocadores — manter o Case explicitamente nesse RecordType garante que
    // nenhum outro RecordType/unidade de negócio precise ser alterado.
    private static Case buildRebocadoresCase(Boolean duploBusinessHours) {
        RecordType rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName = 'AtendimentoRebocadores'
            LIMIT 1
        ];
        Case c = new Case(
            Subject = 'Case Regiao Atendimento Test',
            RecordTypeId = rt.Id,
            Status = AreaParticipanteTestDataFactory.pickValue('Case', 'Status', 0),
            Origin = AreaParticipanteTestDataFactory.pickValue('Case', 'Origin', 0),
            Priority = AreaParticipanteTestDataFactory.pickValue('Case', 'Priority', 0),
            AreasParticipantesSLA__c = 'Atendimento China',
            EtapaAtendimento__c = 'Aguardando Área Interna',
            NavioNome__c = 'Navio Teste',
            PortoNome__c = 'Porto Teste'
        );
        insert c;

        Categorizacao__c categorizacao = CategorizacaoTestDataFactory.base(false, false);
        insert categorizacao;

        GestaoSLA__c gestao = new GestaoSLA__c(
            Name = 'Gestao SLA Test Rebocadores China ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 100000)),
            UnidadeNegocio__c = 'Rebocadores',
            EntitlementProcessName__c = 'Atendimento Rebocadores',
            BusinessHoursName__c = 'Atendimento Rebocadores',
            PossuiBusinessHoursSecundario__c = duploBusinessHours,
            RegiaoAtendimentoSecundaria__c = duploBusinessHours ? 'China' : null,
            BusinessHoursSecundarioName__c = duploBusinessHours ? 'Rebocadores China' : null,
            Ativo__c = true
        );
        insert gestao;

        categorizacao.GestaoSLA__c = gestao.Id;
        update categorizacao;

        c.Categorizacao__c = categorizacao.Id;
        update c;

        RegrasSLACategorizacao__c regra = new RegrasSLACategorizacao__c(
            Categorizacao__c = categorizacao.Id,
            AreaAtendimento__c = 'Atendimento China',
            UsaBusinessHoursSecundario__c = duploBusinessHours,
            Ativo__c = true,
            GestaoSLA__c = gestao.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 60,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );
        insert regra;

        return c;
    }

    private static List<Case> buildRebocadoresCases(Integer total, Boolean duploBusinessHours) {
        RecordType rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName = 'AtendimentoRebocadores'
            LIMIT 1
        ];
        Categorizacao__c categorizacao = CategorizacaoTestDataFactory.base(false, false);
        insert categorizacao;

        GestaoSLA__c gestao = new GestaoSLA__c(
            Name = 'Gestao SLA Test Rebocadores Bulk ' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 100000)),
            UnidadeNegocio__c = 'Rebocadores',
            EntitlementProcessName__c = 'Atendimento Rebocadores',
            BusinessHoursName__c = 'Atendimento Rebocadores',
            PossuiBusinessHoursSecundario__c = duploBusinessHours,
            RegiaoAtendimentoSecundaria__c = duploBusinessHours ? 'China' : null,
            BusinessHoursSecundarioName__c = duploBusinessHours ? 'Rebocadores China' : null,
            Ativo__c = true
        );
        insert gestao;

        categorizacao.GestaoSLA__c = gestao.Id;
        update categorizacao;

        insert new RegrasSLACategorizacao__c(
            Categorizacao__c = categorizacao.Id,
            AreaAtendimento__c = AREA_CHINA,
            UsaBusinessHoursSecundario__c = duploBusinessHours,
            Ativo__c = true,
            GestaoSLA__c = gestao.Id,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 60,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );

        List<Case> casesToInsert = new List<Case>();
        for (Integer i = 0; i < total; i++) {
            casesToInsert.add(new Case(
                Subject = 'Case Regiao Atendimento Bulk ' + i,
                RecordTypeId = rt.Id,
                Status = AreaParticipanteTestDataFactory.pickValue('Case', 'Status', 0),
                Origin = AreaParticipanteTestDataFactory.pickValue('Case', 'Origin', 0),
                Priority = AreaParticipanteTestDataFactory.pickValue('Case', 'Priority', 0),
                AreasParticipantesSLA__c = AREA_CHINA,
                EtapaAtendimento__c = 'Aguardando Área Interna',
                NavioNome__c = 'Navio Teste ' + i,
                PortoNome__c = 'Porto Teste ' + i,
                Categorizacao__c = categorizacao.Id
            ));
        }
        insert casesToInsert;
        return casesToInsert;
    }

    private static void setupBusinessHoursMocks() {
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        BusinessHoursResolverService.injectedByName.clear();
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        if (!bhs.isEmpty()) {
            BusinessHoursResolverService.injectedByName.put('Atendimento Rebocadores', bhs[0].Id);
            BusinessHoursResolverService.injectedByName.put('Rebocadores China', bhs[0].Id);
        }
    }

    @IsTest
    static void testOwnerComRegiaoAbreAreaEOwnerSemRegiaoEncerra() {
        setupBusinessHoursMocks();

        Case c = buildRebocadoresCase(true);

        User chinaUser = createTestUser('chinau', 'China');
        User brUser = createTestUser('brasilu', null);

        Test.startTest();
        c.OwnerId = chinaUser.Id;
        update c;
        Test.stopTest();

        AreaParticipante__c opened = [
            SELECT Id, StatusAtuacao__c
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND AreaAtendimento__c = 'Atendimento China'
            LIMIT 1
        ];
        Assert.areEqual(true, AreaParticipanteHelper.isAbertaOuAndamento(opened.StatusAtuacao__c));

        c.OwnerId = brUser.Id;
        update c;

        AreaParticipante__c closed = [SELECT StatusAtuacao__c FROM AreaParticipante__c WHERE Id = :opened.Id];
        Assert.areEqual(true, AreaParticipanteHelper.isConcluida(closed.StatusAtuacao__c));
    }

    @IsTest
    static void testOwnerSemRegiaoNuncaAbreArea() {
        setupBusinessHoursMocks();

        Case c = buildRebocadoresCase(true);

        User brUser = createTestUser('brasilu2', null);

        Test.startTest();
        c.OwnerId = brUser.Id;
        update c;
        Test.stopTest();

        Integer total = [
            SELECT COUNT()
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND AreaAtendimento__c = 'Atendimento China'
        ];
        Assert.areEqual(0, total);
    }

    @IsTest
    static void testGestaoSemDuploBusinessHoursIgnoraAutomacao() {
        ApexTestSeam.set('AreaParticipanteSLAService.bypassBusinessHoursMath', true);
        Case c = buildRebocadoresCase(false);

        User chinaUser = createTestUser('chinau2', 'China');

        Test.startTest();
        c.OwnerId = chinaUser.Id;
        update c;
        Test.stopTest();

        Integer total = [
            SELECT COUNT()
            FROM AreaParticipante__c
            WHERE Caso__c = :c.Id AND AreaAtendimento__c = 'Atendimento China'
        ];
        Assert.areEqual(0, total);
    }

    @IsTest
    static void testBulkOwnerChangeOpensAndClosesRegionAreas() {
        setupBusinessHoursMocks();
        Integer totalCases = 80;
        List<Case> casesToUpdate = buildRebocadoresCases(totalCases, true);
        Set<Id> caseIds = new Map<Id, Case>(casesToUpdate).keySet();
        User chinaUser = createTestUser('chinbulk', 'China');
        User brUser = createTestUser('brbulk', null);

        for (Case caseRow : casesToUpdate) {
            caseRow.OwnerId = chinaUser.Id;
        }

        Test.startTest();
        update casesToUpdate;
        Test.stopTest();

        Integer openedCount = [
            SELECT COUNT()
            FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds
              AND AreaAtendimento__c = :AREA_CHINA
              AND DataHoraFim__c = null
        ];
        Assert.areEqual(totalCases, openedCount, 'Cada Case do lote deve abrir exatamente uma area secundaria.');

        for (Case caseRow : casesToUpdate) {
            caseRow.OwnerId = brUser.Id;
        }

        update casesToUpdate;

        Integer remainingOpenCount = [
            SELECT COUNT()
            FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds
              AND AreaAtendimento__c = :AREA_CHINA
              AND DataHoraFim__c = null
        ];
        Integer closedCount = [
            SELECT COUNT()
            FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds
              AND AreaAtendimento__c = :AREA_CHINA
              AND StatusAtuacao__c = :AreaParticipanteHelper.resolveConcluidaStatusValue()
        ];

        Assert.areEqual(0, remainingOpenCount, 'Nenhuma area secundaria deve permanecer aberta apos a troca em massa.');
        Assert.areEqual(totalCases, closedCount, 'Todas as areas secundarias abertas pelo lote devem ser encerradas.');
    }
}
