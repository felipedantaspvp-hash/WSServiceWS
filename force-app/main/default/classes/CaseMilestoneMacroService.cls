public inherited sharing class CaseMilestoneMacroService {
    private static final String ETAPA_NOVO = 'Novo';
    private static final String ETAPA_TRIAGEM = 'Em Triagem';
    private static final String ETAPA_ATENDIMENTO = 'Em Atendimento';
    private static final String ETAPA_RETORNO = 'Preparando Retorno ao Cliente';
    private static final String ETAPA_AGUARDANDO_INTERNA = 'Aguardando Área Interna';
    private static final String ETAPA_AGUARDANDO_CLIENTE = 'Aguardando Cliente';
    private static final String ETAPA_CONCLUIDO = 'Concluído';
    private static final String ETAPA_CANCELADO = 'Cancelado';

    private static final String M_PRIMEIRA_RESPOSTA = 'Primeira Resposta';
    private static final String M_ATENDIMENTO = 'Atendimento';
    private static final String M_ATENDIMENTO_N3 = 'Atendimento N3';
    private static final String M_RETORNO_N3 = 'Retorno N3';
    private static final String M_ACOMPANHAMENTO = 'Acompanhamento';
    private static final String M_TOTAL = 'SLA Total';
    @TestVisible private static Map<Id, Set<String>> lastComputedByCase = new Map<Id, Set<String>>();
    @TestVisible private static Boolean bypassCaseMilestoneDmlInTests = false;

    public static void completeByStageTransition(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        if (newMap == null || newMap.isEmpty() || oldMap == null) return;

        Map<Id, Set<String>> toCompleteByCase = new Map<Id, Set<String>>();
        for (Id caseId : newMap.keySet()) {
            Case n = newMap.get(caseId);
            Case o = oldMap.get(caseId);
            if (n == null || o == null) continue;

            Set<String> milestoneNames = new Set<String>();

            if (isIn(o.EtapaAtendimento__c, new Set<String>{ ETAPA_NOVO, ETAPA_TRIAGEM })
                && !isIn(n.EtapaAtendimento__c, new Set<String>{ ETAPA_NOVO, ETAPA_TRIAGEM })) {
                milestoneNames.add(M_PRIMEIRA_RESPOSTA);
            }
            if (o.EtapaAtendimento__c == ETAPA_ATENDIMENTO && n.EtapaAtendimento__c != ETAPA_ATENDIMENTO) {
                milestoneNames.add(M_ATENDIMENTO);
            }
            if (o.EtapaAtendimento__c == ETAPA_RETORNO
                && (n.EtapaAtendimento__c != ETAPA_RETORNO || n.IsClosed == true)) {
                milestoneNames.add(M_RETORNO_N3);
            }
            if (o.EtapaAtendimento__c == ETAPA_AGUARDANDO_INTERNA && n.EtapaAtendimento__c != ETAPA_AGUARDANDO_INTERNA) {
                milestoneNames.add(M_ATENDIMENTO_N3);
            }
            if (o.EtapaAtendimento__c == ETAPA_AGUARDANDO_CLIENTE && n.EtapaAtendimento__c != ETAPA_AGUARDANDO_CLIENTE) {
                milestoneNames.add(M_ACOMPANHAMENTO);
            }
            if ((o.IsClosed == false && n.IsClosed == true) || isIn(n.EtapaAtendimento__c, new Set<String>{ ETAPA_CONCLUIDO, ETAPA_CANCELADO })) {
                milestoneNames.add(M_TOTAL);
            }

            if (!milestoneNames.isEmpty()) toCompleteByCase.put(caseId, milestoneNames);
        }
        if (toCompleteByCase.isEmpty()) return;
        lastComputedByCase = cloneMapSet(toCompleteByCase);
        if (Test.isRunningTest() && bypassCaseMilestoneDmlInTests) return;

        Set<Id> caseIds = toCompleteByCase.keySet();
        Set<String> allNames = new Set<String>();
        for (Set<String> s : toCompleteByCase.values()) allNames.addAll(s);

        List<CaseMilestone> updates = new List<CaseMilestone>();
        Datetime nowRef = System.now();
        for (CaseMilestone cm : [
            SELECT Id, CaseId, CompletionDate, MilestoneType.Name
            FROM CaseMilestone
            WHERE CaseId IN :caseIds
              AND CompletionDate = null
              AND MilestoneType.Name IN :allNames
        ]) {
            Set<String> needed = toCompleteByCase.get(cm.CaseId);
            if (needed != null && needed.contains(cm.MilestoneType.Name)) {
                cm.CompletionDate = nowRef;
                updates.add(cm);
            }
        }
        if (!updates.isEmpty()) update updates;
    }

    private static Boolean isIn(String value, Set<String> allowed) {
        return value != null && allowed != null && allowed.contains(value);
    }

    private static Map<Id, Set<String>> cloneMapSet(Map<Id, Set<String>> source) {
        Map<Id, Set<String>> out = new Map<Id, Set<String>>();
        for (Id key : source.keySet()) out.put(key, new Set<String>(source.get(key)));
        return out;
    }
}