@IsTest
private class CaseAreaAggregationServiceTest {
    private static Case createCaseForAggregation(List<String> areas) {
        return TestDataFactory.createCaseWithSlaChain(new Map<String, Object>{
            'AreasParticipantesSLA__c' => String.join(areas, ';'),
            'EtapaAtendimento__c' => 'Aguardando Área Interna',
            'Priority' => 'Medium',
            'Origin' => 'Manual'
        }, null, null, areas);
    }

    private static Case createCaseWithoutAreas() {
        return TestDataFactory.createCase(new Map<String, Object>{
            'AreasParticipantesSLA__c' => TestDataFactory.commonAreaValues()[0],
            'EtapaAtendimento__c' => 'Aguardando Área Interna',
            'Priority' => 'Medium',
            'Origin' => 'Manual'
        });
    }

    private static String getNonInternalTipoAreaValue() {
        for (Schema.PicklistEntry entry : AreaParticipante__c.TipoAreaParticipante__c.getDescribe().getPicklistValues()) {
            if (!AreaParticipanteSLAHelper.isTipoInterna(entry.getValue())) {
                return entry.getValue();
            }
        }
        return AreaParticipanteSLAHelper.TIPO_AREA_INTERNA;
    }

    private static AreaParticipante__c buildArea(Id caseId, Map<String, Object> overrides) {
        Map<String, Object> mergedOverrides = new Map<String, Object>{
            'TipoAreaParticipante__c' => AreaParticipanteSLAHelper.TIPO_AREA_INTERNA,
            'AreaAtendimento__c' => TestDataFactory.commonAreaValues()[0],
            'ComentarioSolicitacao__c' => 'aggregation test'
        };
        if (overrides != null) {
            mergedOverrides.putAll(overrides);
        }
        return TestDataFactory.buildAreaParticipante(caseId, mergedOverrides);
    }

