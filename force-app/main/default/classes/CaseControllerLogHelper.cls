/**
 * @description Log estruturado de erros inesperados capturados pelos Controllers LWC do módulo Case,
 * reaproveitando o padrão de `LogIntegracao__c` já usado em `CaseScheduleHelper`.
 */
public inherited sharing class CaseControllerLogHelper {
    private static final Integer LOG_TEXT_LIMIT = 131000;

    /**
     * @description Grava um `LogIntegracao__c` com a exceção original, sem interromper o fluxo do Controller
     * (o objeto ou o campo podem não existir/estar acessíveis; nesse caso, a chamada é um no-op silencioso).
     * @param origin Nome do Controller/método de origem (ex.: "CaseCreationController.buildDefaultValues").
     * @param relatedObjectApiName API name do objeto relacionado ao erro (ex.: "Case"), ou null.
     * @param relatedId Id do registro relacionado, ou null.
     * @param ex Exceção capturada.
     */
    public static void logUnexpectedError(String origin, String relatedObjectApiName, Id relatedId, Exception ex) {
        Schema.SObjectType logType = Schema.getGlobalDescribe().get('LogIntegracao__c');
        if (logType == null || !logType.getDescribe().isCreateable() || ex == null) {
            return;
        }
        SObject row = logType.newSObject();
        CaseScheduleHelper.putIfFieldExists(row, 'Name', CaseScheduleHelper.safeLeft(origin, 80));
        CaseScheduleHelper.putIfFieldExists(row, 'MetodoCallout__c', 'CASE_CTRL');
        CaseScheduleHelper.putIfFieldExists(row, 'DescritivoErroLog__c', CaseScheduleHelper.safeLeft(ex.getMessage(), 255));
        CaseScheduleHelper.putIfFieldExists(row, 'ComentariosObservacoes__c', CaseScheduleHelper.safeLeft(ex.getStackTraceString(), LOG_TEXT_LIMIT));
        CaseScheduleHelper.putIfFieldExists(row, 'Endpoint__c', origin);
        if (relatedId != null) {
            CaseScheduleHelper.putIfFieldExists(row, 'ObjetoRelacionamento__c', relatedObjectApiName);
            CaseScheduleHelper.putIfFieldExists(row, 'IdRelacionamento__c', String.valueOf(relatedId));
        }
        Database.insert(new List<SObject>{ row }, false, AccessLevel.USER_MODE);
    }
}
