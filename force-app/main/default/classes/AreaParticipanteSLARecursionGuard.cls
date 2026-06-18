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