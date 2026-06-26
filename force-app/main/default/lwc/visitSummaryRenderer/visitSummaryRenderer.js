import { LightningElement, api, track } from 'lwc';
import { execute } from 'lightning/accApi';

export default class VisitSummaryRenderer extends LightningElement {
    @api value; // The raw VisitSummaryWrapper object
    @track feedbackMessage = '';

    get storeName() { return this.value ? this.value.storeName : ''; }
    get visitDate() { return this.value ? this.value.visitDate : ''; }
    get visitStatus() { return this.value ? this.value.visitStatus : ''; }
    get assignedUser() { return this.value ? this.value.assignedUser : ''; }
    
    get completedTasks() { return this.value && this.value.completedTasks != null ? this.value.completedTasks : 0; }
    get pendingTasks() { return this.value && this.value.pendingTasks != null ? this.value.pendingTasks : 0; }
    get totalTasks() { return this.completedTasks + this.pendingTasks; }

    get promotionsChecked() { return this.value && this.value.promotionsChecked != null ? this.value.promotionsChecked : 0; }
    get outOfStockIssues() { return this.value && this.value.outOfStockIssues != null ? this.value.outOfStockIssues : 0; }
    get ordersCreated() { return this.value && this.value.ordersCreated != null ? this.value.ordersCreated : 0; }
    
    get orderValue() { 
        if (this.value && this.value.orderValue != null) {
            return this.value.orderValue.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        }
        return '0.00'; 
    }

    get representativeNotes() { return this.value ? this.value.representativeNotes : ''; }
    get overallOutcome() { return this.value ? this.value.overallOutcome : ''; }

    get suggestions() {
        return this.value && this.value.suggestions ? this.value.suggestions : [];
    }

    get tasksProgressValue() {
        const total = this.totalTasks;
        if (total === 0) return 0;
        return Math.round((this.completedTasks / total) * 100);
    }

    get statusBadgeClass() {
        const status = this.visitStatus ? this.visitStatus.toLowerCase() : '';
        if (status === 'completed') {
            return 'slds-badge slds-badge_success slds-p-horizontal_small';
        } else if (status === 'inprogress') {
            return 'slds-badge slds-theme_warning slds-p-horizontal_small';
        } else if (status === 'planned') {
            return 'slds-badge slds-badge_lightest slds-p-horizontal_small';
        }
        return 'slds-badge slds-p-horizontal_small';
    }

    async handleChipClick(event) {
        const command = event.currentTarget.dataset.command;
        if (!command) return;

        try {
            await execute({ message: command });
            this.feedbackMessage = `Executing: "${command}"`;
        } catch (err) {
            try {
                await navigator.clipboard.writeText(command);
                this.feedbackMessage = `Copied! Paste in chat.`;
            } catch (clipErr) {
                this.feedbackMessage = `Command: "${command}"`;
            }
        }

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.feedbackMessage = '';
        }, 3000);
    }
}
