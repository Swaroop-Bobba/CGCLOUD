import { LightningElement, api } from 'lwc';

export default class VisitDateTimeEditor extends LightningElement {
    @api value; // The raw input value object from the agent

    get dateTimeValue() {
        return this.value ? this.value.dateTimeValue : '';
    }

    handleDateTimeChange(event) {
        event.stopPropagation();
        const selectedValue = event.detail.value;
        
        // Notify Agentforce of the changed value
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    dateTimeValue: selectedValue
                }
            }
        }));
    }
}
