/**
 * @description DTO para entrada controlada de Case em acompanhamento com pausa de SLA.
 * @author Triscal
 * @group Atendimento
 * @last modified on 06-17-2026
 * @last modified by Marllon Nascimento
 */
@SuppressWarnings('PMD.AvoidBooleanMethodParameters, PMD.ApexDoc')
public inherited sharing class CaseAcompanhamentoDTO {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Id caseId { get; set; }
    @AuraEnabled public String etapaAtual { get; set; }
    @AuraEnabled public String etapaAnterior { get; set; }
    @AuraEnabled public String motivo { get; set; }
    @AuraEnabled public String comentarioEntrada { get; set; }
    @AuraEnabled public String comentarioSaida { get; set; }
    @AuraEnabled public Datetime dataInicio { get; set; }
    @AuraEnabled public Datetime dataFim { get; set; }
    @AuraEnabled public String usuarioInicioNome { get; set; }
    @AuraEnabled public String usuarioFimNome { get; set; }
    @AuraEnabled public Boolean isStopped { get; set; }
    @AuraEnabled public Id acaoPausaAtivaId { get; set; }
    @AuraEnabled public String tipoAcao { get; set; }
    @AuraEnabled public String statusAcao { get; set; }
    @AuraEnabled public Boolean emAcompanhamento { get; set; }
}