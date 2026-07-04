public inherited sharing class CategorizacaoController {
    /**
     * @description Retorna estado inicial para criacao/edicao.
     * @param recordId Id opcional da categorizacao.
     * @return DTO de estado inicial.
     */
    @AuraEnabled
    public static CategorizacaoDTO.InitialState getInitialState(Id recordId) {
        enforceRead();
        return CategorizacaoService.getInitialState(recordId);
    }

    /** @description Retorna record types de categorizacao disponiveis ao usuario. */
    @AuraEnabled(cacheable=true)
    public static List<CategorizacaoDTO.RecordTypeOption> getAvailableRecordTypes() {
        enforceRead();
        return CategorizacaoService.getAvailableRecordTypes();
    }

    /** @description Retorna picklists funcionais para o objeto Categorizacao__c. */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<CategorizacaoDTO.PicklistOption>> getPicklistValues(String recordTypeId) {
        enforceRead();
        return CategorizacaoService.getPicklists();
    }

    /** @description Retorna campos picklist do objeto Case para distribuicao. */
    @AuraEnabled(cacheable=true)
    public static List<CategorizacaoDTO.CasePicklistField> getCasePicklistFields() {
        enforceRead();
        return CategorizacaoService.getCasePicklistFields();
    }

    /** @description Retorna filas compativeis com a unidade de negocio. */
    @AuraEnabled(cacheable=true)
    public static List<CategorizacaoDTO.QueueOption> getQueues(String unidadeNegocio) {
        enforceRead();
        return CategorizacaoService.getQueues(unidadeNegocio);
    }

    /**
     * @description Salva categorizacao com validacoes server-side.
     * @param request DTO de entrada.
     * @return DTO de resposta com sucesso ou erro amigavel.
     */
    @AuraEnabled
    public static CategorizacaoDTO.Response save(CategorizacaoDTO.Request request) {
        try {
            enforceWrite(request == null || request.id == null);
            return CategorizacaoService.save(request);
        } catch (CategorizacaoService.FunctionalException ex) {
            CategorizacaoDTO.Response r = new CategorizacaoDTO.Response();
            r.success = false;
            r.error = new CategorizacaoDTO.ErrorInfo();
            String msg = ex.getMessage();
            String code = ex.code;
            if ((String.isBlank(code) || code == 'VALIDATION_ERROR') && msg != null && msg.contains('::')) {
                List<String> parts = msg.split('::', 2);
                if (parts.size() == 2) {
                    code = parts[0];
                    msg = parts[1];
                }
            }
            r.error.code = String.isBlank(code) ? 'VALIDATION_ERROR' : code;
            r.error.message = msg;
            r.message = r.error.message;
            return r;
        } catch (Exception ex) {
            CaseControllerLogHelper.logUnexpectedError('CategorizacaoController.save', 'Categorizacao__c', request != null ? request.id : null, ex);
            CategorizacaoDTO.Response r = new CategorizacaoDTO.Response();
            r.success = false;
            r.error = new CategorizacaoDTO.ErrorInfo();
            r.error.code = 'UNEXPECTED_ERROR';
            r.error.message = 'Ocorreu um erro inesperado ao salvar a categorização.';
            r.message = r.error.message;
            return r;
        }
    }

    private static void enforceRead() {
        if (!resolveAccess('CategorizacaoController.categorizacaoReadAccess', Schema.sObjectType.Categorizacao__c.isAccessible())) {
            CategorizacaoService.throwFunctional('CRUD_DENIED', 'Usuário sem permissão de leitura para Categorização.');
        }
    }

    private static void enforceWrite(Boolean isInsert) {
        if (isInsert && !resolveAccess('CategorizacaoController.categorizacaoCreateAccess', Schema.sObjectType.Categorizacao__c.isCreateable())) {
            CategorizacaoService.throwFunctional('CRUD_DENIED', 'Usuário sem permissão para criar Categorização.');
        }
        if (!isInsert && !resolveAccess('CategorizacaoController.categorizacaoUpdateAccess', Schema.sObjectType.Categorizacao__c.isUpdateable())) {
            CategorizacaoService.throwFunctional('CRUD_DENIED', 'Usuário sem permissão para editar Categorização.');
        }
        if (!resolveAccess('CategorizacaoController.regrasReadAccess', Schema.sObjectType.RegrasSLACategorizacao__c.isAccessible())) {
            CategorizacaoService.throwFunctional('CRUD_DENIED', 'Usuario sem permissao de leitura para Regras SLA.');
        }
        if (!resolveAccess(
            'CategorizacaoController.regrasManageAccess',
            Schema.sObjectType.RegrasSLACategorizacao__c.isCreateable()
                && Schema.sObjectType.RegrasSLACategorizacao__c.isUpdateable()
                && Schema.sObjectType.RegrasSLACategorizacao__c.isDeletable()
        )) {
            CategorizacaoService.throwFunctional('CRUD_DENIED', 'Usuario sem permissao para manter Regras SLA de Categorizacao.');
        }
    }

    private static Boolean resolveAccess(String overrideKey, Boolean actualValue) {
        Boolean overrideValue = ApexTestSeam.getNullableBoolean(overrideKey);
        if (overrideValue != null) return overrideValue;
        return actualValue;
    }
}