import { LightningElement, api } from 'lwc';

export default class VisitStatusEditor extends LightningElement {
    @api value; // The raw input value object from the agent
    _selectedValue;

    statusOptions = [
        { label: 'Planned', value: 'Planned' },
        { label: 'In Progress', value: 'InProgress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Abandoned', value: 'Abandoned' }
    ];

    get statusValue() {
        return this._selectedValue !== undefined ? this._selectedValue : (this.value ? this.value.statusValue : '');
    }

    handleStatusChange(event) {
        event.stopPropagation();
        this._selectedValue = event.detail.value;
        
        // Notify Agentforce of the changed value
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    statusValue: this._selectedValue
                }
            }
        }));
    }
}
