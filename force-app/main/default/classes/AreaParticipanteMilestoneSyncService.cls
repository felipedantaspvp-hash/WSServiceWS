/**
 * @description       : Serviço de sincronização de marcos (milestones) para o módulo AreaParticipante. Atualiza CaseMilestone em resposta a mudanças de SLA.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-16-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteMilestoneSyncService {

    private static final String ORIGEM_STANDARD = AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD;
    private static final String ORIGEM_CUSTOM   = AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM;

    private static final String NOME_MARCO_SLA_TOTAL = 'Tempo Total de Atendimento';
    private static final String KEY_SLA_TOTAL        = 'sla total';

    // Normalized MilestoneType.Name → TipoAreaParticipante__c picklist value
    // 'Atendimento N3' not mapped: Área Interna requires explicit business decision
    private static final Map<String, String> TIPO_BY_MILESTONE = new Map<String, String>{
        'triagem'                       => 'Categorização Inicial',
        'resposta chat'                 => 'Categorização Inicial',
        'primeira resposta fila n2'     => 'Tratamento Primário',
        'atendimento'                   => 'Tratamento Primário',
        'retorno n3'                    => 'Retorno ao Cliente',
        'acompanhamento'                => 'Retorno ao Cliente',
        'sla total'                     => 'Tempo Total de Atendimento'
    };

    @TestVisible private static List<CaseMilestone> mockMilestonesForSync;

    public static void syncByCaseIds(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        List<CaseMilestone> milestones = mockMilestonesForSync != null
            ? mockMilestonesForSync
            : [SELECT Id, CaseId, MilestoneType.Name,
                      StartDate, TargetDate, CompletionDate,
                      IsCompleted, IsViolated
               FROM CaseMilestone
               WHERE CaseId IN :caseIds];
        syncInternal(milestones);
    }

    public static void syncByCaseMilestoneIds(Set<Id> milestoneIds) {
        if (milestoneIds == null || milestoneIds.isEmpty()) return;
        List<CaseMilestone> milestones = mockMilestonesForSync != null
            ? mockMilestonesForSync
            : [SELECT Id, CaseId, MilestoneType.Name,
                      StartDate, TargetDate, CompletionDate,
                      IsCompleted, IsViolated
               FROM CaseMilestone
               WHERE Id IN :milestoneIds];
        syncInternal(milestones);
    }

    private static void syncInternal(List<CaseMilestone> milestones) {
        if (milestones == null || milestones.isEmpty()) return;

        Set<String> cmIdStrings = new Set<String>();
        for (CaseMilestone cm : milestones) cmIdStrings.add(String.valueOf(cm.Id));

        Map<String, AreaParticipante__c> existingByMilestoneId = new Map<String, AreaParticipante__c>();
        for (AreaParticipante__c a : [
            SELECT Id, CaseMilestoneId__c, OrigemSLA__c
            FROM AreaParticipante__c
            WHERE CaseMilestoneId__c IN :cmIdStrings
        ]) {
            existingByMilestoneId.put(a.CaseMilestoneId__c, a);
        }

        List<AreaParticipante__c> toInsert = new List<AreaParticipante__c>();
        List<AreaParticipante__c> toUpdate = new List<AreaParticipante__c>();

        for (CaseMilestone cm : milestones) {
            String cmId = String.valueOf(cm.Id);
            String milestoneKey = AreaParticipanteHelper.normalizeText(
                cm.MilestoneType != null ? cm.MilestoneType.Name : null
            );
            if (!TIPO_BY_MILESTONE.containsKey(milestoneKey)) continue;

            AreaParticipante__c existing = existingByMilestoneId.get(cmId);
            if (existing != null && ORIGEM_CUSTOM.equals(existing.OrigemSLA__c)) continue;

            AreaParticipante__c record = buildRecord(cm, existing);
            if (existing == null) {
                toInsert.add(record);
            } else {
                toUpdate.add(record);
            }
        }

        if (!toInsert.isEmpty()) Database.insert(toInsert, false);
        if (!toUpdate.isEmpty()) Database.update(toUpdate, false);
    }

    @TestVisible
    static AreaParticipante__c buildRecord(CaseMilestone cm, AreaParticipante__c existing) {
        String milestoneName = cm.MilestoneType != null ? cm.MilestoneType.Name : null;
        String milestoneKey  = AreaParticipanteHelper.normalizeText(milestoneName);

        String tipo      = TIPO_BY_MILESTONE.get(milestoneKey);
        String nomeMarco = KEY_SLA_TOTAL.equals(milestoneKey) ? NOME_MARCO_SLA_TOTAL : milestoneName;

        Boolean isConcluido = cm.IsCompleted == true;
        Boolean isViolado   = cm.IsViolated  == true;

        String statusAtuacao = isConcluido
            ? AreaParticipanteSLAHelper.STATUS_ATUACAO_CONCLUIDA
            : AreaParticipanteSLAHelper.STATUS_ATUACAO_ABERTA;

        String statusSLA;
        if (isConcluido && isViolado) {
            statusSLA = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO;
        } else if (isConcluido) {
            statusSLA = AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO;
        } else if (isViolado) {
            statusSLA = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO;
        } else {
            statusSLA = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO;
        }

        // Compute time fields from dates — ElapsedTimeInMins/TimeRemainingInMins return "MM:SS"
        // string format on some orgs (not a plain Integer), so they are not queried.
        Decimal slaTotal  = null;
        Decimal elapsed   = null;
        Decimal remaining = null;
        Decimal percentual = null;

        if (cm.StartDate != null && cm.TargetDate != null) {
            Long totalMs = cm.TargetDate.getTime() - cm.StartDate.getTime();
            if (totalMs > 0) {
                slaTotal = (Decimal.valueOf(totalMs) / 60000).setScale(2);
                Datetime refEnd = (isConcluido && cm.CompletionDate != null)
                    ? cm.CompletionDate : Datetime.now();
                Long elapsedMs = Math.max(0L, Math.min(
                    refEnd.getTime() - cm.StartDate.getTime(), totalMs));
                elapsed   = (Decimal.valueOf(elapsedMs) / 60000).setScale(2);
                remaining = slaTotal > elapsed ? slaTotal - elapsed : Decimal.valueOf(0);
                percentual = slaTotal > 0 ? (elapsed / slaTotal * 100).setScale(2) : Decimal.valueOf(0);
            }
        }

        AreaParticipante__c record = existing != null
            ? new AreaParticipante__c(Id = existing.Id)
            : new AreaParticipante__c();

        record.Caso__c                   = cm.CaseId;
        record.CaseMilestoneId__c        = String.valueOf(cm.Id);
        record.OrigemSLA__c              = ORIGEM_STANDARD;
        record.TipoAreaParticipante__c   = tipo;
        record.NomeMarco__c              = nomeMarco;
        record.DataHoraInicio__c         = cm.StartDate;
        record.DataHoraPrazo__c          = cm.TargetDate;
        record.DataHoraFim__c            = cm.CompletionDate;
        record.StatusAtuacao__c          = statusAtuacao;
        record.StatusSLA__c              = statusSLA;
        record.ViolouSLA__c              = isViolado;
        record.BloqueiaFechamentoCaso__c = false;
        record.TempoConsumidoMinutos__c  = elapsed;
        record.TempoRestanteMinutos__c   = isConcluido ? Decimal.valueOf(0) : remaining;
        record.TempoSLAMinutos__c        = slaTotal;
        record.PercentualDecorrido__c    = percentual;

        return record;
    }
}