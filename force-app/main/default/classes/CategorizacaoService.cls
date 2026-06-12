public inherited sharing class CategorizacaoService {
    public class FunctionalException extends Exception { public String code; }

    public static void beforeSave(List<Categorizacao__c> records) {
        if (records == null || records.isEmpty()) return;

        Set<Id> rtIds = new Set<Id>();
        Set<String> queueDevNames = new Set<String>();
        for (Categorizacao__c row : records) {
            if (row.RecordTypeId != null) rtIds.add(row.RecordTypeId);
            if (!String.isBlank(row.FilaDeveloperName__c)) queueDevNames.add(row.FilaDeveloperName__c);
        }

        Map<Id, RecordType> rts = CategorizacaoSelector.getRecordTypesById(rtIds);
        Map<String, CategorizacaoSelector.UnidadeConfig> cfgByRt = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName();
        Map<String, CategorizacaoSelector.QueueData> queueByDev = CategorizacaoSelector.getCaseQueuesByDeveloperName(queueDevNames);

        for (Categorizacao__c row : records) {
            validateAndNormalize(row, rts.get(row.RecordTypeId), cfgByRt, queueByDev);
        }

        Set<String> hashes = new Set<String>();
        Set<Id> ids = new Set<Id>();
        for (Categorizacao__c row : records) {
            if (!String.isBlank(row.ChaveNaturalHash__c)) hashes.add(row.ChaveNaturalHash__c);
            if (row.Id != null) ids.add(row.Id);
        }

        Map<String, Categorizacao__c> existing = CategorizacaoSelector.getExistingByHash(hashes, ids);
        Set<String> seen = new Set<String>();
        for (Categorizacao__c row : records) {
            if (String.isBlank(row.ChaveNaturalHash__c)) continue;
            if (existing.containsKey(row.ChaveNaturalHash__c) || seen.contains(row.ChaveNaturalHash__c)) {
                row.addError('Já existe uma categorização equivalente cadastrada para esta Unidade de Negócio.');
            }
            seen.add(row.ChaveNaturalHash__c);
        }
    }

    public static CategorizacaoDTO.Response save(CategorizacaoDTO.Request req) {
        Categorizacao__c existing;
        if (req != null && req.id != null) {
            existing = CategorizacaoSelector.getById(req.id);
        }

        Categorizacao__c row = CategorizacaoHelper.toSObject(req);
        if (req == null || req.ativo == null) {
            row.Ativo__c = existing != null && existing.Ativo__c != null ? existing.Ativo__c : true;
        }
        if (existing != null) {
            if (req.recordTypeId == null) row.RecordTypeId = existing.RecordTypeId;
            if (String.isBlank(req.unidadeNegocio)) row.UnidadeNegocios__c = existing.UnidadeNegocios__c;
            if (String.isBlank(req.tipoCaso)) row.TipoCaso__c = existing.TipoCaso__c;
            if (String.isBlank(req.categoria)) row.Categoria__c = existing.Categoria__c;
            if (String.isBlank(req.assunto)) row.Assunto__c = existing.Assunto__c;
            if (String.isBlank(req.subassunto)) row.Subassunto__c = existing.Subassunto__c;
            if (String.isBlank(req.prioridade)) row.Prioridade__c = existing.Prioridade__c;
            if (String.isBlank(req.descricao)) row.Descricao__c = existing.Descricao__c;
            if (String.isBlank(req.motivoInativacao)) row.MotivoInativacao__c = existing.MotivoInativacao__c;
            if (req.distribuirParaFila == null) row.DistribuirParaFila__c = existing.DistribuirParaFila__c;
            if (req.porCategorizacao == null) row.PorCategorizacao__c = existing.PorCategorizacao__c;
            if (String.isBlank(req.filaDeveloperName)) row.FilaDeveloperName__c = existing.FilaDeveloperName__c;
            if (String.isBlank(req.campoDistribuicao)) row.CampoDistribuicao__c = existing.CampoDistribuicao__c;
            if (String.isBlank(req.valorDistribuicao)) row.ValorDistribuicao__c = existing.ValorDistribuicao__c;
        }
        beforeSave(new List<Categorizacao__c>{ row });
        if (row.getErrors().size() > 0) throwFunctional('VALIDATION_ERROR', row.getErrors()[0].getMessage());

        try {
            if (row.Id == null) insert row; else update row;
            saveRegrasSla(row.Id, req == null ? null : req.regrasSla);
        } catch (DmlException dmx) {
            throwFunctional('VALIDATION_ERROR', dmx.getDmlMessage(0));
        }

        CategorizacaoDTO.Response response = new CategorizacaoDTO.Response();
        response.success = true;
        response.message = 'Categorização salva com sucesso.';
        response.registro = CategorizacaoHelper.toView(CategorizacaoSelector.getById(row.Id), canViewTechnicalSummary());
        return response;
    }

    public static List<CategorizacaoDTO.RecordTypeOption> getAvailableRecordTypes() {
        List<CategorizacaoDTO.RecordTypeOption> out = new List<CategorizacaoDTO.RecordTypeOption>();
        Map<Id, Schema.RecordTypeInfo> infos = Categorizacao__c.SObjectType.getDescribe().getRecordTypeInfosById();
        for (RecordType rt : CategorizacaoSelector.getAvailableRecordTypesForObject()) {
            Schema.RecordTypeInfo rti = infos.get(rt.Id);
            if (rti == null || !rti.isAvailable()) continue;
            CategorizacaoDTO.RecordTypeOption o = new CategorizacaoDTO.RecordTypeOption();
            o.recordTypeId = rt.Id; o.developerName = rt.DeveloperName; o.label = rt.Name;
            out.add(o);
        }
        return out;
    }

    public static Map<String, List<CategorizacaoDTO.PicklistOption>> getPicklists() {
        Map<String, List<CategorizacaoDTO.PicklistOption>> out = new Map<String, List<CategorizacaoDTO.PicklistOption>>();
        out.put('TipoCaso__c', CategorizacaoHelper.toPicklistOptions(Categorizacao__c.TipoCaso__c.getDescribe().getPicklistValues()));
        out.put('Categoria__c', CategorizacaoHelper.toPicklistOptions(Categorizacao__c.Categoria__c.getDescribe().getPicklistValues()));
        out.put('Assunto__c', CategorizacaoHelper.toPicklistOptions(Categorizacao__c.Assunto__c.getDescribe().getPicklistValues()));
        out.put('Subassunto__c', CategorizacaoHelper.toPicklistOptions(Categorizacao__c.Subassunto__c.getDescribe().getPicklistValues()));
        out.put('Prioridade__c', CategorizacaoHelper.toPicklistOptions(Case.Priority.getDescribe().getPicklistValues()));
        return out;
    }

    public static List<CategorizacaoDTO.CasePicklistField> getCasePicklistFields() {
        List<CategorizacaoDTO.CasePicklistField> out = new List<CategorizacaoDTO.CasePicklistField>();
        Map<String, Schema.SObjectField> fields = Case.SObjectType.getDescribe().fields.getMap();
        for (String apiName : fields.keySet()) {
            Schema.DescribeFieldResult d = fields.get(apiName).getDescribe();
            if (d.getType() != Schema.DisplayType.Picklist) continue;
            CategorizacaoDTO.CasePicklistField f = new CategorizacaoDTO.CasePicklistField();
            f.apiName = apiName; f.label = d.getLabel(); f.type = String.valueOf(d.getType());
            f.values = CategorizacaoHelper.toPicklistOptions(d.getPicklistValues());
            out.add(f);
        }
        out.sort(new CaseFieldComparator());
        return out;
    }

    public class CaseFieldComparator implements System.Comparator<CategorizacaoDTO.CasePicklistField> {
        public Integer compare(CategorizacaoDTO.CasePicklistField a, CategorizacaoDTO.CasePicklistField b) {
            return String.valueOf(a.label).toLowerCase().compareTo(String.valueOf(b.label).toLowerCase());
        }
    }

    public static List<CategorizacaoDTO.QueueOption> getQueues(String unidadeNegocio) {
        String prefix;
        for (CategorizacaoSelector.UnidadeConfig cfg : CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName().values()) {
            if (cfg.ativo == true && cfg.unidadeNegocio == unidadeNegocio) prefix = cfg.queuePrefix;
        }
        List<CategorizacaoDTO.QueueOption> out = new List<CategorizacaoDTO.QueueOption>();
        for (CategorizacaoSelector.QueueData q : CategorizacaoSelector.listCaseQueuesByPrefix(prefix)) {
            CategorizacaoDTO.QueueOption o = new CategorizacaoDTO.QueueOption();
            o.id = q.id; o.name = q.name; o.developerName = q.developerName;
            out.add(o);
        }
        return out;
    }

    public static CategorizacaoDTO.InitialState getInitialState(Id recordId) {
        CategorizacaoDTO.InitialState state = new CategorizacaoDTO.InitialState();
        state.availableRecordTypes = getAvailableRecordTypes();
        Map<String, List<CategorizacaoDTO.PicklistOption>> p = getPicklists();
        state.tipoCasoOptions = p.get('TipoCaso__c');
        state.categoriaOptions = p.get('Categoria__c');
        state.assuntoOptions = p.get('Assunto__c');
        state.subassuntoOptions = p.get('Subassunto__c');
        state.prioridadeOptions = p.get('Prioridade__c');
        state.regraTipoAreaOptions = CategorizacaoHelper.toPicklistOptions(RegrasSLACategorizacao__c.TipoAreaParticipante__c.getDescribe().getPicklistValues());
        state.regraAreaAtendimentoOptions = CategorizacaoHelper.toPicklistOptions(RegrasSLACategorizacao__c.AreaAtendimento__c.getDescribe().getPicklistValues());
        state.regraOrigemOptions = CategorizacaoHelper.toPicklistOptions(RegrasSLACategorizacao__c.Origem__c.getDescribe().getPicklistValues());
        state.casePicklistFields = getCasePicklistFields();
        state.canViewTechnicalSummary = canViewTechnicalSummary();

        if (recordId != null) {
            Categorizacao__c row = CategorizacaoSelector.getById(recordId);
            state.registro = CategorizacaoHelper.toView(row, state.canViewTechnicalSummary);
            state.regrasSla = toRegraViews(CategorizacaoSelector.getRegrasSlaByCategorizacao(recordId));
            state.queueOptions = getQueues(row.UnidadeNegocios__c);
        } else {
            state.registro = new CategorizacaoDTO.CategorizacaoView();
            state.regrasSla = new List<CategorizacaoDTO.RegraSLAView>();
            if (state.availableRecordTypes.size() == 1) {
                CategorizacaoDTO.RecordTypeOption only = state.availableRecordTypes[0];
                state.registro.recordTypeId = only.recordTypeId;
                state.registro.recordTypeDeveloperName = only.developerName;
                CategorizacaoSelector.UnidadeConfig cfg = CategorizacaoSelector.getUnidadeConfigsByRecordTypeDeveloperName().get(only.developerName);
                state.registro.unidadeNegocio = cfg == null ? null : cfg.unidadeNegocio;
                state.queueOptions = getQueues(state.registro.unidadeNegocio);
            } else {
                state.queueOptions = new List<CategorizacaoDTO.QueueOption>();
            }
            state.registro.ativo = true;
            state.registro.distribuirParaFila = false;
            state.registro.porCategorizacao = false;
        }
        return state;
    }

    private static List<CategorizacaoDTO.RegraSLAView> toRegraViews(List<RegrasSLACategorizacao__c> rows) {
        List<CategorizacaoDTO.RegraSLAView> out = new List<CategorizacaoDTO.RegraSLAView>();
        for (RegrasSLACategorizacao__c row : rows) {
            CategorizacaoDTO.RegraSLAView v = new CategorizacaoDTO.RegraSLAView();
            v.id = row.Id;
            v.tipoAreaParticipante = row.TipoAreaParticipante__c;
            v.areaAtendimento = row.AreaAtendimento__c;
            v.origem = row.Origem__c;
            v.businessHoursName = row.BusinessHoursName__c;
            v.ativo = row.Ativo__c;
            out.add(v);
        }
        return out;
    }

    private static void saveRegrasSla(Id categorizacaoId, List<CategorizacaoDTO.RegraSLARequest> requestRows) {
        if (categorizacaoId == null || requestRows == null) return;

        Map<Id, RegrasSLACategorizacao__c> existingById = new Map<Id, RegrasSLACategorizacao__c>(
            CategorizacaoSelector.getRegrasSlaByCategorizacao(categorizacaoId)
        );

        Set<Id> keepIds = new Set<Id>();
        List<RegrasSLACategorizacao__c> toUpsert = new List<RegrasSLACategorizacao__c>();

        for (CategorizacaoDTO.RegraSLARequest req : requestRows) {
            if (req == null) continue;
            if (req.id != null && req.markedForDelete == true) continue;

            RegrasSLACategorizacao__c row = req.id == null
                ? new RegrasSLACategorizacao__c(Categorizacao__c = categorizacaoId)
                : new RegrasSLACategorizacao__c(Id = req.id, Categorizacao__c = categorizacaoId);

            row.TipoAreaParticipante__c = req.tipoAreaParticipante;
            row.AreaAtendimento__c = req.areaAtendimento;
            row.Origem__c = req.origem;
            row.BusinessHoursName__c = req.businessHoursName;
            row.Ativo__c = req.ativo == null ? true : req.ativo;

            toUpsert.add(row);
            if (req.id != null) keepIds.add(req.id);
        }

        List<RegrasSLACategorizacao__c> toDelete = new List<RegrasSLACategorizacao__c>();
        for (RegrasSLACategorizacao__c existing : existingById.values()) {
            if (!keepIds.contains(existing.Id)) toDelete.add(existing);
        }

        if (!toDelete.isEmpty()) delete toDelete;
        if (!toUpsert.isEmpty()) upsert toUpsert;
    }

    public static Boolean canViewTechnicalSummary() {
        return Categorizacao__c.ChaveNatural__c.getDescribe().isAccessible() && Categorizacao__c.ChaveNaturalHash__c.getDescribe().isAccessible();
    }

    public static void throwFunctional(String code, String message) {
        FunctionalException ex = new FunctionalException(code + '::' + message);
        ex.code = code;
        throw ex;
    }

    private static void validateAndNormalize(Categorizacao__c row, RecordType rt, Map<String, CategorizacaoSelector.UnidadeConfig> cfgByRt, Map<String, CategorizacaoSelector.QueueData> queueByDev) {
        if (String.isBlank(row.UnidadeNegocios__c)) row.addError('Unidade de Negócio é obrigatória.');
        if (String.isBlank(row.TipoCaso__c)) row.addError('Tipo de Caso é obrigatório.');
        if (String.isBlank(row.Categoria__c)) row.addError('Categoria é obrigatória.');
        if (row.Ativo__c == null) row.addError('Ativo deve possuir valor.');
        if (row.Ativo__c == false && String.isBlank(row.MotivoInativacao__c)) row.addError('Motivo de inativação é obrigatório.');
        if (!String.isBlank(row.Prioridade__c)) {
            Set<String> activeCasePriorities = new Set<String>();
            for (Schema.PicklistEntry pe : Case.Priority.getDescribe().getPicklistValues()) {
                if (pe.isActive()) activeCasePriorities.add(pe.getValue());
            }
            if (!activeCasePriorities.contains(row.Prioridade__c)) {
                row.addError('Priorização sugerida inválida para os valores de Prioridade do Case.');
            }
        }

        CategorizacaoSelector.UnidadeConfig cfg = (rt == null) ? null : cfgByRt.get(rt.DeveloperName);
        if (cfg != null && cfg.ativo == true) {
            if (String.isBlank(row.UnidadeNegocios__c)) row.UnidadeNegocios__c = cfg.unidadeNegocio;
            if (row.UnidadeNegocios__c != cfg.unidadeNegocio) row.addError('Record Type incompatível com Unidade de Negócio.');
        }

        Boolean distribuir = CategorizacaoHelper.isTrueFlag(row.DistribuirParaFila__c);
        Boolean porCat = CategorizacaoHelper.isTrueFlag(row.PorCategorizacao__c);

        if (!distribuir) {
            clearDistribution(row, true, true);
        } else {
            row.DistribuirParaFila__c = 'Sim';
            row.PorCategorizacao__c = porCat ? 'Sim' : 'Não';

            if (String.isBlank(row.FilaDeveloperName__c)) row.addError('Fila é obrigatória.');
            CategorizacaoSelector.QueueData q = queueByDev.get(row.FilaDeveloperName__c);
            if (q == null) {
                row.addError('Fila inválida ou não habilitada para Case.');
            } else {
                if (cfg != null && !String.isBlank(cfg.queuePrefix) && !q.developerName.startsWith(cfg.queuePrefix)) {
                    row.addError('Prefixo da fila inválido para a Unidade de Negócio.');
                }
                row.NomeFilaDistribuicao__c = q.name;
                row.FilaId__c = String.valueOf(q.id);
            }

            if (porCat) {
                clearDistribution(row, false, false);
            } else {
                if (String.isBlank(row.CampoDistribuicao__c)) row.addError('Campo de distribuição é obrigatório.');
                if (String.isBlank(row.ValorDistribuicao__c)) row.addError('Valor de distribuição é obrigatório.');

                if (!String.isBlank(row.CampoDistribuicao__c)) {
                    Map<String, Schema.SObjectField> caseFields = Case.SObjectType.getDescribe().fields.getMap();
                    if (!caseFields.containsKey(row.CampoDistribuicao__c)) {
                        row.addError('Campo de distribuição inválido em Case.');
                    } else {
                        Schema.DescribeFieldResult df = caseFields.get(row.CampoDistribuicao__c).getDescribe();
                        if (df.getType() != Schema.DisplayType.Picklist) {
                            row.addError('Campo de distribuição deve ser Picklist.');
                        } else {
                            row.LabelCampoDistribuicao__c = df.getLabel();
                            Boolean found = false;
                            for (Schema.PicklistEntry pe : df.getPicklistValues()) {
                                if (!pe.isActive()) continue;
                                if (pe.getValue() == row.ValorDistribuicao__c) {
                                    row.LabelValorDistribuicao__c = pe.getLabel();
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) row.addError('Valor de distribuição inválido para o campo selecionado.');
                        }
                    }
                }
            }
        }

        String key = CategorizacaoHelper.buildNaturalKey(row);
        row.ChaveNatural__c = key;
        row.ChaveNaturalHash__c = CategorizacaoHelper.sha256Hex(key);
    }

    private static void clearDistribution(Categorizacao__c row, Boolean clearQueue, Boolean clearPorCategorizacao) {
        if (clearPorCategorizacao) row.PorCategorizacao__c = 'Não';
        if (clearQueue) {
            row.DistribuirParaFila__c = 'Não';
            row.NomeFilaDistribuicao__c = null;
            row.FilaDeveloperName__c = null;
            row.FilaId__c = null;
        }
        row.CampoDistribuicao__c = null;
        row.LabelCampoDistribuicao__c = null;
        row.ValorDistribuicao__c = null;
        row.LabelValorDistribuicao__c = null;
    }
}