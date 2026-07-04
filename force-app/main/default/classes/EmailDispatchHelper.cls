/**
 * @description       : Helper compartilhado para interpretar resultados de envio de e-mail.
 * @author            : Triscal
 * @group             : Atendimento
 * @last modified on  : 07-04-2026
 * @last modified by  : Jean Duarte
 **/
public class EmailDispatchHelper {
    private static final String ERROR_PREFIX = 'Erro ao enviar e-mail: ';
    private static final String ERROR_SEPARATOR = ' | ';

    /**
     * @description Determina se o envio foi bem-sucedido para um índice específico.
     * @param index Índice do envelope/mensagem na operação em lote.
     * @param emailResults Resultados retornados por Messaging.sendEmail.
     * @param skipExternalEffectsForTest Indica se o teste pulou efeitos externos e deve simular sucesso.
     * @param testEmailErrorsByIndex Mapa opcional de erros simulados por índice em contexto de teste.
     * @return True quando o envio deve ser tratado como sucesso.
     */
    public static Boolean isEmailSuccess(
        Integer index,
        Messaging.SendEmailResult[] emailResults,
        Boolean skipExternalEffectsForTest,
        Map<Integer, String> testEmailErrorsByIndex
    ) {
        if (Test.isRunningTest() && testEmailErrorsByIndex != null) {
            return !testEmailErrorsByIndex.containsKey(index);
        }
        if (Test.isRunningTest() && skipExternalEffectsForTest) {
            return true;
        }
        return emailResults[index].isSuccess();
    }

    /**
     * @description Monta a mensagem de erro padronizada do envio de e-mail para um índice específico.
     * @param index Índice do envelope/mensagem na operação em lote.
     * @param emailResults Resultados retornados por Messaging.sendEmail.
     * @param testEmailErrorsByIndex Mapa opcional de erros simulados por índice em contexto de teste.
     * @return Mensagem consolidada de erro do envio.
     */
    public static String buildEmailErrorMessage(
        Integer index,
        Messaging.SendEmailResult[] emailResults,
        Map<Integer, String> testEmailErrorsByIndex
    ) {
        if (Test.isRunningTest() && testEmailErrorsByIndex != null && testEmailErrorsByIndex.containsKey(index)) {
            return ERROR_PREFIX + testEmailErrorsByIndex.get(index);
        }

        List<String> messages = new List<String>();
        for (Messaging.SendEmailError error : emailResults[index].getErrors()) {
            messages.add(String.valueOf(error.getStatusCode()) + ': ' + error.getMessage());
        }
        return ERROR_PREFIX + String.join(messages, ERROR_SEPARATOR);
    }
}
