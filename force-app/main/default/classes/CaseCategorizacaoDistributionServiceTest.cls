@IsTest
private class CaseCategorizacaoDistributionServiceTest {
    @TestSetup
    static void setupData() {
        Group primaryQueue = new Group(Name = 'TSV Queue Test', DeveloperName = 'TSV_Q_TEST', Type = 'Queue');
        insert primaryQueue;
        insert new QueueSobject(QueueId = primaryQueue.Id, SobjectType = 'Case');

        Group fallbackQueue = new Group(Name = 'TSV Queue Fallback Test', DeveloperName = 'TSV_Q_TEST_FALLBACK', Type = 'Queue');
        insert fallbackQueue;
        insert new QueueSobject(QueueId = fallbackQueue.Id, SobjectType = 'Case');
    }

    @IsTest
    static void shouldAssignPrimaryQueueWhenCustomFieldMatches() {
        Categorizacao__c categorizacao = buildCategorizacao(true, 'Sim');
        categorizacao.CampoDistribuicao__c = 'Priority';
        categorizacao.ValorDistribuicao__c = 'High';
        insert categorizacao;

        Case currentCase = buildCase(categorizacao.Id, 'High', null, 'Novo');

        Test.startTest();
        CaseCategorizacaoDistributionService.applyDistribution(new List<Case>{ currentCase });
        Test.stopTest();

        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'TSV_Q_TEST' LIMIT 1];
        Assert.areEqual(queue.Id, currentCase.OwnerId, 'A fila principal deve ser aplicada quando o valor configurado bater.');
        Assert.areEqual(true, currentCase.DistribuicaoSolicitada__c, 'A distribuicao deve ser marcada no Case.');
        Assert.areEqual('Categorização', currentCase.OrigemDistribuicao__c, 'A origem da distribuicao deve ser categorizacao.');
    }

    @IsTest
    static void shouldAssignFallbackQueueWhenCustomFieldDoesNotMatch() {
        Categorizacao__c categorizacao = buildCategorizacao(true, 'Sim');
        categorizacao.CampoDistribuicao__c = 'Priority';
        categorizacao.ValorDistribuicao__c = 'High';
        categorizacao.FilaDeveloperNameFallback__c = 'TSV_Q_TEST_FALLBACK';
        insert categorizacao;

        Case currentCase = buildCase(categorizacao.Id, 'Low', null, 'Novo');

        Test.startTest();
        CaseCategorizacaoDistributionService.applyDistribution(new List<Case>{ currentCase });
        Test.stopTest();

        Group fallbackQueue = [SELECT Id FROM Group WHERE DeveloperName = 'TSV_Q_TEST_FALLBACK' LIMIT 1];
        Assert.areEqual(fallbackQueue.Id, currentCase.OwnerId, 'A fila fallback deve ser aplicada quando o valor nao bater.');
        Assert.areEqual('TSV_Q_TEST_FALLBACK', currentCase.FilaDestinoDeveloperName__c, 'O developer name da fila fallback deve ser preservado.');
    }

    @IsTest
    static void shouldKeepOwnerWhenAssumirIsAllowed() {
        Categorizacao__c categorizacao = buildCategorizacao(true, 'Não');
        categorizacao.PermiteAssumirComFilaParametrizada__c = 'Sim';
        insert categorizacao;

        Id currentUserId = UserInfo.getUserId();
        Case currentCase = buildCase(categorizacao.Id, 'High', currentUserId, 'Novo');
        currentCase.AcaoPosCategorizacao__c = 'Assumir';

        Test.startTest();
        CaseCategorizacaoDistributionService.applyDistribution(new List<Case>{ currentCase });
        Test.stopTest();

        Assert.areEqual(currentUserId, currentCase.OwnerId, 'Assumir permitido deve preservar o owner original.');
        Assert.areEqual(false, currentCase.DistribuicaoSolicitada__c, 'Nao deve marcar distribuicao quando houver bypass explicito permitido.');
    }

    @IsTest
    static void shouldSkipDistributionWhenActionIsEncerrar() {
        Categorizacao__c categorizacao = buildCategorizacao(true, 'Não');
        insert categorizacao;

        Id currentUserId = UserInfo.getUserId();
        Case currentCase = buildCase(categorizacao.Id, 'High', currentUserId, 'Novo');
        currentCase.AcaoPosCategorizacao__c = 'Encerrar';

        Test.startTest();
        CaseCategorizacaoDistributionService.applyDistribution(new List<Case>{ currentCase });
        Test.stopTest();

        Assert.areEqual(currentUserId, currentCase.OwnerId, 'Encerrar deve bypassar a distribuicao trigger-side.');
        Assert.areEqual(false, currentCase.DistribuicaoSolicitada__c, 'Nao deve marcar distribuicao quando a acao for Encerrar.');
    }

    private static Categorizacao__c buildCategorizacao(Boolean distribuirParaFila, String porCampoCustomizado) {
        Categorizacao__c categorizacao = CategorizacaoTestDataFactory.base(distribuirParaFila, false);
        categorizacao.RecordTypeId = recordTypeByDeveloperName('Categorizacao__c', 'AtendimentoTeconSalvador').Id;
        categorizacao.UnidadeNegocios__c = 'Atendimento Tecon Salvador';
        categorizacao.FilaDeveloperName__c = 'TSV_Q_TEST';
        categorizacao.PorCampoCustomizado__c = porCampoCustomizado;
        categorizacao.EtapaAtendimentoDistribuicao__c = 'Em Atendimento';
        return categorizacao;
    }

    private static Case buildCase(Id categorizacaoId, String priority, Id ownerId, String etapa) {
        Map<String, Object> overrides = new Map<String, Object>{
            'RecordTypeId' => recordTypeByDeveloperName('Case', 'AtendimentoTeconSalvador').Id,
            'UnidadeNegocio__c' => 'Atendimento Tecon Salvador',
            'Origin' => 'Manual',
            'Status' => 'Aberto',
            'Priority' => priority,
            'EtapaAtendimento__c' => etapa,
            'Categorizacao__c' => categorizacaoId
        };
        if (ownerId != null) {
            overrides.put('OwnerId', ownerId);
        }
        return TestDataFactory.buildCase(overrides);
    }

    private static RecordType recordTypeByDeveloperName(String sobjectType, String developerName) {
        return TestDataFactory.recordTypeByDeveloperName(sobjectType, developerName);
    }
}
