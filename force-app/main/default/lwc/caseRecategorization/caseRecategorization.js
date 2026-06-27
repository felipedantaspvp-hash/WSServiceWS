import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import CaseRecategorizationModal from 'c/caseRecategorizationModal';

export default class CaseRecategorization extends LightningElement {
    _recordId;
    _opened = false;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        this.openModalIfReady();
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
        this.openModalIfReady();
    }

    openModalIfReady() {
        if (this._opened || !this._recordId) {
            return;
        }
        this._opened = true;
        CaseRecategorizationModal.open({
            size: 'medium',
            recordId: this._recordId
        });
        // Defer closing the Quick Action panel to the next tick: LightningModal.open()
        // mounts the modal asynchronously, and closing the panel (which tears down this
        // launcher component) too soon can destroy the modal before it finishes mounting.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        }, 0);
    }
}