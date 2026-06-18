import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import getClosureContext from '@salesforce/apex/CaseClosureSurveyController.getClosureContext';
import closeCase from '@salesforce/apex/CaseClosureSurveyController.closeCase';

export default class CaseClosureSurvey extends LightningElement {
    _recordId;
    @track context;
    @track loading = true;
    @track model = {
        closureReason: null,
        closureSolution: null,
        closureComment: null,
        selectedSendSurvey: false
    };

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value && !this.context) {
            this.initialize();
        }
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (this._recordId) return;
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
        this.loading = true;
        try {
            this.context = await getClosureContext({ caseId: this.recordId });
            this.model.closureReason = this.context?.closureReason;
            this.model.closureSolution = this.context?.closureSolution;
            this.model.closureComment = this.context?.closureComment;
            this.model.selectedSendSurvey = this.context?.selectedSendSurvey === true;
        } catch (error) {
            this.toast('Erro', this.reduceError(error), 'error');
        } finally {
            this.loading = false;
        }
    }

    get showSurveyInfo() {
        return this.context?.surveyMode === 'ALWAYS';
    }

    get sendSurveyValue() {
        return this.model.selectedSendSurvey ? 'true' : 'false';
    }

    get surveyOptions() {
        const disableYes =
            this.context?.customerAlreadyReceivedSurveyToday === true &&
            this.context?.allowSameDaySurvey !== true;
        return [
            { label: 'Sim', value: 'true', disabled: disableYes },
            { label: 'Não', value: 'false' }
        ];
    }

    get isClosureBlocked() {
        return this.context?.isCategorized === false;
    }

    get disableSubmit() {
        return this.loading || this.isClosureBlocked;
    }

    handleChange(event) {
        const field = event.target?.dataset?.field;
        if (!field) return;
        this.model[field] = event.detail?.value ?? event.target.value;
    }

    handleSurveyChange(event) {
        this.model.selectedSendSurvey = event.detail.value === 'true';
    }

    async submit() {
        const valid = [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((isValid, input) => {
                input.reportValidity();
                return isValid && input.checkValidity();
            }, true);
        if (!valid) return;

        this.loading = true;
        try {
            const request = {
                caseId: this.recordId,
                closureStatus: this.context?.closureStatus,
                closureReason: this.model.closureReason,
                closureSolution: this.model.closureSolution,
                closureComment: this.model.closureComment,
                selectedSendSurvey: this.model.selectedSendSurvey
            };
            const response = await closeCase({ request });
            if (response?.errorMessage) {
                this.toast('Erro', response.errorMessage, 'error');
                return;
            }
            this.toast('Sucesso', response?.successMessage || 'Caso encerrado com sucesso.', 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.toast('Erro', this.reduceError(error), 'error');
        } finally {
            this.loading = false;
        }
    }

    cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Erro inesperado.';
    }
}