    @IsTest
    static void shouldRefreshOpenAndDueCountsWhenCasesHaveMixedRows() {
        List<String> availableAreas = TestDataFactory.commonAreaValues();
        Assert.isTrue(availableAreas.size() >= 3,
            'O teste requer pelo menos 3 áreas configuradas em comum entre Case e AreaParticipante.');
        List<String> selectedAreas = new List<String>{ availableAreas[0], availableAreas[1], availableAreas[2] };

        Case caseWithRows = createCaseForAggregation(selectedAreas);
        Case caseWithoutRows = createCaseWithoutAreas();

        List<AreaParticipante__c> areas = new List<AreaParticipante__c>{
            buildArea(caseWithRows.Id, new Map<String, Object>{
                'AreaAtendimento__c' => selectedAreas[0],
                'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
                'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO
            }),
            buildArea(caseWithRows.Id, new Map<String, Object>{
                'AreaAtendimento__c' => selectedAreas[1],
                'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA,
                'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
            }),
            buildArea(caseWithRows.Id, new Map<String, Object>{
                'AreaAtendimento__c' => selectedAreas[2],
                'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_VENCIDA,
                'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
            }),
            buildArea(caseWithRows.Id, new Map<String, Object>{
                'AreaAtendimento__c' => selectedAreas[0],
                'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_CANCELADA,
                'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO,
                'DataHoraFim__c' => System.now()
            }),
            buildArea(caseWithRows.Id, new Map<String, Object>{
                'AreaAtendimento__c' => selectedAreas[1],
                'TipoAreaParticipante__c' => getNonInternalTipoAreaValue(),
                'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
                'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
            })
        };
        insert areas;

        update new List<AreaParticipante__c>{
            new AreaParticipante__c(
                Id = areas[1].Id,
                StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_PAUSADA,
                StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
            ),
            new AreaParticipante__c(
                Id = areas[2].Id,
                StatusAtuacao__c = AreaParticipanteSLAHelper.STATUS_ATUACAO_VENCIDA,
                StatusSLA__c = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
            )
        };

        update new List<Case>{
            new Case(
                Id = caseWithRows.Id,
                QtdAreasParticipantesAbertas__c = 99,
                QtdAreasParticipantesVencidas__c = 99
            ),
            new Case(
                Id = caseWithoutRows.Id,
                QtdAreasParticipantesAbertas__c = 77,
                QtdAreasParticipantesVencidas__c = 77
            )
        };

        Test.startTest();
        CaseAreaParticipanteAggregationService.refreshForCases(new Set<Id>{ caseWithRows.Id, caseWithoutRows.Id });
        Test.stopTest();

        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT QtdAreasParticipantesAbertas__c, QtdAreasParticipantesVencidas__c
            FROM Case
            WHERE Id IN :new Set<Id>{ caseWithRows.Id, caseWithoutRows.Id }
        ]);
        Assert.areEqual(3, Integer.valueOf(casesById.get(caseWithRows.Id).QtdAreasParticipantesAbertas__c),
            'O serviço deve contar apenas áreas internas abertas, em andamento, pausadas ou vencidas.');
        Assert.areEqual(2, Integer.valueOf(casesById.get(caseWithRows.Id).QtdAreasParticipantesVencidas__c),
            'O serviço deve contar apenas áreas internas sem DataHoraFim__c e com SLA vencido.');
        Assert.areEqual(0, Integer.valueOf(casesById.get(caseWithoutRows.Id).QtdAreasParticipantesAbertas__c),
            'Case sem áreas elegíveis deve voltar com zero áreas abertas.');
        Assert.areEqual(0, Integer.valueOf(casesById.get(caseWithoutRows.Id).QtdAreasParticipantesVencidas__c),
            'Case sem áreas elegíveis deve voltar com zero áreas vencidas.');
    }

    @IsTest
    static void shouldSkipRefreshWhenRecursionGuardIsAlreadyEntered() {
        Case c = createCaseForAggregation(new List<String>{ TestDataFactory.commonAreaValues()[0] });
        insert buildArea(c.Id, new Map<String, Object>{
            'StatusAtuacao__c' => AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA,
            'StatusSLA__c' => AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO
        });

        update new Case(
            Id = c.Id,
            QtdAreasParticipantesAbertas__c = 5,
            QtdAreasParticipantesVencidas__c = 6
        );

        AreaParticipanteSLARecursionGuard.enter('CASE_AGGREGATION');
        try {
            Test.startTest();
            CaseAreaParticipanteAggregationService.refreshForCases(new Set<Id>{ c.Id });
            Test.stopTest();
        } finally {
            AreaParticipanteSLARecursionGuard.leave('CASE_AGGREGATION');
        }

        Case caseAfter = [
            SELECT QtdAreasParticipantesAbertas__c, QtdAreasParticipantesVencidas__c
            FROM Case
            WHERE Id = :c.Id
        ];
        Assert.areEqual(5, Integer.valueOf(caseAfter.QtdAreasParticipantesAbertas__c),
            'Quando o guard já está ativo, o serviço não deve recalcular áreas abertas.');
        Assert.areEqual(6, Integer.valueOf(caseAfter.QtdAreasParticipantesVencidas__c),
            'Quando o guard já está ativo, o serviço não deve recalcular áreas vencidas.');
    }

    @IsTest
    static void shouldIgnoreNullOrEmptyCaseSets() {
        Case c = createCaseForAggregation(new List<String>{ TestDataFactory.commonAreaValues()[0] });
        update new Case(
            Id = c.Id,
            QtdAreasParticipantesAbertas__c = 3,
            QtdAreasParticipantesVencidas__c = 4
        );

        Test.startTest();
        CaseAreaParticipanteAggregationService.refreshForCases(null);
        CaseAreaParticipanteAggregationService.refreshForCases(new Set<Id>());
        Test.stopTest();

        Case caseAfter = [
            SELECT QtdAreasParticipantesAbertas__c, QtdAreasParticipantesVencidas__c
            FROM Case
            WHERE Id = :c.Id
        ];
        Assert.areEqual(3, Integer.valueOf(caseAfter.QtdAreasParticipantesAbertas__c),
            'Set nulo ou vazio não deve alterar a contagem de áreas abertas.');
        Assert.areEqual(4, Integer.valueOf(caseAfter.QtdAreasParticipantesVencidas__c),
            'Set nulo ou vazio não deve alterar a contagem de áreas vencidas.');
    }
}
