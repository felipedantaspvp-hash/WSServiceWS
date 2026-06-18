/**
 * @description       : Serviço isolado que abre/encerra automaticamente a Área Interna de SLA de uma
 *                      Região de Atendimento Secundária (ex: Rebocadores com equipe na China), de acordo
 *                      com a região cadastrada no usuário responsável (Owner) do Case. Totalmente
 *                      orientado a dados: não há nenhuma referência a unidade de negócio ou região
 *                      específica neste código — tudo vem de GestaoSLA__c, RegrasSLACategorizacao__c e User.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteRegiaoAtendimentoService {
    private static final String GUARD_KEY = 'AREA_REGIAO_ATENDIMENTO';
    private static final String COMENTARIO_ABERTURA =
        'Aberto automaticamente para acompanhamento de SLA da Região de Atendimento Secundária.';
    private static final String COMENTARIO_FECHAMENTO =
        'Encerrado automaticamente: o Case não está mais com um atendente da Região de Atendimento Secundária.';

    public static void handleOwnerChange(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        if (newMap == null || newMap.isEmpty() || oldMap == null) return;
        if (!AreaParticipanteSLARecursionGuard.enter(GUARD_KEY)) return;

        try {
            Set<Id> changedOwnerCaseIds = new Set<Id>();
            for (Id caseId : newMap.keySet()) {
                Case n = newMap.get(caseId);
                Case o = oldMap.get(caseId);
                if (n == null || o == null) continue;
                if (n.OwnerId != o.OwnerId) changedOwnerCaseIds.add(caseId);
            }
            if (changedOwnerCaseIds.isEmpty()) return;

            List<Case> cases = [
                SELECT Id, OwnerId, Categorizacao__c,
                       Categorizacao__r.GestaoSLA__c,
                       Categorizacao__r.GestaoSLA__r.PossuiBusinessHoursSecundario__c,
                       Categorizacao__r.GestaoSLA__r.RegiaoAtendimentoSecundaria__c
                FROM Case
                WHERE Id IN :changedOwnerCaseIds
            ];

            Set<Id> ownerIds = new Set<Id>();
            for (Case c : cases) {
                if (c.OwnerId != null) ownerIds.add(c.OwnerId);
            }

            Map<Id, User> userById = ownerIds.isEmpty()
                ? new Map<Id, User>()
                : new Map<Id, User>([SELECT Id, RegiaoAtendimentoSecundaria__c FROM User WHERE Id IN :ownerIds]);

            for (Case c : cases) {
                if (c.Categorizacao__c == null || c.Categorizacao__r.GestaoSLA__c == null) continue;
                if (c.Categorizacao__r.GestaoSLA__r.PossuiBusinessHoursSecundario__c != true) continue;

                String gestaoRegiao = c.Categorizacao__r.GestaoSLA__r.RegiaoAtendimentoSecundaria__c;
                if (String.isBlank(gestaoRegiao)) continue;

                User owner = userById.get(c.OwnerId);
                Boolean ownerMatchesRegiao = owner != null && gestaoRegiao == owner.RegiaoAtendimentoSecundaria__c;

                try {
                    if (ownerMatchesRegiao) {
                        ensureRegionAreaOpen(c.Id, c.Categorizacao__c, c.Categorizacao__r.GestaoSLA__c);
                    } else {
                        closeRegionAreaIfOpen(c.Id);
                    }
                } catch (Exception ex) {
                    // Automação auxiliar: uma falha aqui nunca deve impedir o salvamento do Case.
                    System.debug(LoggingLevel.WARN, 'AreaParticipanteRegiaoAtendimentoService falhou para Case ' + c.Id + ': ' + ex.getMessage());
                }
            }
        } finally {
            AreaParticipanteSLARecursionGuard.leave(GUARD_KEY);
        }
    }

    private static void ensureRegionAreaOpen(Id caseId, Id categorizacaoId, Id gestaoId) {
        for (AreaParticipante__c a : [
            SELECT Id, StatusAtuacao__c
            FROM AreaParticipante__c
            WHERE Caso__c = :caseId
              AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND RegraSLACategorizacao__r.UsaBusinessHoursSecundario__c = true
        ]) {
            if (AreaParticipanteHelper.isAbertaOuAndamento(a.StatusAtuacao__c)) return;
        }

        String area = resolveRegionArea(categorizacaoId, gestaoId);
        if (String.isBlank(area)) return;

        AreaParticipanteDTO.AddBulkItemDTO item = new AreaParticipanteDTO.AddBulkItemDTO();
        item.area = area;
        item.comentarioSolicitacao = COMENTARIO_ABERTURA;

        AreaParticipanteDTO.AddBulkRequestDTO request = new AreaParticipanteDTO.AddBulkRequestDTO();
        request.caseId = caseId;
        request.items = new List<AreaParticipanteDTO.AddBulkItemDTO>{ item };

        AreaParticipanteService.addParticipationBulk(request);
    }

    private static void closeRegionAreaIfOpen(Id caseId) {
        for (AreaParticipante__c a : [
            SELECT Id, StatusAtuacao__c
            FROM AreaParticipante__c
            WHERE Caso__c = :caseId
              AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND RegraSLACategorizacao__r.UsaBusinessHoursSecundario__c = true
        ]) {
            if (!AreaParticipanteHelper.isAbertaOuAndamento(a.StatusAtuacao__c)) continue;

            AreaParticipanteDTO.CloseRequestDTO request = new AreaParticipanteDTO.CloseRequestDTO();
            request.areaParticipanteId = a.Id;
            request.comentarioRetorno = COMENTARIO_FECHAMENTO;
            request.solucaoRetorno = COMENTARIO_FECHAMENTO;
            AreaParticipanteService.closeParticipation(request);
        }
    }

    private static String resolveRegionArea(Id categorizacaoId, Id gestaoId) {
        List<RegrasSLACategorizacao__c> rules = [
            SELECT AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
              AND Categorizacao__c = :categorizacaoId
              AND GestaoSLA__c = :gestaoId
              AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
              AND UsaBusinessHoursSecundario__c = true
              AND AreaAtendimento__c != null
            LIMIT 1
        ];
        return rules.isEmpty() ? null : rules[0].AreaAtendimento__c;
    }
}
