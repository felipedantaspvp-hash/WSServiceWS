import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';
import LightningConfirm from 'lightning/confirm';
import getInitialState from '@salesforce/apex/AccountCaseScheduleController.getInitialState';
import getTreeOptions from '@salesforce/apex/AccountCaseScheduleController.getTreeOptions';
import resolveCategorizationSelection from '@salesforce/apex/AccountCaseScheduleController.resolveCategorizationSelection';
import getAvailableQueues from '@salesforce/apex/AccountCaseScheduleController.getAvailableQueues';
import searchUsers from '@salesforce/apex/AccountCaseScheduleController.searchUsers';
import saveSchedule from '@salesforce/apex/AccountCaseScheduleController.saveSchedule';
import setActive from '@salesforce/apex/AccountCaseScheduleController.setActive';
import title from '@salesforce/label/c.AccountCaseSchedule_Title';
import newSchedule from '@salesforce/label/c.AccountCaseSchedule_NewSchedule';
import loadingSchedules from '@salesforce/label/c.AccountCaseSchedule_LoadingSchedules';
import emptyState from '@salesforce/label/c.AccountCaseSchedule_EmptyState';
import scheduleNumber from '@salesforce/label/c.AccountCaseSchedule_ScheduleNumber';
import active from '@salesforce/label/c.AccountCaseSchedule_Active';
import inactive from '@salesforce/label/c.AccountCaseSchedule_Inactive';
import businessUnit from '@salesforce/label/c.AccountCaseSchedule_BusinessUnit';
import selectedBusinessUnit from '@salesforce/label/c.AccountCaseSchedule_SelectedBusinessUnit';
import caseType from '@salesforce/label/c.AccountCaseSchedule_CaseType';
import category from '@salesforce/label/c.AccountCaseSchedule_Category';
import subject from '@salesforce/label/c.AccountCaseSchedule_Subject';
import subsubject from '@salesforce/label/c.AccountCaseSchedule_Subsubject';
import frequency from '@salesforce/label/c.AccountCaseSchedule_Frequency';
import weekdays from '@salesforce/label/c.AccountCaseSchedule_Weekdays';
import availableWeekdays from '@salesforce/label/c.AccountCaseSchedule_AvailableWeekdays';
import selectedWeekdays from '@salesforce/label/c.AccountCaseSchedule_SelectedWeekdays';
import executionTime from '@salesforce/label/c.AccountCaseSchedule_ExecutionTime';
import startDate from '@salesforce/label/c.AccountCaseSchedule_StartDate';
import owner from '@salesforce/label/c.AccountCaseSchedule_Owner';
import lastError from '@salesforce/label/c.AccountCaseSchedule_LastError';
import lastExecution from '@salesforce/label/c.AccountCaseSchedule_LastExecution';
import nextExecution from '@salesforce/label/c.AccountCaseSchedule_NextExecution';
import edit from '@salesforce/label/c.AccountCaseSchedule_Edit';
import activate from '@salesforce/label/c.AccountCaseSchedule_Activate';
import deactivate from '@salesforce/label/c.AccountCaseSchedule_Deactivate';
import editSchedule from '@salesforce/label/c.AccountCaseSchedule_EditSchedule';
import newScheduleTitle from '@salesforce/label/c.AccountCaseSchedule_NewScheduleTitle';
import close from '@salesforce/label/c.AccountCaseSchedule_Close';
import serviceData from '@salesforce/label/c.AccountCaseSchedule_ServiceData';
import activityDescription from '@salesforce/label/c.AccountCaseSchedule_ActivityDescription';
import recurrence from '@salesforce/label/c.AccountCaseSchedule_Recurrence';
import skipWeekends from '@salesforce/label/c.AccountCaseSchedule_SkipWeekends';
import responsible from '@salesforce/label/c.AccountCaseSchedule_Responsible';
import suggestedQueue from '@salesforce/label/c.AccountCaseSchedule_SuggestedQueue';
import ownerType from '@salesforce/label/c.AccountCaseSchedule_OwnerType';
import searchActiveUser from '@salesforce/label/c.AccountCaseSchedule_SearchActiveUser';
import user from '@salesforce/label/c.AccountCaseSchedule_User';
import queue from '@salesforce/label/c.AccountCaseSchedule_Queue';
import cancel from '@salesforce/label/c.AccountCaseSchedule_Cancel';
import save from '@salesforce/label/c.AccountCaseSchedule_Save';
import errorTitle from '@salesforce/label/c.AccountCaseSchedule_ErrorTitle';
import successTitle from '@salesforce/label/c.AccountCaseSchedule_SuccessTitle';
import confirmStatusTitle from '@salesforce/label/c.AccountCaseSchedule_ConfirmStatusTitle';
import confirmActivate from '@salesforce/label/c.AccountCaseSchedule_ConfirmActivate';
import confirmDeactivate from '@salesforce/label/c.AccountCaseSchedule_ConfirmDeactivate';
import statusUpdated from '@salesforce/label/c.AccountCaseSchedule_StatusUpdated';
import scheduleSaved from '@salesforce/label/c.AccountCaseSchedule_ScheduleSaved';
import unexpectedError from '@salesforce/label/c.AccountCaseSchedule_UnexpectedError';

