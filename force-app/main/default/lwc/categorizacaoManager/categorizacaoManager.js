import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LANG from '@salesforce/i18n/lang';
import getInitialState from '@salesforce/apex/CategorizacaoController.getInitialState';
import getQueues from '@salesforce/apex/CategorizacaoController.getQueues';
import save from '@salesforce/apex/CategorizacaoController.save';
import getActiveAtendimentoConfigs from '@salesforce/apex/AtendimentoConfigService.getActiveAtendimentoConfigs';
const MARCO_ATENDIMENTO_N3 = 'Atendimento N3';
const MARCO_ORDER = ['Triagem', 'Resposta Chat', 'Primeira Resposta', 'Atendimento', 'Retorno N3', 'SLA Total'];
const MULTI_PRIORITY_MARCOS = new Set(['Primeira Resposta', 'Atendimento', 'Retorno N3', 'SLA Total']);
const BLOCKED_MARCOS = new Set(['Acompanhamento', MARCO_ATENDIMENTO_N3]);
const TIPO_AREA_INTERNA = 'Área Interna';
const MARCO_DESCRIPTION_PT = {
    Triagem: 'Tempo em que um caso novo é criado e ainda não foi categorizado.',
    'Resposta Chat': 'Tempo em que o chat foi transbordado e ainda não foi atendido pelo Analista de Atendimento.',
    'Primeira Resposta': 'Tempo de fila, onde um caso foi categorizado e distribuído para uma fila, mas que ainda não foi atendido.',
    Atendimento: 'Quando um case é removido da fila e está em atendimento pelo N2.',
    'Atendimento N3': 'Quando está em uma área interna, mas que não é de atendimento.',
    'Retorno N3': 'É o tempo que o analista de atendimento tem para retornar ao cliente com a resposta do N3.',
    'SLA Total': 'É o tempo que todo o case deve ser concluído, ou seja, expectativa da resolução desde o momento que o case foi aberto.'
};
const MARCO_DESCRIPTION_EN = {
    Triagem: 'Time between case creation and categorization.',
    'Resposta Chat': 'Time after chat overflow until an Attendance Analyst starts handling it.',
    'Primeira Resposta': 'Queue time after categorization and distribution, before first handling.',
    Atendimento: 'When a case leaves the queue and is being handled by N2.',
    'Atendimento N3': 'When the case is with an internal area that is not the attendance team.',
    'Retorno N3': 'Time the attendance analyst has to return to the customer with the N3 answer.',
    'SLA Total': 'Total time expected to conclude the case from the moment it was opened.'
};
const MARCO_LABEL_EN = {
    Triagem: 'Triage',
    'Resposta Chat': 'Chat Response',
    'Primeira Resposta': 'First Response',
    Atendimento: 'Handling',
    'Atendimento N3': 'N3 Handling',
    'Retorno N3': 'N3 Return',
    'SLA Total': 'Total SLA'
};
const AREA_LABEL_EN = {
    'Operações': 'Operations',
    Armazenagem: 'Storage',
    'Apoio Aduaneiro': 'Customs Support',
    Liberação: 'Release',
    Faturamento: 'Billing',
    Comercial: 'Sales',
    Financeiro: 'Finance',
    Fiscal: 'Tax',
    Qualidade: 'Quality',
    Jurídico: 'Legal',
    TI: 'IT'
};
const PRIORITY_COLUMNS = [
    { label: 'Alta', value: 'High' },
    { label: 'Normal', value: 'Medium' },
    { label: 'Baixa', value: 'Low' }
];
const SINGLE_PRIORITY_MARCOS = new Set(['Triagem', 'Resposta Chat']);
const PRIORITY_NORMALIZATION = {
    alta: 'High',
    high: 'High',
    media: 'Medium',
    média: 'Medium',
    normal: 'Medium',
    medium: 'Medium',
    baixa: 'Low',
    low: 'Low'
};
const I18N = {
    pt: {
        cardTitle: 'Gestor de Categorização',
        sectionGeneral: 'Informações Gerais',
        sectionDistribution: 'Distribuição',
        sectionSla: 'Regras SLA da Categorização',
        n3Strategy: 'Estratégia da Área Interna',
        n3Unique: 'Tempo único para qualquer área',
        n3ByArea: 'Tempo por área específica',
        n3AppliedAll: 'Aplicado para todas as áreas internas.',
        noMilestones: 'Nenhum marco gerenciável disponível.',
        area: 'Área',
        unidadeNegocio: 'Unidade de Negócio',
        tipoCaso: 'Tipo de Caso',
        categoria: 'Categoria',
        assunto: 'Assunto',
        subassunto: 'Subassunto',
        ativo: 'Ativo',
        descricao: 'Descrição',
        motivoInativacao: 'Motivo de Inativação',
        distribuirFila: 'Distribuir para fila?',
        porCategorizacao: 'Por categorização?',
        filaCase: 'Fila de Case',
        qualCampo: 'Qual campo?',
        valor: 'Valor',
        high: 'Alta',
        normal: 'Normal',
        low: 'Baixa',
        minutes: 'minutos',
        timeMinutes: 'Tempo (minutos)',
        configuredAreas: '{0} áreas configuradas.',
        cancel: 'Cancelar',
        save: 'Salvar',
        error: 'Erro',
        requiredCategory: 'Categoria é obrigatória.',
        requiredInactiveReason: 'Preencha o Motivo de Inativação quando Ativo estiver desmarcado.',
        success: 'Sucesso',
        saved: 'Salvo com sucesso.'
    },
    en: {
        cardTitle: 'Categorization Manager',
        sectionGeneral: 'General Information',
        sectionDistribution: 'Distribution',
        sectionSla: 'Categorization SLA Rules',
        n3Strategy: 'Internal Area Strategy',
        n3Unique: 'Single time for any area',
        n3ByArea: 'Time by specific area',
        n3AppliedAll: 'Applied to all internal areas.',
        noMilestones: 'No manageable milestones available.',
        area: 'Area',
        unidadeNegocio: 'Business Unit',
        tipoCaso: 'Case Type',
        categoria: 'Category',
        assunto: 'Subject',
        subassunto: 'Subsubject',
        ativo: 'Active',
        descricao: 'Description',
        motivoInativacao: 'Inactivation Reason',
        distribuirFila: 'Distribute to queue?',
        porCategorizacao: 'By categorization?',
        filaCase: 'Case Queue',
        qualCampo: 'Which field?',
        valor: 'Value',
        high: 'High',
        normal: 'Normal',
        low: 'Low',
        minutes: 'minutes',
        timeMinutes: 'Time (minutes)',
        configuredAreas: '{0} configured areas.',
        cancel: 'Cancel',
        save: 'Save',
        error: 'Error',
        requiredCategory: 'Category is required.',
        requiredInactiveReason: 'Fill in Inactivation Reason when Active is unchecked.',
        success: 'Success',
        saved: 'Saved successfully.'
    }
};

