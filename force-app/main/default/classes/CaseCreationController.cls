/**
 * @description       : Controller Apex expondo endpoints @AuraEnabled para o módulo CaseCreation. Delega toda lógica ao CaseCreationService.
 * @author            : Triscal
 * @group             : Case Creation
 * @last modified on  : 06-11-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class CaseCreationController {
    @TestVisible static Exception testException;

    /**
     * @description Carrega contexto inicial para criação de Case: record types disponíveis, filas e metadados de categorização.
     * @return InitialContextDTO com todas as opções necessárias para inicializar o formulário.
     **/
    @AuraEnabled(cacheable=true)
    public static CaseCreationDTO.InitialContextDTO getInitialContext() {
        return CaseCreationService.getInitialContext();
    }

    /**
     * @description Retorna opções da árvore de categorização com base na seleção atual do formulário.
     * @param request CategorizationRequestDTO com nível e valores já selecionados.
     * @return TreeOptionsDTO com opções disponíveis para o próximo nível da árvore.
     **/
    @AuraEnabled(cacheable=true)
    public static CaseCreationDTO.TreeOptionsDTO getTreeOptions(CaseCreationDTO.CategorizationRequestDTO request) {
        return CaseCreationService.getTreeOptions(request);
    }

    /**
     * @description Resolve a seleção de categorização e retorna valores padrão derivados para preencher o formulário.
     * @param request CategorizationRequestDTO com seleção completa do usuário.
     * @return ResolveSelectionResponseDTO com valores resolvidos e warnings de validação.
     **/
    @AuraEnabled
    public static CaseCreationDTO.ResolveSelectionResponseDTO resolveCategorizationSelection(CaseCreationDTO.CategorizationRequestDTO request) {
        return CaseCreationService.resolveCategorizationSelection(request);
    }

    /**
     * @description Retorna filas disponíveis para o record type e unidade de negócio informados.
     * @param recordTypeDeveloperName Nome do RecordType selecionado.
     * @param unidadeNegocio Valor da unidade de negócio para filtrar filas compatíveis.
     * @return Lista de QueueOptionDTO com label e value para o campo de fila.
     **/
    @AuraEnabled(cacheable=true)
    public static List<CaseCreationDTO.QueueOptionDTO> getAvailableQueues(String recordTypeDeveloperName, String unidadeNegocio) {
        return CaseCreationService.getAvailableQueues(recordTypeDeveloperName, unidadeNegocio);
    }

    /**
     * @description Constrói valores padrão para o formulário de criação de Case com base na categorização selecionada.
     *              Consulta regras de SLA ativas e preenche campos como BusinessHours, Entitlement e fila sugerida.
     * @param request BuildDefaultValuesRequestDTO com record type, categorização e contexto do formulário.
     * @return BuildDefaultValuesResponseDTO com mapa de valores padrão e warnings.
     **/
    @AuraEnabled
    public static CaseCreationDTO.BuildDefaultValuesResponseDTO buildDefaultValues(CaseCreationDTO.BuildDefaultValuesRequestDTO request) {
        try {
            if (Test.isRunningTest() && testException != null) throw testException;
            return CaseCreationService.buildDefaultValues(request);
        } catch (CaseCreationService.FunctionalException ex) {
            CaseCreationDTO.BuildDefaultValuesResponseDTO out = new CaseCreationDTO.BuildDefaultValuesResponseDTO();
            out.success = false;
            out.defaultValues = new Map<String, String>();
            out.warnings = new List<String>();
            out.errors = new List<String>{ ex.getMessage() };
            out.error = new CaseCreationDTO.ErrorInfo();
            out.error.code = String.isBlank(ex.code) ? 'VALIDATION_ERROR' : ex.code;
            out.error.message = ex.getMessage();
            return out;
        } catch (Exception ex) {
            CaseCreationDTO.BuildDefaultValuesResponseDTO out = new CaseCreationDTO.BuildDefaultValuesResponseDTO();
            out.success = false;
            out.defaultValues = new Map<String, String>();
            out.warnings = new List<String>();
            out.errors = new List<String>{ 'Erro inesperado ao preparar o formulário de criação do Case.' };
            out.error = new CaseCreationDTO.ErrorInfo();
            out.error.code = 'UNEXPECTED_ERROR';
            out.error.message = out.errors[0];
            return out;
        }
    }
}