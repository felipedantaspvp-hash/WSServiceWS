/**
 * TestDataFactory centralizada do módulo de Atendimento (Case, GestaoSLA__c, Categorizacao__c,
 * RegrasSLACategorizacao__c, AreaParticipante__c, Reclamacao__c, Agendamento__c).
 *
 * Criada em resposta à dívida técnica de 5 factories dispersas (AreaParticipanteTestDataFactory,
 * CaseCreationTestDataFactory, CaseRecategorizationTestDataFactory, CategorizacaoTestDataFactory,
 * WS_EmailToCaseTestDataFactory) e dezenas de classes de teste duplicando setup manualmente.
 * É autocontida por design: não depende das 5 factories legadas, que permanecem em uso e
 * intocadas nesta entrega (migração completa fica para entregas futuras).
 */
@IsTest
public inherited sharing class TestDataFactory {
    private static final String AREA_FIELD = 'AreaAtendimento__c';
    private static Integer counter = 0;

    // ------------------------------------------------------------------
    // Utilitários de picklist / RecordType
    // ------------------------------------------------------------------

    public static String randomSuffix() {
        counter++;
        return String.valueOf(Math.mod(Crypto.getRandomInteger(), 1000000)) + '_' + counter;
    }

    public static String pickValue(String objectApiName, String fieldApiName, Integer index) {
        List<String> values = pickAllValues(objectApiName, fieldApiName);
        if (values.isEmpty()) return null;
        Integer safe = values.size() > index ? index : 0;
        return values[safe];
    }

    public static List<String> pickAllValues(String objectApiName, String fieldApiName) {
        Map<String, Schema.SObjectType> types = Schema.getGlobalDescribe();
        Schema.DescribeFieldResult dfr = types.get(objectApiName).getDescribe().fields.getMap().get(fieldApiName).getDescribe();
        List<String> out = new List<String>();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            out.add(pe.getValue());
        }
        return out;
    }

    public static RecordType anyActiveRecordType(String sobjectApiName) {
        return [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = :sobjectApiName AND IsActive = true LIMIT 1];
    }

    public static RecordType recordTypeByDeveloperName(String sobjectApiName, String developerName) {
        return [
            SELECT Id, DeveloperName, Name
            FROM RecordType
            WHERE SObjectType = :sobjectApiName AND DeveloperName = :developerName
            LIMIT 1
        ];
    }

    public static Boolean isRebocadoresRecordType(Id recordTypeId) {
        if (recordTypeId == null) return false;
        RecordType rt = [SELECT DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1];
        return rt.DeveloperName == 'AtendimentoRebocadores';
    }

    // Interseção entre Case.AreasParticipantesSLA__c e AreaParticipante__c.AreaAtendimento__c
    public static List<String> commonAreaValues() {
        Set<String> caseValues = new Set<String>(pickAllValues('Case', 'AreasParticipantesSLA__c'));
        List<String> out = new List<String>();
        for (String value : pickAllValues('AreaParticipante__c', AREA_FIELD)) {
            if (caseValues.contains(value)) out.add(value);
        }
        if (out.isEmpty()) {
            out.addAll(pickAllValues('AreaParticipante__c', AREA_FIELD));
        }
        return out;
    }

    // ------------------------------------------------------------------
    // Account / Contact
    // ------------------------------------------------------------------

    public static Account buildAccount(Map<String, Object> overrides) {
        Account acc = new Account(Name = 'Conta Teste ' + randomSuffix());
        applyOverrides(acc, overrides);
        return acc;
    }

    public static Account createAccount(Map<String, Object> overrides) {
        Account acc = buildAccount(overrides);
        insert acc;
        return acc;
    }

    public static Contact buildContact(Id accountId, Map<String, Object> overrides) {
        Contact con = new Contact(
            LastName = 'Contato Teste',
            Email = 'contato' + randomSuffix() + '@example.com',
            Phone = '11999990000',
            AccountId = accountId
        );
        applyOverrides(con, overrides);
        return con;
    }

    public static Contact createContact(Id accountId, Map<String, Object> overrides) {
        Contact con = buildContact(accountId, overrides);
        insert con;
        return con;
    }

    public static Contact createAccountAndContact(Map<String, Object> accountOverrides, Map<String, Object> contactOverrides) {
        Account acc = createAccount(accountOverrides);
        return createContact(acc.Id, contactOverrides);
    }

    // ------------------------------------------------------------------
    // Queue / User
    // ------------------------------------------------------------------

    public static Group createQueue(String developerName) {
        Group g = new Group(Name = developerName, DeveloperName = developerName, Type = 'Queue');
        insert g;
        insert new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
        return g;
    }

    public static User createUser(String aliasSeed, Map<String, Object> overrides) {
        Profile profile = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String uniq = String.valueOf(DateTime.now().getTime());
        User u = new User(
            Alias = aliasSeed.left(8),
            Email = aliasSeed + uniq + '@wilsonsons.com.br',
            EmailEncodingKey = 'UTF-8',
            LastName = 'WS',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            Username = aliasSeed + uniq + '@wilsonsons.com.br'
        );
        applyOverrides(u, overrides);
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

    // ------------------------------------------------------------------
    // Case
    // ------------------------------------------------------------------

    // Resolve RecordType, aplica defaults só onde não vier override, e cobre automaticamente
    // a regra de Rebocadores (Navio/Porto obrigatórios via Bloqueio_Navio_Nao_Informado /
    // Bloqueio_Porto_Nao_Informado) sempre que o RT resolvido for AtendimentoRebocadores.
    //
    // 'RecordTypeId' => null em overrides significa "não define RecordType, deixa o default
    // da org resolver" — a chave é removida antes de applyOverrides para que o campo nunca
    // seja tocado no SObject (setar explicitamente null é diferente, para o Salesforce, de
    // simplesmente não informar o campo, e causa INVALID_CROSS_REFERENCE_KEY no insert).
    public static Case buildCase(Map<String, Object> overrides) {
        Map<String, Object> ov = overrides == null ? new Map<String, Object>() : overrides.clone();
        Boolean recordTypeKeyPresent = ov.containsKey('RecordTypeId');
        Object recordTypeOverrideValue = recordTypeKeyPresent ? ov.remove('RecordTypeId') : null;
        Id recordTypeId = recordTypeKeyPresent ? (Id) recordTypeOverrideValue : anyActiveRecordType('Case').Id;

        Case c = new Case(
            Subject = 'Case Teste ' + randomSuffix(),
            Status = pickValue('Case', 'Status', 0),
            Origin = pickValue('Case', 'Origin', 0),
            Priority = pickValue('Case', 'Priority', 0)
        );
        if (recordTypeId != null) {
            c.RecordTypeId = recordTypeId;
        }

        Boolean overridesHaveNavio = ov.containsKey('NavioNome__c') || ov.containsKey('NavioIMO__c');
        Boolean overridesHavePorto = ov.containsKey('PortoNome__c') || ov.containsKey('PortoCodigoMercante__c');
        if (isRebocadoresRecordType(recordTypeId)) {
            if (!overridesHaveNavio) c.NavioNome__c = 'Navio Teste';
            if (!overridesHavePorto) c.PortoNome__c = 'Porto Teste';
        }

        applyOverrides(c, ov);
        return c;
    }

    public static Case createCase(Map<String, Object> overrides) {
        Case c = buildCase(overrides);
        insert c;
        return c;
    }

    // Fluxo completo pronto: Case + Categorizacao__c + GestaoSLA__c compartilhada + N
    // RegrasSLACategorizacao__c (uma por área distinta), já linkados entre si.
    public static Case createCaseWithSlaChain(
        Map<String, Object> caseOverrides,
        Map<String, Object> categorizacaoOverrides,
        Map<String, Object> gestaoOverrides,
        List<String> areas
    ) {
        List<String> allowed = pickAllValues('Case', 'AreasParticipantesSLA__c');
        if (allowed.isEmpty()) allowed.add('A definir');
        List<String> resolvedAreas = new List<String>();
        if (areas != null) {
            for (String area : areas) {
                if (!String.isBlank(area) && allowed.contains(area) && !resolvedAreas.contains(area)) {
                    resolvedAreas.add(area);
                }
            }
        }
        if (resolvedAreas.isEmpty()) resolvedAreas.add(allowed[0]);

        Map<String, Object> mergedCaseOverrides = caseOverrides == null ? new Map<String, Object>() : caseOverrides.clone();
        if (!mergedCaseOverrides.containsKey('AreasParticipantesSLA__c')) {
            mergedCaseOverrides.put('AreasParticipantesSLA__c', String.join(resolvedAreas, ';'));
        }
        if (!mergedCaseOverrides.containsKey('EtapaAtendimento__c')) {
            mergedCaseOverrides.put('EtapaAtendimento__c', 'Aguardando Área Interna');
        }
        Case c = createCase(mergedCaseOverrides);

        Categorizacao__c categorizacao = createCategorizacao(categorizacaoOverrides);
        GestaoSLA__c gestao = createGestaoSla(gestaoOverrides);
        linkGestaoSla(categorizacao.Id, gestao.Id);

        for (String area : resolvedAreas) {
            createRegraSla(categorizacao.Id, gestao.Id, area, null);
        }

        c.Categorizacao__c = categorizacao.Id;
        update c;
        return c;
    }

    // ------------------------------------------------------------------
    // GestaoSLA__c
    // ------------------------------------------------------------------

    public static GestaoSLA__c buildGestaoSla(Map<String, Object> overrides) {
        String unidade = pickValue('GestaoSLA__c', 'UnidadeNegocio__c', 0);
        if (String.isBlank(unidade)) unidade = 'Salvador';
        GestaoSLA__c gestao = new GestaoSLA__c(
            Name = 'Gestao SLA Teste ' + randomSuffix(),
            UnidadeNegocio__c = unidade,
            EntitlementProcessName__c = 'Atendimento Salvador',
            BusinessHoursName__c = 'Tecon Salvador',
            Ativo__c = true
        );
        applyOverrides(gestao, overrides);
        return gestao;
    }

    public static GestaoSLA__c createGestaoSla(Map<String, Object> overrides) {
        GestaoSLA__c gestao = buildGestaoSla(overrides);
        insert gestao;
        return gestao;
    }

    // ------------------------------------------------------------------
    // Categorizacao__c
    // ------------------------------------------------------------------

    public static Categorizacao__c buildCategorizacao(Map<String, Object> overrides) {
        Id recordTypeId = overrides != null && overrides.containsKey('RecordTypeId')
            ? (Id) overrides.get('RecordTypeId')
            : anyActiveRecordType('Categorizacao__c').Id;

        String unidade = CaseCreationSelector.resolveCanonicalBusinessUnit(
            [SELECT DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1].DeveloperName
        );
        if (String.isBlank(unidade)) {
            unidade = CaseCreationSelector.resolveCanonicalBusinessUnit('Tecon Salvador');
        }

        Categorizacao__c c = new Categorizacao__c(
            RecordTypeId = recordTypeId,
            UnidadeNegocios__c = unidade,
            TipoCaso__c = 'Solicitação',
            Categoria__c = 'Solicitação',
            Assunto__c = 'Cadastro',
            Subassunto__c = 'Alteração',
            Ativo__c = true,
            DistribuirParaFila__c = 'Não',
            PorCampoCustomizado__c = 'Não'
        );
        applyOverrides(c, overrides);
        return c;
    }

    public static Categorizacao__c createCategorizacao(Map<String, Object> overrides) {
        Categorizacao__c c = buildCategorizacao(overrides);
        insert c;
        return c;
    }

    // Encapsula o `update Categorizacao__c { GestaoSLA__c = ... }` hoje repetido manualmente
    // em vários testes (a Categorizacao__c precisa existir antes da regra ser criada, e só
    // depois é linkada à GestaoSLA__c compartilhada).
    public static Categorizacao__c linkGestaoSla(Id categorizacaoId, Id gestaoSlaId) {
        Categorizacao__c c = new Categorizacao__c(Id = categorizacaoId, GestaoSLA__c = gestaoSlaId);
        update c;
        return c;
    }

    // ------------------------------------------------------------------
    // RegrasSLACategorizacao__c
    // ------------------------------------------------------------------

    public static RegrasSLACategorizacao__c buildRegraSla(Id categorizacaoId, Id gestaoSlaId, String area, Map<String, Object> overrides) {
        RegrasSLACategorizacao__c rule = new RegrasSLACategorizacao__c(
            Categorizacao__c = categorizacaoId,
            AreaAtendimento__c = area,
            BusinessHoursName__c = 'Tecon Salvador',
            Ativo__c = true,
            GestaoSLA__c = gestaoSlaId,
            EscopoRegra__c = RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA,
            TempoBaixa__c = 60,
            TempoMedia__c = 60,
            TempoAlta__c = 60
        );
        applyOverrides(rule, overrides);
        return rule;
    }

    public static RegrasSLACategorizacao__c createRegraSla(Id categorizacaoId, Id gestaoSlaId, String area, Map<String, Object> overrides) {
        RegrasSLACategorizacao__c rule = buildRegraSla(categorizacaoId, gestaoSlaId, area, overrides);
        insert rule;
        return rule;
    }

    // ------------------------------------------------------------------
    // AreaParticipante__c
    // ------------------------------------------------------------------

    // Não força DataHoraInicio__c/DataHoraPrazo__c a menos que estejam em overrides —
    // diferente do createArea legado, que sempre setava prazo.
    public static AreaParticipante__c buildAreaParticipante(Id caseId, Map<String, Object> overrides) {
        List<String> allowed = pickAllValues('AreaParticipante__c', AREA_FIELD);
        AreaParticipante__c row = new AreaParticipante__c(
            Caso__c = caseId,
            StatusAtuacao__c = openStatus(),
            ComentarioSolicitacao__c = 'Solicitação de teste'
        );
        row.put(AREA_FIELD, allowed.isEmpty() ? null : allowed[0]);
        applyOverrides(row, overrides);
        return row;
    }

    // Se o chamador pedir um DataHoraPrazo__c explícito, um trigger de SLA pode recalculá-lo
    // automaticamente no insert (matching de RegrasSLACategorizacao__c) e sobrescrever o valor
    // pedido — por isso, quando a chave está presente em overrides, força de volta via update
    // pós-insert (mesmo padrão usado historicamente pelas factories legadas desta base).
    public static AreaParticipante__c createAreaParticipante(Id caseId, Map<String, Object> overrides) {
        AreaParticipante__c row = buildAreaParticipante(caseId, overrides);
        insert row;
        if (overrides != null && overrides.containsKey('DataHoraPrazo__c')) {
            row.DataHoraPrazo__c = (Datetime) overrides.get('DataHoraPrazo__c');
            update row;
        }
        return row;
    }

    public static String openStatus() {
        for (Schema.PicklistEntry pe : AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues()) {
            String n = AreaParticipanteHelper.normalizeText(pe.getValue() + ' ' + pe.getLabel());
            if (n.contains('abert') || n.contains('andamento') || n.contains('open') || n.contains('progress')) return pe.getValue();
        }
        List<Schema.PicklistEntry> values = AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues();
        return values.isEmpty() ? 'Aberta' : values[0].getValue();
    }

    public static String closedStatus() {
        for (Schema.PicklistEntry pe : AreaParticipante__c.StatusAtuacao__c.getDescribe().getPicklistValues()) {
            String n = AreaParticipanteHelper.normalizeText(pe.getValue() + ' ' + pe.getLabel());
            if (n.contains('conclu') || n.contains('completed') || n.contains('finaliz')) return pe.getValue();
        }
        return AreaParticipanteHelper.resolveConcluidaStatusValue();
    }

    // ------------------------------------------------------------------
    // Reclamacao__c (gap sem factory até então)
    // ------------------------------------------------------------------

    // Espelho mínimo, alinhado ao que ReclamacaoService.buildReclamacao() cria na origem —
    // não replica o enriquecimento de negócio (isso é responsabilidade do Service, testado
    // separadamente via seam próprio).
    public static Reclamacao__c buildReclamacao(Id caseId, Map<String, Object> overrides) {
        Id recordTypeId = overrides != null && overrides.containsKey('RecordTypeId')
            ? (Id) overrides.get('RecordTypeId')
            : anyActiveRecordType('Reclamacao__c').Id;
        Reclamacao__c r = new Reclamacao__c(
            RecordTypeId = recordTypeId,
            Caso__c = caseId,
            Categoria__c = 'Solicitação',
            Assunto__c = 'Cadastro',
            Subassunto__c = 'Alteração'
        );
        applyOverrides(r, overrides);
        return r;
    }

    public static Reclamacao__c createReclamacao(Id caseId, Map<String, Object> overrides) {
        Reclamacao__c r = buildReclamacao(caseId, overrides);
        insert r;
        return r;
    }

    // ------------------------------------------------------------------
    // Agendamento__c (gap sem factory até então)
    // ------------------------------------------------------------------

    public static Agendamento__c buildAgendamento(Map<String, Object> overrides) {
        Agendamento__c a = new Agendamento__c(
            Assunto__c = 'Cadastro',
            Categoria__c = 'Solicitação',
            TipoCaso__c = 'Solicitação',
            UnidadeNegocio__c = 'Salvador',
            Ativo__c = true,
            DataInicio__c = Date.today()
        );
        applyOverrides(a, overrides);
        return a;
    }

    public static Agendamento__c createAgendamento(Map<String, Object> overrides) {
        Agendamento__c a = buildAgendamento(overrides);
        insert a;
        return a;
    }

    // ------------------------------------------------------------------
    // Interno
    // ------------------------------------------------------------------

    private static void applyOverrides(SObject record, Map<String, Object> overrides) {
        if (overrides == null) return;
        for (String key : overrides.keySet()) {
            record.put(key, overrides.get(key));
        }
    }
}