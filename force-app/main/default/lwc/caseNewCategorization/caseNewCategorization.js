import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { encodeDefaultFieldValues, decodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import LANG from '@salesforce/i18n/lang';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import getInitialContext from '@salesforce/apex/CaseCreationController.getInitialContext';
import getTreeOptions from '@salesforce/apex/CaseCreationController.getTreeOptions';
import resolveCategorizationSelection from '@salesforce/apex/CaseCreationController.resolveCategorizationSelection';
import getAvailableQueues from '@salesforce/apex/CaseCreationController.getAvailableQueues';
import buildDefaultValues from '@salesforce/apex/CaseCreationController.buildDefaultValues';

export default class CaseNewCategorization extends NavigationMixin(LightningElement) {
    @track loading = true;
    @track context;
    @track recordTypeOptions = [];
    @track tipoOptions = [];
    @track categoriaOptions = [];
    @track assuntoOptions = [];
    @track subassuntoOptions = [];
    @track queueOptions = [];
    @track resolvedQueue;
    @track destinationAction = 'ASSUMIR';
    @track destinationManuallySet = false;
    @track selectedQueueDeveloperName;
    @track objectInfo;
    @track customFieldApiName;
    @track customFieldLabel;
    @track customFieldOptions = [];
    @track customFieldValue;
    @track hasParametrizedQueue = false;
    @track permiteAssumir = true;

    language = (LANG || '').toLowerCase();

    labels = this.language.startsWith('en')
        ? {
              cardTitle: 'New Case',
              subtitle: 'Select the initial categorization to load the standard Case form.',
              ctxTitle: '1. Case Context',
              categorizationTitle: '2. Initial Categorization',
              destinationTitle: '3. Case Destination',
              unidadeRecordType: 'Business Unit / Record Type',
              unidadeNegocio: 'Business Unit',
              tipoCaso: 'Case Type',
              categoria: 'Category',
              assunto: 'Subject',
              subassunto: 'Subsubject',
              destino: 'Destination',
              destinationHintAssume: 'The current user will be the owner.',
              destinationHintDistribute: 'Uses configured queue or manual selection.',
              destinationHintClose: 'Closes the case and keeps owner as current user.',
              queueResolved: 'Queue defined by categorization',
              manualQueue: 'Manual queue',
              cancel: 'Cancel',
              continueCase: 'Continue to Case creation',
              assume: 'Assume case',
              distribute: 'Distribute to queue',
              close: 'Close on creation',
              assumirBloqueadoHint: 'This categorization requires distribution to the configured queue; assuming the case directly is not allowed.',
              errorTitle: 'Error',
              unexpected: 'Unexpected error',
              prepareFailed: 'Failed to prepare Case creation.'
          }
        : {
              cardTitle: 'Novo Caso',
              subtitle: 'Selecione a categorização inicial para carregar o formulário padrão do Case.',
              ctxTitle: '1. Contexto do Caso',
              categorizationTitle: '2. Categorização Inicial',
              destinationTitle: '3. Destino do Caso',
              unidadeRecordType: 'Unidade / Record Type',
              unidadeNegocio: 'Unidade de Negócio',
              tipoCaso: 'Tipo de Caso',
              categoria: 'Categoria',
              assunto: 'Assunto',
              subassunto: 'Subassunto',
              destino: 'Destino',
              destinationHintAssume: 'O usuário atual será proprietário.',
              destinationHintDistribute: 'Usa fila parametrizada ou seleção manual.',
              destinationHintClose: 'Fecha o caso e mantém owner como usuário atual.',
              queueResolved: 'Fila definida pela categorização',
              manualQueue: 'Fila manual',
              cancel: 'Cancelar',
              continueCase: 'Continuar para criação do Case',
              assume: 'Assumir o caso',
              distribute: 'Distribuir para fila',
              close: 'Encerrar na criação',
              assumirBloqueadoHint: 'Esta categorização exige distribuição para a fila configurada; não é permitido assumir o caso diretamente.',
              errorTitle: 'Erro',
              unexpected: 'Erro inesperado',
              prepareFailed: 'Falha ao preparar criação do Case.'
          };

    originalDefaults = {};

    model = {
        recordTypeId: null,
        recordTypeDeveloperName: null,
        unidadeNegocio: null,
        tipoCaso: null,
        categoria: null,
        assunto: null,
        subassunto: null
    };

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) this.objectInfo = data;
    }

    @wire(CurrentPageReference)
    parsePageRef(pageRef) {
        const df = pageRef?.state?.defaultFieldValues;
        this.originalDefaults = df ? decodeDefaultFieldValues(df) : {};
    }

    connectedCallback() {
        this.init();
    }

    get destinationOptions() {
        return [
            { label: this.labels.assume, value: 'ASSUMIR' },
            { label: this.labels.distribute, value: 'DISTRIBUIR' },
            { label: this.labels.close, value: 'ENCERRAR' }
        ];
    }

    get assumirBloqueado() {
        return this.hasParametrizedQueue && !this.permiteAssumir;
    }

    get destinationCards() {
        const assumirBloqueado = this.assumirBloqueado;
        return [
            {
                value: 'ASSUMIR',
                label: this.labels.assume,
                description: this.labels.destinationHintAssume,
                checked: this.destinationAction === 'ASSUMIR',
                disabled: assumirBloqueado,
                cssClass: this.cardCssClass(this.destinationAction === 'ASSUMIR', assumirBloqueado),
                radioGlyph: this.destinationAction === 'ASSUMIR' ? '◉' : '◯'
            },
            {
                value: 'DISTRIBUIR',
                label: this.labels.distribute,
                description: this.labels.destinationHintDistribute,
                checked: this.destinationAction === 'DISTRIBUIR',
                disabled: false,
                cssClass: this.cardCssClass(this.destinationAction === 'DISTRIBUIR', false),
                radioGlyph: this.destinationAction === 'DISTRIBUIR' ? '◉' : '◯'
            },
            {
                value: 'ENCERRAR',
                label: this.labels.close,
                description: this.labels.destinationHintClose,
                checked: this.destinationAction === 'ENCERRAR',
                disabled: false,
                cssClass: this.cardCssClass(this.destinationAction === 'ENCERRAR', false),
                radioGlyph: this.destinationAction === 'ENCERRAR' ? '◉' : '◯'
            }
        ];
    }

    cardCssClass(checked, disabled) {
        let cssClass = 'destination-card';
        if (checked) cssClass += ' destination-card_selected';
        if (disabled) cssClass += ' destination-card_disabled';
        return cssClass;
    }

    get showCustomField() {
        return !!this.customFieldApiName;
    }

    async init() {
        this.loading = true;
        try {
            this.context = await getInitialContext();
            this.recordTypeOptions = (this.context?.recordTypes || []).map((r) => ({
                label: `${r.unidadeNegocio || r.label} (${r.label})`,
                value: r.recordTypeId,
                devName: r.developerName,
                unidade: r.unidadeNegocio
            }));

            if (this.recordTypeOptions.length === 1) {
                this.setRecordType(this.recordTypeOptions[0]);
            } else if (this.context?.defaultRecordTypeId) {
                const d = this.recordTypeOptions.find((o) => o.value === this.context.defaultRecordTypeId);
                if (d) this.setRecordType(d);
            }

            if (this.model.recordTypeId && this.model.unidadeNegocio) {
                await this.loadTreeOptions();
            }
        } catch (e) {
            this.toast(this.labels.errorTitle, this.reduceError(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    setRecordType(option) {
        this.model.recordTypeId = option.value;
        this.model.recordTypeDeveloperName = option.devName;
        this.model.unidadeNegocio = option.unidade;
    }

    async loadTreeOptions() {
        if (!this.model.recordTypeId || !this.model.unidadeNegocio) {
            this.tipoOptions = [];
            this.categoriaOptions = [];
            this.assuntoOptions = [];
            this.subassuntoOptions = [];
            return;
        }
        const res = await getTreeOptions({ request: this.model });
        this.tipoOptions = (res?.tipoCasoOptions || []).map((i) => ({ label: i.label, value: i.value }));
        this.categoriaOptions = (res?.categoriaOptions || []).map((i) => ({ label: i.label, value: i.value }));
        this.assuntoOptions = (res?.assuntoOptions || []).map((i) => ({ label: i.label, value: i.value }));
        this.subassuntoOptions = (res?.subassuntoOptions || []).map((i) => ({ label: i.label, value: i.value }));
    }

    handleRecordTypeChange(event) {
        const selected = this.recordTypeOptions.find((o) => o.value === event.detail.value);
        this.setRecordType(selected);
        this.model.tipoCaso = null;
        this.model.categoria = null;
        this.model.assunto = null;
        this.model.subassunto = null;
        this.destinationAction = 'ASSUMIR';
        this.destinationManuallySet = false;
        this.resetCustomField();
        this.loadTreeOptions();
    }

    resetCustomField() {
        this.customFieldApiName = null;
        this.customFieldLabel = null;
        this.customFieldOptions = [];
        this.customFieldValue = null;
    }

    handleFieldChange(event) {
        this.handleFieldChangeAsync(event);
    }

    async handleFieldChangeAsync(event) {
        const f = event.target.name;
        this.model[f] = event.detail.value;

        if (f === 'tipoCaso') {
            this.model.categoria = null;
            this.model.assunto = null;
            this.model.subassunto = null;
        }
        if (f === 'categoria') {
            this.model.assunto = null;
            this.model.subassunto = null;
        }
        if (f === 'assunto') {
            this.model.subassunto = null;
        }
        await this.loadTreeOptions();
        await this.refreshDestinationSection();
    }

    async handleDestinationChange(event) {
        this.destinationManuallySet = true;
        this.destinationAction = event.detail.value;
        await this.refreshDestinationSection();
    }

    async handleDestinationCardSelect(event) {
        const selected = event.currentTarget?.dataset?.value;
        if (!selected || selected === this.destinationAction) return;
        if (selected === 'ASSUMIR' && this.assumirBloqueado) return;
        this.destinationManuallySet = true;
        this.destinationAction = selected;
        await this.refreshDestinationSection();
    }

    async refreshDestinationSection() {
        this.selectedQueueDeveloperName = null;
        this.queueOptions = [];
        this.resolvedQueue = null;

        // Resolve a categorização sempre que a árvore estiver completa, independente do destino
        // atual — só assim é possível sugerir "Distribuir para fila" automaticamente quando a
        // Categorização já está parametrizada para isso (sem exigir que o usuário lembre de mudar
        // o destino manualmente, que por padrão é "Assumir o caso").
        if (!this.model.tipoCaso || !this.model.categoria || !this.model.assunto) {
            this.resetCustomField();
            this.hasParametrizedQueue = false;
            this.permiteAssumir = true;
            return;
        }

        let resolved;
        try {
            resolved = await resolveCategorizationSelection({ request: { ...this.model, customFieldValue: this.customFieldValue } });
        } catch (e) {
            return;
        }

        if (resolved?.usaCampoCustomizado) {
            this.customFieldApiName = resolved.campoDistribuicao;
            this.customFieldLabel = resolved.campoDistribuicaoLabel;
            this.customFieldOptions = (resolved.campoDistribuicaoOptions || []).map((o) => ({ label: o.label, value: o.value }));

            if (this.customFieldValue == null) {
                // Pré-preenche com o valor configurado na Categorização e refaz a resolução
                // server-side para já refletir se essa sugestão atende ao critério.
                this.customFieldValue = resolved.valorDistribuicao;
                await this.refreshDestinationSection();
                return;
            }
        } else {
            this.resetCustomField();
        }

        this.hasParametrizedQueue = !!resolved?.hasParametrizedQueue;
        this.permiteAssumir = resolved?.permiteAssumirComFilaParametrizada !== false;

        if (this.hasParametrizedQueue && !this.permiteAssumir) {
            // Categorização não permite assumir diretamente quando há fila parametrizada
            // (fixa, por campo customizado batendo o critério, ou fallback) — trava o destino
            // mesmo que o usuário já tivesse escolhido manualmente outro antes.
            this.destinationAction = 'DISTRIBUIR';
        } else if (this.hasParametrizedQueue && !this.destinationManuallySet) {
            this.destinationAction = 'DISTRIBUIR';
        }

        if (this.destinationAction === 'DISTRIBUIR') {
            this.resolvedQueue = resolved?.queue;
            if (!resolved?.hasParametrizedQueue) {
                const queues = await getAvailableQueues({ recordTypeDeveloperName: this.model.recordTypeDeveloperName, unidadeNegocio: this.model.unidadeNegocio });
                this.queueOptions = (queues || []).map((q) => ({ label: `${q.name} (${q.developerName})`, value: q.developerName }));
            }
        }
    }

    async handleCustomFieldChange(event) {
        this.customFieldValue = event.detail.value;
        await this.refreshDestinationSection();
    }

    handleQueueChange(event) {
        this.selectedQueueDeveloperName = event.detail.value;
    }

    get showRecordTypeSelector() {
        return this.recordTypeOptions.length > 1;
    }

    get showQueueSelector() {
        return this.destinationAction === 'DISTRIBUIR' && !this.resolvedQueue;
    }

    get fieldLabels() {
        const fields = this.objectInfo?.fields || {};
        return {
            unidadeNegocio: fields.UnidadeNegocio__c?.label || this.labels.unidadeNegocio,
            tipoCaso: fields.TipoCaso__c?.label || this.labels.tipoCaso,
            categoria: fields.Categoria__c?.label || this.labels.categoria,
            assunto: fields.Assunto__c?.label || this.labels.assunto,
            subassunto: fields.Subassunto__c?.label || this.labels.subassunto
        };
    }

    get disableTipoCaso() {
        return !this.model.recordTypeId || !this.model.unidadeNegocio || this.tipoOptions.length === 0;
    }

    get disableCategoria() {
        return !this.model.tipoCaso || this.categoriaOptions.length === 0;
    }

    get disableAssunto() {
        return !this.model.categoria || this.assuntoOptions.length === 0;
    }

    get disableSubassunto() {
        return !this.model.assunto || this.subassuntoOptions.length === 0;
    }

    findLabel(options, value) {
        const found = (options || []).find((item) => item.value === value);
        return found ? found.label : value;
    }

    get tipoCasoDisplay() {
        return this.findLabel(this.tipoOptions, this.model.tipoCaso);
    }

    get categoriaDisplay() {
        return this.findLabel(this.categoriaOptions, this.model.categoria);
    }

    get assuntoDisplay() {
        return this.findLabel(this.assuntoOptions, this.model.assunto);
    }

    get subassuntoDisplay() {
        return this.findLabel(this.subassuntoOptions, this.model.subassunto);
    }

    get disableContinue() {
        if (!this.model.recordTypeId || !this.model.unidadeNegocio) return true;
        if (this.destinationAction !== 'DISTRIBUIR') return false;
        if (this.resolvedQueue) return false;
        return !this.selectedQueueDeveloperName;
    }

    get requiredTipoCaso() {
        return this.tipoOptions.length > 0;
    }

    get requiredCategoria() {
        return this.categoriaOptions.length > 0;
    }

    get requiredAssunto() {
        return this.assuntoOptions.length > 0;
    }

    get requiredSubassunto() {
        return this.subassuntoOptions.length > 0;
    }

    cancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Case', actionName: 'list' }
        });
    }

    async continueToStandardForm() {
        this.loading = true;
        try {
            const req = {
                categorization: { ...this.model, customFieldValue: this.customFieldValue },
                destination: {
                    action: this.destinationAction,
                    selectedQueueDeveloperName: this.selectedQueueDeveloperName
                },
                originalDefaults: this.originalDefaults,
                sourceContext: {}
            };
            const res = await buildDefaultValues({ request: req });
            if (!res?.success) {
                this.toast(this.labels.errorTitle, res?.error?.message || this.labels.prepareFailed, 'error');
                return;
            }

            const encoded = encodeDefaultFieldValues(res.defaultValues || {});
            const pageRef = {
                type: 'standard__objectPage',
                attributes: { objectApiName: 'Case', actionName: 'new' },
                state: {
                    nooverride: '1',
                    recordTypeId: this.model.recordTypeId,
                    defaultFieldValues: encoded
                }
            };
            const url = await this[NavigationMixin.GenerateUrl](pageRef);
            window.location.assign(url);
        } catch (e) {
            this.toast(this.labels.errorTitle, this.reduceError(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        return error?.body?.message || error?.message || this.labels.unexpected;
    }
}