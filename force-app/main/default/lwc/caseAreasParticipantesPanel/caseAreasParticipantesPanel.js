import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPanelDataFresh from '@salesforce/apex/AreaParticipanteController.getPanelDataFresh';
import closeParticipation from '@salesforce/apex/AreaParticipanteController.closeParticipation';
import getParticipationDetails from '@salesforce/apex/AreaParticipanteController.getParticipationDetails';
import addParticipationBulk from '@salesforce/apex/AreaParticipanteController.addParticipationBulk';
import pauseParticipation from '@salesforce/apex/AreaParticipanteController.pauseParticipation';
import resumeParticipation from '@salesforce/apex/AreaParticipanteController.resumeParticipation';

import titleLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Title';
import internalAreaLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_InternalArea';
import atendimentoLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Atendimento';
import operationalSummaryLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_OperationalSummary';
import openGroupLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_OpenGroup';
import doneGroupLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_DoneGroup';
import emptyLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Empty';
import openPluralLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_OpenPlural';
import overduePluralLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_OverduePlural';
import violatedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Violated';
import overdueLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Overdue';
import pausedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Paused';
import completedViolatedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CompletedViolated';
import completedInTimeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CompletedInTime';
import cancelledLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Cancelled';
import cancelledViolatedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CancelledViolated';
import inTimeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_InTime';
import slaStatusLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_SlaStatus';
import slaTimeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_SlaTime';
import consumedTimeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_ConsumedTime';
import remainingTimeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_RemainingTime';
import pausedTimeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_PausedTime';
import sequenceLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Sequence';
import elapsedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Elapsed';
import startLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Start';
import deadlineLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Deadline';
import requestLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Request';
import nextDeadlineLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_NextDeadline';
import closeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Close';
import detailsLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Details';
import closeTitleLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CloseTitle';
import areaLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Area';
import currentStatusLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CurrentStatus';
import requestCommentLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_RequestComment';
import returnCommentLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_ReturnComment';
import solutionLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Solution';
import cancelLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Cancel';
import confirmCloseLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_ConfirmClose';
import detailTitleLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_DetailTitle';
import backLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Back';
import statusLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Status';
import closeModalLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CloseModal';
import errorLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Error';
import successLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Success';
import closeSuccessLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CloseSuccess';
import pauseLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Pause';
import resumeLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Resume';
import pauseSuccessLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_PauseSuccess';
import resumeSuccessLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_ResumeSuccess';
import addLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Add';
import addTitleLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_AddTitle';
import requestCommentInputLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_RequestCommentInput';
import confirmAddLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_ConfirmAdd';
import addSuccessCountLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_AddSuccessCount';
import unexpectedErrorLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_UnexpectedError';
import addStep2TitleLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_AddStep2Title';
import addAvailableLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_AddAvailable';
import addSelectedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_AddSelected';
import nextLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Next';
import refreshLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_Refresh';
import completedOnLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_CompletedOn';
import statusLineCompletedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_StatusLineCompleted';
import statusLineCancelledLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_StatusLineCancelled';
import statusLinePausedLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_StatusLinePaused';
import statusLineOverdueByLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_StatusLineOverdueBy';
import statusLineOverdueLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_StatusLineOverdue';
import statusLineDeadlineLabel from '@salesforce/label/c.CaseAreasParticipantesPanel_StatusLineDeadline';

