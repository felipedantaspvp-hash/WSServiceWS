import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import LANG from '@salesforce/i18n/lang';

import getContext from '@salesforce/apex/CaseRecategorizationController.getContext';
import getTreeOptions from '@salesforce/apex/CaseRecategorizationController.getTreeOptions';
import recategorize from '@salesforce/apex/CaseRecategorizationController.recategorize';
import resolveCategorizationSelection from '@salesforce/apex/CaseCreationController.resolveCategorizationSelection';
import getAvailableQueues from '@salesforce/apex/CaseCreationController.getAvailableQueues';

export default class CaseRecategorizationModal extends NavigationMixin(LightningModal) {
    @api recordId;

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
    language = (LANG || '').toLowerCase();
    isEnglish = ((LANG || '').toLowerCase().replace('_', '-')).startsWith('en');

    labels = this.isEnglish
        ? {
              title: 'Recategorize Case',
              caseInfo: 'Current Case',
              currentCat: 'Current Categorization',
              newCat: 'New Categorization',
              summary: 'Change Summary',
              destinationTitle: 'Case Destination',
              destination: 'Destination',
              assume: 'Assume case',
              distribute: 'Distribute to queue',
              close: 'Close on creation',
              queueResolved: 'Queue defined by categorization',
              manualQueue: 'Manual queue',
              caseNumber: 'Case Number',
              status: 'Status',
              unidade: 'Business Unit',
              recordType: 'Record Type',
              currentTipo: 'Current Case Type',
              currentCategoria: 'Current Category',
              currentAssunto: 'Current Subject',
              currentSubassunto: 'Current Subsubject',
              newTipo: 'Case Type',
              newCategoria: 'Category',
              newAssunto: 'Subject',
              newSubassunto: 'Subsubject',
              from: 'From',
              to: 'To',
              warning: 'After confirming recategorization, the standard Case edit screen will open so you can complete required fields.',
              cancel: 'Cancel',
              save: 'Recategorize',
              successTitle: 'Success',
              successMsg: 'Case recategorized successfully.',
              errorTitle: 'Error',
              noValues: 'No options available'
          }
        : {
              title: 'Recategorizar Caso',
              caseInfo: 'Caso Atual',
              currentCat: 'Categorização Atual',
              newCat: 'Nova Categorização',
              summary: 'Resumo da Alteração',
              destinationTitle: 'Destino do Caso',
              destination: 'Destino',
              assume: 'Assumir o caso',
              distribute: 'Distribuir para fila',
              close: 'Encerrar na criação',
              queueResolved: 'Fila definida pela categorização',
              manualQueue: 'Fila manual',
              caseNumber: 'Número do Caso',
              status: 'Status',
              unidade: 'Unidade de Negócio',
              recordType: 'Record Type',
              currentTipo: 'Tipo de Caso atual',
              currentCategoria: 'Categoria atual',
              currentAssunto: 'Assunto atual',
              currentSubassunto: 'Subassunto atual',
              newTipo: 'Tipo de Caso',
              newCategoria: 'Categoria',
              newAssunto: 'Assunto',
              newSubassunto: 'Subassunto',
              from: 'De',
              to: 'Para',
              warning: 'Após confirmar a recategorização, a tela padrão de edição do Caso será aberta para preenchimento dos campos exigidos pela nova categorização.',
              cancel: 'Cancelar',
              save: 'Recategorizar',
              successTitle: 'Sucesso',
              successMsg: 'Caso recategorizado com sucesso.',
              errorTitle: 'Erro',
              noValues: 'Sem opções disponíveis'
          };

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) this.objectInfo = data;
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
        this.close('cancel');
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
            this.close('recategorized');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Case',
                    actionName: 'edit'
                }
            });
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
