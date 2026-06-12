/**
 * @description       : DTO de contexto e requisição para encerramento de Case com Survey.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 06-10-2026
 * @last modified by  : Codex
 **/
public inherited sharing class CaseClosureSurveyDTO {
    @AuraEnabled public Id caseId { get; set; }
    @AuraEnabled public String caseNumber { get; set; }
    @AuraEnabled public String businessUnit { get; set; }
    @AuraEnabled public String channel { get; set; }
    @AuraEnabled public String surveyMode { get; set; }
    @AuraEnabled public Boolean showSurveyQuestion { get; set; }
    @AuraEnabled public Boolean defaultSendSurvey { get; set; }
    @AuraEnabled public Boolean selectedSendSurvey { get; set; }
    @AuraEnabled public Boolean showDailySurveyIndicator { get; set; }
    @AuraEnabled public Boolean customerAlreadyReceivedSurveyToday { get; set; }
    @AuraEnabled public Boolean allowSameDaySurvey { get; set; }
    @AuraEnabled public String surveyAlreadySentMessage { get; set; }
    @AuraEnabled public String closureStatus { get; set; }
    @AuraEnabled public String closureReason { get; set; }
    @AuraEnabled public String closureComment { get; set; }
    @AuraEnabled public String closureSolution { get; set; }
    @AuraEnabled public String successMessage { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
}