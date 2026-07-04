import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';

import getContext from '@salesforce/apex/CaseRecategorizationController.getContext';
import getTreeOptions from '@salesforce/apex/CaseRecategorizationController.getTreeOptions';
import recategorize from '@salesforce/apex/CaseRecategorizationController.recategorize';
import resolveCategorizationSelection from '@salesforce/apex/CaseCreationController.resolveCategorizationSelection';
import getAvailableQueues from '@salesforce/apex/CaseCreationController.getAvailableQueues';

import titleLabel from '@salesforce/label/c.CaseRecategorization_Title';
import caseInfoLabel from '@salesforce/label/c.CaseRecategorization_CaseInfo';
import currentCatLabel from '@salesforce/label/c.CaseRecategorization_CurrentCat';
import newCatLabel from '@salesforce/label/c.CaseRecategorization_NewCat';
import summaryLabel from '@salesforce/label/c.CaseRecategorization_Summary';
import destinationTitleLabel from '@salesforce/label/c.CaseRecategorization_DestinationTitle';
import destinationLabel from '@salesforce/label/c.CaseRecategorization_Destination';
import assumeLabel from '@salesforce/label/c.CaseRecategorization_Assume';
import distributeLabel from '@salesforce/label/c.CaseRecategorization_Distribute';
import closeLabel from '@salesforce/label/c.CaseRecategorization_Close';
import queueResolvedLabel from '@salesforce/label/c.CaseRecategorization_QueueResolved';
import manualQueueLabel from '@salesforce/label/c.CaseRecategorization_ManualQueue';
import caseNumberLabel from '@salesforce/label/c.CaseRecategorization_CaseNumber';
import statusLabel from '@salesforce/label/c.CaseRecategorization_Status';
import unidadeLabel from '@salesforce/label/c.CaseRecategorization_Unidade';
import recordTypeLabel from '@salesforce/label/c.CaseRecategorization_RecordType';
import currentTipoLabel from '@salesforce/label/c.CaseRecategorization_CurrentTipo';
import currentCategoriaLabel from '@salesforce/label/c.CaseRecategorization_CurrentCategoria';
import currentAssuntoLabel from '@salesforce/label/c.CaseRecategorization_CurrentAssunto';
import currentSubassuntoLabel from '@salesforce/label/c.CaseRecategorization_CurrentSubassunto';
import newTipoLabel from '@salesforce/label/c.CaseRecategorization_NewTipo';
import newCategoriaLabel from '@salesforce/label/c.CaseRecategorization_NewCategoria';
import newAssuntoLabel from '@salesforce/label/c.CaseRecategorization_NewAssunto';
import newSubassuntoLabel from '@salesforce/label/c.CaseRecategorization_NewSubassunto';
import fromLabel from '@salesforce/label/c.CaseRecategorization_From';
import toLabel from '@salesforce/label/c.CaseRecategorization_To';
import warningLabel from '@salesforce/label/c.CaseRecategorization_Warning';
import cancelLabel from '@salesforce/label/c.CaseRecategorization_Cancel';
import loadingLabel from '@salesforce/label/c.CaseRecategorization_Loading';
import saveLabel from '@salesforce/label/c.CaseRecategorization_Save';
import successTitleLabel from '@salesforce/label/c.CaseRecategorization_SuccessTitle';
import successMsgLabel from '@salesforce/label/c.CaseRecategorization_SuccessMsg';
import errorTitleLabel from '@salesforce/label/c.CaseRecategorization_ErrorTitle';
import noValuesLabel from '@salesforce/label/c.CaseRecategorization_NoValues';

