/**
 * @description       : Aplica a distribuicao parametrizada por Categorizacao__c no before insert de Case,
 *                       mantendo a automacao trigger-side separada do fluxo sincrono do wizard de criacao.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 07-04-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseCategorizacaoDistributionService {
    private static final String ACAO_ENCERRAR = 'Encerrar';
    private static final String ACAO_ASSUMIR = 'Assumir';
    private static final String ORIGEM_DISTRIBUICAO_CATEGORIZACAO = 'Categorização';

    /**
     * Reforca a fila parametrizada da Categorizacao no before insert do Case.
     * @param newRows Cases sendo inseridos no contexto before insert
     */
    public static void applyDistribution(List<Case> newRows) {
        Set<Id> categorizacaoIds = new Set<Id>();
        for (Case currentCase : newRows) {
            if (currentCase.Categorizacao__c != null) {
                categorizacaoIds.add(currentCase.Categorizacao__c);
            }
        }
        if (categorizacaoIds.isEmpty()) {
            return;
        }

        Map<Id, Categorizacao__c> categorizacoesById = new Map<Id, Categorizacao__c>([
            SELECT Id, DistribuirParaFila__c, PorCampoCustomizado__c, CampoDistribuicao__c, ValorDistribuicao__c,
                   FilaDeveloperName__c, FilaId__c, FilaDeveloperNameFallback__c, FilaIdFallback__c,
                   PermiteAssumirComFilaParametrizada__c, EtapaAtendimentoDistribuicao__c
            FROM Categorizacao__c
            WHERE Id IN :categorizacaoIds
            WITH USER_MODE
        ]);
        if (categorizacoesById.isEmpty()) {
            return;
        }

        Map<String, Schema.SObjectField> caseFields =
            Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();

        for (Case currentCase : newRows) {
            applyDistribution(currentCase, categorizacoesById.get(currentCase.Categorizacao__c), caseFields);
        }
    }

    private static void applyDistribution(
        Case currentCase,
        Categorizacao__c categorizacao,
        Map<String, Schema.SObjectField> caseFields
    ) {
        if (currentCase == null || currentCase.Categorizacao__c == null || categorizacao == null) {
            return;
        }
        if (!CategorizacaoHelper.isTrueFlag(categorizacao.DistribuirParaFila__c)) {
            return;
        }
        if (currentCase.AcaoPosCategorizacao__c == ACAO_ENCERRAR) {
            return;
        }

        String targetFilaId = categorizacao.FilaId__c;
        String targetFilaDevName = categorizacao.FilaDeveloperName__c;

        if (CategorizacaoHelper.isTrueFlag(categorizacao.PorCampoCustomizado__c)
            && !String.isBlank(categorizacao.CampoDistribuicao__c)
            && !String.isBlank(categorizacao.ValorDistribuicao__c)
            && caseFields.containsKey(categorizacao.CampoDistribuicao__c)) {
            Object liveValue = currentCase.get(categorizacao.CampoDistribuicao__c);
            String liveValueStr = liveValue == null ? null : String.valueOf(liveValue);
            if (CaseCreationHelper.sameNormalizedValue(liveValueStr, categorizacao.ValorDistribuicao__c)) {
                targetFilaId = categorizacao.FilaId__c;
                targetFilaDevName = categorizacao.FilaDeveloperName__c;
            } else if (!String.isBlank(categorizacao.FilaIdFallback__c)) {
                targetFilaId = categorizacao.FilaIdFallback__c;
                targetFilaDevName = categorizacao.FilaDeveloperNameFallback__c;
            } else {
                return;
            }
        }

        if (String.isBlank(targetFilaId)) {
            return;
        }

        Boolean permiteAssumir = String.isBlank(categorizacao.PermiteAssumirComFilaParametrizada__c)
            || CategorizacaoHelper.isTrueFlag(categorizacao.PermiteAssumirComFilaParametrizada__c);
        if (currentCase.AcaoPosCategorizacao__c == ACAO_ASSUMIR && permiteAssumir) {
            return;
        }

        currentCase.OwnerId = targetFilaId;
        currentCase.DistribuicaoSolicitada__c = true;
        currentCase.OrigemDistribuicao__c = ORIGEM_DISTRIBUICAO_CATEGORIZACAO;
        currentCase.FilaDestinoDeveloperName__c = targetFilaDevName;
        currentCase.FilaDestinoId__c = targetFilaId;
        if (!String.isBlank(categorizacao.EtapaAtendimentoDistribuicao__c)) {
            currentCase.EtapaAtendimento__c = categorizacao.EtapaAtendimentoDistribuicao__c;
        }
    }
}
