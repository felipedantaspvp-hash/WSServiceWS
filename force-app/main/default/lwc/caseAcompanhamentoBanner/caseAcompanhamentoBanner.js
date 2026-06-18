import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { IsConsoleNavigation } from 'lightning/platformWorkspaceApi';
import { refreshRecordPage } from 'c/caseAcompanhamentoRefresh';

import getAcompanhamentoData from '@salesforce/apex/CaseAcompanhamentoController.getAcompanhamentoData';
import retomarAtendimento from '@salesforce/apex/CaseAcompanhamentoController.retomarAtendimento';

import ETAPA_FIELD from '@salesforce/schema/Case.EtapaAtendimento__c';
import IS_STOPPED_FIELD from '@salesforce/schema/Case.IsStopped';
import ACAO_PAUSA_ATIVA_FIELD from '@salesforce/schema/Case.AcaoPausaAtiva__c';

import titleLabel from '@salesforce/label/c.Acao_Acompanhamento_BannerTitulo';
import badgeLabel from '@salesforce/label/c.Acao_Acompanhamento_BannerBadgeSlaPausado';
import descriptionLabel from '@salesforce/label/c.Acao_Acompanhamento_BannerDescricao';
import reasonLabel from '@salesforce/label/c.Acao_Acompanhamento_LabelMotivo';
import startCommentLabel from '@salesforce/label/c.Acao_Acompanhamento_LabelComentarioEntrada';
import startDateLabel from '@salesforce/label/c.Acao_Acompanhamento_LabelDataInicio';
import ownerLabel from '@salesforce/label/c.Acao_Acompanhamento_LabelUsuarioInicio';
import previousStageLabel from '@salesforce/label/c.Acao_Acompanhamento_LabelEtapaAnterior';
import resumeLabel from '@salesforce/label/c.Acao_Acompanhamento_BotaoRetomar';
import modalTitleLabel from '@salesforce/label/c.Acao_Acompanhamento_ModalRetomarTitulo';
import resumeCommentLabel from '@salesforce/label/c.Acao_Acompanhamento_ComentarioSaidaLabel';
import resumeCommentRequiredLabel from '@salesforce/label/c.Acao_Acompanhamento_ComentarioSaidaObrigatorio';
import resumeSuccessLabel from '@salesforce/label/c.Acao_Acompanhamento_SucessoRetomada';
import cancelLabel from '@salesforce/label/c.Acao_Acompanhamento_BotaoCancelar';
import errorTitleLabel from '@salesforce/label/c.Acao_Acompanhamento_ErroRetomarTitulo';
import loadErrorLabel from '@salesforce/label/c.Acao_Acompanhamento_ErroCarregarDados';
import loadingLabel from '@salesforce/label/c.Acao_Acompanhamento_Carregando';
import loadingResumeLabel from '@salesforce/label/c.Acao_Acompanhamento_CarregandoRetomada';

const FOLLOW_UP_STAGE = 'Em Acompanhamento';
const CASE_STATE_FIELDS = [ETAPA_FIELD, IS_STOPPED_FIELD, ACAO_PAUSA_ATIVA_FIELD];

export default class CaseAcompanhamentoBanner extends LightningElement {
    @api recordId;

    data;
    errorMessage;
    comentarioSaida = '';
    isLoading = false;
    isResumeModalOpen = false;
    hasFollowUpSignal = false;
    lastLoadedStateKey;

    labels = {
        title: titleLabel,
        badge: badgeLabel,
        description: descriptionLabel,
        reason: reasonLabel,
        startComment: startCommentLabel,
        startDate: startDateLabel,
        owner: ownerLabel,
        previousStage: previousStageLabel,
        resume: resumeLabel,
        modalTitle: modalTitleLabel,
        resumeComment: resumeCommentLabel,
        resumeCommentRequired: resumeCommentRequiredLabel,
        cancel: cancelLabel,
        errorTitle: errorTitleLabel,
        loading: loadingLabel,
        loadingResume: loadingResumeLabel
    };

    @wire(IsConsoleNavigation)
    isConsoleNavigation;

    @wire(getRecord, { recordId: '$recordId', fields: CASE_STATE_FIELDS })
    wiredCaseState({ data, error }) {
        if (data) {
            const etapa = getFieldValue(data, ETAPA_FIELD);
            const isStopped = getFieldValue(data, IS_STOPPED_FIELD) === true;
            const activeActionId = getFieldValue(data, ACAO_PAUSA_ATIVA_FIELD);
            this.hasFollowUpSignal = etapa === FOLLOW_UP_STAGE || isStopped || Boolean(activeActionId);

            if (this.hasFollowUpSignal) {
                const stateKey = `${this.recordId}:${etapa}:${isStopped}:${activeActionId || ''}`;
                if (stateKey !== this.lastLoadedStateKey) {
                    this.lastLoadedStateKey = stateKey;
                    this.loadAcompanhamentoData();
                }
            } else {
                this.resetBanner();
            }
        } else if (error) {
            this.hasFollowUpSignal = true;
            this.errorMessage = this.reduceErrors(error) || loadErrorLabel;
        }
    }

    get shouldRender() {
        return this.hasFollowUpSignal || this.data?.emAcompanhamento === true || Boolean(this.errorMessage);
    }

    get showContent() {
        return !this.isLoading && !this.errorMessage && this.data?.emAcompanhamento === true;
    }

    get detailItems() {
        const items = [
            { key: 'motivo', label: this.labels.reason, value: this.data?.motivo },
            { key: 'comentarioEntrada', label: this.labels.startComment, value: this.data?.comentarioEntrada },
            { key: 'usuarioInicio', label: this.labels.owner, value: this.data?.usuarioInicioNome },
            { key: 'etapaAnterior', label: this.labels.previousStage, value: this.data?.etapaAnterior }
        ];
        return items.map((item) => ({
            ...item,
            value: item.value || '-'
        }));
    }

    async loadAcompanhamentoData() {
        if (!this.recordId) return;

        this.isLoading = true;
        this.errorMessage = null;
        try {
            const result = await getAcompanhamentoData({ caseId: this.recordId });
            this.data = result?.emAcompanhamento === true ? result : null;
            this.hasFollowUpSignal = result?.emAcompanhamento === true;
        } catch (error) {
            this.errorMessage = this.reduceErrors(error) || loadErrorLabel;
            this.data = null;
        } finally {
            this.isLoading = false;
        }
    }

    openResumeModal() {
        this.comentarioSaida = '';
        this.isResumeModalOpen = true;
    }

    closeResumeModal() {
        if (this.isLoading) return;
        this.isResumeModalOpen = false;
        this.comentarioSaida = '';
    }

    handleResumeCommentChange(event) {
        this.comentarioSaida = event.detail.value;
    }

    async handleResume() {
        const textarea = this.template.querySelector('lightning-textarea');
        if (textarea) {
            textarea.reportValidity();
            if (!textarea.checkValidity()) return;
        }

        this.isLoading = true;
        try {
            await retomarAtendimento({
                caseId: this.recordId,
                comentarioSaida: this.comentarioSaida
            });
            this.showToast(modalTitleLabel, resumeSuccessLabel, 'success');
            this.isResumeModalOpen = false;
            this.resetBanner();
            await refreshRecordPage(this, this.recordId, this.isConsoleNavigation?.data);
        } catch (error) {
            this.showToast(errorTitleLabel, this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    resetBanner() {
        this.data = null;
        this.errorMessage = null;
        this.hasFollowUpSignal = false;
        this.lastLoadedStateKey = null;
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