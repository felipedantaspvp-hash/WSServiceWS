public inherited sharing class TextNormalizationUtil {
    public static String stripAccents(String value) {
        if (value == null) return null;
        String out = value;
        out = out.replace('á', 'a').replace('à', 'a').replace('â', 'a').replace('ã', 'a').replace('ä', 'a');
        out = out.replace('é', 'e').replace('è', 'e').replace('ê', 'e').replace('ë', 'e');
        out = out.replace('í', 'i').replace('ì', 'i').replace('î', 'i').replace('ï', 'i');
        out = out.replace('ó', 'o').replace('ò', 'o').replace('ô', 'o').replace('õ', 'o').replace('ö', 'o');
        out = out.replace('ú', 'u').replace('ù', 'u').replace('û', 'u').replace('ü', 'u');
        out = out.replace('ç', 'c');
        out = out.replace('Á', 'A').replace('À', 'A').replace('Â', 'A').replace('Ã', 'A').replace('Ä', 'A');
        out = out.replace('É', 'E').replace('È', 'E').replace('Ê', 'E').replace('Ë', 'E');
        out = out.replace('Í', 'I').replace('Ì', 'I').replace('Î', 'I').replace('Ï', 'I');
        out = out.replace('Ó', 'O').replace('Ò', 'O').replace('Ô', 'O').replace('Õ', 'O').replace('Ö', 'O');
        out = out.replace('Ú', 'U').replace('Ù', 'U').replace('Û', 'U').replace('Ü', 'U');
        out = out.replace('Ç', 'C');
        out = out.replace('ñ', 'n').replace('Ñ', 'N');
        return out;
    }
}