const FREQUENCY_SPECIFIC_WEEKDAYS = 'Dias específicos da semana';

const LABELS = {
    title,
    newSchedule,
    loadingSchedules,
    emptyState,
    scheduleNumber,
    active,
    inactive,
    businessUnit,
    selectedBusinessUnit,
    caseType,
    category,
    subject,
    subsubject,
    frequency,
    weekdays,
    availableWeekdays,
    selectedWeekdays,
    executionTime,
    startDate,
    owner,
    lastError,
    lastExecution,
    nextExecution,
    edit,
    activate,
    deactivate,
    editSchedule,
    newScheduleTitle,
    close,
    serviceData,
    activityDescription,
    recurrence,
    skipWeekends,
    responsible,
    suggestedQueue,
    ownerType,
    searchActiveUser,
    user,
    queue,
    cancel,
    save,
    errorTitle,
    successTitle,
    confirmStatusTitle,
    confirmActivate,
    confirmDeactivate,
    statusUpdated,
    scheduleSaved,
    unexpectedError
};

export default class AccountCaseScheduleManager extends LightningElement {
    _recordId;
    loading = false;
    saving = false;
    showForm = false;
    accountName;
    schedules = [];
    labels = LABELS;
    recordTypeOptions = [];
    frequenciaOptions = [];
    diasDaSemanaOptions = [];
    ownerTypeOptions = [];
    tipoOptions = [];
    categoriaOptions = [];
    assuntoOptions = [];
    subassuntoOptions = [];
    queueOptions = [];
    userOptions = [];
    userSearchTerm = '';
    resolvedQueue;