export default class CaseAreasParticipantesPanel extends LightningElement {
    @api recordId;
    @track panel;
    @track loading = true;
    @track showCloseModal = false;
    @track showDetailModal = false;
    @track selectedItem;
    @track showAddModal = false;
    @track closeComment = '';
    @track closeSolution = '';
    @track submitting = false;
    @track addStep = 1;
    @track addAreas = [];
    @track addItems = [];
    @track isOpenGroupExpanded = true;
    @track isDoneGroupExpanded = false;
    labels = {
        title: titleLabel,
        internalArea: internalAreaLabel,
        operationalSummary: operationalSummaryLabel,
        openGroup: openGroupLabel,
        doneGroup: doneGroupLabel,
        empty: emptyLabel,
        openPlural: openPluralLabel,
        overduePlural: overduePluralLabel,
        violated: violatedLabel,
        overdue: overdueLabel,
        paused: pausedLabel,
        completedViolated: completedViolatedLabel,
        completedInTime: completedInTimeLabel,
        cancelled: cancelledLabel,
        cancelledViolated: cancelledViolatedLabel,
        inTime: inTimeLabel,
        slaStatus: slaStatusLabel,
        slaTime: slaTimeLabel,
        consumedTime: consumedTimeLabel,
        remainingTime: remainingTimeLabel,
        pausedTime: pausedTimeLabel,
        sequence: sequenceLabel,
        elapsed: elapsedLabel,
        start: startLabel,
        deadline: deadlineLabel,
        request: requestLabel,
        nextDeadline: nextDeadlineLabel,
        close: closeLabel,
        details: detailsLabel,
        closeTitle: closeTitleLabel,
        area: areaLabel,
        currentStatus: currentStatusLabel,
        requestComment: requestCommentLabel,
        returnComment: returnCommentLabel,
        solution: solutionLabel,
        cancel: cancelLabel,
        confirmClose: confirmCloseLabel,
        detailTitle: detailTitleLabel,
        back: backLabel,
        status: statusLabel,
        closeModal: closeModalLabel,
        error: errorLabel,
        success: successLabel,
        closeSuccess: closeSuccessLabel,
        pause: pauseLabel,
        resume: resumeLabel,
        pauseSuccess: pauseSuccessLabel,
        resumeSuccess: resumeSuccessLabel,
        add: addLabel,
        addTitle: addTitleLabel,
        requestCommentInput: requestCommentInputLabel,
        confirmAdd: confirmAddLabel,
        unexpectedError: unexpectedErrorLabel,
        addStep2Title: addStep2TitleLabel,
        addAvailable: addAvailableLabel,
        addSelected: addSelectedLabel,
        next: nextLabel,
        refresh: refreshLabel,
        completedOn: completedOnLabel
    };

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.loading = true;
        try {
            const data = await getPanelDataFresh({ caseId: this.recordId, refreshToken: String(Date.now()) });
            this.panel = data ? JSON.parse(JSON.stringify(data)) : undefined;
        } catch (error) {
            this.showToast(this.labels.error, this.getErrorMessage(error), 'error');
        } finally {
            this.loading = false;
        }
    }

    get hasItems() {
        return !!(this.panel?.items?.length);
    }

    get canManage() {
        return this.panel?.canManage === true;
    }

    handleRefresh() {
        this.loadData();
    }

    get displayItems() {
        const items = [...(this.panel?.items || [])];
        items.sort((a, b) => {
            const rankA = this.getStatusRank(a);
            const rankB = this.getStatusRank(b);
            if (rankA !== rankB) return rankA - rankB;
            const isTotalA = (a?.isStandard && (a?.nomeMarco || '') === 'Tempo Total de Atendimento') ? 1 : 0;
            const isTotalB = (b?.isStandard && (b?.nomeMarco || '') === 'Tempo Total de Atendimento') ? 1 : 0;
            if (isTotalA !== isTotalB) return isTotalA - isTotalB;
            const dateA = a?.dataHoraInicio ? new Date(a.dataHoraInicio).getTime() : Number.MAX_SAFE_INTEGER;
            const dateB = b?.dataHoraInicio ? new Date(b.dataHoraInicio).getTime() : Number.MAX_SAFE_INTEGER;
            return dateA - dateB;
        });
        return items.map((item) => {
            const tone = this.getTone(item);
            const deadlineText = this.formatDateTime(item?.dataHoraPrazo);
            const value = Number(item.percentualDecorrido || 0);
            const pct = Math.max(0, Math.min(100, value));
            return {
                ...item,
                areaTypePillLabel: item.isStandard ? atendimentoLabel : this.labels.internalArea,
                areaDisplayLabel: item.isStandard ? (item.nomeMarco || '-') : item.areaLabel,
                cardClass: `slds-box slds-m-bottom_xx-small area-item-compact ${tone}`,
                progressBarClass: `progress-bar ${tone === 'cancelled' ? 'done' : tone}`,
                progressStyle: `width: ${pct}%`,
                showProgress: item?.percentualDecorrido !== null && item?.percentualDecorrido !== undefined,
                statusLine: this.buildStatusLine(item, tone, deadlineText),
                statusLineClass: `compact-status-line status-${tone}`
            };
        });
    }

    get openItems() {
        return this.displayItems.filter((i) => !i?.isConcluida && !i?.isCancelada);
    }

    get doneItems() {
        return this.displayItems.filter((i) => i?.isConcluida || i?.isCancelada);
    }

    get hasOpenItems() {
        return this.openItems.length > 0;
    }

    get hasDoneItems() {
        return this.doneItems.length > 0;
    }

    get openGroupIcon() {
        return this.isOpenGroupExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get doneGroupIcon() {
        return this.isDoneGroupExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    toggleOpenGroup() {
        this.isOpenGroupExpanded = !this.isOpenGroupExpanded;
    }

    toggleDoneGroup() {
        this.isDoneGroupExpanded = !this.isDoneGroupExpanded;
    }

    get summaryText() {
        if (!this.panel) return '';
        const parts = [];
        parts.push(`${this.panel.totalAbertas || 0} ${this.labels.openPlural}`);
        parts.push(`${this.panel.totalVencidas || 0} ${this.labels.overduePlural}`);
        if (this.panel.proximoPrazo) {
            parts.push(`${this.labels.nextDeadline}: ${new Intl.DateTimeFormat(undefined, { dateStyle: 'short', timeStyle: 'short' }).format(new Date(this.panel.proximoPrazo))}`);
        }
        return parts.join(' • ');
    }

    getTone(item) {
        if ((item?.statusSLA || '').toLowerCase() === 'pausado') return 'paused';
        if (item?.isCancelada) return 'cancelled';
        if (item?.isConcluida) return 'done';
        if (item?.isVencida) return 'overdue';
        return 'open';
    }

    getStatusRank(item) {
        return item?.isConcluida || item?.isCancelada ? 1 : 0;
    }

    getStatusTone(item) {
        if (item?.isCancelada) return 'cancelled';
        if (item?.isConcluida) return 'done';
        return 'open';
    }

    formatDateTime(value) {
        if (!value) return '-';
        try {
            return new Intl.DateTimeFormat(undefined, { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value));
        } catch (_e) {
            return '-';
        }
    }

    buildElapsedLabel(item, pct) {
        const hasConsumed = item?.tempoConsumidoMinutos !== null && item?.tempoConsumidoMinutos !== undefined;
        const hasRemaining = item?.tempoRestanteMinutos !== null && item?.tempoRestanteMinutos !== undefined;
        const hasSlaTotal = item?.tempoSLAMinutos !== null && item?.tempoSLAMinutos !== undefined;

        if (hasConsumed || hasRemaining || hasSlaTotal) {
            const parts = [];
            if (hasConsumed) {
                parts.push(`${this.labels.consumedTime}: ${this.formatMinutes(item?.tempoConsumidoMinutos)}`);
            }
            if (hasRemaining) {
                parts.push(`${this.labels.remainingTime}: ${this.formatMinutes(item?.tempoRestanteMinutos)}`);
            }
            if (hasSlaTotal) {
                parts.push(`${this.labels.slaTime}: ${this.formatMinutes(item?.tempoSLAMinutos)}`);
            }
            const pctText = item?.percentualDecorrido !== null && item?.percentualDecorrido !== undefined
                ? ` (${Math.round(pct)}%)`
                : '';
            return `${parts.join(' | ')}${pctText}`;
        }

        const startMs = item?.dataHoraInicio ? new Date(item.dataHoraInicio).getTime() : null;
        const endMs = item?.dataHoraFim ? new Date(item.dataHoraFim).getTime() : Date.now();
        if (!startMs || Number.isNaN(startMs)) {
            return `${this.labels.elapsed}: -`;
        }
        const elapsedMs = Math.max(0, endMs - startMs);
        const elapsedPretty = this.msToPretty(elapsedMs);

        const deadlineMs = item?.dataHoraPrazo ? new Date(item.dataHoraPrazo).getTime() : null;
        if (!deadlineMs || Number.isNaN(deadlineMs) || deadlineMs <= startMs) {
            return `${this.labels.elapsed}: ${elapsedPretty}`;
        }

        const totalPretty = this.msToPretty(deadlineMs - startMs);
        return `${this.labels.elapsed}: ${elapsedPretty} / ${totalPretty} (${Math.round(pct)}%)`;
    }

    formatMinutes(value, withSeconds = false) {
        if (value === null || value === undefined || value === '') return '-';
        const num = Number(value);
        if (Number.isNaN(num)) return '-';
        const sign = num < 0 ? '-' : '';
        if (withSeconds) {
            const totalSec = Math.abs(Math.round(num * 60));
            const h = Math.floor(totalSec / 3600);
            const m = Math.floor((totalSec % 3600) / 60);
            const s = totalSec % 60;
            const parts = [];
            if (h > 0) parts.push(`${h}h`);
            parts.push(`${String(m).padStart(2, '0')}m`);
            parts.push(`${String(s).padStart(2, '0')}s`);
            return `${sign}${parts.join(' ')}`;
        }
        const total = Math.abs(Math.round(num));
        const hours = Math.floor(total / 60);
        const minutes = total % 60;
        return `${sign}${String(hours).padStart(2, '0')}h ${String(minutes).padStart(2, '0')}m`;
    }

    formatSequence(value) {
        if (value === null || value === undefined || value === '') return '-';
        const num = Number(value);
        if (Number.isNaN(num)) return '-';
        return `${this.labels.sequence} ${num}`;
    }

    buildClassificationPills(item) {
        const pills = [];
        const statusSLA = (item?.statusSLA || '').toLowerCase();
        const isConcluida = item?.isConcluida === true;
        const isCancelada = item?.isCancelada === true;
        const isVencida = item?.isVencida === true || statusSLA === 'vencido';
        const isPausada = statusSLA === 'pausado';
        const isInTimeOpen = statusSLA === 'dentro do prazo';
        const violou = item?.violouSLA === true;
        const isAberta = !isConcluida && !isCancelada;

        if (isPausada) {
            pills.push({ key: 'paused', label: this.labels.paused, className: 'status-pill paused' });
            return pills;
        }

        if (isConcluida && violou) {
            pills.push({ key: 'done-violated', label: this.labels.completedViolated, className: 'status-pill violated' });
            return pills;
        }

        if (isConcluida && !violou) {
            pills.push({ key: 'done-intime', label: this.labels.completedInTime, className: 'status-pill done' });
            return pills;
        }

        if (isCancelada && violou) {
            pills.push({ key: 'cancelled-violated', label: this.labels.cancelledViolated, className: 'status-pill violated' });
            return pills;
        }

        if (isCancelada && !violou) {
            pills.push({ key: 'cancelled', label: this.labels.cancelled, className: 'status-pill cancelled' });
            return pills;
        }

        if (isAberta && isVencida) {
            pills.push({ key: 'overdue', label: this.labels.overdue, className: 'status-pill overdue' });
            return pills;
        }

        if (isAberta && isInTimeOpen) {
            pills.push({ key: 'in-time', label: this.labels.inTime, className: 'status-pill open' });
        }

        return pills;
    }

    buildStatusLine(item, tone, deadlineText) {
        if (tone === 'done') {
            const endText = this.formatDateTime(item?.dataHoraFim);
            return statusLineCompletedLabel.replace('{0}', endText);
        }
        if (tone === 'cancelled') return statusLineCancelledLabel;
        if (tone === 'paused') return statusLinePausedLabel;
        if (tone === 'overdue') {
            const deadlineMs = item?.dataHoraPrazo ? new Date(item.dataHoraPrazo).getTime() : null;
            if (deadlineMs) {
                const overdueMs = Math.max(0, Date.now() - deadlineMs);
                return statusLineOverdueByLabel.replace('{0}', this.msToPretty(overdueMs));
            }
            return statusLineOverdueLabel;
        }
        if (deadlineText && deadlineText !== '-') {
            return statusLineDeadlineLabel.replace('{0}', deadlineText);
        }
        return '';
    }

    msToPretty(ms) {
        const totalMinutes = Math.floor(ms / 60000);
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        return `${String(hours).padStart(2, '0')}h ${String(minutes).padStart(2, '0')}m`;
    }

    handleCloseAction(event) {
        const itemId = event.currentTarget.dataset.id;
        this.openCloseModalById(itemId);
    }

    handleCloseIcon(event) {
        event.stopPropagation();
        this.openCloseModalById(event.currentTarget.dataset.id);
    }

    async handlePauseAction(event) {
        await this.runPauseResumeAction(event.currentTarget.dataset.id, pauseParticipation, this.labels.pauseSuccess);
    }

    async handleResumeAction(event) {
        await this.runPauseResumeAction(event.currentTarget.dataset.id, resumeParticipation, this.labels.resumeSuccess);
    }

    async handlePauseIcon(event) {
        event.stopPropagation();
        await this.runPauseResumeAction(event.currentTarget.dataset.id, pauseParticipation, this.labels.pauseSuccess);
    }

    async handleResumeIcon(event) {
        event.stopPropagation();
        await this.runPauseResumeAction(event.currentTarget.dataset.id, resumeParticipation, this.labels.resumeSuccess);
    }

    async runPauseResumeAction(itemId, action, successMessage) {
        if (!itemId || this.submitting) {
            return;
        }
        this.submitting = true;
        this.loading = true;
        try {
            await action({ request: { areaParticipanteId: itemId } });
            this.showToast(this.labels.success, successMessage, 'success');
            await this.loadData();
        } catch (error) {
            this.showToast(this.labels.error, this.getErrorMessage(error), 'error');
            this.loading = false;
        } finally {
            this.submitting = false;
        }
    }

    openCloseModalById(itemId) {
        const found = (this.panel?.items || []).find((x) => x.id === itemId);
        this.selectedItem = found;
        this.closeComment = '';
        this.closeSolution = '';
        this.showCloseModal = true;
    }

    openAddModal() {
        this.addStep = 1;
        this.addAreas = [];
        this.addItems = [];
        this.showAddModal = true;
    }

    async handleViewDetails(event) {
        event.stopPropagation();
        await this.openDetailById(event.currentTarget.dataset.id);
    }

    async handleCardClick(event) {
        if (this.showDetailModal || this.showCloseModal || this.showAddModal) return;
        await this.openDetailById(event.currentTarget.dataset.id);
    }

    async openDetailById(itemId) {
        if (!itemId) return;
        try {
            const detail = await getParticipationDetails({ areaParticipanteId: itemId });
            const raw = detail?.item;
            if (raw) {
                const tone = this.getTone(raw);
                const deadlineText = this.formatDateTime(raw.dataHoraPrazo);
                this.selectedItem = {
                    ...raw,
                    areaTypePillLabel: raw.isStandard ? atendimentoLabel : this.labels.internalArea,
                    areaDisplayLabel: raw.isStandard ? (raw.nomeMarco || '-') : raw.areaLabel,
                    startText: this.formatDateTime(raw.dataHoraInicio),
                    deadlineText,
                    endText: this.formatDateTime(raw.dataHoraFim),
                    tempoSLAText: this.formatMinutes(raw.tempoSLAMinutos, true),
                    tempoConsumidoText: this.formatMinutes(raw.tempoConsumidoMinutos, true),
                    tempoRestanteText: this.formatMinutes(raw.tempoRestanteMinutos, true),
                    tempoPausadoText: this.formatMinutes(raw.tempoPausadoMinutos, true),
                    sequenciaText: this.formatSequence(raw.sequenciaAcionamento),
                    requestText: (raw.comentarioSolicitacao || '').trim() || '-',
                    statusLine: this.buildStatusLine(raw, tone, deadlineText),
                    statusLineClass: `compact-status-line status-${tone}`
                };
            }
            this.showDetailModal = true;
        } catch (error) {
            this.showToast(this.labels.error, this.getErrorMessage(error), 'error');
        }
    }

    stopDetailPropagation(event) {
        event.stopPropagation();
    }

    closeDetailModal(event) {
        if (event) event.stopPropagation();
        this.showDetailModal = false;
        this.selectedItem = null;
    }

    closeModal() {
        this.showCloseModal = false;
        this.showDetailModal = false;
        this.showAddModal = false;
        this.selectedItem = null;
    }

    handleCommentChange(event) {
        this.closeComment = event.target.value;
    }

    handleSolutionChange(event) {
        this.closeSolution = event.target.value;
    }

    handleAddAreasChange(event) {
        this.addAreas = event.detail.value;
    }

    handleAddItemComentarioChange(event) {
        const area = event.currentTarget.dataset.area;
        this.addItems = this.addItems.map((item) =>
            item.area === area ? { ...item, comentario: event.target.value } : item
        );
    }

    handleAddNext() {
        if (!this.addAreas.length) return;
        const optionMap = {};
        (this.addAreaOptions || []).forEach((o) => { optionMap[o.value] = o.label; });
        const existingComments = {};
        (this.addItems || []).forEach((i) => { existingComments[i.area] = i.comentario; });
        this.addItems = this.addAreas.map((area) => ({
            area,
            areaLabel: optionMap[area] || area,
            comentario: existingComments[area] || ''
        }));
        this.addStep = 2;
    }

    handleAddBack() {
        this.addStep = 1;
    }

    get isAddStep1() {
        return this.addStep === 1;
    }

    get addNextDisabled() {
        return !this.addAreas || !this.addAreas.length;
    }

    get canConfirmClose() {
        return !this.submitting && this.closeComment?.trim() && this.closeSolution?.trim();
    }

    get addAreaOptions() {
        return this.panel?.areaOptions || [];
    }

    get canConfirmAdd() {
        return !this.submitting && this.addItems.length > 0 && this.addItems.every((i) => i.comentario?.trim());
    }

    async confirmClose() {
        if (!this.canConfirmClose || !this.selectedItem?.id) {
            return;
        }
        this.submitting = true;
        try {
            await closeParticipation({
                request: {
                    areaParticipanteId: this.selectedItem.id,
                    comentarioRetorno: this.closeComment,
                    solucaoRetorno: this.closeSolution
                }
            });
            this.showToast(this.labels.success, this.labels.closeSuccess, 'success');
            this.closeModal();
            await this.loadData();
        } catch (error) {
            this.showToast(this.labels.error, this.getErrorMessage(error), 'error');
        } finally {
            this.submitting = false;
        }
    }

    async confirmAdd() {
        if (!this.canConfirmAdd) return;
        this.submitting = true;
        try {
            const count = this.addItems.length;
            await addParticipationBulk({
                request: {
                    caseId: this.recordId,
                    items: this.addItems.map((i) => ({ area: i.area, comentarioSolicitacao: i.comentario }))
                }
            });
            const successMsg = addSuccessCountLabel.replace('{0}', count);
            this.showToast(this.labels.success, successMsg, 'success');
            this.closeModal();
            await this.loadData();
        } catch (error) {
            this.showToast(this.labels.error, this.getErrorMessage(error), 'error');
        } finally {
            this.submitting = false;
        }
    }

    getErrorMessage(error) {
        return error?.body?.message || error?.message || this.labels.unexpectedError;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}