export default class CaseRecategorization extends NavigationMixin(LightningElement) {
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value && !this.context && !this.loading) {
            this.initialize();
        }
    }

    @track loading = true;
    @track context;
    @track tipoOptions = [];
    @track categoriaOptions = [];
    @track assuntoOptions = [];
    @track subassuntoOptions = [];
    @track queueOptions = [];
    @track resolvedQueue;

    @track model = {
        tipoCaso: null,
        categoria: null,
        assunto: null,
        subassunto: null
    };
    @track destinationAction = 'ASSUMIR';
    @track selectedQueueDeveloperName;

    objectInfo;

    labels = {
        title: titleLabel,
        caseInfo: caseInfoLabel,
        currentCat: currentCatLabel,
        newCat: newCatLabel,
        summary: summaryLabel,
        destinationTitle: destinationTitleLabel,
        destination: destinationLabel,
        assume: assumeLabel,
        distribute: distributeLabel,
        close: closeLabel,
        queueResolved: queueResolvedLabel,
        manualQueue: manualQueueLabel,
        caseNumber: caseNumberLabel,
        status: statusLabel,
        unidade: unidadeLabel,
        recordType: recordTypeLabel,
        currentTipo: currentTipoLabel,
        currentCategoria: currentCategoriaLabel,
        currentAssunto: currentAssuntoLabel,
        currentSubassunto: currentSubassuntoLabel,
        newTipo: newTipoLabel,
        newCategoria: newCategoriaLabel,
        newAssunto: newAssuntoLabel,
        newSubassunto: newSubassuntoLabel,
        from: fromLabel,
        to: toLabel,
        warning: warningLabel,
        cancel: cancelLabel,
        loading: loadingLabel,
        save: saveLabel,
        successTitle: successTitleLabel,
        successMsg: successMsgLabel,
        errorTitle: errorTitleLabel,
        noValues: noValuesLabel
    };

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) this.objectInfo = data;
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (this._recordId) {
            return;
        }
        const fallbackRecordId = pageRef?.state?.recordId || pageRef?.attributes?.recordId;
        if (fallbackRecordId) {
            this.recordId = fallbackRecordId;
        }
    }

    connectedCallback() {
        if (this.recordId) {
            this.initialize();
        } else {
            this.loading = false;
        }
    }

    async initialize() {
        if (!this.recordId) {
            return;
        }
        this.loading = true;
        try {
            this.context = await getContext({ caseId: this.recordId });
            this.model.tipoCaso = this.context?.currentTipoCaso;
            this.model.categoria = this.context?.currentCategoria;
            this.model.assunto = this.context?.currentAssunto;
            this.model.subassunto = this.context?.currentSubassunto;
            await this.loadTreeOptions();
            await this.refreshDestinationSection();
        } catch (e) {
            this.toast(this.labels.errorTitle, this.reduceError(e), 'error');
        } finally {
            this.loading = false;
        }
    }

    async loadTreeOptions() {
        const req = {
            caseId: this.recordId,
            recordTypeId: this.context?.recordTypeId,
            recordTypeDeveloperName: this.context?.recordTypeDeveloperName,
            unidadeNegocio: this.context?.unidadeNegocio,
            selectedTipoCaso: this.model.tipoCaso,
            selectedCategoria: this.model.categoria,
            selectedAssunto: this.model.assunto,
            selectedSubassunto: this.model.subassunto
        };

        const out = await getTreeOptions({ request: req });
        this.tipoOptions = this.mapOptions(out?.tipoCasoOptions);
        this.categoriaOptions = this.mapOptions(out?.categoriaOptions);
        this.assuntoOptions = this.mapOptions(out?.assuntoOptions);
        this.subassuntoOptions = this.mapOptions(out?.subassuntoOptions);
    }

    mapOptions(options) {
        const out = (options || []).map((o) => ({ label: o.label, value: o.value }));
        if (out.length === 0) {
            return [{ label: this.labels.noValues, value: '__NONE__' }];
        }
        return out;
    }

    async handleFieldChange(event) {
        const field = event.target.name;
        const value = event.detail.value === '__NONE__' ? null : event.detail.value;
        this.model[field] = value;

        if (field === 'tipoCaso') {
            this.model.categoria = null;
            this.model.assunto = null;
            this.model.subassunto = null;
        } else if (field === 'categoria') {
            this.model.assunto = null;
            this.model.subassunto = null;
        } else if (field === 'assunto') {
            this.model.subassunto = null;
        }

        await this.loadTreeOptions();
        await this.refreshDestinationSection();
    }

    get destinationCards() {
        return [
            { value: 'ASSUMIR', label: this.labels.assume, checked: this.destinationAction === 'ASSUMIR' },
            { value: 'DISTRIBUIR', label: this.labels.distribute, checked: this.destinationAction === 'DISTRIBUIR' },
            { value: 'ENCERRAR', label: this.labels.close, checked: this.destinationAction === 'ENCERRAR' }
        ];
    }

    get showDestinationSection() {
        return !this.context?.currentCategoria;
    }

    async handleDestinationCardSelect(event) {
        const selected = event.currentTarget?.dataset?.value;
        if (!selected || selected === this.destinationAction) return;
        this.destinationAction = selected;
        await this.refreshDestinationSection();
    }

    async refreshDestinationSection() {
        this.selectedQueueDeveloperName = null;
        this.queueOptions = [];
        this.resolvedQueue = null;

        if (!this.showDestinationSection || this.destinationAction !== 'DISTRIBUIR' || !this.context) {
            return;
        }

        const categorization = {
            recordTypeId: this.context.recordTypeId,
            recordTypeDeveloperName: this.context.recordTypeDeveloperName,
            unidadeNegocio: this.context.unidadeNegocio,
            tipoCaso: this.model.tipoCaso,
            categoria: this.model.categoria,
            assunto: this.model.assunto,
            subassunto: this.model.subassunto
        };
        const resolved = await resolveCategorizationSelection({ request: categorization });
        this.resolvedQueue = resolved?.queue;
        if (!resolved?.hasParametrizedQueue) {
            const queues = await getAvailableQueues({
                recordTypeDeveloperName: this.context.recordTypeDeveloperName,
                unidadeNegocio: this.context.unidadeNegocio
            });
            this.queueOptions = (queues || []).map((q) => ({ label: `${q.name} (${q.developerName})`, value: q.developerName }));
        }
    }

    handleQueueChange(event) {
        this.selectedQueueDeveloperName = event.detail.value;
    }

    get showQueueSelector() {
        return this.showDestinationSection && this.destinationAction === 'DISTRIBUIR' && !this.resolvedQueue;
    }

    get disableTipo() {
        return this.tipoOptions.length === 0 || (this.tipoOptions.length === 1 && this.tipoOptions[0].value === '__NONE__');
    }

    get disableCategoria() {
        return !this.model.tipoCaso || this.categoriaOptions.length === 0 || (this.categoriaOptions.length === 1 && this.categoriaOptions[0].value === '__NONE__');
    }

    get disableAssunto() {
        return !this.model.categoria || this.assuntoOptions.length === 0 || (this.assuntoOptions.length === 1 && this.assuntoOptions[0].value === '__NONE__');
    }

    get disableSubassunto() {
        return !this.model.assunto || this.subassuntoOptions.length === 0 || (this.subassuntoOptions.length === 1 && this.subassuntoOptions[0].value === '__NONE__');
    }

    get fieldLabels() {
        const fields = this.objectInfo?.fields || {};
        return {
            tipo: fields.TipoCaso__c?.label || this.labels.newTipo,
            categoria: fields.Categoria__c?.label || this.labels.newCategoria,
            assunto: fields.Assunto__c?.label || this.labels.newAssunto,
            subassunto: fields.Subassunto__c?.label || this.labels.newSubassunto,
            unidade: fields.UnidadeNegocio__c?.label || this.labels.unidade
        };
    }

    get canSubmit() {
        if (!this.model.tipoCaso || !this.model.categoria) return false;
        if (this.showDestinationSection && this.destinationAction === 'DISTRIBUIR' && !this.resolvedQueue && !this.selectedQueueDeveloperName) {
            return false;
        }
        return true;
    }

    get hasContext() {
        return !!this.context;
    }

    get readOnlyRecordTypeLabel() {
        return this.context?.recordTypeLabel || this.context?.recordTypeDeveloperName;
    }

    get readOnlySubassuntoAtual() {
        return this.context?.currentSubassuntoLabel || this.context?.currentSubassunto || '-';
    }

    get readOnlySubassuntoNovo() {
        return this.findLabel(this.subassuntoOptions, this.model.subassunto) || '-';
    }

    get currentTipoCasoDisplay() {
        return this.context?.currentTipoCasoLabel || this.context?.currentTipoCaso;
    }

    get currentCategoriaDisplay() {
        return this.context?.currentCategoriaLabel || this.context?.currentCategoria;
    }

    get currentAssuntoDisplay() {
        return this.context?.currentAssuntoLabel || this.context?.currentAssunto;
    }

    findLabel(options, value) {
        if (!value) return null;
        const found = (options || []).find((item) => item.value === value);
        return found ? found.label : value;
    }

    get newTipoCasoDisplay() {
        return this.findLabel(this.tipoOptions, this.model.tipoCaso) || '-';
    }

    get newCategoriaDisplay() {
        return this.findLabel(this.categoriaOptions, this.model.categoria) || '-';
    }

    get newAssuntoDisplay() {
        return this.findLabel(this.assuntoOptions, this.model.assunto) || '-';
    }

    cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async submitRecategorization() {
        this.loading = true;
        try {
            const response = await recategorize({
                request: {
                    caseId: this.recordId,
                    tipoCaso: this.model.tipoCaso,
                    categoria: this.model.categoria,
                    assunto: this.model.assunto,
                    subassunto: this.model.subassunto,
                    destinationAction: this.showDestinationSection ? this.destinationAction : null,
                    selectedQueueDeveloperName: this.showDestinationSection ? this.selectedQueueDeveloperName : null
                }
            });

            if (!response?.success) {
                this.toast(this.labels.errorTitle, response?.message || this.labels.errorTitle, 'error');
                return;
            }

            this.toast(this.labels.successTitle, this.labels.successMsg, 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Case',
                    actionName: 'edit'
                }
            });
            this.dispatchEvent(new CloseActionScreenEvent());
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
        return error?.body?.message || error?.message || this.labels.errorTitle;
    }
}