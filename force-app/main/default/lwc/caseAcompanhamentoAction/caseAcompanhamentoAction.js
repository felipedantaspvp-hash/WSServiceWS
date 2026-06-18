import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { IsConsoleNavigation } from 'lightning/platformWorkspaceApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { refreshRecordPage } from 'c/caseAcompanhamentoRefresh';
import entrarEmAcompanhamento from '@salesforce/apex/CaseAcompanhamentoController.entrarEmAcompanhamento';
import CASE_OBJECT from '@salesforce/schema/Case';
import MOTIVO_FIELD from '@salesforce/schema/Case.MotivoAcompanhamento__c';

import titleLabel from '@salesforce/label/c.Acao_Acompanhamento_TituloEntrada';
import messageLabel from '@salesforce/label/c.Acao_Acompanhamento_MensagemEntrada';
import confirmLabel from '@salesforce/label/c.Acao_Acompanhamento_BotaoConfirmar';
import cancelLabel from '@salesforce/label/c.Acao_Acompanhamento_BotaoCancelar';
import reasonRequiredLabel from '@salesforce/label/c.Acao_Acompanhamento_ErroMotivoObrigatorio';
import commentRequiredLabel from '@salesforce/label/c.Acao_Acompanhamento_ErroComentarioObrigatorio';
import reasonLabel from '@salesforce/label/c.Acao_Acompanhamento_MotivoLabel';
import commentLabel from '@salesforce/label/c.Acao_Acompanhamento_ComentarioEntradaLabel';
import successTitleLabel from '@salesforce/label/c.Acao_Acompanhamento_SucessoTitulo';
import errorTitleLabel from '@salesforce/label/c.Acao_Acompanhamento_ErroTitulo';
import loadingLabel from '@salesforce/label/c.Acao_Acompanhamento_Carregando';

export default class CaseAcompanhamentoAction extends LightningElement {
    @api recordId;

    motivo = '';
    comentarioEntrada = '';
    isLoading = false;
    reasonOptions = [];

    labels = {
        title: titleLabel,
        message: messageLabel,
        confirm: confirmLabel,
        cancel: cancelLabel,
        reasonRequired: reasonRequiredLabel,
        commentRequired: commentRequiredLabel,
        reason: reasonLabel,
        comment: commentLabel,
        successTitle: successTitleLabel,
        errorTitle: errorTitleLabel,
        loading: loadingLabel
    };

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    @wire(IsConsoleNavigation)
    isConsoleNavigation;

    @wire(getPicklistValues, {
        recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId',
        fieldApiName: MOTIVO_FIELD
    })
    wiredReasons({ data, error }) {
        if (data) {
            this.reasonOptions = data.values.map((item) => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            this.showToast(this.labels.errorTitle, this.reduceErrors(error), 'error');
        }
    }

    handleReasonChange(event) {
        this.motivo = event.detail.value;
    }

    handleCommentChange(event) {
        this.comentarioEntrada = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleConfirm() {
        if (!this.validateForm()) return;

        this.isLoading = true;
        try {
            const result = await entrarEmAcompanhamento({
                caseId: this.recordId,
                motivo: this.motivo,
                comentarioEntrada: this.comentarioEntrada
            });
            this.showToast(this.labels.successTitle, result?.message, 'success');
            await refreshRecordPage(this, this.recordId, this.isConsoleNavigation?.data);
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.showToast(this.labels.errorTitle, this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        return [...this.template.querySelectorAll('lightning-combobox, lightning-textarea')]
            .reduce((isValid, input) => {
                input.reportValidity();
                return isValid && input.checkValidity();
            }, true);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    reduceErrors(error) {
        const errors = Array.isArray(error) ? error : [error];
        return errors
            .filter((entry) => entry)
            .map((entry) => {
                if (Array.isArray(entry.body)) return entry.body.map((body) => body.message).join(', ');
                if (entry.body?.message) return entry.body.message;
                if (entry.message) return entry.message;
                return JSON.stringify(entry);
            })
            .join('; ');
    }
}