export default class CategorizacaoManagerV2 extends NavigationMixin(LightningElement) {
    @api recordId;
    @track model = {};
    @track state = {};
    @track queueOptionsData = [];
    _rtUnidadeMap = {};
    @track n3Mode = 'UNICO';
    @track n3UniqueByPriority = {};
    @track n3AreaRows = [];
    loading = false;
    initialRecordTypeId;
    language = (LANG || '').toLowerCase();

    @wire(CurrentPageReference)
    parsePageRef(pageRef) {
        this.initialRecordTypeId = pageRef?.state?.recordTypeId || null;
    }

    @wire(getActiveAtendimentoConfigs)
    wiredAtendimentoConfigs({ data }) {
        if (data) {
            const map = {};
            data.forEach(cfg => {
                if (cfg.caseRecordTypeDeveloperName && cfg.businessUnit) {
                    map[cfg.caseRecordTypeDeveloperName] = cfg.businessUnit;
                }
            });
            this._rtUnidadeMap = map;
        }
    }

    connectedCallback() {
        this.loadState();
    }

    async loadState() {
        this.loading = true;
        try {
            const initialState = await getInitialState({ recordId: this.recordId || null });
            this.state = JSON.parse(JSON.stringify(initialState || {}));
            this.queueOptionsData = [...(this.state.queueOptions || [])];
            this.model = { ...(this.state.registro || {}) };
            this.model.regrasSla = (this.state.regrasSla || []).map((r, idx) => this.normalizeRegraFromServer(r, idx));
            this.initializeN3FromRules();
            if (this.model.ativo === undefined || this.model.ativo === null) {
                this.model.ativo = true;
            }
            if (!this.recordId && this.initialRecordTypeId && !this.model.recordTypeId) {
                this.model.recordTypeId = this.initialRecordTypeId;
                const selected = (this.state.availableRecordTypes || []).find((r) => r.recordTypeId === this.model.recordTypeId);
                this.model.recordTypeDeveloperName = selected?.developerName;
                this.model.unidadeNegocio = this._rtUnidadeMap[selected?.developerName] || this.model.unidadeNegocio;
                this.queueOptionsData = await getQueues({ unidadeNegocio: this.model.unidadeNegocio });
            }
        } catch (e) {
            this.toast('Erro', this.reduceError(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    get isEditMode() { return !!this.recordId; }
    get localeKey() { return this.language.startsWith('en') ? 'en' : 'pt'; }
    t(key) { return I18N[this.localeKey][key] || key; }
    format(key, value) { return this.t(key).replace('{0}', value); }
    get cardTitle() { return this.t('cardTitle'); }
    get sectionGeneral() { return this.t('sectionGeneral'); }
    get sectionDistribution() { return this.t('sectionDistribution'); }
    get sectionSla() { return this.t('sectionSla'); }
    get cancelLabel() { return this.t('cancel'); }
    get saveLabel() { return this.t('save'); }
    get timeMinutesLabel() { return this.t('timeMinutes'); }
    get noMilestonesLabel() { return this.t('noMilestones'); }
    get n3StrategyLabel() { return this.t('n3Strategy'); }
    get n3AppliedAllLabel() { return this.t('n3AppliedAll'); }
    get n3AreaHeaderLabel() { return this.t('area'); }
    get n3HighMinutesLabel() { return `${this.t('high')} (${this.t('minutes')})`; }
    get n3NormalMinutesLabel() { return `${this.t('normal')} (${this.t('minutes')})`; }
    get n3LowMinutesLabel() { return `${this.t('low')} (${this.t('minutes')})`; }
    get n3HighLabel() { return this.t('high'); }
    get n3NormalLabel() { return this.t('normal'); }
    get n3LowLabel() { return this.t('low'); }
    get unidadeNegocioLabel() { return this.t('unidadeNegocio'); }
    get tipoCasoLabel() { return this.t('tipoCaso'); }
    get categoriaLabel() { return this.t('categoria'); }
    get assuntoLabel() { return this.t('assunto'); }
    get subassuntoLabel() { return this.t('subassunto'); }
    get ativoLabel() { return this.t('ativo'); }
    get descricaoLabel() { return this.t('descricao'); }
    get motivoInativacaoLabel() { return this.t('motivoInativacao'); }
    get distribuirFilaLabel() { return this.t('distribuirFila'); }
    get porCategorizacaoLabel() { return this.t('porCategorizacao'); }
    get filaCaseLabel() { return this.t('filaCase'); }
    get qualCampoLabel() { return this.t('qualCampo'); }
    get valorLabel() { return this.t('valor'); }
    get showMotivoInativacao() { return this.model.ativo === false; }
    get showDistribuicao() { return this.model.distribuirParaFila === true; }
    get showCampoValor() { return this.showDistribuicao && this.model.porCategorizacao !== true; }
    get unidadeOptions() {
        const opts = [];
        const seen = new Set();
        (this.state.availableRecordTypes || []).forEach((rt) => {
            const unidade = this._rtUnidadeMap[rt.developerName];
            if (unidade && !seen.has(unidade)) {
                seen.add(unidade);
                opts.push({ label: unidade, value: unidade });
            }
        });
        return opts;
    }
    get tipoCasoOptions() { return (this.state.tipoCasoOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get categoriaOptions() { return (this.state.categoriaOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get assuntoOptions() { return (this.state.assuntoOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get subassuntoOptions() { return (this.state.subassuntoOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get prioridadeOptions() { return (this.state.prioridadeOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get regraMarcoOptions() { return (this.state.regraMarcoOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get regraTipoAreaOptions() { return (this.state.regraTipoAreaOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get regraAreaAtendimentoOptions() { return (this.state.regraAreaAtendimentoOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get regraOrigemOptions() { return (this.state.regraOrigemOptions || []).map((o) => ({ label: o.label, value: o.value })); }
    get prioridadeLabel() {
        return this.language.startsWith('en') ? 'Suggested Prioritization' : 'Priorização Sugerida';
    }
    get queueOptions() { return (this.queueOptionsData || []).map((q) => ({ label: `${q.name} (${q.developerName})`, value: q.developerName })); }
    get casePicklistFieldOptions() { return (this.state.casePicklistFields || []).map((f) => ({ label: f.label, value: f.apiName })); }

    get casePicklistValueOptions() {
        const f = (this.state.casePicklistFields || []).find((x) => x.apiName === this.model.campoDistribuicao);
        return (f?.values || []).map((v) => ({ label: v.label, value: v.value }));
    }

    get regrasSlaRows() {
        const existing = (this.model?.regrasSla || []).filter((r) => r?.markedForDelete !== true);
        const marcoOptions = (this.state?.regraMarcoOptions || [])
            .map((o) => o.value)
            .filter((m) => !this.isBlockedMarco(m));
        const baseMarcos = MARCO_ORDER.filter((m) => marcoOptions.includes(m));
        const extraMarcos = [...new Set(
            existing
                .map((r) => r.marco)
                .filter((m) => !!m && !this.isBlockedMarco(m) && !baseMarcos.includes(m))
        )];
        const orderedMarcos = [...baseMarcos, ...extraMarcos];
        return orderedMarcos.map((marco) => {
            const isMulti = MULTI_PRIORITY_MARCOS.has(marco);
            if (!isMulti) {
                const regra = this.findRegra(marco, null);
                return {
                    key: `m-${marco}`,
                    marco,
                    marcoLabel: this.getMarcoLabel(marco),
                    description: (this.localeKey === 'en' ? MARCO_DESCRIPTION_EN : MARCO_DESCRIPTION_PT)[marco] || null,
                    isMulti: false,
                    singleTempo: regra?.tempoMinutos ?? null
                };
            }
            return {
                key: `m-${marco}`,
                marco,
                marcoLabel: this.getMarcoLabel(marco),
                description: (this.localeKey === 'en' ? MARCO_DESCRIPTION_EN : MARCO_DESCRIPTION_PT)[marco] || null,
                isMulti: true,
                cells: PRIORITY_COLUMNS.map((col) => {
                    const regra = this.findRegra(marco, col.value);
                    const label = col.value === 'High' ? this.t('high') : col.value === 'Medium' ? this.t('normal') : this.t('low');
                    return {
                        key: `m-${marco}-p-${col.value}`,
                        label,
                        labelWithUnit: `${label} (${this.t('minutes')})`,
                        priority: col.value,
                        tempo: regra?.tempoMinutos ?? null
                    };
                })
            };
        });
    }

    get n3ModeOptions() {
        return [
            { label: this.t('n3Unique'), value: 'UNICO' },
            { label: this.t('n3ByArea'), value: 'POR_AREA' }
        ];
    }

    get atendimentoN3Description() {
        return (this.localeKey === 'en' ? MARCO_DESCRIPTION_EN : MARCO_DESCRIPTION_PT)[MARCO_ATENDIMENTO_N3];
    }
    get atendimentoN3Label() {
        return this.getMarcoLabel(MARCO_ATENDIMENTO_N3);
    }

    get showN3Unique() {
        return this.n3Mode === 'UNICO';
    }

    get showN3ByArea() {
        return this.n3Mode === 'POR_AREA';
    }

    get n3AreaConfiguredCount() {
        const count = (this.n3AreaRows || []).filter((row) =>
            this.hasPositive(row.high) || this.hasPositive(row.medium) || this.hasPositive(row.low)
        ).length;
        return this.format('configuredAreas', count);
    }

    async handleUnidadeChange(event) {
        this.model.unidadeNegocio = event.detail.value;
        const selected = (this.state.availableRecordTypes || []).find((r) => this._rtUnidadeMap[r.developerName] === this.model.unidadeNegocio);
        this.model.recordTypeId = selected?.recordTypeId || this.model.recordTypeId;
        this.model.recordTypeDeveloperName = selected?.developerName || this.model.recordTypeDeveloperName;
        this.queueOptionsData = await getQueues({ unidadeNegocio: this.model.unidadeNegocio });
    }

    handleChange(event) {
        const field = event.target.name || event.target.dataset?.field;
        if (!field) {
            return;
        }
        this.model[field] = event.target.type === 'checkbox' ? event.target.checked : event.detail.value;

        if (field === 'distribuirParaFila' && this.model.distribuirParaFila === false) {
            this.model.porCategorizacao = false;
            this.model.filaDeveloperName = null;
            this.model.campoDistribuicao = null;
            this.model.valorDistribuicao = null;
        }
        if (field === 'porCategorizacao' && this.model.porCategorizacao === true) {
            this.model.campoDistribuicao = null;
            this.model.valorDistribuicao = null;
        }
        if (field === 'campoDistribuicao') this.model.valorDistribuicao = null;
    }

    handleRegraTempoChange(event) {
        const marco = event.target.dataset.marco;
        const prioridade = event.target.dataset.prioridade || null;
        const rawValue = event.detail?.value;
        const value = rawValue === '' || rawValue === null || rawValue === undefined ? null : Number(rawValue);
        this.upsertRegraTempo(marco, prioridade, value);
    }

    handleN3ModeChange(event) {
        this.n3Mode = event.detail.value;
    }

    handleN3UniqueChange(event) {
        const priority = event.target.dataset.priority;
        const rawValue = event.detail?.value;
        const value = rawValue === '' || rawValue === null || rawValue === undefined ? null : Number(rawValue);
        this.n3UniqueByPriority = { ...this.n3UniqueByPriority, [priority]: value };
    }

    handleN3AreaChange(event) {
        const area = event.target.dataset.area;
        const priority = event.target.dataset.priority;
        const rawValue = event.detail?.value;
        const value = rawValue === '' || rawValue === null || rawValue === undefined ? null : Number(rawValue);
        this.n3AreaRows = (this.n3AreaRows || []).map((row) => (row.area === area ? { ...row, [priority]: value } : row));
    }

    findRegra(marco, prioridade) {
        const normalizedPriority = prioridade || '';
        return (this.model?.regrasSla || []).find((r) =>
            r?.markedForDelete !== true &&
            r?.marco === marco &&
            String(r?.prioridade || '') === normalizedPriority
        );
    }

    upsertRegraTempo(marco, prioridade, tempoMinutos) {
        if (!marco) return;
        if (!this.model.regrasSla) this.model.regrasSla = [];
        const normalizedPriority = prioridade || '';
        const idx = this.model.regrasSla.findIndex((r) =>
            r?.marco === marco &&
            String(r?.prioridade || '') === normalizedPriority &&
            r?.markedForDelete !== true
        );

        if (idx >= 0) {
            this.model.regrasSla = this.model.regrasSla.map((r, i) => (i === idx ? { ...r, tempoMinutos } : r));
            return;
        }

        this.model.regrasSla = [
            ...this.model.regrasSla,
            {
                clientKey: `new-${marco}-${normalizedPriority || 'none'}-${Date.now()}`,
                marco,
                tipoAreaParticipante: '',
                areaAtendimento: '',
                prioridade: normalizedPriority || null,
                origem: 'Qualquer',
                tempoMinutos,
                businessHoursName: this._rtUnidadeMap[this.model.recordTypeDeveloperName] || '',
                ativo: true,
                markedForDelete: false
            }
        ];
    }

    buildRegrasSlaPayload() {
        const baseRules = (this.model.regrasSla || [])
            .filter((r) => !this.isAtendimentoN3Marco(r.marco))
            .filter((r) => {
                if (r.markedForDelete === true) return true;
                if (r.tempoMinutos === null || r.tempoMinutos === undefined || Number(r.tempoMinutos) <= 0) return false;
                if (MULTI_PRIORITY_MARCOS.has(r.marco)) return !!r.prioridade;
                if (SINGLE_PRIORITY_MARCOS.has(r.marco)) return !r.prioridade;
                return true;
            })
            .map((r) => ({
                id: r.id,
                marco: r.marco,
                tipoAreaParticipante: r.tipoAreaParticipante,
                areaAtendimento: r.areaAtendimento,
                prioridade: r.prioridade,
                origem: r.origem,
                tempoMinutos: r.tempoMinutos,
                businessHoursName: r.businessHoursName,
                ativo: r.ativo === true,
                markedForDelete: r.markedForDelete === true
            }));

        const n3Rules = this.buildN3RulesPayload();
        return [...baseRules, ...n3Rules];
    }

    buildN3RulesPayload() {
        const out = [];
        if (this.n3Mode === 'UNICO') {
            const allAreas = (this.n3AreaRows || [])
                .map((row) => row.area)
                .filter((area) => !!String(area || '').trim());
            PRIORITY_COLUMNS.forEach((col) => {
                const tempo = this.n3UniqueByPriority[col.value];
                if (!this.hasPositive(tempo)) return;
                allAreas.forEach((area) => {
                    out.push(this.createN3Rule(col.value, tempo, area));
                });
            });
            return out;
        }

        (this.n3AreaRows || []).forEach((row) => {
            if (!row?.area) return;
            PRIORITY_COLUMNS.forEach((col) => {
                const key = col.value === 'High' ? 'high' : col.value === 'Medium' ? 'medium' : 'low';
                const tempo = row[key];
                if (!this.hasPositive(tempo)) return;
                out.push(this.createN3Rule(col.value, tempo, row.area));
            });
        });
        return out;
    }

    createN3Rule(priority, tempoMinutos, areaAtendimento) {
        return {
            marco: MARCO_ATENDIMENTO_N3,
            tipoAreaParticipante: TIPO_AREA_INTERNA,
            areaAtendimento,
            prioridade: priority,
            origem: 'Qualquer',
            tempoMinutos,
            businessHoursName: this._rtUnidadeMap[this.model.recordTypeDeveloperName] || '',
            ativo: true,
            markedForDelete: false
        };
    }

    normalizeRegraFromServer(regra, idx) {
        const rawPriority = String(regra?.prioridade || '').trim();
        const normalizedKey = rawPriority.toLowerCase();
        const normalizedPriority = PRIORITY_NORMALIZATION[normalizedKey] || rawPriority || null;
        return {
            ...regra,
            prioridade: normalizedPriority,
            clientKey: regra?.id || `new-${idx}`
        };
    }

    initializeN3FromRules() {
        const n3Rules = (this.model.regrasSla || []).filter((r) => this.isAtendimentoN3Marco(r.marco) && r.markedForDelete !== true);
        const hasAreaSpecific = n3Rules.some((r) => !!String(r.areaAtendimento || '').trim());
        this.n3Mode = hasAreaSpecific ? 'POR_AREA' : 'UNICO';

        this.n3UniqueByPriority = {};
        PRIORITY_COLUMNS.forEach((col) => {
            const row = n3Rules.find((r) => String(r.prioridade || '') === col.value && !String(r.areaAtendimento || '').trim());
            this.n3UniqueByPriority[col.value] = row?.tempoMinutos ?? null;
        });

        const existingByKey = new Map();
        n3Rules.forEach((r) => {
            if (!r.areaAtendimento) return;
            const key = `${r.areaAtendimento}|${r.prioridade}`;
            existingByKey.set(key, r.tempoMinutos ?? null);
        });
        this.n3AreaRows = (this.state.regraAreaAtendimentoOptions || []).map((opt) => ({
            area: opt.value,
            label: this.getAreaLabel(opt.label || opt.value),
            high: existingByKey.get(`${opt.value}|High`) ?? null,
            medium: existingByKey.get(`${opt.value}|Medium`) ?? null,
            low: existingByKey.get(`${opt.value}|Low`) ?? null
        }));
    }

    hasPositive(value) {
        return value !== null && value !== undefined && Number(value) > 0;
    }

    getMarcoLabel(marco) {
        if (this.localeKey === 'en') return MARCO_LABEL_EN[marco] || marco;
        return marco;
    }

    getAreaLabel(label) {
        if (this.localeKey !== 'en') return label;
        return AREA_LABEL_EN[label] || label;
    }

    normalizeMarco(value) {
        return String(value || '')
            .trim()
            .toLowerCase()
            .replace(/\s+/g, ' ');
    }

    isAtendimentoN3Marco(value) {
        return this.normalizeMarco(value) === this.normalizeMarco(MARCO_ATENDIMENTO_N3);
    }

    isBlockedMarco(value) {
        const normalized = this.normalizeMarco(value);
        for (const blocked of BLOCKED_MARCOS) {
            if (normalized === this.normalizeMarco(blocked)) return true;
        }
        return false;
    }

    async handleSave() {
        if (this.model.ativo === undefined || this.model.ativo === null) {
            this.model.ativo = true;
        }
        if (!String(this.model.categoria || '').trim()) {
            this.toast(this.t('error'), this.t('requiredCategory'), 'error');
            return;
        }
        if (this.model.ativo === false && !String(this.model.motivoInativacao || '').trim()) {
            this.toast(this.t('error'), this.t('requiredInactiveReason'), 'error');
            return;
        }
        this.loading = true;
        try {
            const request = {
                id: this.model.id,
                recordTypeId: this.model.recordTypeId,
                unidadeNegocio: this.model.unidadeNegocio,
                tipoCaso: this.model.tipoCaso,
                categoria: this.model.categoria,
                assunto: this.model.assunto,
                subassunto: this.model.subassunto,
                prioridade: this.model.prioridade,
                ativo: this.model.ativo === true,
                descricao: this.model.descricao,
                motivoInativacao: this.model.motivoInativacao,
                distribuirParaFila: this.model.distribuirParaFila === true,
                porCategorizacao: this.model.porCategorizacao === true,
                filaDeveloperName: this.model.filaDeveloperName,
                campoDistribuicao: this.model.campoDistribuicao,
                valorDistribuicao: this.model.valorDistribuicao,
                regrasSla: this.buildRegrasSlaPayload()
            };
            const res = await save({ request });
            if (res?.success) {
                this.model = { ...(res.registro || this.model) };
                this.toast(this.t('success'), res.message || this.t('saved'), 'success');
                const targetId = this.model.id || res?.registro?.id;
                if (targetId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: targetId,
                            objectApiName: 'Categorizacao__c',
                            actionName: 'view'
                        }
                    });
                }
            } else {
                this.toast(this.t('error'), res?.error?.message || res?.message || 'Falha ao salvar.', 'error');
            }
        } catch (e) {
            this.toast(this.t('error'), this.reduceError(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    handleCancel() {
        if (this.model?.id || this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.model?.id || this.recordId,
                    objectApiName: 'Categorizacao__c',
                    actionName: 'view'
                }
            });
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Categorizacao__c',
                actionName: 'list'
            }
        });
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        return error?.body?.message || error?.message || 'Erro inesperado';
    }
}