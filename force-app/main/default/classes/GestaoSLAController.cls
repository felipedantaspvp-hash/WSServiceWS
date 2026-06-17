public inherited sharing class GestaoSLAController {
    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.BootstrapResponse getBootstrap() {
        try {
            return GestaoSLAService.getBootstrap();
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.GestaoDetailResponse getGestaoDetail(Id gestaoSLAId) {
        try {
            return GestaoSLAService.getGestaoDetail(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.CategoriasResponse getCategorias(Id gestaoSLAId, String searchTerm, String tipoCaso, String categoria, String assunto, Boolean ativo) {
        try {
            return GestaoSLAService.getCategorias(gestaoSLAId, searchTerm, tipoCaso, categoria, assunto, ativo);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.MarcosResponse getMarcos(Id gestaoSLAId) {
        try {
            return GestaoSLAService.getMarcos(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

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

    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.InactiveGestoesResponse getInactiveGestoes() {
        try {
            return GestaoSLAService.getInactiveGestoes();
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static GestaoSLADTO.InactiveCategoriasResponse getInactiveCategorias(Id gestaoSLAId) {
        try {
            return GestaoSLAService.getInactiveCategorias(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.GestaoDetailResponse createGestaoSLA(GestaoSLADTO.CreateGestaoRequest request) {
        try {
            return GestaoSLAService.createGestaoSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.GestaoDetailResponse updateGestaoSLA(GestaoSLADTO.UpdateGestaoRequest request) {
        try {
            return GestaoSLAService.updateGestaoSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.GestaoDetailResponse reactivateGestaoSLA(Id gestaoSLAId) {
        try {
            return GestaoSLAService.reactivateGestaoSLA(gestaoSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo createCategoria(GestaoSLADTO.CategoriaRequest request) {
        try {
            return GestaoSLAService.createCategoria(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo updateCategoria(GestaoSLADTO.CategoriaRequest request) {
        try {
            return GestaoSLAService.updateCategoria(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo deactivateCategoria(Id categoriaId) {
        try {
            return GestaoSLAService.deactivateCategoria(categoriaId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.CategoriaResumo reactivateCategoria(Id categoriaId) {
        try {
            return GestaoSLAService.reactivateCategoria(categoriaId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo createRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        try {
            return GestaoSLAService.createRegraSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo updateRegraSLA(GestaoSLADTO.RegraSLARequest request) {
        try {
            return GestaoSLAService.updateRegraSLA(request);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo deactivateRegraSLA(Id regraSLAId) {
        try {
            return GestaoSLAService.deactivateRegraSLA(regraSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static GestaoSLADTO.RegraSLAResumo activateRegraSLA(Id regraSLAId) {
        try {
            return GestaoSLAService.activateRegraSLA(regraSLAId);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAreasInternas() {
        try {
            return GestaoSLAService.getAreasInternas();
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<GestaoSLADTO.RegraSLAResumo> createRegrasSLABulk(List<GestaoSLADTO.RegraSLARequest> requests) {
        try {
            return GestaoSLAService.createRegrasSLABulk(requests);
        } catch (GestaoSLAService.FunctionalException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}