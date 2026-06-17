/**
 * @description       : Funções utilitárias e helpers para o módulo WSWillCaseLookup.
 * @author            : Triscal
 * @group             : WSWill
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class WSWillCaseLookupHelper {
    public static String normalizeCaseNumber(String caseNumber) {
        if (String.isBlank(caseNumber)) return null;
        String digitsOnly = caseNumber.replaceAll('[^0-9]', '');
        if (String.isBlank(digitsOnly)) return null;
        while (digitsOnly.length() < 8) {
            digitsOnly = '0' + digitsOnly;
        }
        return digitsOnly;
    }

    public static String normalizeLang(String lang) {
        return WSWillContextResolverHelper.normalizePreferredLanguage(lang);
    }

    public static String translateValue(String fieldApiName, String value, String language) {
        if (String.isBlank(value)) return null;
        String normalizedLanguage = normalizeLang(language);
        if (normalizedLanguage != 'en_US') return value;

        Map<String, Map<String, String>> translationsByField = englishTranslations();
        Map<String, String> translations = translationsByField.get(fieldApiName);
        if (translations == null || !translations.containsKey(value)) return value;
        return translations.get(value);
    }

    private static Map<String, Map<String, String>> englishTranslations() {
        return new Map<String, Map<String, String>>{
            'TipoCaso__c' => new Map<String, String>{
                'Elogio' => 'Compliment',
                'Informação' => 'Information',
                'Reclamação' => 'Complaint',
                'Solicitação' => 'Request'
            },
            'Status' => new Map<String, String>{
                'Aberto' => 'Open',
                'Em Andamento' => 'In Progress',
                'Fechado' => 'Closed',
                'Cancelado' => 'Canceled',
                'Novo' => 'New'
            },
            'Categoria__c' => new Map<String, String>{
                'Elogio' => 'Compliment',
                'Informação' => 'Information',
                'Reclamação' => 'Complaint',
                'Solicitação' => 'Request'
            },
            'Assunto__c' => new Map<String, String>{
                'Informativo' => 'Informative',
                'Informar status de remoção de carga' => 'Inform cargo removal status',
                'Reclamação formal do cliente' => 'Formal customer complaint',
                'Solicitação de Proposta' => 'Proposal request',
                'Solicitação para faturar' => 'Billing request',
                'Solicitação de status do transporte' => 'Transportation status request',
                'Status' => 'Status',
                'Status de Atendimento' => 'Service status',
                'Status de Operação' => 'Operation status',
                'Status de aprovação' => 'Approval status'
            }
        };
    }
}