import { LightningElement, api, wire } from 'lwc';
import getActiveUsers from '@salesforce/apex/Visit_Agent_Service.getActiveUsers';
import getVisitFieldValues from '@salesforce/apex/Visit_Agent_Service.getVisitFieldValues';

export default class VisitOwnerEditor extends LightningElement {
    @api value; // The raw input value object from the agent
    @api visitId;
    ownerOptions = [];
    _selectedOwner;

    @wire(getActiveUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.ownerOptions = data;
        } else if (error) {
            console.error('Error fetching users:', error);
        }
    }

    @wire(getVisitFieldValues, { visitId: '$visitId' })
    wiredVisit({ error, data }) {
        if (data && data.ownerId) {
            if (this._selectedOwner === undefined) {
                this._selectedOwner = data.ownerId;
                this.dispatchChange(data.ownerId);
            }
        } else if (error) {
            console.error('Error loading visit owner:', error);
        }
    }

    connectedCallback() {
        if (this.value && this.value.ownerName) {
            this._selectedOwner = this.value.ownerName;
        }
    }

    get selectedOwner() {
        return this._selectedOwner !== undefined ? this._selectedOwner : (this.value ? this.value.ownerName : '');
    }

    handleOwnerChange(event) {
        event.stopPropagation();
        this._selectedOwner = event.detail.value;
        this.dispatchChange(this._selectedOwner);
    }

    dispatchChange(val) {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    ownerName: val
                }
            }
        }));
    }
}
