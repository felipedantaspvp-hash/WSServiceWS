public inherited sharing class CategorizacaoHelper {
    public static final String SEP = '|';

    public static String nv(String value) {
        return String.isBlank(value) ? '' : value.trim();
    }

    public static String normalizeKeyPart(String value) {
        return removeAccents(nv(value)).toUpperCase();
    }

    public static String removeAccents(String value) {
        if (String.isBlank(value)) return '';
        String out = value;
        Map<String, String> accents = new Map<String, String>{
            'Á'=>'A','À'=>'A','Â'=>'A','Ã'=>'A','Ä'=>'A','á'=>'a','à'=>'a','â'=>'a','ã'=>'a','ä'=>'a',
            'É'=>'E','È'=>'E','Ê'=>'E','Ë'=>'E','é'=>'e','è'=>'e','ê'=>'e','ë'=>'e',
            'Í'=>'I','Ì'=>'I','Î'=>'I','Ï'=>'I','í'=>'i','ì'=>'i','î'=>'i','ï'=>'i',
            'Ó'=>'O','Ò'=>'O','Ô'=>'O','Õ'=>'O','Ö'=>'O','ó'=>'o','ò'=>'o','ô'=>'o','õ'=>'o','ö'=>'o',
            'Ú'=>'U','Ù'=>'U','Û'=>'U','Ü'=>'U','ú'=>'u','ù'=>'u','û'=>'u','ü'=>'u',
            'Ç'=>'C','ç'=>'c','Ñ'=>'N','ñ'=>'n'
        };
        for (String k : accents.keySet()) out = out.replace(k, accents.get(k));
        return out;
    }

    public static Boolean isTrueFlag(String value) {
        String n = normalizeKeyPart(value);
        return n == 'SIM' || n == 'TRUE' || n == 'YES' || n == '1';
    }

    public static String boolToFlag(Boolean value) {
        return value == true ? 'Sim' : 'Não';
    }

    public static String buildNaturalKey(Categorizacao__c row) {
        List<String> parts = new List<String>{
            normalizeKeyPart(row.UnidadeNegocios__c),
            normalizeKeyPart(row.TipoCaso__c),
            normalizeKeyPart(row.Categoria__c),
            normalizeKeyPart(row.Assunto__c),
            normalizeKeyPart(row.Subassunto__c)
        };

        if (!isTrueFlag(row.DistribuirParaFila__c)) {
            parts.add('SEM_DISTRIBUICAO');
        } else if (isTrueFlag(row.PorCategorizacao__c)) {
            parts.add('POR_CATEGORIZACAO');
        } else {
            parts.add(normalizeKeyPart(row.CampoDistribuicao__c));
            parts.add(normalizeKeyPart(row.ValorDistribuicao__c));
        }
        return String.join(parts, SEP);
    }

    public static String sha256Hex(String payload) {
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(String.valueOf(payload)));
        return EncodingUtil.convertToHex(digest);
    }

    public static Categorizacao__c toSObject(CategorizacaoDTO.Request req) {
        Categorizacao__c row = req.id == null ? new Categorizacao__c() : new Categorizacao__c(Id = req.id);
        row.RecordTypeId = req.recordTypeId;
        row.UnidadeNegocios__c = req.unidadeNegocio;
        row.TipoCaso__c = req.tipoCaso;
        row.Categoria__c = req.categoria;
        row.Assunto__c = req.assunto;
        row.Subassunto__c = req.subassunto;
        row.Prioridade__c = req.prioridade;
        row.Ativo__c = req.ativo;
        row.Descricao__c = req.descricao;
        row.MotivoInativacao__c = req.motivoInativacao;
        row.DistribuirParaFila__c = boolToFlag(req.distribuirParaFila);
        row.PorCategorizacao__c = boolToFlag(req.porCategorizacao);
        row.FilaDeveloperName__c = req.filaDeveloperName;
        row.CampoDistribuicao__c = req.campoDistribuicao;
        row.ValorDistribuicao__c = req.valorDistribuicao;
        return row;
    }

    public static CategorizacaoDTO.CategorizacaoView toView(Categorizacao__c row, Boolean allowTechnical) {
        CategorizacaoDTO.CategorizacaoView view = new CategorizacaoDTO.CategorizacaoView();
        view.id = row.Id;
        view.recordTypeId = row.RecordTypeId;
        view.recordTypeDeveloperName = row.RecordType == null ? null : row.RecordType.DeveloperName;
        view.unidadeNegocio = row.UnidadeNegocios__c;
        view.tipoCaso = row.TipoCaso__c;
        view.categoria = row.Categoria__c;
        view.assunto = row.Assunto__c;
        view.subassunto = row.Subassunto__c;
        view.prioridade = row.Prioridade__c;
        view.ativo = row.Ativo__c;
        view.descricao = row.Descricao__c;
        view.motivoInativacao = row.MotivoInativacao__c;
        view.distribuirParaFila = isTrueFlag(row.DistribuirParaFila__c);
        view.porCategorizacao = isTrueFlag(row.PorCategorizacao__c);
        view.nomeFilaDistribuicao = row.NomeFilaDistribuicao__c;
        view.filaDeveloperName = row.FilaDeveloperName__c;
        view.filaId = row.FilaId__c;
        view.campoDistribuicao = row.CampoDistribuicao__c;
        view.labelCampoDistribuicao = row.LabelCampoDistribuicao__c;
        view.valorDistribuicao = row.ValorDistribuicao__c;
        view.labelValorDistribuicao = row.LabelValorDistribuicao__c;
        if (allowTechnical) {
            view.chaveNatural = row.ChaveNatural__c;
            view.chaveNaturalHash = row.ChaveNaturalHash__c;
        }
        return view;
    }

    public static List<CategorizacaoDTO.PicklistOption> toPicklistOptions(List<Schema.PicklistEntry> entries) {
        List<CategorizacaoDTO.PicklistOption> out = new List<CategorizacaoDTO.PicklistOption>();
        for (Schema.PicklistEntry e : entries) {
            if (!e.isActive()) continue;
            CategorizacaoDTO.PicklistOption p = new CategorizacaoDTO.PicklistOption();
            p.value = e.getValue();
            p.label = e.getLabel();
            out.add(p);
        }
        return out;
    }
}