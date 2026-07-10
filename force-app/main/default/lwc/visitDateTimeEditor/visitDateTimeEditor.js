import { LightningElement, api, wire } from 'lwc';
import getVisitFieldValues from '@salesforce/apex/Visit_Agent_Service.getVisitFieldValues';

export default class VisitDateTimeEditor extends LightningElement {
    @api value; // The raw input value object from the agent
    @api visitId;
    @api plannedStartTimeStr;
    @api plannedEndTimeStr;
    _selectedDateTime;

    @wire(getVisitFieldValues, { visitId: '$visitId' })
    wiredVisit({ error, data }) {
        if (data) {
            if (this._selectedDateTime === undefined) {
                // Distinguish between start and end time based on which parameter is present
                let initialVal;
                if (this.plannedEndTimeStr !== undefined) {
                    initialVal = data.plannedEndTime;
                } else {
                    initialVal = data.plannedStartTime;
                }
                
                if (initialVal) {
                    this._selectedDateTime = initialVal;
                    this.dispatchChange(initialVal);
                }
            }
        } else if (error) {
            console.error('Error loading visit date/time:', error);
        }
    }

    connectedCallback() {
        if (this.value && this.value.dateTimeValue) {
            this._selectedDateTime = this.value.dateTimeValue;
        }
    }

    get dateTimeValue() {
        return this._selectedDateTime !== undefined ? this._selectedDateTime : (this.value ? this.value.dateTimeValue : '');
    }

    handleDateTimeChange(event) {
        event.stopPropagation();
        this._selectedDateTime = event.detail.value;
        this.dispatchChange(this._selectedDateTime);
    }

    dispatchChange(val) {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    dateTimeValue: val
                }
            }
        }));
    }
}
