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
    private static final String ETAPA_AGUARDANDO_AREA_INTERNA = 'Aguardando Área Interna';
    private static final String ETAPA_PREPARANDO_RETORNO = 'Preparando Retorno ao Cliente';
    private static final String AREA_FIELD = 'AreaAtendimento__c';

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
                SELECT Id, OwnerId, Status, EtapaAtendimento__c, AreasParticipantes__c, AreasParticipantesSLA__c, Categorizacao__c,
                       Categorizacao__r.GestaoSLA__c,
                       Categorizacao__r.GestaoSLA__r.PossuiBusinessHoursSecundario__c,
                       Categorizacao__r.GestaoSLA__r.RegiaoAtendimentoSecundaria__c
                FROM Case
                WHERE Id IN :changedOwnerCaseIds
            ];

            Set<Id> ownerIds = new Set<Id>();
            Set<Id> eligibleCaseIds = new Set<Id>();
            Set<Id> categorizacaoIds = new Set<Id>();
            Set<Id> gestaoIds = new Set<Id>();
            for (Case c : cases) {
                if (c.OwnerId != null) ownerIds.add(c.OwnerId);
                if (!isEligibleForSecondaryRegionAutomation(c)) continue;
                eligibleCaseIds.add(c.Id);
                categorizacaoIds.add(c.Categorizacao__c);
                gestaoIds.add(c.Categorizacao__r.GestaoSLA__c);
            }

            Map<Id, User> userById = ownerIds.isEmpty()
                ? new Map<Id, User>()
                : new Map<Id, User>([SELECT Id, RegiaoAtendimentoSecundaria__c FROM User WHERE Id IN :ownerIds]);

            if (eligibleCaseIds.isEmpty()) return;

            Map<Id, List<AreaParticipante__c>> regionAreasByCase = getRegionAreasByCase(eligibleCaseIds);
            Map<String, String> regionAreaByRuleKey = getRegionAreaByRuleKey(categorizacaoIds, gestaoIds);
            Map<Id, Case> caseById = new Map<Id, Case>(cases);
            Datetime nowRef = System.now();

            List<AreaParticipante__c> areasToInsert = new List<AreaParticipante__c>();
            List<Id> insertCaseIds = new List<Id>();
            List<String> insertAreaValues = new List<String>();
            List<AreaParticipante__c> areasToClose = new List<AreaParticipante__c>();
            List<Id> closeCaseIds = new List<Id>();
            List<String> closeAreaValues = new List<String>();

            for (Case c : cases) {
                if (!eligibleCaseIds.contains(c.Id)) continue;

                String gestaoRegiao = c.Categorizacao__r.GestaoSLA__r.RegiaoAtendimentoSecundaria__c;
                User owner = userById.get(c.OwnerId);
                Boolean ownerMatchesRegiao = owner != null && gestaoRegiao == owner.RegiaoAtendimentoSecundaria__c;
                List<AreaParticipante__c> regionAreas = regionAreasByCase.get(c.Id);
                if (regionAreas == null) regionAreas = new List<AreaParticipante__c>();

                if (ownerMatchesRegiao) {
                    if (hasOpenRegionArea(regionAreas)) continue;

                    String area = regionAreaByRuleKey.get(buildRuleKey(c.Categorizacao__c, c.Categorizacao__r.GestaoSLA__c));
                    if (String.isBlank(area)) continue;

                    areasToInsert.add(buildRegionAreaToOpen(c.Id, area, nowRef));
                    insertCaseIds.add(c.Id);
                    insertAreaValues.add(area);
                    continue;
                }

                for (AreaParticipante__c regionArea : regionAreas) {
                    if (!AreaParticipanteHelper.isAbertaOuAndamento(regionArea.StatusAtuacao__c)) continue;

                    prepareRegionAreaToClose(regionArea, nowRef);
                    areasToClose.add(regionArea);
                    closeCaseIds.add(c.Id);
                    closeAreaValues.add((String) regionArea.get(AREA_FIELD));
                }
            }

            Map<Id, String> caseAreasSlaById = new Map<Id, String>();
            Map<Id, String> caseAreasById = new Map<Id, String>();
            Set<Id> casesToAguardarAreaInterna = new Set<Id>();
            Set<Id> casesWithSuccessfulClose = new Set<Id>();

            if (!areasToInsert.isEmpty()) {
                Database.SaveResult[] insertResults = Database.insert(areasToInsert, false);
                for (Integer i = 0; i < insertResults.size(); i++) {
                    Id caseId = insertCaseIds[i];
                    if (!insertResults[i].isSuccess()) {
                        logDmlErrors('abrir área automática', caseId, insertResults[i].getErrors());
                        continue;
                    }

                    Case caseRow = caseById.get(caseId);
                    String currentAreasSla = caseAreasSlaById.containsKey(caseId)
                        ? caseAreasSlaById.get(caseId)
                        : caseRow.AreasParticipantesSLA__c;
                    String currentAreas = caseAreasById.containsKey(caseId)
                        ? caseAreasById.get(caseId)
                        : caseRow.AreasParticipantes__c;

                    caseAreasSlaById.put(caseId, AreaParticipanteHelper.addValue(currentAreasSla, insertAreaValues[i]));
                    caseAreasById.put(caseId, AreaParticipanteHelper.addValue(currentAreas, insertAreaValues[i]));
                    if (!isTerminalCase(caseRow)) {
                        casesToAguardarAreaInterna.add(caseId);
                    }
                }
            }

            if (!areasToClose.isEmpty()) {
                Database.SaveResult[] closeResults = Database.update(areasToClose, false);
                for (Integer i = 0; i < closeResults.size(); i++) {
                    Id caseId = closeCaseIds[i];
                    if (!closeResults[i].isSuccess()) {
                        logDmlErrors('encerrar área automática', caseId, closeResults[i].getErrors());
                        continue;
                    }

                    Case caseRow = caseById.get(caseId);
                    String currentAreasSla = caseAreasSlaById.containsKey(caseId)
                        ? caseAreasSlaById.get(caseId)
                        : caseRow.AreasParticipantesSLA__c;
                    caseAreasSlaById.put(caseId, AreaParticipanteHelper.removeValue(currentAreasSla, closeAreaValues[i]));
                    casesWithSuccessfulClose.add(caseId);
                }
            }

            Set<Id> casesToPrepararRetorno = new Set<Id>();
            if (!casesWithSuccessfulClose.isEmpty()) {
                Map<Id, Integer> remainingOpenCustomAreasByCase = countRemainingOpenCustomAreas(casesWithSuccessfulClose);
                for (Id caseId : casesWithSuccessfulClose) {
                    if (isTerminalCase(caseById.get(caseId))) continue;
                    if ((remainingOpenCustomAreasByCase.containsKey(caseId) ? remainingOpenCustomAreasByCase.get(caseId) : 0) == 0) {
                        casesToPrepararRetorno.add(caseId);
                    }
                }
            }

            List<Case> casesToUpdate = new List<Case>();
            Set<Id> caseIdsToUpdate = new Set<Id>();
            caseIdsToUpdate.addAll(caseAreasSlaById.keySet());
            caseIdsToUpdate.addAll(caseAreasById.keySet());
            caseIdsToUpdate.addAll(casesToAguardarAreaInterna);
            caseIdsToUpdate.addAll(casesToPrepararRetorno);

            for (Id caseId : caseIdsToUpdate) {
                Case caseUpdate = new Case(Id = caseId);
                Boolean hasChanges = false;
                if (caseAreasSlaById.containsKey(caseId)) {
                    caseUpdate.AreasParticipantesSLA__c = caseAreasSlaById.get(caseId);
                    hasChanges = true;
                }
                if (caseAreasById.containsKey(caseId)) {
                    caseUpdate.AreasParticipantes__c = caseAreasById.get(caseId);
                    hasChanges = true;
                }
                if (casesToPrepararRetorno.contains(caseId)) {
                    caseUpdate.EtapaAtendimento__c = ETAPA_PREPARANDO_RETORNO;
                    hasChanges = true;
                } else if (casesToAguardarAreaInterna.contains(caseId)) {
                    caseUpdate.EtapaAtendimento__c = ETAPA_AGUARDANDO_AREA_INTERNA;
                    hasChanges = true;
                }
                if (hasChanges) {
                    casesToUpdate.add(caseUpdate);
                }
            }

            if (!casesToUpdate.isEmpty()) {
                Database.SaveResult[] caseResults = Database.update(casesToUpdate, false);
                for (Integer i = 0; i < caseResults.size(); i++) {
                    if (caseResults[i].isSuccess()) continue;
                    logDmlErrors('sincronizar Case após automação de região', casesToUpdate[i].Id, caseResults[i].getErrors());
                }
            }
        } finally {
            AreaParticipanteSLARecursionGuard.leave(GUARD_KEY);
        }
    }

    private static Boolean isEligibleForSecondaryRegionAutomation(Case caseRow) {
        return caseRow != null
            && caseRow.Categorizacao__c != null
            && caseRow.Categorizacao__r.GestaoSLA__c != null
            && caseRow.Categorizacao__r.GestaoSLA__r.PossuiBusinessHoursSecundario__c == true
            && !String.isBlank(caseRow.Categorizacao__r.GestaoSLA__r.RegiaoAtendimentoSecundaria__c);
    }

    private static Map<Id, List<AreaParticipante__c>> getRegionAreasByCase(Set<Id> caseIds) {
        Map<Id, List<AreaParticipante__c>> areasByCase = new Map<Id, List<AreaParticipante__c>>();
        if (caseIds == null || caseIds.isEmpty()) return areasByCase;

        for (AreaParticipante__c area : [
            SELECT Id, Caso__c, AreaAtendimento__c, StatusAtuacao__c, TipoAreaParticipante__c, OrigemSLA__c,
                   DataHoraInicio__c, DataHoraPrazo__c
            FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds
              AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND RegraSLACategorizacao__r.UsaBusinessHoursSecundario__c = true
        ]) {
            if (!areasByCase.containsKey(area.Caso__c)) {
                areasByCase.put(area.Caso__c, new List<AreaParticipante__c>());
            }
            areasByCase.get(area.Caso__c).add(area);
        }
        return areasByCase;
    }

    private static Boolean hasOpenRegionArea(List<AreaParticipante__c> regionAreas) {
        if (regionAreas == null) return false;
        for (AreaParticipante__c regionArea : regionAreas) {
            if (AreaParticipanteHelper.isAbertaOuAndamento(regionArea.StatusAtuacao__c)) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, String> getRegionAreaByRuleKey(Set<Id> categorizacaoIds, Set<Id> gestaoIds) {
        Map<String, String> areaByRuleKey = new Map<String, String>();
        if (categorizacaoIds == null || categorizacaoIds.isEmpty() || gestaoIds == null || gestaoIds.isEmpty()) {
            return areaByRuleKey;
        }

        for (RegrasSLACategorizacao__c rule : [
            SELECT Categorizacao__c, GestaoSLA__c, AreaAtendimento__c
            FROM RegrasSLACategorizacao__c
            WHERE Ativo__c = true
              AND Categorizacao__c IN :categorizacaoIds
              AND GestaoSLA__c IN :gestaoIds
              AND EscopoRegra__c = :RegrasSLACompatibilidadeService.ESCOPO_AREA_INTERNA
              AND UsaBusinessHoursSecundario__c = true
              AND AreaAtendimento__c != null
            ORDER BY CreatedDate ASC, Id ASC
        ]) {
            String key = buildRuleKey(rule.Categorizacao__c, rule.GestaoSLA__c);
            if (!areaByRuleKey.containsKey(key)) {
                areaByRuleKey.put(key, rule.AreaAtendimento__c);
            }
        }
        return areaByRuleKey;
    }

    private static String buildRuleKey(Id categorizacaoId, Id gestaoId) {
        return String.valueOf(categorizacaoId) + '|' + String.valueOf(gestaoId);
    }

    private static AreaParticipante__c buildRegionAreaToOpen(Id caseId, String area, Datetime nowRef) {
        AreaParticipante__c regionArea = new AreaParticipante__c();
        regionArea.Caso__c = caseId;
        regionArea.put(AREA_FIELD, area);
        regionArea.TipoAreaParticipante__c = AreaParticipanteSLAHelper.TIPO_AREA_INTERNA;
        regionArea.OrigemAtuacao__c = 'Manual';
        regionArea.StatusAtuacao__c = AreaParticipanteHelper.resolveOpenStatusValue();
        regionArea.DataHoraInicio__c = nowRef;
        regionArea.ComentarioSolicitacao__c = COMENTARIO_ABERTURA;
        if (AreaParticipante__c.Solicitante__c.getDescribe().isCreateable()) {
            regionArea.Solicitante__c = UserInfo.getUserId();
        }
        return regionArea;
    }

    private static void prepareRegionAreaToClose(AreaParticipante__c regionArea, Datetime nowRef) {
        regionArea.StatusAtuacao__c = AreaParticipanteHelper.resolveConcluidaStatusValue();
        regionArea.DataHoraFim__c = nowRef;
        regionArea.ComentarioRetorno__c = COMENTARIO_FECHAMENTO;
        regionArea.SolucaoTomada__c = COMENTARIO_FECHAMENTO;
        if (AreaParticipante__c.FinalizadoPor__c.getDescribe().isUpdateable()) {
            regionArea.FinalizadoPor__c = UserInfo.getUserId();
        }
        if (AreaParticipante__c.ViolouSLA__c.getDescribe().isUpdateable()) {
            regionArea.ViolouSLA__c = regionArea.DataHoraPrazo__c != null && nowRef.getTime() > regionArea.DataHoraPrazo__c.getTime();
        }
        if (AreaParticipante__c.PercentualDecorrido__c.getDescribe().isUpdateable()
            && regionArea.DataHoraInicio__c != null
            && regionArea.DataHoraPrazo__c != null) {
            regionArea.PercentualDecorrido__c =
                AreaParticipanteHelper.calculatePercent(regionArea.DataHoraInicio__c, regionArea.DataHoraPrazo__c, nowRef);
        }
    }

    private static Map<Id, Integer> countRemainingOpenCustomAreas(Set<Id> caseIds) {
        Map<Id, Integer> openCustomAreasByCase = new Map<Id, Integer>();
        for (AreaParticipante__c regionArea : [
            SELECT Id, Caso__c, StatusAtuacao__c, DataHoraPrazo__c
            FROM AreaParticipante__c
            WHERE Caso__c IN :caseIds
              AND TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM
              AND DataHoraFim__c = null
        ]) {
            if (!AreaParticipanteHelper.isAbertaOuAndamento(regionArea.StatusAtuacao__c)
                && !AreaParticipanteHelper.isOverdue(regionArea.DataHoraPrazo__c, System.now(), regionArea.StatusAtuacao__c)) {
                continue;
            }
            openCustomAreasByCase.put(
                regionArea.Caso__c,
                (openCustomAreasByCase.containsKey(regionArea.Caso__c) ? openCustomAreasByCase.get(regionArea.Caso__c) : 0) + 1
            );
        }
        return openCustomAreasByCase;
    }

    private static Boolean isTerminalCase(Case caseRow) {
        String etapaNorm = AreaParticipanteHelper.normalizeText(caseRow.EtapaAtendimento__c);
        String statusNorm = AreaParticipanteHelper.normalizeText(caseRow.Status);
        return statusNorm.contains('fechad') || etapaNorm.contains('conclu') || etapaNorm.contains('cancel');
    }

    private static void logDmlErrors(String action, Id caseId, Database.Error[] errors) {
        if (errors == null || errors.isEmpty()) return;
        List<String> messages = new List<String>();
        for (Database.Error error : errors) {
            messages.add(error.getMessage());
        }
        System.debug(
            LoggingLevel.WARN,
            'AreaParticipanteRegiaoAtendimentoService falhou ao ' + action + ' para Case ' + caseId + ': ' + String.join(messages, ' | ')
        );
    }
}
