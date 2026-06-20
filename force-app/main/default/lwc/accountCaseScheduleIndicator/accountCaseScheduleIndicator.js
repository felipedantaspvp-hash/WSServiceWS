import { LightningElement, api, wire } from 'lwc';
import getIndicator from '@salesforce/apex/AccountCaseScheduleController.getIndicator';
import indicatorTitle from '@salesforce/label/c.AccountCaseSchedule_IndicatorTitle';
import indicatorActive from '@salesforce/label/c.AccountCaseSchedule_IndicatorActive';
import indicatorInactive from '@salesforce/label/c.AccountCaseSchedule_IndicatorInactive';
import indicatorNone from '@salesforce/label/c.AccountCaseSchedule_IndicatorNone';
import indicatorUnavailable from '@salesforce/label/c.AccountCaseSchedule_IndicatorUnavailable';
import loadingSchedules from '@salesforce/label/c.AccountCaseSchedule_LoadingSchedules';
import active from '@salesforce/label/c.AccountCaseSchedule_Active';
import inactive from '@salesforce/label/c.AccountCaseSchedule_Inactive';
import unexpectedError from '@salesforce/label/c.AccountCaseSchedule_UnexpectedError';

const LABELS = {
    indicatorTitle,
    indicatorActive,
    indicatorInactive,
    indicatorNone,
    indicatorUnavailable,
    loadingSchedules,
    active,
    inactive,
    unexpectedError
};

export default class AccountCaseScheduleIndicator extends LightningElement {
    @api recordId;
    labels = LABELS;
    indicator;
    errorMessage;

    @wire(getIndicator, { accountId: '$recordId' })
    wiredIndicator({ data, error }) {
        if (data) {
            this.indicator = data;
            this.errorMessage = null;
        } else if (error) {
            this.indicator = null;
            this.errorMessage = this.reduceError(error);
        }
    }

    get loading() {
        return !this.indicator && !this.errorMessage;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get hasData() {
        return !!this.indicator;
    }

    get stateClass() {
        if (!this.hasSchedules) return 'indicator-state indicator-state_neutral';
        return this.hasActiveSchedules
            ? 'indicator-state indicator-state_active'
            : 'indicator-state indicator-state_inactive';
    }

    get stateIcon() {
        if (!this.hasSchedules) return 'utility:dash';
        return this.hasActiveSchedules ? 'utility:success' : 'utility:pause';
    }

    get stateTitle() {
        if (!this.hasSchedules) return this.labels.indicatorNone;
        return this.hasActiveSchedules ? this.labels.indicatorActive : this.labels.indicatorInactive;
    }

    get countSummary() {
        if (!this.indicator) return '';
        return `${this.indicator.activeSchedules} ${this.labels.active} / ${this.indicator.inactiveSchedules} ${this.labels.inactive}`;
    }

    get hasSchedules() {
        return (this.indicator?.totalSchedules || 0) > 0;
    }

    get hasActiveSchedules() {
        return (this.indicator?.activeSchedules || 0) > 0;
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map((item) => item.message).join(', ');
        return error?.body?.message || error?.message || this.labels.unexpectedError;
    }
}