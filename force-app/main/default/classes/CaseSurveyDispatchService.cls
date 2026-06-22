/**
 * @description       : Service de disparo de Survey de Atendimento após fechamento do Case.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Marllon Nascimento
 **/
public inherited sharing class CaseSurveyDispatchService {
    @TestVisible private static Map<String, Id> testSurveyIdsByDeveloperName;
    @TestVisible private static Map<String, Id> testTemplateIdsByDeveloperName;
    @TestVisible private static Map<String, Id> testOrgWideEmailIdsByAddress;
    @TestVisible private static Map<String, Id> testNetworkIdsByUrlPathPrefix;
    @TestVisible private static Set<Id> testCasesWithSurveySubject;

    private class DispatchPlan {
        Case caseRecord;
        AtendimentoConfigDTO config;
        String language;
        Boolean sendSurvey;
        String surveyName;
        String templateName;
    }

    /**
     * @description Processa Cases elegíveis para criação/envio de Survey Invitation.
     * @param requests Requisições da FlowAction.
     * @return Resultado por Case solicitado.
     */
    public static List<CaseSurveyDispatchDTO.Response> dispatch(List<CaseSurveyDispatchDTO.Request> requests) {
        Set<Id> caseIds = CaseSurveyDispatchHelper.extractCaseIds(requests);
        if (caseIds.isEmpty()) return new List<CaseSurveyDispatchDTO.Response>();

        Map<Id, Case> casesById = CaseSurveyDispatchSelector.selectCasesById(caseIds);

        Set<Id> alreadyLinkedCaseIds = getCasesWithSurveySubject(caseIds);
        Set<String> surveyNames = new Set<String>();
        Set<String> templateNames = new Set<String>();
        Set<String> orgWideEmailAddresses = new Set<String>();
        Set<String> networkUrlPathPrefixes = new Set<String>();

        List<CaseSurveyDispatchDTO.Response> responses = new List<CaseSurveyDispatchDTO.Response>();
        List<DispatchPlan> plans = new List<DispatchPlan>();
        for (Id caseId : caseIds) {
            Case c = casesById.get(caseId);
            String skipReason = getSkipReason(c, alreadyLinkedCaseIds);
            if (skipReason != null) {
                responses.add(CaseSurveyDispatchHelper.response(caseId, true, skipReason, null));
                continue;
            }

            AtendimentoConfigDTO config = AtendimentoConfigService.getSurveyConfigByBusinessUnit(c.UnidadeNegocio__c);
            skipReason = getConfigSkipReason(c, config);
            if (skipReason != null) {
                responses.add(CaseSurveyDispatchHelper.response(caseId, true, skipReason, null));
                continue;
            }

            String language = CaseSurveyDispatchHelper.resolveLanguage(c, config);
            Boolean sendSurvey = shouldSendSurvey(c, config);
            String surveyName = sendSurvey ? CaseSurveyDispatchHelper.chooseSurveyDeveloperName(config, language) : null;
            String templateName = sendSurvey
                ? CaseSurveyDispatchHelper.chooseTemplateDeveloperName(config, language)
                : CaseSurveyDispatchHelper.chooseCaseClosureTemplateDeveloperName(config, language);

            DispatchPlan plan = new DispatchPlan();
            plan.caseRecord = c;
            plan.config = config;
            plan.language = language;
            plan.sendSurvey = sendSurvey;
            plan.surveyName = surveyName;
            plan.templateName = templateName;
            plans.add(plan);

            if (!String.isBlank(surveyName)) surveyNames.add(surveyName);
            if (!String.isBlank(templateName)) templateNames.add(templateName);
            if (!String.isBlank(config.orgWideEmailAddress)) {
                orgWideEmailAddresses.add(config.orgWideEmailAddress.trim().toLowerCase());
            }
            if (sendSurvey && !String.isBlank(config.surveyCommunityUrlPathPrefix)) {
                networkUrlPathPrefixes.add(config.surveyCommunityUrlPathPrefix.trim());
            }
        }

        Map<String, Id> surveyIdsByName = getSurveyIdsByDeveloperName(surveyNames);
        Map<String, Id> templateIdsByName = getTemplateIdsByDeveloperName(templateNames);
        Map<String, Id> orgWideEmailIdsByAddress = getOrgWideEmailIdsByAddress(orgWideEmailAddresses);
        Map<String, Id> networkIdsByUrlPathPrefix = getNetworkIdsByUrlPathPrefix(networkUrlPathPrefixes);
        List<CaseSurveyDispatchServiceAgent.DispatchEnvelope> surveyEnvelopes = new List<CaseSurveyDispatchServiceAgent.DispatchEnvelope>();
        List<CaseSurveyDispatchServiceAgent.CaseClosureEnvelope> closureEnvelopes = new List<CaseSurveyDispatchServiceAgent.CaseClosureEnvelope>();

        for (DispatchPlan plan : plans) {
            Case c = plan.caseRecord;
            AtendimentoConfigDTO config = plan.config;
            Id templateId = templateIdsByName.get(plan.templateName);

            if (templateId == null) {
                responses.add(CaseSurveyDispatchHelper.response(c.Id, false, 'Template de e-mail não encontrado para a unidade de negócio e idioma do contato.', null));
                continue;
            }
            Id orgWideEmailAddressId = String.isBlank(config.orgWideEmailAddress)
                ? null
                : orgWideEmailIdsByAddress.get(config.orgWideEmailAddress.trim().toLowerCase());

            if (plan.sendSurvey == true) {
                Id surveyId = surveyIdsByName.get(plan.surveyName);
                Id communityId = String.isBlank(config.surveyCommunityUrlPathPrefix)
                    ? null
                    : networkIdsByUrlPathPrefix.get(config.surveyCommunityUrlPathPrefix.trim().toLowerCase());

                if (surveyId == null) {
                    responses.add(CaseSurveyDispatchHelper.response(c.Id, false, 'Survey não encontrada para a unidade de negócio e idioma do contato.', null));
                    continue;
                }
                if (communityId == null) {
                    responses.add(CaseSurveyDispatchHelper.response(c.Id, false, 'Comunidade de Survey não encontrada para a unidade de negócio.', null));
                    continue;
                }

                CaseSurveyDispatchServiceAgent.DispatchEnvelope envelope = new CaseSurveyDispatchServiceAgent.DispatchEnvelope();
                envelope.caseRecord = c;
                envelope.surveyId = surveyId;
                envelope.emailTemplateId = templateId;
                envelope.orgWideEmailAddressId = orgWideEmailAddressId;
                envelope.communityId = communityId;
                surveyEnvelopes.add(envelope);
            } else {
                CaseSurveyDispatchServiceAgent.CaseClosureEnvelope envelope = new CaseSurveyDispatchServiceAgent.CaseClosureEnvelope();
                envelope.caseRecord = c;
                envelope.emailTemplateId = templateId;
                envelope.orgWideEmailAddressId = orgWideEmailAddressId;
                closureEnvelopes.add(envelope);
            }
        }

        List<CaseSurveyDispatchServiceAgent.DispatchResult> surveyResults = CaseSurveyDispatchServiceAgent.send(surveyEnvelopes);
        List<CaseSurveyDispatchServiceAgent.DispatchResult> closureResults = CaseSurveyDispatchServiceAgent.sendCaseClosureEmails(closureEnvelopes);

        List<Case> casesToUpdate = new List<Case>();
        for (CaseSurveyDispatchServiceAgent.DispatchResult sent : surveyResults) {
            if (sent.success == true) {
                casesToUpdate.add(new Case(
                    Id = sent.caseId,
                    PesquisaEnviada__c = true,
                    DataHoraEnvioPesquisa__c = System.now()
                ));
            }
            responses.add(CaseSurveyDispatchHelper.response(sent.caseId, sent.success, sent.message, sent.surveyInvitationId));
        }
        for (CaseSurveyDispatchServiceAgent.DispatchResult sent : closureResults) {
            responses.add(CaseSurveyDispatchHelper.response(sent.caseId, sent.success, sent.message, null));
        }
        if (!casesToUpdate.isEmpty()) update casesToUpdate;

        return responses;
    }

    private static String getSkipReason(Case c, Set<Id> alreadyLinkedCaseIds) {
        if (c == null) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Case não encontrado.';
        if (c.IsClosed != true) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Case não está fechado.';
        if (c.PesquisaEnviada__c == true) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Survey já marcada como enviada.';
        if (alreadyLinkedCaseIds.contains(c.Id)) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Case já possui Survey vinculada.';
        if (c.ContactId == null) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Case sem contato para envio do template.';
        if (String.isBlank(CaseClosureSurveyHelper.resolveRecipientEmail(c))) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Contato sem e-mail.';
        return null;
    }

    private static String getConfigSkipReason(Case c, AtendimentoConfigDTO config) {
        if (config == null || config.isActive != true) return CaseSurveyDispatchHelper.STATUS_SKIPPED + ': Configuração de atendimento inativa ou ausente.';
        return null;
    }

    private static Boolean shouldSendSurvey(Case c, AtendimentoConfigDTO config) {
        if (c.EnviarPesquisaSatisfacao__c != true) return false;
        if (AtendimentoConfigHelper.normalizeSurveyMode(config.surveyMode) == AtendimentoConfigHelper.SURVEY_MODE_NEVER) return false;
        if (CaseClosureSurveyHelper.isBlockedInternalDomain(CaseClosureSurveyHelper.resolveRecipientEmail(c), config.blockedInternalDomain)) return false;
        return true;
    }

    private static Set<Id> getCasesWithSurveySubject(Set<Id> caseIds) {
        if (Test.isRunningTest() && testCasesWithSurveySubject != null) {
            return new Set<Id>(testCasesWithSurveySubject);
        }
        Set<Id> linked = new Set<Id>();
        for (SurveySubject subject : CaseSurveyDispatchSelector.selectSurveySubjectsByCaseIds(caseIds)) {
            linked.add(subject.SubjectId);
        }
        return linked;
    }

    private static Map<String, Id> getSurveyIdsByDeveloperName(Set<String> developerNames) {
        if (Test.isRunningTest() && testSurveyIdsByDeveloperName != null) {
            return new Map<String, Id>(testSurveyIdsByDeveloperName);
        }
        Map<String, Id> result = new Map<String, Id>();
        if (developerNames.isEmpty()) return result;
        for (Survey survey : CaseSurveyDispatchSelector.selectSurveysByDeveloperNames(developerNames)) {
            result.put(survey.DeveloperName, survey.Id);
        }
        return result;
    }

    private static Map<String, Id> getTemplateIdsByDeveloperName(Set<String> developerNames) {
        if (Test.isRunningTest() && testTemplateIdsByDeveloperName != null) {
            return new Map<String, Id>(testTemplateIdsByDeveloperName);
        }
        Map<String, Id> result = new Map<String, Id>();
        if (developerNames.isEmpty()) return result;
        for (EmailTemplate template : CaseSurveyDispatchSelector.selectEmailTemplatesByDeveloperNames(developerNames)) {
            result.put(template.DeveloperName, template.Id);
        }
        return result;
    }

    private static Map<String, Id> getOrgWideEmailIdsByAddress(Set<String> addresses) {
        if (Test.isRunningTest() && testOrgWideEmailIdsByAddress != null) {
            return new Map<String, Id>(testOrgWideEmailIdsByAddress);
        }
        Map<String, Id> result = new Map<String, Id>();
        if (addresses.isEmpty()) return result;
        for (OrgWideEmailAddress sender : CaseSurveyDispatchSelector.selectOrgWideEmailsByAddresses(addresses)) {
            result.put(sender.Address.toLowerCase(), sender.Id);
        }
        return result;
    }

    private static Map<String, Id> getNetworkIdsByUrlPathPrefix(Set<String> urlPathPrefixes) {
        if (Test.isRunningTest() && testNetworkIdsByUrlPathPrefix != null) {
            return new Map<String, Id>(testNetworkIdsByUrlPathPrefix);
        }
        Map<String, Id> result = new Map<String, Id>();
        if (urlPathPrefixes.isEmpty()) return result;
        for (Network network : CaseSurveyDispatchSelector.selectNetworksByUrlPathPrefixes(urlPathPrefixes)) {
            result.put(network.UrlPathPrefix.toLowerCase(), network.Id);
        }
        return result;
    }
}