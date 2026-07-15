import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class VisitNavigator extends NavigationMixin(LightningElement) {
    _value;

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
        if (val && val.visitId) {
            this.navigateToRecord(val.visitId);
        }
    }

    connectedCallback() {
        if (this._value && this._value.visitId) {
            this.navigateToRecord(this._value.visitId);
        }
    }

    navigateToRecord(recordId) {
        console.log('visitNavigator: Navigating to record:', recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}
