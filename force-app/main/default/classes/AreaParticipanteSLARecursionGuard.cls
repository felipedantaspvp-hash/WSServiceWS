/**
 * @description       : Guarda de recursão para o módulo AreaParticipante. Previne reprocessamento recursivo em triggers e serviços de SLA.
 * @author            : Triscal
 * @group             : Área Participante
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class AreaParticipanteSLARecursionGuard {
    private static Set<String> keys = new Set<String>();

    public static Boolean enter(String key) {
        if (String.isBlank(key)) return true;
        if (keys.contains(key)) return false;
        keys.add(key);
        return true;
    }

    public static void leave(String key) {
        if (String.isBlank(key)) return;
        keys.remove(key);
    }
}