    form = this.newForm();

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadInitialState();
        }
    }

    get hasSchedules() {
        return this.schedules.length > 0;
    }

    get scheduleRows() {
        return this.schedules.map((row) => ({
            ...row,
            statusLabel: row.ativo ? this.labels.active : this.labels.inactive,
            toggleLabel: row.ativo ? this.labels.deactivate : this.labels.activate
        }));
    }

    get scheduleCards() {
        return this.scheduleRows.map((row) => ({
            ...row,
            statusClass: row.ativo ? 'status-pill status-pill_active' : 'status-pill status-pill_inactive',
            toggleIconName: row.ativo ? 'utility:pause' : 'utility:play',
            hasAssunto: !!row.assunto,
            hasSubassunto: !!row.subassunto,
            hasLastError: !!row.ultimoErroExecucao,
            hasUltimaExecucao: !!row.ultimaExecucao,
            hasProximaExecucao: !!row.proximaExecucao,
            hasDiasDaSemana: !!(row.diasDaSemana && row.diasDaSemana.length),
            displayUnidadeNegocio: row.unidadeNegocioLabel || row.unidadeNegocio,
            displayTipoCaso: row.tipoCasoLabel || row.tipoCaso,
            displayCategoria: row.categoriaLabel || row.categoria,
            displayAssunto: row.assuntoLabel || row.assunto,
            displaySubassunto: row.subassuntoLabel || row.subassunto,
            displayFrequencia: row.frequenciaLabel || row.frequencia,
            displayDiasDaSemana: (row.diasDaSemana || []).join(', ')
        }));
    }

    get formTitle() {
        return this.form.id ? this.labels.editSchedule : this.labels.newScheduleTitle;
    }

    get disableTipoCaso() {
        return !this.form.categorization.recordTypeId || this.tipoOptions.length === 0;
    }

    get disableCategoria() {
        return !this.form.categorization.tipoCaso || this.categoriaOptions.length === 0;
    }

    get disableAssunto() {
        return !this.form.categorization.categoria || this.assuntoOptions.length === 0;
    }

    get disableSubassunto() {
        return !this.form.categorization.assunto || this.subassuntoOptions.length === 0;
    }

    get hasResolvedQueue() {
        return !!this.resolvedQueue;
    }

    get resolvedQueueLabel() {
        return this.resolvedQueue ? `${this.resolvedQueue.name} (${this.resolvedQueue.developerName})` : '';
    }

    get showUserOwner() {
        return this.form.ownerType === 'USER';
    }

    get showQueueOwner() {
        return this.form.ownerType === 'QUEUE';
    }

    get showWeekdays() {
        return this.form.frequencia === FREQUENCY_SPECIFIC_WEEKDAYS;
    }

    async loadInitialState() {
        this.loading = true;
        try {
            const state = await getInitialState({ accountId: this.recordId });
            this.accountName = state?.accountName;
            this.schedules = state?.schedules || [];
            this.frequenciaOptions = this.toComboboxOptions(state?.frequenciaOptions);
            this.diasDaSemanaOptions = this.toComboboxOptions(state?.diasDaSemanaOptions);
            this.ownerTypeOptions = this.toComboboxOptions(state?.ownerTypeOptions);
            this.recordTypeOptions = (state?.caseContext?.recordTypes || []).map((recordType) => ({
                label: `${recordType.unidadeNegocio || recordType.label} (${recordType.label})`,
                value: recordType.recordTypeId,
                developerName: recordType.developerName,
                unidadeNegocio: recordType.unidadeNegocio
            }));
        } catch (error) {
            this.toast(this.labels.errorTitle, this.reduceError(error), 'error');
        } finally {
            this.loading = false;
        }
    }

    handleNew() {
        this.form = this.newForm();
        this.resetDependentOptions();
        this.showForm = true;
        if (this.recordTypeOptions.length === 1) {
            this.applyRecordType(this.recordTypeOptions[0]);
            this.loadTreeOptions();
        }
    }

    async handleScheduleAction(event) {
        const action = event.currentTarget.dataset.action;
        const scheduleId = event.currentTarget.dataset.id;
        const row = this.scheduleRows.find((item) => item.id === scheduleId);
        if (!row) return;
        if (action === 'edit') {
            await this.openEdit(row);
        } else if (action === 'toggle') {
            await this.toggleSchedule(row);
        }
    }

    async openEdit(row) {
        this.form = {
            id: row.id,
            accountId: this.recordId,
            ativo: row.ativo,
            categorization: {
                recordTypeId: row.recordTypeId,
                recordTypeDeveloperName: row.recordTypeDeveloperName,
                unidadeNegocio: row.unidadeNegocio,
                tipoCaso: row.tipoCaso,
                categoria: row.categoria,
                assunto: row.assunto,
                subassunto: row.subassunto
            },
            frequencia: row.frequencia,
            diasDaSemana: row.diasDaSemana || [],
            horarioExecucao: row.horarioExecucao,
            dataInicio: row.dataInicio,
            pularFimDeSemana: row.pularFimDeSemana,
            descricaoAtividade: row.descricaoAtividade,
            ownerType: row.ownerType,
            ownerUserId: row.ownerUserId,
            ownerQueueDeveloperName: row.ownerQueueDeveloperName
        };
        this.userOptions = row.ownerUserId ? [{ label: row.ownerUserName || row.ownerDisplay, value: row.ownerUserId }] : [];
        this.showForm = true;
        await this.loadTreeOptions();
        await this.refreshOwnerOptions(false);
    }

    async toggleSchedule(row) {
        const confirmed = await LightningConfirm.open({
            message: row.ativo ? this.labels.confirmDeactivate : this.labels.confirmActivate,
            label: this.labels.confirmStatusTitle,
            theme: 'warning'
        });
        if (!confirmed) return;
        this.loading = true;
        try {
            await setActive({ accountId: this.recordId, scheduleId: row.id, active: !row.ativo });
            this.toast(this.labels.successTitle, this.labels.statusUpdated, 'success');
            await this.refreshView();
        } catch (error) {
            this.toast(this.labels.errorTitle, this.reduceError(error), 'error');
        } finally {
            this.loading = false;
        }
    }

    async handleRecordTypeChange(event) {
        const selected = this.recordTypeOptions.find((option) => option.value === event.detail.value);
        this.applyRecordType(selected);
        this.form.categorization.tipoCaso = null;
        this.form.categorization.categoria = null;
        this.form.categorization.assunto = null;
        this.form.categorization.subassunto = null;
        await this.loadTreeOptions();
        await this.refreshOwnerOptions(true);
    }

    async handleCategorizationChange(event) {
        const field = event.target.name;
        this.form = {
            ...this.form,
            categorization: {
                ...this.form.categorization,
                [field]: event.detail.value
            }
        };
        if (field === 'tipoCaso') {
            this.form.categorization.categoria = null;
            this.form.categorization.assunto = null;
            this.form.categorization.subassunto = null;
        } else if (field === 'categoria') {
            this.form.categorization.assunto = null;
            this.form.categorization.subassunto = null;
        } else if (field === 'assunto') {
            this.form.categorization.subassunto = null;
        }
        this.form = { ...this.form, categorization: { ...this.form.categorization } };
        await this.loadTreeOptions();
        await this.refreshOwnerOptions(true);
    }

    handleFormChange(event) {
        const field = event.target.name;
        const value = event.detail.value;
        this.form = { ...this.form, [field]: value };
        if (field === 'frequencia' && value !== FREQUENCY_SPECIFIC_WEEKDAYS) {
            this.form = { ...this.form, diasDaSemana: [] };
        }
    }

    handleWeekdaysChange(event) {
        this.form = { ...this.form, diasDaSemana: event.detail.value };
    }

    handleCheckboxChange(event) {
        this.form = { ...this.form, [event.target.name]: event.target.checked };
    }

    async handleOwnerTypeChange(event) {
        const ownerType = event.detail.value;
        this.form = {
            ...this.form,
            ownerType,
            ownerUserId: ownerType === 'USER' ? this.form.ownerUserId : null,
            ownerQueueDeveloperName: ownerType === 'QUEUE' ? this.form.ownerQueueDeveloperName : null
        };
        if (ownerType === 'QUEUE') {
            await this.loadAvailableQueues();
        } else {
            this.queueOptions = [];
        }
    }

    handleQueueChange(event) {
        this.form = { ...this.form, ownerQueueDeveloperName: event.detail.value };
    }

    async handleUserSearch(event) {
        this.userSearchTerm = event.detail.value;
        if (!this.userSearchTerm || this.userSearchTerm.length < 2) return;
        try {
            const users = await searchUsers({ searchTerm: this.userSearchTerm });
            this.userOptions = this.toComboboxOptions(users);
        } catch (error) {
            this.toast(this.labels.errorTitle, this.reduceError(error), 'error');
        }
    }

    handleUserChange(event) {
        this.form = { ...this.form, ownerUserId: event.detail.value };
    }

    async handleSave() {
        if (!this.reportValidity()) return;
        this.saving = true;
        try {
            await saveSchedule({ request: this.form });
            this.toast(this.labels.successTitle, this.labels.scheduleSaved, 'success');
            this.showForm = false;
            await this.refreshView();
        } catch (error) {
            this.toast(this.labels.errorTitle, this.reduceError(error), 'error');
        } finally {
            this.saving = false;
        }
    }

    handleCancel() {
        this.showForm = false;
    }

    async loadTreeOptions() {
        if (!this.form.categorization.recordTypeId || !this.form.categorization.unidadeNegocio) {
            this.resetDependentOptions();
            return;
        }
        try {
            const result = await getTreeOptions({ request: this.form.categorization });
            this.tipoOptions = this.toComboboxOptions(result?.tipoCasoOptions);
            this.categoriaOptions = this.toComboboxOptions(result?.categoriaOptions);
            this.assuntoOptions = this.toComboboxOptions(result?.assuntoOptions);
            this.subassuntoOptions = this.toComboboxOptions(result?.subassuntoOptions);
        } catch (error) {
            this.toast(this.labels.errorTitle, this.reduceError(error), 'error');
        }
    }

    async refreshOwnerOptions(resetManualOwner) {
        this.resolvedQueue = null;
        if (!this.form.categorization.tipoCaso || !this.form.categorization.categoria) {
            if (resetManualOwner) this.clearOwner();
            return;
        }
        try {
            const resolved = await resolveCategorizationSelection({ request: this.form.categorization });
            this.resolvedQueue = resolved?.queue;
            if (this.resolvedQueue) {
                this.queueOptions = [{ label: this.resolvedQueueLabel, value: this.resolvedQueue.developerName }];
                this.form = {
                    ...this.form,
                    ownerType: 'QUEUE',
                    ownerUserId: null,
                    ownerQueueDeveloperName: this.resolvedQueue.developerName
                };
            } else {
                await this.loadAvailableQueues();
                if (resetManualOwner) this.clearOwner();
            }
        } catch {
            this.resolvedQueue = null;
            if (resetManualOwner) this.clearOwner();
        }
    }

    async loadAvailableQueues() {
        if (!this.form.categorization.recordTypeDeveloperName || !this.form.categorization.unidadeNegocio) {
            this.queueOptions = [];
            return;
        }
        const queues = await getAvailableQueues({
            recordTypeDeveloperName: this.form.categorization.recordTypeDeveloperName,
            unidadeNegocio: this.form.categorization.unidadeNegocio
        });
        this.queueOptions = (queues || []).map((queue) => ({
            label: `${queue.name} (${queue.developerName})`,
            value: queue.developerName
        }));
    }

    applyRecordType(option) {
        if (!option) return;
        this.form = {
            ...this.form,
            categorization: {
                ...this.form.categorization,
                recordTypeId: option.value,
                recordTypeDeveloperName: option.developerName,
                unidadeNegocio: option.unidadeNegocio
            }
        };
    }

    resetDependentOptions() {
        this.tipoOptions = [];
        this.categoriaOptions = [];
        this.assuntoOptions = [];
        this.subassuntoOptions = [];
        this.queueOptions = [];
        this.resolvedQueue = null;
    }

    clearOwner() {
        this.form = {
            ...this.form,
            ownerType: null,
            ownerUserId: null,
            ownerQueueDeveloperName: null
        };
    }

    reportValidity() {
        return [...this.template.querySelectorAll('[data-form-field]')].reduce((valid, field) => {
            field.reportValidity();
            return valid && field.checkValidity();
        }, true);
    }

    toComboboxOptions(options) {
        return (options || []).map((option) => ({
            label: option.label,
            value: option.value || option.id || option.developerName
        }));
    }

    async refreshView() {
        await this.loadInitialState();
        if (this.recordId) {
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        }
        this.dispatchEvent(new RefreshEvent());
    }

    newForm() {
        return {
            id: null,
            accountId: this.recordId,
            ativo: true,
            categorization: {
                recordTypeId: null,
                recordTypeDeveloperName: null,
                unidadeNegocio: null,
                tipoCaso: null,
                categoria: null,
                assunto: null,
                subassunto: null
            },
            frequencia: null,
            diasDaSemana: [],
            horarioExecucao: null,
            dataInicio: null,
            pularFimDeSemana: true,
            descricaoAtividade: null,
            ownerType: null,
            ownerUserId: null,
            ownerQueueDeveloperName: null
        };
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((item) => item.message).join(', ');
        return error?.body?.message || error?.message || this.labels.unexpectedError;
    }
}