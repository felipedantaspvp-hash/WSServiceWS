/**
 * @description       : Serviço de negócio para o módulo GestaoSLAHealthCheck. Contém lógica de validação e DML, seguindo arquitetura Triscal.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-15-2026
 * @last modified by  : Jean Duarte
 **/
public with sharing class GestaoSLAHealthCheckService {

    private static final Integer DEFAULT_MAX_RECORDS = 200;
    private static final Integer MAX_RECORDS_CASE    = 100;

    // Valores antigos de EscopoRegra__c removidos no Pacote 15D
    private static final Set<String> ESCOPOS_LEGADOS = new Set<String>{
        'Global', 'Por Categorizacao', 'Por Area Interna'
    };

    // ─────────────────────────────────────────────────────────────
    // Ponto de entrada
    // ─────────────────────────────────────────────────────────────
    public static GestaoSLAHealthCheckDTO.HealthCheckResult runHealthCheck(Integer maxRecords) {
        Integer lim = (maxRecords != null && maxRecords > 0) ? maxRecords : DEFAULT_MAX_RECORDS;

        GestaoSLAHealthCheckDTO.HealthCheckResult result = new GestaoSLAHealthCheckDTO.HealthCheckResult();
        result.executionDateTime = System.now();

        checkRegrasSLA(result.issues, lim);
        checkAreaParticipante(result.issues, lim);
        checkStandardVsCustom(result.issues, lim);
        checkCaseEtapa(result.issues, Math.min(lim, MAX_RECORDS_CASE));

        result.totalChecks = 4;
        result.totalIssues = result.issues.size();
        for (GestaoSLAHealthCheckDTO.Issue issue : result.issues) {
            if      ('Critical'.equals(issue.severity)) result.totalCritical++;
            else if ('High'    .equals(issue.severity)) result.totalHigh++;
            else if ('Medium'  .equals(issue.severity)) result.totalMedium++;
            else if ('Low'     .equals(issue.severity)) result.totalLow++;
            else                                         result.totalInfo++;
        }

        return result;
    }

    // ─────────────────────────────────────────────────────────────
    // 1. Regras SLA
    // ─────────────────────────────────────────────────────────────
    private static void checkRegrasSLA(List<GestaoSLAHealthCheckDTO.Issue> issues, Integer lim) {
        List<RegrasSLACategorizacao__c> regras = [
            SELECT Id, Name, Ativo__c, EscopoRegra__c, BusinessHoursName__c,
                   TempoAlta__c, TempoBaixa__c, TempoMedia__c, ChaveUnica__c
            FROM RegrasSLACategorizacao__c
            LIMIT :lim
        ];

        // Contagem para deteccao de duplicatas via ChaveUnica__c
        Map<String, Integer> chaveCount = new Map<String, Integer>();
        for (RegrasSLACategorizacao__c r : regras) {
            if (String.isBlank(r.ChaveUnica__c)) continue;
            Integer cur = chaveCount.containsKey(r.ChaveUnica__c) ? chaveCount.get(r.ChaveUnica__c) : 0;
            chaveCount.put(r.ChaveUnica__c, cur + 1);
        }

        for (RegrasSLACategorizacao__c r : regras) {
            // Sem prazo em nenhuma prioridade
            if (r.TempoAlta__c == null && r.TempoBaixa__c == null && r.TempoMedia__c == null) {
                issues.add(newIssue('High', 'REGRAS_SLA', 'RegrasSLACategorizacao__c', r.Id, r.Name,
                    'REGRA_SEM_PRAZO',
                    'Regra sem prazo configurado em nenhuma prioridade (TempoAlta__c, TempoMedia__c e TempoBaixa__c estao nulos).',
                    'Configurar pelo menos um dos campos de tempo para que a regra seja aplicavel.'));
            }
            // Escopo com valor legado (pre-Pacote 15D)
            if (!String.isBlank(r.EscopoRegra__c) && ESCOPOS_LEGADOS.contains(r.EscopoRegra__c)) {
                issues.add(newIssue('Critical', 'REGRAS_SLA', 'RegrasSLACategorizacao__c', r.Id, r.Name,
                    'ESCOPO_LEGADO',
                    'Regra usa valor antigo de EscopoRegra__c: ' + r.EscopoRegra__c + '. Valores validos: Atendimento, Area Interna.',
                    'Atualizar EscopoRegra__c para Atendimento ou Area Interna (Pacote 15D).'));
            }
            // Duplicata funcional
            if (!String.isBlank(r.ChaveUnica__c) && chaveCount.containsKey(r.ChaveUnica__c)
                && chaveCount.get(r.ChaveUnica__c) > 1) {
                issues.add(newIssue('High', 'REGRAS_SLA', 'RegrasSLACategorizacao__c', r.Id, r.Name,
                    'REGRA_DUPLICADA',
                    'Regra com ChaveUnica__c duplicada: ' + r.ChaveUnica__c + '. Multiplas regras para a mesma combinacao funcional.',
                    'Inativar ou remover a regra duplicada.'));
            }
            // Sem Business Hours configurado
            if (String.isBlank(r.BusinessHoursName__c)) {
                issues.add(newIssue('Medium', 'REGRAS_SLA', 'RegrasSLACategorizacao__c', r.Id, r.Name,
                    'REGRA_SEM_BUSINESS_HOURS',
                    'Regra sem BusinessHoursName__c. O calculo de prazo pode falhar ou usar horario padrao incorreto.',
                    'Configurar BusinessHoursName__c com o nome exato do Business Hours correspondente.'));
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 2. Area Participante
    // ─────────────────────────────────────────────────────────────
    private static void checkAreaParticipante(List<GestaoSLAHealthCheckDTO.Issue> issues, Integer lim) {
        List<AreaParticipante__c> areas = [
            SELECT Id, Name, TipoAreaParticipante__c, OrigemSLA__c,
                   StatusAtuacao__c, StatusSLA__c,
                   DataHoraPrazo__c, DataHoraFim__c, DataHoraInicio__c,
                   DataHoraInicioPausa__c, TempoPausadoMinutos__c, ViolouSLA__c
            FROM AreaParticipante__c
            WHERE TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
            LIMIT :lim
        ];

        for (AreaParticipante__c a : areas) {
            Boolean isCustom      = AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM.equals(a.OrigemSLA__c);
            Boolean isAberta      = AreaParticipanteHelper.isAbertaOuAndamento(a.StatusAtuacao__c);
            Boolean isConcluida   = AreaParticipanteHelper.isConcluida(a.StatusAtuacao__c);
            Boolean isCancelada   = AreaParticipanteHelper.isCancelada(a.StatusAtuacao__c);
            Boolean isTerminal    = isConcluida || isCancelada;
            String  statusSla     = a.StatusSLA__c;
            Boolean isPausadoSla  = AreaParticipanteSLAHelper.STATUS_SLA_PAUSADO.equals(statusSla);
            Boolean isVencidoSla  = AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO.equals(statusSla);
            Boolean isDentroPrazo = AreaParticipanteSLAHelper.STATUS_SLA_DENTRO_PRAZO.equals(statusSla);

            // Custom aberta sem DataHoraPrazo__c
            if (isCustom && isAberta && a.DataHoraPrazo__c == null) {
                issues.add(newIssue('High', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'CUSTOM_ABERTA_SEM_PRAZO',
                    'Area Interna Custom aberta sem DataHoraPrazo__c configurado.',
                    'Verificar se a regra SLA foi aplicada corretamente pelo beforeSave de AreaParticipanteSLAService.'));
            }
            // Sem StatusAtuacao__c
            if (String.isBlank(a.StatusAtuacao__c)) {
                issues.add(newIssue('Critical', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'SEM_STATUS_ATUACAO',
                    'Registro sem StatusAtuacao__c preenchido.',
                    'Verificar AreaParticipanteTrigger e beforeSave — campo obrigatorio.'));
            }
            // Sem StatusSLA__c
            if (String.isBlank(statusSla)) {
                issues.add(newIssue('High', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'SEM_STATUS_SLA',
                    'Registro sem StatusSLA__c preenchido.',
                    'Verificar calculateCacheBulk em AreaParticipanteSLAService.'));
            }
            // Concluida com StatusSLA incoerente
            if (isConcluida && !String.isBlank(statusSla)
                && !AreaParticipanteSLAHelper.STATUS_SLA_CONCLUIDO.equals(statusSla)
                && !AreaParticipanteSLAHelper.STATUS_SLA_VENCIDO.equals(statusSla)) {
                issues.add(newIssue('Medium', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'STATUS_SLA_INCOERENTE_CONCLUIDA',
                    'Registro concluido com StatusSLA__c incoerente: ' + statusSla + '. Esperado: Concluido ou Vencido.',
                    'Recalcular StatusSLA__c ao concluir participacao.'));
            }
            // Cancelada com StatusSLA incoerente
            if (isCancelada && !String.isBlank(statusSla)
                && !AreaParticipanteSLAHelper.STATUS_SLA_CANCELADO.equals(statusSla)) {
                issues.add(newIssue('Low', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'STATUS_SLA_INCOERENTE_CANCELADA',
                    'Registro cancelado com StatusSLA__c incoerente: ' + statusSla + '. Esperado: Cancelado.',
                    'Verificar atualizacao de StatusSLA__c ao cancelar participacao.'));
            }
            // Vencido com ViolouSLA = false
            if (isVencidoSla && a.ViolouSLA__c != true) {
                issues.add(newIssue('Medium', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'VIOLOU_SLA_INCONSISTENTE_VENCIDO',
                    'StatusSLA__c = Vencido mas ViolouSLA__c = false.',
                    'Recalcular ViolouSLA__c via calculateCacheBulk de AreaParticipanteSLAService.'));
            }
            // Dentro do prazo com ViolouSLA = true
            if (isDentroPrazo && a.ViolouSLA__c == true) {
                issues.add(newIssue('Low', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'VIOLOU_SLA_INCONSISTENTE_DENTRO_PRAZO',
                    'StatusSLA__c = Dentro do Prazo mas ViolouSLA__c = true.',
                    'Recalcular ViolouSLA__c.'));
            }
            // Pausado sem DataHoraInicioPausa__c
            if (isPausadoSla && a.DataHoraInicioPausa__c == null) {
                issues.add(newIssue('High', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'PAUSADO_SEM_DATA_INICIO_PAUSA',
                    'StatusSLA__c = Pausado mas DataHoraInicioPausa__c esta vazio.',
                    'Verificar logica de pausa em AreaParticipanteService.pauseRows — DataHoraInicioPausa__c deve ser preenchido.'));
            }
            // Nao pausado com DataHoraInicioPausa__c preenchida (e nao terminal)
            if (!isPausadoSla && a.DataHoraInicioPausa__c != null && !isTerminal) {
                issues.add(newIssue('Medium', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'DATA_INICIO_PAUSA_INDEVIDA',
                    'DataHoraInicioPausa__c preenchida mas StatusSLA__c nao e Pausado (' + statusSla + ').',
                    'Verificar se resumeRows limpou DataHoraInicioPausa__c corretamente.'));
            }
            // TempoPausadoMinutos__c negativo
            if (a.TempoPausadoMinutos__c != null && a.TempoPausadoMinutos__c < 0) {
                issues.add(newIssue('High', 'AREA_PARTICIPANTE', 'AreaParticipante__c', a.Id, a.Name,
                    'TEMPO_PAUSADO_NEGATIVO',
                    'TempoPausadoMinutos__c e negativo: ' + a.TempoPausadoMinutos__c + '.',
                    'Verificar calculo de tempo pausado em AreaParticipanteService.resumeRows.'));
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 3. Standard vs Custom
    // ─────────────────────────────────────────────────────────────
    private static void checkStandardVsCustom(List<GestaoSLAHealthCheckDTO.Issue> issues, Integer lim) {
        // Standard com DataHoraInicioPausa__c (pausa nao permitida para Standard)
        for (AreaParticipante__c a : [
            SELECT Id, Name FROM AreaParticipante__c
            WHERE TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD
              AND DataHoraInicioPausa__c != null
            LIMIT :lim
        ]) {
            issues.add(newIssue('Critical', 'STANDARD_VS_CUSTOM', 'AreaParticipante__c', a.Id, a.Name,
                'STANDARD_COM_PAUSA',
                'Registro Standard com DataHoraInicioPausa__c preenchida — pausa nao e permitida para OrigemSLA__c = Standard.',
                'Investigar como a pausa foi acionada. AreaParticipanteService deve rejeitar pausa de Standard via NOT_CUSTOM_INTERNAL_AREA.'));
        }

        // Standard sem CaseMilestoneId__c (informativo — sincronizacao pode estar pendente)
        for (AreaParticipante__c a : [
            SELECT Id, Name FROM AreaParticipante__c
            WHERE TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_STANDARD
              AND CaseMilestoneId__c = null
            LIMIT :lim
        ]) {
            issues.add(newIssue('Info', 'STANDARD_VS_CUSTOM', 'AreaParticipante__c', a.Id, a.Name,
                'STANDARD_SEM_MILESTONE',
                'Registro Standard sem CaseMilestoneId__c — vinculo de CaseMilestone nao encontrado.',
                'Verificar sincronizacao via AreaParticipanteMilestoneSyncService se o entitlement process estiver ativo.'));
        }

        // Custom com CaseMilestoneId__c (vinculo indevido)
        for (AreaParticipante__c a : [
            SELECT Id, Name FROM AreaParticipante__c
            WHERE TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND OrigemSLA__c = :AreaParticipanteSLAHelper.ORIGEM_SLA_CUSTOM
              AND CaseMilestoneId__c != null
            LIMIT :lim
        ]) {
            issues.add(newIssue('High', 'STANDARD_VS_CUSTOM', 'AreaParticipante__c', a.Id, a.Name,
                'CUSTOM_COM_MILESTONE',
                'Registro Custom com CaseMilestoneId__c preenchido — vinculo de Milestone nao e esperado para Custom.',
                'Verificar se o campo foi preenchido incorretamente. Apenas Standard deve ter CaseMilestoneId__c.'));
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 4. Case / Etapa de Atendimento (read-only)
    // ─────────────────────────────────────────────────────────────
    private static void checkCaseEtapa(List<GestaoSLAHealthCheckDTO.Issue> issues, Integer lim) {
        Set<Id> caseIdsComAreaAberta = new Set<Id>();
        for (AreaParticipante__c a : [
            SELECT Caso__c FROM AreaParticipante__c
            WHERE TipoAreaParticipante__c = :AreaParticipanteSLAHelper.TIPO_AREA_INTERNA
              AND StatusAtuacao__c NOT IN ('Concluída', 'Cancelada')
              AND Caso__c != null
            LIMIT :lim
        ]) {
            caseIdsComAreaAberta.add(a.Caso__c);
        }

        if (caseIdsComAreaAberta.isEmpty()) return;

        for (Case c : [
            SELECT Id, CaseNumber, EtapaAtendimento__c, Status
            FROM Case
            WHERE Id IN :caseIdsComAreaAberta
              AND (EtapaAtendimento__c = 'Concluído' OR EtapaAtendimento__c = 'Cancelado')
        ]) {
            issues.add(newIssue('High', 'CASE_ETAPA', 'Case', c.Id, c.CaseNumber,
                'CASE_TERMINAL_COM_AREA_ABERTA',
                'Case com EtapaAtendimento__c = ' + c.EtapaAtendimento__c + ' mas possui Area Interna ainda aberta.',
                'Verificar se a regra de bloqueio de fechamento (Pacote 20) e o CaseTriggerHandler estao funcionando corretamente.'));
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Factory de Issue
    // ─────────────────────────────────────────────────────────────
    @TestVisible
    private static GestaoSLAHealthCheckDTO.Issue newIssue(
        String severity, String category, String objectApiName,
        Id recordId, String recordName,
        String ruleCode, String message, String recommendation
    ) {
        GestaoSLAHealthCheckDTO.Issue i = new GestaoSLAHealthCheckDTO.Issue();
        i.severity       = severity;
        i.category       = category;
        i.objectApiName  = objectApiName;
        i.recordId       = recordId;
        i.recordName     = recordName;
        i.ruleCode       = ruleCode;
        i.message        = message;
        i.recommendation = recommendation;
        return i;
    }
}
