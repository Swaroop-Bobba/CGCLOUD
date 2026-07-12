import { LightningElement, api, wire } from 'lwc';
import getVisitFieldValues from '@salesforce/apex/Visit_Agent_Service.getVisitFieldValues';

export default class VisitStatusEditor extends LightningElement {
    @api value; // The raw input value object from the agent
    @api visitId;
    _selectedValue;

    statusOptions = [
        { label: 'Planned', value: 'Planned' },
        { label: 'In Progress', value: 'InProgress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Canceled', value: 'Canceled' },
        { label: 'Abandoned', value: 'Abandoned' }
    ];

    @wire(getVisitFieldValues, { visitId: '$visitId' })
    wiredVisit({ error, data }) {
        if (data && data.status) {
            if (this._selectedValue === undefined) {
                this._selectedValue = data.status;
                this.dispatchChange(data.status);
            }
        } else if (error) {
            console.error('Error loading visit status:', error);
        }
    }

    connectedCallback() {
        if (this.value && this.value.statusValue) {
            this._selectedValue = this.value.statusValue;
        }
    }

    get statusValue() {
        return this._selectedValue !== undefined ? this._selectedValue : (this.value ? this.value.statusValue : '');
    }

    handleStatusChange(event) {
        event.stopPropagation();
        this._selectedValue = event.detail.value;
        this.dispatchChange(this._selectedValue);
    }

    dispatchChange(val) {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    statusValue: val
                }
            }
        }));
    }
}
