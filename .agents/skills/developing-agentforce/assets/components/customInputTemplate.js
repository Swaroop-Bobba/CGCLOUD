import { LightningElement, api } from 'lwc';

export default class CustomInputTemplate extends LightningElement {
    @api value; // The raw input value object from the agent
    _selectedValue;

    // Dispatch the valuechange custom event on user action
    handleValueChange(event) {
        event.stopPropagation();
        this._selectedValue = event.detail.value;
        
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    valuePlaceholder: this._selectedValue
                }
            }
        }));
    }
}
