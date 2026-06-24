import { LightningElement, api, wire } from 'lwc';
import getActiveUsers from '@salesforce/apex/Update_Visit_Owner_Action.getActiveUsers';

export default class VisitOwnerEditor extends LightningElement {
    @api value; // The raw input value object from the agent
    ownerOptions = [];

    @wire(getActiveUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.ownerOptions = data;
        } else if (error) {
            console.error('Error fetching users:', error);
        }
    }

    get selectedOwner() {
        return this.value ? this.value.ownerName : '';
    }

    handleOwnerChange(event) {
        event.stopPropagation();
        const selectedValue = event.detail.value;
        
        // Notify Agentforce of the changed value
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    ownerName: selectedValue
                }
            }
        }));
    }
}
