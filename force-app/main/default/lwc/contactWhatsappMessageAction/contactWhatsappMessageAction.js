import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getContext from '@salesforce/apex/ContactWhatsappMessageController.getContext';

import header from '@salesforce/label/c.ContactWhatsApp_Header';
import loading from '@salesforce/label/c.ContactWhatsApp_Loading';
import intro from '@salesforce/label/c.ContactWhatsApp_Intro';
import emptyState from '@salesforce/label/c.ContactWhatsApp_EmptyState';
import openMessagingUser from '@salesforce/label/c.ContactWhatsApp_OpenMessagingUser';
import close from '@salesforce/label/c.ContactWhatsApp_Close';
import recommended from '@salesforce/label/c.ContactWhatsApp_Recommended';
import channel from '@salesforce/label/c.ContactWhatsApp_Channel';
import sendMessage from '@salesforce/label/c.ContactWhatsApp_SendMessage';
import toastTitle from '@salesforce/label/c.ContactWhatsApp_ErrorTitle';
import unexpectedError from '@salesforce/label/c.ContactWhatsApp_ErrorUnexpected';

export default class ContactWhatsappMessageAction extends NavigationMixin(LightningElement) {
    _recordId;
    @track context;
    @track loading = true;

    labels = {
        header,
        loading,
        intro,
        emptyState,
        openMessagingUser,
        close,
        recommended,
        channel,
        sendMessage
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

    get errorMessage() {
        return this.context?.errorMessage;
    }

    get candidates() {
        return this.context?.candidates || [];
    }

    get hasCandidates() {
        return this.context?.hasCandidates === true;
    }

    async initialize() {
        this.loading = true;
        try {
            this.context = await getContext({ contactId: this.recordId });
            if (this.context?.errorMessage) {
                this.toast(this.context.errorMessage);
            }
        } catch (error) {
            const message = this.reduceError(error);
            this.context = { errorMessage: message, hasCandidates: false, candidates: [] };
            this.toast(message);
        } finally {
            this.loading = false;
        }
    }

    openMessagingUser(event) {
        const recordId = event.currentTarget?.dataset?.id;
        if (!recordId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'MessagingEndUser',
                actionName: 'view'
            }
        });
        this.close();
    }

    sendMessage(event) {
        const recordId = event.currentTarget?.dataset?.id;
        if (!recordId) return;

        this.close();
        window.setTimeout(() => {
            this[NavigationMixin.Navigate]({
                type: 'standard__quickAction',
                attributes: {
                    apiName: '_SendConversationMessage'
                },
                state: {
                    recordId
                }
            });
        }, 0);
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    toast(message) {
        this.dispatchEvent(new ShowToastEvent({ title: toastTitle, message, variant: 'error' }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.body?.message || error?.message || unexpectedError;
    }
}