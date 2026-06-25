import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { decodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import LANG from '@salesforce/i18n/lang';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import getInitialContext from '@salesforce/apex/CaseCreationController.getInitialContext';
import getTreeOptions from '@salesforce/apex/CaseCreationController.getTreeOptions';
import resolveCategorizationSelection from '@salesforce/apex/CaseCreationController.resolveCategorizationSelection';
import getAvailableQueues from '@salesforce/apex/CaseCreationController.getAvailableQueues';
import buildDefaultValues from '@salesforce/apex/CaseCreationController.buildDefaultValues';
import contextSectionLabel from '@salesforce/label/c.CaseNewCategorization_ContextSection';
import categorizacaoLabel from '@salesforce/label/c.Categorizacao';
import destinationSectionLabel from '@salesforce/label/c.CaseNewCategorization_DestinationSection';
import informacoesClienteLabel from '@salesforce/label/c.InformacoesCliente';
import additionalInfoSectionLabel from '@salesforce/label/c.CaseNewCategorization_AdditionalInfoSection';
import detalhesLabel from '@salesforce/label/c.Detalhes';
import descriptionSectionLabel from '@salesforce/label/c.CaseNewCategorization_DescriptionSection';

// Replica, por Unidade de Negócio, as seções/campos/regras de visibilidade "preenchíveis na criação"
// da Lightning Page real (Dynamic Forms) daquela unidade — extraído de LP_Atendimento_Salvador em
// 2026-06-25. Os campos que o próprio wizard já resolve (Unidade, Tipo, Categoria, Assunto,
// Subassunto, Owner, Etapa, Origin) ficam de fora de propósito, pois são injetados via
// buildDefaultValues no submit, não preenchidos aqui. Campos somente leitura/auditoria (CreatedDate,
// SuppliedEmail, CreatedById, etc.) também ficam fora — não fazem sentido na criação.
// `visibleWhen`/seção e campo recebem o contexto {tipoCaso, categoria, modalidade} com os valores
// atuais (categoria/tipoCaso vêm do wizard; modalidade vem do próprio campo desta seção, em tempo real).
// Atualizar aqui sempre que a Lightning Page da unidade correspondente mudar. Unidades sem entrada
// aqui caem no fallback de Page Layout puro (lightning-record-form).
const NAO_ELOGIO = (ctx) => ctx.tipoCaso !== 'Elogio';
const CASE_DETAIL_SECTIONS_BY_UNIDADE = {
    'Atendimento Tecon Salvador': [
        {
            title: informacoesClienteLabel,
            rows: [
                [{ field: 'AccountId', required: true }, { field: 'ContactId', required: true }],
                [{ field: 'Representante__c' }, null]
            ]
        },
        {
            title: additionalInfoSectionLabel,
            rows: [
                [{ field: 'Modalidade__c', required: true, visibleWhen: NAO_ELOGIO }, { field: 'Priority' }],
                [{ field: 'AreasParticipantes__c', required: true }, { field: 'Container__c', required: true, visibleWhen: NAO_ELOGIO }]
            ]
        },
        {
            title: detalhesLabel,
            visibleWhen: (ctx) =>
                ctx.tipoCaso === 'Elogio' ||
                (NAO_ELOGIO(ctx) &&
                    (ctx.modalidade === 'Cabotagem Embarque' || ctx.modalidade === 'Exportação' || ctx.categoria === 'Acesso ao Porto')),
            rows: [
                [{ field: 'Colaborador__c', visibleWhen: (ctx) => ctx.tipoCaso === 'Elogio' }, null],
                [
                    { field: 'BL__c', visibleWhen: (ctx) => NAO_ELOGIO(ctx) && ctx.modalidade === 'Importação' },
                    { field: 'Booking__c', visibleWhen: (ctx) => NAO_ELOGIO(ctx) && (ctx.modalidade === 'Cabotagem Embarque' || ctx.modalidade === 'Exportação') }
                ],
                [{ field: 'EvidenciaGatePlaca__c', visibleWhen: (ctx) => NAO_ELOGIO(ctx) && ctx.categoria === 'Acesso ao Porto' }, null]
            ]
        },
        {
            title: descriptionSectionLabel,
            rows: [[{ field: 'Description', required: true }, null]]
        }
    ]
};

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
    @track creating = false;
    @track detailModalidade = null;
    @track recordTypeConfirmed = false;

    language = (LANG || '').toLowerCase();

    bilingualLabels = this.language.startsWith('en')
        ? {
              cardTitle: 'New Case',
              subtitle: 'Select the initial categorization to load the standard Case form.',
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
              assume: 'Assume case',
              distribute: 'Distribute to queue',
              close: 'Close on creation',
              assumirBloqueadoHint: 'This categorization requires distribution to the configured queue; assuming the case directly is not allowed.',
              errorTitle: 'Error',
              unexpected: 'Unexpected error',
              prepareFailed: 'Please complete the categorization above before saving.',
              resolveFailed: 'Failed to resolve Case defaults.',
              save: 'Save',
              continueButton: 'Next',
              successTitle: 'Success',
              successMsg: 'Case created successfully.',
              createFailed: 'Failed to create Case.'
          }
        : {
              cardTitle: 'Novo Caso',
              subtitle: 'Selecione a categorização inicial para carregar o formulário padrão do Case.',
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
              assume: 'Assumir o caso',
              distribute: 'Distribuir para fila',
              close: 'Encerrar na criação',
              assumirBloqueadoHint: 'Esta categorização exige distribuição para a fila configurada; não é permitido assumir o caso diretamente.',
              errorTitle: 'Erro',
              unexpected: 'Erro inesperado',
              prepareFailed: 'Complete a categorização acima antes de salvar.',
              resolveFailed: 'Falha ao resolver os valores padrão do Caso.',
              save: 'Salvar',
              continueButton: 'Avançar',
              successTitle: 'Sucesso',
              successMsg: 'Caso criado com sucesso.',
              createFailed: 'Falha ao criar o Caso.'
          };

    labels = {
        ...this.bilingualLabels,
        ctxTitle: contextSectionLabel,
        categorizationTitle: categorizacaoLabel,
        destinationTitle: destinationSectionLabel,
        caseDetailsTitle: detalhesLabel
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
                this.recordTypeConfirmed = true;
            } else if (this.context?.defaultRecordTypeId) {
                // Múltiplos Record Types disponíveis: pré-seleciona o default só visualmente no
                // card — ainda exige o clique em "Seguir" antes de abrir o restante do wizard.
                const d = this.recordTypeOptions.find((o) => o.value === this.context.defaultRecordTypeId);
                if (d) this.setRecordType(d);
            }

            if (this.model.recordTypeId && this.model.unidadeNegocio && this.recordTypeConfirmed) {
                await this.loadTreeOptions();
            }
        } catch (e) {
            this.toast(this.labels.errorTitle, this.reduceError(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    setRecordType(option) {
        this.model = {
            ...this.model,
            recordTypeId: option.value,
            recordTypeDeveloperName: option.devName,
            unidadeNegocio: option.unidade
        };
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
        this.applyRecordTypeSelection(selected);
    }

    handleRecordTypeCardSelect(event) {
        const value = event.currentTarget?.dataset?.value;
        if (!value || value === this.model.recordTypeId) return;
        const selected = this.recordTypeOptions.find((o) => o.value === value);
        this.applyRecordTypeSelection(selected);
    }

    applyRecordTypeSelection(selected) {
        if (!selected) return;
        this.model = {
            ...this.model,
            recordTypeId: selected.value,
            recordTypeDeveloperName: selected.devName,
            unidadeNegocio: selected.unidade,
            tipoCaso: null,
            categoria: null,
            assunto: null,
            subassunto: null
        };
        this.destinationAction = 'ASSUMIR';
        this.destinationManuallySet = false;
        this.resetCustomField();
    }

    get showRecordTypeGate() {
        return this.recordTypeOptions.length > 1 && !this.recordTypeConfirmed;
    }

    get disableConfirmRecordType() {
        return !this.model.recordTypeId;
    }

    async confirmRecordType() {
        if (!this.model.recordTypeId) return;
        this.loading = true;
        try {
            this.recordTypeConfirmed = true;
            await this.loadTreeOptions();
        } finally {
            this.loading = false;
        }
    }

    get recordTypeCards() {
        return this.recordTypeOptions.map((option) => {
            const checked = this.model.recordTypeId === option.value;
            let cssClass = 'destination-card';
            if (checked) cssClass += ' destination-card_selected';
            return {
                value: option.value,
                label: option.unidade || option.label,
                description: option.unidade ? option.label : null,
                checked,
                cssClass,
                radioGlyph: checked ? '◉' : '◯'
            };
        });
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
        const updates = { [f]: event.detail.value };

        if (f === 'tipoCaso') {
            updates.categoria = null;
            updates.assunto = null;
            updates.subassunto = null;
        }
        if (f === 'categoria') {
            updates.assunto = null;
            updates.subassunto = null;
        }
        if (f === 'assunto') {
            updates.subassunto = null;
        }
        this.model = { ...this.model, ...updates };
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

    get hasRecordType() {
        return !!(this.model.recordTypeId && this.model.unidadeNegocio);
    }

    get detailContext() {
        return {
            tipoCaso: this.model.tipoCaso,
            categoria: this.model.categoria,
            modalidade: this.detailModalidade
        };
    }

    resolveDetailField(fieldConfig, ctx) {
        if (!fieldConfig) return null;
        if (fieldConfig.visibleWhen && !fieldConfig.visibleWhen(ctx)) return null;
        return {
            field: fieldConfig.field,
            required: fieldConfig.required === true
        };
    }

    get caseDetailSections() {
        const sections = CASE_DETAIL_SECTIONS_BY_UNIDADE[this.model.unidadeNegocio];
        if (!sections) return null;
        const ctx = this.detailContext;
        return sections
            .filter((section) => !section.visibleWhen || section.visibleWhen(ctx))
            .map((section, sectionIndex) => ({
                key: `case-detail-section-${sectionIndex}`,
                title: section.title,
                rows: section.rows
                    .map((row, rowIndex) => ({
                        key: `case-detail-row-${sectionIndex}-${rowIndex}`,
                        left: this.resolveDetailField(row[0], ctx),
                        right: this.resolveDetailField(row[1], ctx)
                    }))
                    .filter((row) => row.left || row.right)
            }))
            .filter((section) => section.rows.length > 0);
    }

    get hasCuratedSections() {
        return !!CASE_DETAIL_SECTIONS_BY_UNIDADE[this.model.unidadeNegocio];
    }

    handleDetailFieldChange(event) {
        if (event.target?.fieldName === 'Modalidade__c') {
            this.detailModalidade = event.detail?.value;
        }
    }

    validationError() {
        if (!this.hasRecordType) return this.labels.prepareFailed;
        if (!this.model.tipoCaso || !this.model.categoria) return this.labels.prepareFailed;
        if (this.destinationAction === 'DISTRIBUIR' && !this.resolvedQueue && !this.selectedQueueDeveloperName) {
            return this.labels.prepareFailed;
        }
        return null;
    }

    async handleRecordFormSubmit(event) {
        event.preventDefault();
        const validationMessage = this.validationError();
        if (validationMessage) {
            this.toast(this.labels.errorTitle, validationMessage, 'error');
            return;
        }

        this.creating = true;
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
                this.toast(this.labels.errorTitle, res?.error?.message || this.labels.resolveFailed, 'error');
                this.creating = false;
                return;
            }

            // Os valores resolvidos pelo wizard (campos do Dynamic Forms, fila, status, etc.) entram
            // como base; qualquer valor que o agente realmente preencheu/alterou no formulário (Conta,
            // Contato, Descrição, e quaisquer campos ainda presentes no Page Layout) prevalece por cima,
            // preservando a mesma semântica de "valor padrão, mas editável" que defaultFieldValues tinha.
            const fields = { ...(res.defaultValues || {}), ...event.detail.fields };
            const formEl = this.template.querySelector('lightning-record-edit-form') || this.template.querySelector('lightning-record-form');
            formEl.submit(fields);
        } catch (e) {
            this.creating = false;
            this.toast(this.labels.errorTitle, this.reduceError(e), 'error');
        }
    }

    handleRecordFormSuccess(event) {
        this.creating = false;
        this.toast(this.labels.successTitle, this.labels.successMsg, 'success');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    handleRecordFormError(event) {
        this.creating = false;
        this.toast(this.labels.errorTitle, this.reduceError(event.detail) || this.labels.createFailed, 'error');
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((e) => e.message).join(', ');
        return error?.body?.message || error?.message || this.labels.unexpected;
    }
}