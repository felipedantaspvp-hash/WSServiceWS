/**
 * @description Mecanismo único de "test seam" para forçar branches de erro/bypass em testes
 * (substitui o padrão de flags `@TestVisible static Boolean`/`Exception` reimplementado por classe).
 * Registro chave→valor namespaced por classe (ex.: "CaseAcompanhamentoController.forceUnexpectedError"),
 * só ativo durante execução de teste — fora de teste, `get`/`getBoolean`/`getException` sempre retornam
 * o valor "sem override" (null/false), então nenhuma chamada de produção depende do estado deste registro.
 * Ver CR-020 do CodeReview.md.
 */
public inherited sharing class ApexTestSeam {
    @TestVisible private static Map<String, Object> overridesByKey = new Map<String, Object>();

    /**
     * @description Define um override de teste para a chave informada. Não tem efeito fora de teste.
     * @param key Chave namespaced (ex.: "NomeDaClasse.cenario").
     * @param value Valor a retornar quando a produção consultar essa chave.
     */
    @TestVisible
    private static void set(String key, Object value) {
        overridesByKey.put(key, value);
    }

    /**
     * @description Remove o override de uma chave específica.
     * @param key Chave a limpar.
     */
    @TestVisible
    private static void clear(String key) {
        overridesByKey.remove(key);
    }

    /**
     * @description Remove todos os overrides ativos (chamar entre testes, se necessário, para evitar
     * vazamento de estado entre métodos de teste da mesma classe).
     */
    @TestVisible
    private static void clearAll() {
        overridesByKey.clear();
    }

    /**
     * @description Valor bruto do override, ou null se não houver (ou se não estiver em contexto de teste).
     * @param key Chave namespaced.
     * @return Valor registrado, ou null.
     */
    public static Object get(String key) {
        return Test.isRunningTest() ? overridesByKey.get(key) : null;
    }

    /**
     * @description Override booleano "força true", com false como padrão quando não setado.
     * @param key Chave namespaced.
     * @return true somente se explicitamente setado como true em teste.
     */
    public static Boolean getBoolean(String key) {
        return get(key) == true;
    }

    /**
     * @description Override booleano tri-state (null = sem override, true/false = valor forçado).
     * Útil para simular resultado de permissão/CRUD sem depender do perfil real de execução.
     * @param key Chave namespaced.
     * @return Boolean setado, ou null se não houver override.
     */
    public static Boolean getNullableBoolean(String key) {
        Object value = get(key);
        return value == null ? null : (Boolean) value;
    }

    /**
     * @description Exceção a lançar, injetada via teste (substitui o padrão `@TestVisible static Exception testException`).
     * @param key Chave namespaced.
     * @return Exceção registrada, ou null se não houver override.
     */
    public static Exception getException(String key) {
        return (Exception) get(key);
    }
}
