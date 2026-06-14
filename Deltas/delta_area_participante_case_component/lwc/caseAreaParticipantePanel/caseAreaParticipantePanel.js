import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPanelData from '@salesforce/apex/AreaParticipanteController.getPanelData';
import addParticipation from '@salesforce/apex/AreaParticipanteController.addParticipation';
import closeParticipation from '@salesforce/apex/AreaParticipanteController.closeParticipation';

export default class CaseAreaParticipantePanel extends LightningElement {
    @api recordId;

    @track loading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track panel = null;

    @track showAddModal = false;
    @track addArea = '';
    @track addComment = '';
    @track saving = false;

    @track showCloseModal = false;
    @track closeAreaId = null;
    @track closeComment = '';
    @track closeSolution = '';
    @track closing = false;

    connectedCallback() {
        this.loadPanel();
    }

    async loadPanel() {
        this.loading = true;
        this.hasError = false;
        this.errorMessage = '';
        try {
            this.panel = await getPanelData({ caseId: this.recordId });
        } catch (error) {
            this.hasError = true;
            this.errorMessage = this.reduceError(error) || 'Erro ao carregar áreas participantes.';
        } finally {
            this.loading = false;
        }
    }

    handleRefresh() {
        this.loadPanel();
    }

    get canManage() {
        return this.panel?.canManage === true;
    }

    get hasItems() {
        return (this.panel?.items || []).length > 0;
    }

    get hasNoItems() {
        return !this.loading && !this.hasError && !this.hasItems;
    }

    get totalAbertas() {
        return this.panel?.totalAbertas || 0;
    }

    get totalVencidas() {
        return this.panel?.totalVencidas || 0;
    }

    get totalConcluidas() {
        return this.panel?.totalConcluidas || 0;
    }

    get hasVencidas() {
        return this.totalVencidas > 0;
    }

    get areaOptions() {
        return (this.panel?.areaOptions || []).map(o => ({ label: o.label, value: o.value }));
    }

    get hasAreaOptions() {
        return this.areaOptions.length > 0;
    }

    get items() {
        return (this.panel?.items || []).map(item => {
            const pct = item.percentualDecorrido != null ? Math.min(100, Math.round(item.percentualDecorrido)) : 0;
            return {
                ...item,
                containerClass: `slds-box slds-m-bottom_x-small area-item ${item.cssClass || 'open'}`,
                progressStyle: `width: ${pct}%`,
                progressBarClass: `progress-bar-fill ${item.progressClass || 'progress-ok'}`,
                hasPercent: item.percentualDecorrido != null && item.percentualDecorrido > 0,
                statusBadgeClass: item.isVencida
                    ? 'slds-badge badge-overdue'
                    : item.isConcluida
                    ? 'slds-badge badge-done'
                    : item.isCancelada
                    ? 'slds-badge badge-cancelada'
                    : 'slds-badge badge-aberta'
            };
        });
    }

    handleOpenAddModal() {
        this.addArea = '';
        this.addComment = '';
        this.showAddModal = true;
    }

    handleCloseAddModal() {
        this.showAddModal = false;
        this.saving = false;
    }

    handleAddAreaChange(event) {
        this.addArea = event.detail.value;
    }

    handleAddCommentChange(event) {
        this.addComment = event.detail.value;
    }

    async handleConfirmAdd() {
        if (!this.addArea) {
            this.showToast('Erro', 'Selecione a área participante.', 'error');
            return;
        }
        if (!this.addComment || !this.addComment.trim()) {
            this.showToast('Erro', 'Informe o comentário de solicitação.', 'error');
            return;
        }
        this.saving = true;
        try {
            await addParticipation({
                request: {
                    caseId: this.recordId,
                    area: this.addArea,
                    comentarioSolicitacao: this.addComment
                }
            });
            this.showToast('Sucesso', 'Área participante adicionada com sucesso.', 'success');
            this.handleCloseAddModal();
            await this.loadPanel();
        } catch (error) {
            this.showToast('Erro', this.reduceError(error) || 'Erro ao adicionar participação.', 'error');
        } finally {
            this.saving = false;
        }
    }

    handleOpenCloseModal(event) {
        this.closeAreaId = event.currentTarget.dataset.id;
        this.closeComment = '';
        this.closeSolution = '';
        this.showCloseModal = true;
    }

    handleCloseCloseModal() {
        this.showCloseModal = false;
        this.closing = false;
    }

    handleCloseCommentChange(event) {
        this.closeComment = event.detail.value;
    }

    handleCloseSolutionChange(event) {
        this.closeSolution = event.detail.value;
    }

    async handleConfirmClose() {
        if (!this.closeComment || !this.closeComment.trim()) {
            this.showToast('Erro', 'Informe o comentário de retorno.', 'error');
            return;
        }
        if (!this.closeSolution || !this.closeSolution.trim()) {
            this.showToast('Erro', 'Informe a solução ou retorno da área.', 'error');
            return;
        }
        this.closing = true;
        try {
            await closeParticipation({
                request: {
                    areaParticipanteId: this.closeAreaId,
                    comentarioRetorno: this.closeComment,
                    solucaoRetorno: this.closeSolution
                }
            });
            this.showToast('Sucesso', 'Participação encerrada com sucesso.', 'success');
            this.handleCloseCloseModal();
            await this.loadPanel();
        } catch (error) {
            this.showToast('Erro', this.reduceError(error) || 'Erro ao encerrar participação.', 'error');
        } finally {
            this.closing = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        return error?.body?.message || error?.message || '';
    }
}
