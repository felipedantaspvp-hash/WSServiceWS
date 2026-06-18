/**
 * @description       : Controller Apex expondo endpoints @AuraEnabled para o módulo GestaoSLA. Delega toda lógica ao GestaoSLAService.
 * @author            : Triscal
 * @group             : Gestão de SLA
 * @last modified on  : 06-17-2026
 * @last modified by  : Jean Duarte
 **/
public inherited sharing class GestaoSLAController {
    /**
     * @description Carrega dados de bootstrap para o LWC de Gestão de SLA: lista de gestões ativas,
     *              marcos SLA, áreas internas e metadados necessários para inicializar o componente.
     * @return BootstrapResponse com gestões ativas, marcos e opções de picklist.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.BootstrapResponse getBootstrap() {
        try {
            return GestaoSLAService.getBootstrap();
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna detalhes completos de uma Gestão de SLA específica.
     * @param gestaoSLAId Id do registro GestaoSLA__c.
     * @return GestaoDetailResponse com campos, categorias e regras associadas.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.GestaoDetailResponse getGestaoDetail(Id gestaoSLAId) {
        try {
            return GestaoSLAService.getGestaoDetail(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna lista paginada/filtrada de categorizações vinculadas a uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param searchTerm Termo de busca livre para filtrar por nome.
     * @param tipoCaso Filtro por tipo de caso.
     * @param categoria Filtro por categoria.
     * @param assunto Filtro por assunto.
     * @param ativo Filtro por status ativo/inativo.
     * @return CategoriasResponse com lista de categorizações filtradas.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.CategoriasResponse getCategorias(Id gestaoSLAId, String searchTerm, String tipoCaso, String categoria, String assunto, Boolean ativo) {
        try {
            return GestaoSLAService.getCategorias(gestaoSLAId, searchTerm, tipoCaso, categoria, assunto, ativo);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna os marcos de SLA (entitlement processes) disponíveis para uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return MarcosResponse com lista de marcos disponíveis para associação.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.MarcosResponse getMarcos(Id gestaoSLAId) {
        try {
            return GestaoSLAService.getMarcos(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna regras de SLA vinculadas a uma Gestão de SLA com filtros opcionais.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @param categorizacaoId Filtro por categorização.
     * @param marcoSLAId Filtro por marco SLA.
     * @param escopo Filtro por escopo (ex: Área Participante).
     * @param areaAtendimento Filtro por área de atendimento.
     * @param ativo Filtro por status ativo/inativo.
     * @return RegrasSLAResponse com lista de regras filtradas.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.RegrasSLAResponse getRegrasSLA(
        Id gestaoSLAId,
        Id categorizacaoId,
        Id marcoSLAId,
        String escopo,
        String areaAtendimento,
        Boolean ativo
    ) {
        try {
            return GestaoSLAService.getRegrasSLA(gestaoSLAId, categorizacaoId, marcoSLAId, escopo, areaAtendimento, ativo);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna lista de Gestões de SLA inativas para reativação.
     * @return InactiveGestoesResponse com registros GestaoSLA__c inativos.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.InactiveGestoesResponse getInactiveGestoes() {
        try {
            return GestaoSLAService.getInactiveGestoes();
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna categorizações inativas vinculadas a uma Gestão de SLA.
     * @param gestaoSLAId Id da Gestão de SLA.
     * @return InactiveCategoriasResponse com categorizações inativas disponíveis para reativação.
     **/
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.InactiveCategoriasResponse getInactiveCategorias(Id gestaoSLAId) {
        try {
            return GestaoSLAService.getInactiveCategorias(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Cria uma nova Gestão de SLA com os dados fornecidos.
     * @param request CreateGestaoRequest com nome, unidade de negócio e configurações iniciais.
     * @return GestaoDetailResponse com o registro criado e seus campos.
     **/
    @AuraEnabled
    public static GestaoSLADTO.GestaoDetailResponse createGestaoSLA(GestaoSLADTO.CreateGestaoRequest request) {
        try {
            return GestaoSLAService.createGestaoSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Atualiza os campos de uma Gestão de SLA existente.
     * @param request UpdateGestaoRequest com id e campos a atualizar.
     * @return GestaoDetailResponse com o registro atualizado.
     **/
    @AuraEnabled
    public static GestaoSLADTO.GestaoDetailResponse updateGestaoSLA(GestaoSLADTO.UpdateGestaoRequest request) {
        try {
            return GestaoSLAService.updateGestaoSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Reativa uma Gestão de SLA inativa, tornando-a elegível para novas regras e categorizações.
     * @param gestaoSLAId Id da Gestão de SLA a reativar.
     * @return GestaoDetailResponse com o registro reativado.
     **/
    @AuraEnabled
    public static GestaoSLADTO.GestaoDetailResponse reactivateGestaoSLA(Id gestaoSLAId) {
        try {
            return GestaoSLAService.reactivateGestaoSLA(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Exclui definitivamente uma Gestão de SLA. Restrito ao Admin Técnico.
     * @param gestaoSLAId Id da GestaoSLA__c a excluir.
     **/
    @AuraEnabled
    public static void deleteGestaoSLA(Id gestaoSLAId) {
        try {
            GestaoSLAService.deleteGestaoSLA(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Exclui definitivamente uma Categorização. Restrito ao Admin Técnico.
     * @param categoriaId Id da Categorizacao__c a excluir.
     **/
    @AuraEnabled
    public static void deleteCategoria(Id categoriaId) {
        try {
            GestaoSLAService.deleteCategoria(categoriaId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Exclui definitivamente uma Regra de SLA. Restrito ao Admin Técnico.
     * @param regraSLAId Id da RegrasSLACategorizacao__c a excluir.
     **/
    @AuraEnabled
    public static void deleteRegraSLA(Id regraSLAId) {
        try {
            GestaoSLAService.deleteRegraSLA(regraSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Exclui em lote Regras de SLA de Área Interna cujos tempos foram limpos na grid.
     * @param regraIds Ids das RegrasSLACategorizacao__c a excluir.
     **/
    @AuraEnabled
    public static void deleteRegrasSLABulk(List<Id> regraIds) {
        try {
            GestaoSLAService.deleteRegrasSLABulk(regraIds);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Cria uma nova categorização (Categorizacao__c) vinculada a uma Gestão de SLA.
     * @param request CategoriaRequest com dados da nova categorização.
     * @return CategoriaResumo com id e campos resumidos do registro criado.
     **/
    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo createCategoria(GestaoSLADTO.CategoriaRequest request) {
        try {
            return GestaoSLAService.createCategoria(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Atualiza campos de uma categorização existente vinculada a uma Gestão de SLA.
     * @param request CategoriaRequest com id e campos a atualizar.
     * @return CategoriaResumo com campos atualizados.
     **/
    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo updateCategoria(GestaoSLADTO.CategoriaRequest request) {
        try {
            return GestaoSLAService.updateCategoria(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Desativa uma categorização, impedindo novos Cases de utilizá-la.
     * @param categoriaId Id da Categorizacao__c a desativar.
     * @return CategoriaResumo com status atualizado para inativo.
     **/
    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo deactivateCategoria(Id categoriaId) {
        try {
            return GestaoSLAService.deactivateCategoria(categoriaId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Reativa uma categorização previamente desativada.
     * @param categoriaId Id da Categorizacao__c a reativar.
     * @return CategoriaResumo com status atualizado para ativo.
     **/
    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo reactivateCategoria(Id categoriaId) {
        try {
            return GestaoSLAService.reactivateCategoria(categoriaId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Cria uma nova Regra de SLA vinculada a uma categorização e marco SLA específicos.
     * @param request RegraSLARequest com escopo, área, tempo e referências de gestão/categorização/marco.
     * @return RegraSLAResumo com id e campos resumidos da regra criada.
     **/
    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo createRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        try {
            return GestaoSLAService.createRegraSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Atualiza campos de uma Regra de SLA existente.
     * @param request RegraSLARequest com id e campos a atualizar.
     * @return RegraSLAResumo com campos atualizados.
     **/
    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo updateRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        try {
            return GestaoSLAService.updateRegraSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Desativa uma Regra de SLA, impedindo que seja aplicada em novos Cases.
     * @param regraSLAId Id da RegrasSLACategorizacao__c a desativar.
     * @return RegraSLAResumo com status atualizado para inativo.
     **/
    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo deactivateRegraSLA(Id regraSLAId) {
        try {
            return GestaoSLAService.deactivateRegraSLA(regraSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Reativa uma Regra de SLA previamente desativada.
     * @param regraSLAId Id da RegrasSLACategorizacao__c a reativar.
     * @return RegraSLAResumo com status atualizado para ativo.
     **/
    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo activateRegraSLA(Id regraSLAId) {
        try {
            return GestaoSLAService.activateRegraSLA(regraSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Retorna lista de áreas internas disponíveis como opções de picklist para regras de SLA.
     * @return Lista de Strings com os valores da picklist de áreas internas.
     **/
    @AuraEnabled(cacheable=true)
    public static List<String> getAreasInternas() {
        try {
            return GestaoSLAService.getAreasInternas();
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Cria múltiplas Regras de SLA em uma única operação DML.
     *              Valida cada regra individualmente antes de inserir em bulk.
     * @param requests Lista de RegraSLARequest com dados de cada regra a criar.
     * @return Lista de RegraSLAResumo com os registros criados.
     **/
    @AuraEnabled
    public static List<GestaoSLADTO.RegraSLAResumo> createRegrasSLABulk(List<GestaoSLADTO.RegraSLARequest> requests) {
        try {
            return GestaoSLAService.createRegrasSLABulk(requests);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
