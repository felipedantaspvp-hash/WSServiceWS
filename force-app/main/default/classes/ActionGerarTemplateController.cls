/**
 * @description       : 
 * @author            : wrodrigues@triscal.com.br
 * @group             : 
 * @last modified on  : 07-16-2025
 * @last modified by  : wrodrigues@triscal.com.br
**/
public with sharing class ActionGerarTemplateController {

    @AuraEnabled
    public static void gerarTemplate(String recordId) {
        try {
            ActionGerarTemplateService service = ActionGerarTemplateService.getInstance();
            service.setRecorId(recordId);
            service.montarPdf();
        } catch (Exception e) {
            System.debug('Erro: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Erro ao gerar o template: ' + e.getMessage());
        }
    }
}