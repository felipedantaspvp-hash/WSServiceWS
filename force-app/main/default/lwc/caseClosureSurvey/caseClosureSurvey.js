import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import CLOSURE_REASON_FIELD from '@salesforce/schema/Case.MotivoEncerramento__c';

import getClosureContext from '@salesforce/apex/CaseClosureSurveyController.getClosureContext';
import closeCase from '@salesforce/apex/CaseClosureSurveyController.closeCase';
import businessUnitLabel from '@salesforce/label/c.CaseClosureSurvey_BusinessUnit';
import cancelLabel from '@salesforce/label/c.CaseClosureSurvey_Cancel';
import caseNumberLabel from '@salesforce/label/c.CaseClosureSurvey_CaseNumber';
import channelLabel from '@salesforce/label/c.CaseClosureSurvey_Channel';
import closeLabel from '@salesforce/label/c.CaseClosureSurvey_Close';
import closeCaseTitleLabel from '@salesforce/label/c.CaseClosureSurvey_CloseCaseTitle';
import closureCommentLabel from '@salesforce/label/c.CaseClosureSurvey_ClosureComment';
import closureDataTitleLabel from '@salesforce/label/c.CaseClosureSurvey_ClosureDataTitle';
import closureReasonLabel from '@salesforce/label/c.CaseClosureSurvey_ClosureReason';
import closureSolutionLabel from '@salesforce/label/c.CaseClosureSurvey_ClosureSolution';
import closureStatusLabel from '@salesforce/label/c.CaseClosureSurvey_ClosureStatus';
import complaintTitleLabel from '@salesforce/label/c.CaseClosureSurvey_ComplaintTitle';
import errorTitleLabel from '@salesforce/label/c.CaseClosureSurvey_ErrorTitle';
import generateComplaintQuestionLabel from '@salesforce/label/c.CaseClosureSurvey_GenerateComplaintQuestion';
import loadingLabel from '@salesforce/label/c.CaseClosureSurvey_Loading';
import noLabel from '@salesforce/label/c.CaseClosureSurvey_No';
import sendSurveyQuestionLabel from '@salesforce/label/c.CaseClosureSurvey_SendSurveyQuestion';
import successMessageLabel from '@salesforce/label/c.CaseClosureSurvey_SuccessMessage';
import successTitleLabel from '@salesforce/label/c.CaseClosureSurvey_SuccessTitle';
import surveyAlwaysInfoLabel from '@salesforce/label/c.CaseClosureSurvey_SurveyAlwaysInfo';
import surveyTitleLabel from '@salesforce/label/c.CaseClosureSurvey_SurveyTitle';
import statusClosedLabel from '@salesforce/label/c.CaseClosureSurvey_StatusClosed';
import unexpectedErrorLabel from '@salesforce/label/c.CaseClosureSurvey_UnexpectedError';
import yesLabel from '@salesforce/label/c.CaseClosureSurvey_Yes';

export default class CaseClosureSurvey extends LightningElement {
    _recordId;
    @track context;
    @track loading = true;
    @track caseRecordTypeId;
    @track closureReasonPicklist;
    @track model = {
        closureReason: null,
        closureSolution: null,
        closureComment: null,
        selectedSendSurvey: false,
        selectedGerarReclamacao: false
    };

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    wiredCaseObjectInfo({ data }) {
        if (data && !this.caseRecordTypeId) {
            this.caseRecordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseRecordTypeId', fieldApiName: CLOSURE_REASON_FIELD })
    wiredClosureReasonPicklist(result) {
        this.closureReasonPicklist = result;
    }
    labels = {
        businessUnit: businessUnitLabel,
        cancel: cancelLabel,
        caseNumber: caseNumberLabel,
        channel: channelLabel,
        close: closeLabel,
        closeCaseTitle: closeCaseTitleLabel,
        closureComment: closureCommentLabel,
        closureDataTitle: closureDataTitleLabel,
        closureReason: closureReasonLabel,
        closureSolution: closureSolutionLabel,
        closureStatus: closureStatusLabel,
        complaintTitle: complaintTitleLabel,
        errorTitle: errorTitleLabel,
        generateComplaintQuestion: generateComplaintQuestionLabel,
        loading: loadingLabel,
        sendSurveyQuestion: sendSurveyQuestionLabel,
        successMessage: successMessageLabel,
        successTitle: successTitleLabel,
        surveyAlwaysInfo: surveyAlwaysInfoLabel,
        surveyTitle: surveyTitleLabel
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
            this._recordId = fallbackRecordId;
            this.initialize();
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
            this.caseRecordTypeId = this.context?.recordTypeId || this.caseRecordTypeId;
            this.model.closureReason = this.context?.closureReason;
            this.model.closureSolution = this.context?.closureSolution;
            this.model.closureComment = this.context?.closureComment;
            this.model.selectedSendSurvey = this.context?.selectedSendSurvey === true;
            this.model.selectedGerarReclamacao = this.context?.selectedGerarReclamacao === true;
        } catch (error) {
            this.toast(errorTitleLabel, this.reduceError(error), 'error');
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
            { label: yesLabel, value: 'true', disabled: disableYes },
            { label: noLabel, value: 'false' }
        ];
    }

    get isClosureBlocked() {
        return this.context?.isCategorized === false;
    }

    get closureStatusDisplay() {
        return this.context?.closureStatus === 'Fechado' ? statusClosedLabel : this.context?.closureStatus;
    }

    get closureReasonOptions() {
        return this.closureReasonPicklist?.data?.values || [];
    }

    get isClosureReasonPicklistLoading() {
        return !this.closureReasonPicklist?.data && !this.closureReasonPicklist?.error;
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

    handleGerarReclamacaoChange(event) {
        this.model.selectedGerarReclamacao = event.target.checked;
    }

    async submit() {
        const valid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
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
                selectedSendSurvey: this.model.selectedSendSurvey,
                selectedGerarReclamacao: this.model.selectedGerarReclamacao
            };
            const response = await closeCase({ request });
            if (response?.errorMessage) {
                this.toast(errorTitleLabel, response.errorMessage, 'error');
                return;
            }
            this.toast(successTitleLabel, response?.successMessage || successMessageLabel, 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.toast(errorTitleLabel, this.reduceError(error), 'error');
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
        return error?.body?.message || error?.message || unexpectedErrorLabel;
    }
}