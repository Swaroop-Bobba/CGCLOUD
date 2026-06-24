import { LightningElement, api, wire } from 'lwc';
import getStatusOptions from '@salesforce/apex/Update_Visit_Status_Action.getStatusOptions';

export default class VisitStatusEditor extends LightningElement {
    @api value; // The raw input value object from the agent
    statusOptions = [];

    @wire(getStatusOptions)
    wiredStatus({ error, data }) {
        if (data) {
            this.statusOptions = data;
        } else if (error) {
            console.error('Error fetching status options:', error);
        }
    }

    get statusValue() {
        return this.value ? this.value.statusValue : '';
    }

    handleStatusChange(event) {
        event.stopPropagation();
        const selectedValue = event.detail.value;
        
        // Notify Agentforce of the changed value
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    statusValue: selectedValue
                }
            }
        }));
    }
}
