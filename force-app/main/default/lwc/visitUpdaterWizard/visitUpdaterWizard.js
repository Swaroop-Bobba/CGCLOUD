import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getActiveUsers from '@salesforce/apex/VisitUpdaterController.getActiveUsers';
import getVisitDetails from '@salesforce/apex/VisitUpdaterController.getVisitDetails';
import updateVisitRecord from '@salesforce/apex/VisitUpdaterController.updateVisitRecord';

export default class VisitUpdaterWizard extends LightningElement {
    _value;
    _visitId;

    @api 
    get value() {
        return this._value;
    }
    set value(val) {
        console.log('visitUpdaterWizard: value setter called with', JSON.stringify(val));
        this._value = val;
        if (val) {
            if (val.updatesJson) {
                console.log('visitUpdaterWizard: updatesJson detected. Freezing on Step 4 (finalized state).');
                this.currentStep = '4';
                this.isConfirming = true;
            }
            if (val.visitId && this.isValidId(val.visitId) && val.visitId !== this.selectedVisitId) {
                this.selectedVisitId = val.visitId;
                this.originalVisit = null;
                this.loadVisitDetails(val.visitId);
            }
        }
    }

    @api 
    get visitId() {
        return this._visitId;
    }
    set visitId(val) {
        console.log('visitUpdaterWizard: visitId setter called with', val);
        this._visitId = val;
        if (val && this.isValidId(val) && val !== this.selectedVisitId) {
            this.selectedVisitId = val;
            this.originalVisit = null;
            this.loadVisitDetails(val);
        }
    }
    
    @track currentStep = '1';
    @track isLoading = true;
    @track userOptions = [];
    
    @track selectedVisitId = '';
    @track selectedVisit = null;
    @track originalVisit = null;
    
    @track selectedFields = {
        cgcloud__Subject__c: false,
        Status: false,
        PlannedVisitStartTime: false,
        PlannedVisitEndTime: false,
        cgcloud__Responsible__c: false,
        cgcloud__Accountable__c: false,
        cgcloud__Note__c: false
    };

    @track fieldValues = {
        cgcloud__Subject__c: '',
        Status: '',
        PlannedVisitStartTime: '',
        PlannedVisitEndTime: '',
        cgcloud__Responsible__c: '',
        cgcloud__Accountable__c: '',
        cgcloud__Note__c: ''
    };

    isConfirming = false;

    statusOptions = [
        { label: 'Planned', value: 'Planned' },
        { label: 'In Progress', value: 'InProgress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Canceled', value: 'Canceled' },
        { label: 'Abandoned', value: 'Abandoned' }
    ];

    @wire(getActiveUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.userOptions = data;
        } else if (error) {
            console.error('Error loading active users:', error);
        }
    }

    @wire(CurrentPageReference)
    wireCurrentPageReference(currentPageReference) {
        console.log('visitUpdaterWizard: currentPageReference received:', JSON.stringify(currentPageReference));
        if (currentPageReference && currentPageReference.type === 'standard__recordPage') {
            const recId = currentPageReference.attributes?.recordId;
            if (recId && this.isValidId(recId) && String(recId).startsWith('0Z5') && !this.selectedVisitId) {
                console.log('visitUpdaterWizard: successfully resolved Visit ID from CurrentPageReference:', recId);
                this.selectedVisitId = recId;
                this.originalVisit = null;
                this.loadVisitDetails(recId);
            }
        }
    }

    connectedCallback() {
        console.log('visitUpdaterWizard: connectedCallback check. _value:', JSON.stringify(this._value), '_visitId:', this._visitId);
        let initialId = '';
        if (this._value && this._value.visitId) {
            initialId = this._value.visitId;
            if (this._value.updatesJson) {
                console.log('visitUpdaterWizard: updatesJson detected in connectedCallback. Freezing on Step 4.');
                this.currentStep = '4';
                this.isConfirming = true;
            }
        } else if (this._visitId) {
            initialId = this._visitId;
        }
        
        // Robust client-side fallback: parse active Visit ID directly from browser window URL
        if (!this.isValidId(initialId)) {
            const parsedId = this.extractVisitIdFromUrl();
            if (parsedId) {
                console.log('visitUpdaterWizard: successfully parsed Visit ID from browser URL:', parsedId);
                initialId = parsedId;
            }
        }
        
        if (this.isValidId(initialId)) {
            this.selectedVisitId = initialId;
            this.loadVisitDetails(initialId);
        } else {
            this.selectedVisitId = '';
            this.isLoading = false;
        }
    }

    extractVisitIdFromUrl() {
        try {
            const url = window.location.href;
            const match = url.match(/\/Visit\/([a-zA-Z0-9]{15,18})/i);
            if (match && match[1]) {
                return match[1];
            }
            // Fallback check for any 15/18 char word starting with 0Z5 key prefix
            const fallbackMatch = url.match(/\b(0Z5[a-zA-Z0-9]{12,15})\b/i);
            if (fallbackMatch && fallbackMatch[0]) {
                return fallbackMatch[0];
            }
        } catch (e) {
            console.error('visitUpdaterWizard: Error parsing browser URL context:', e);
        }
        return null;
    }

    isValidId(idVal) {
        if (!idVal) return false;
        const cleaned = String(idVal).trim();
        if (cleaned.toLowerCase() === 'none' || cleaned.toLowerCase() === 'null' || cleaned.toLowerCase() === 'undefined') {
            return false;
        }
        return (cleaned.length === 15 || cleaned.length === 18);
    }

    loadVisitDetails(visitId) {
        console.log('visitUpdaterWizard: loadVisitDetails started for ID:', visitId);
        this.isLoading = true;
        getVisitDetails({ visitId: visitId })
            .then(result => {
                console.log('visitUpdaterWizard: loadVisitDetails succeeded. Result:', JSON.stringify(result));
                this.isLoading = false;
                if (result) {
                    this.selectedVisit = result;
                    if (!this.originalVisit) {
                        this.originalVisit = JSON.parse(JSON.stringify(result));
                    }
                    if (!this.isConfirming) {
                        this.fieldValues.Status = result.status;
                        this.fieldValues.PlannedVisitStartTime = result.plannedStartTime;
                        this.fieldValues.PlannedVisitEndTime = result.plannedEndTime;
                        this.fieldValues.cgcloud__Responsible__c = result.responsibleUserId;
                        this.fieldValues.cgcloud__Accountable__c = result.accountableUserId;
                        this.fieldValues.cgcloud__Subject__c = result.subject;
                        this.fieldValues.cgcloud__Note__c = result.notes;
                    }
                } else {
                    console.warn('visitUpdaterWizard: loadVisitDetails returned null/empty record.');
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('visitUpdaterWizard: loadVisitDetails failed with error:', error);
            });
    }

    @track selectAllChecked = false;
    @track isCancelled = false;

    get isStep1() { return this.currentStep === '1'; }
    get isStep2() { return this.currentStep === '2'; }
    get isStep3() { return this.currentStep === '3'; }
    get isStep4() { return this.currentStep === '4'; }

    get showCancelButton() {
        return (this.currentStep === '1' || this.currentStep === '2' || this.currentStep === '3') && !this.isConfirming;
    }

    get showBackButton() {
        return this.currentStep === '2' || this.currentStep === '3';
    }

    get showNextButton() {
        return this.currentStep === '1' || this.currentStep === '2';
    }

    get selectedVisitName() {
        return this.selectedVisit ? `${this.selectedVisit.visitName} (${this.selectedVisit.accountName})` : 'Context Visit';
    }

    get isNextDisabled() {
        if (this.currentStep === '1') {
            // Must select at least one field
            return !Object.values(this.selectedFields).some(val => val === true);
        }
        return false;
    }

    handleSelectAllChange(event) {
        const isChecked = event.target.checked;
        this.selectAllChecked = isChecked;
        for (const key of Object.keys(this.selectedFields)) {
            this.selectedFields[key] = isChecked;
        }
        if (isChecked) {
            // Automatically proceed to step 2 when Select All is checked
            this.currentStep = '2';
        }
    }

    handleFieldCheckboxChange(event) {
        const fieldName = event.target.name;
        this.selectedFields[fieldName] = event.target.checked;
        this.selectAllChecked = Object.values(this.selectedFields).every(val => val === true);
    }

    handleCancelWizard() {
        console.log('visitUpdaterWizard: Cancel clicked. Transitioning to Step 4 with empty updates.');
        this.isCancelled = true;
        this.isConfirming = true;
        this.currentStep = '4';
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    visitId: this.selectedVisitId,
                    updatesJson: "{}"
                }
            }
        }));
    }

    handleValueChange(event) {
        const fieldName = event.target.name;
        this.fieldValues[fieldName] = event.target.value;
    }

    handleNext() {
        if (this.currentStep === '1') {
            this.currentStep = '2';
        } else if (this.currentStep === '2') {
            this.currentStep = '3';
        }
    }

    handleBack() {
        if (this.currentStep === '2') {
            this.currentStep = '1';
        } else if (this.currentStep === '3') {
            this.currentStep = '2';
        }
    }

    get previewChanges() {
        const changes = [];
        const baseVisit = this.originalVisit || this.selectedVisit;
        if (!baseVisit) return changes;

        const fieldLabels = {
            cgcloud__Subject__c: 'Subject',
            Status: 'Status',
            PlannedVisitStartTime: 'Start Date/Time',
            PlannedVisitEndTime: 'End Date/Time',
            cgcloud__Responsible__c: 'Responsible User',
            cgcloud__Accountable__c: 'Accountable User',
            cgcloud__Note__c: 'Notes'
        };

        for (const fieldName of Object.keys(this.selectedFields)) {
            if (this.selectedFields[fieldName]) {
                let currentValLabel = '';
                let newValLabel = '';

                if (fieldName === 'Status') {
                    currentValLabel = baseVisit.status;
                    newValLabel = this.fieldValues.Status;
                } else if (fieldName === 'PlannedVisitStartTime') {
                    currentValLabel = this.formatDate(baseVisit.plannedStartTime);
                    newValLabel = this.formatDate(this.fieldValues.PlannedVisitStartTime);
                } else if (fieldName === 'PlannedVisitEndTime') {
                    currentValLabel = this.formatDate(baseVisit.plannedEndTime);
                    newValLabel = this.formatDate(this.fieldValues.PlannedVisitEndTime);
                } else if (fieldName === 'cgcloud__Responsible__c') {
                    currentValLabel = baseVisit.responsibleUserName || 'None';
                    newValLabel = this.getUserLabel(this.fieldValues.cgcloud__Responsible__c);
                } else if (fieldName === 'cgcloud__Accountable__c') {
                    currentValLabel = baseVisit.accountableUserName || 'None';
                    newValLabel = this.getUserLabel(this.fieldValues.cgcloud__Accountable__c);
                } else if (fieldName === 'cgcloud__Subject__c') {
                    currentValLabel = baseVisit.subject || 'None';
                    newValLabel = this.getUserLabel(this.fieldValues.cgcloud__Subject__c);
                } else if (fieldName === 'cgcloud__Note__c') {
                    currentValLabel = baseVisit.notes || 'None';
                    newValLabel = this.fieldValues.cgcloud__Note__c || 'None';
                }

                changes.push({
                    fieldName: fieldName,
                    label: fieldLabels[fieldName],
                    current: currentValLabel,
                    newValue: newValLabel
                });
            }
        }
        return changes;
    }

    formatDate(dateStr) {
        if (!dateStr) return 'None';
        try {
            const date = new Date(dateStr);
            return date.toLocaleString();
        } catch {
            return dateStr;
        }
    }

    getUserLabel(userId) {
        if (!userId) return 'None';
        const found = this.userOptions.find(opt => opt.value === userId);
        return found ? found.label : userId;
    }

    handleConfirm() {
        this.isLoading = true;
        this.isConfirming = true;
        const updatesPayload = {};
        for (const fieldName of Object.keys(this.selectedFields)) {
            if (this.selectedFields[fieldName]) {
                updatesPayload[fieldName] = this.fieldValues[fieldName];
            }
        }
        updateVisitRecord({ visitId: this.selectedVisitId, updatesJson: JSON.stringify(updatesPayload) })
            .then(() => {
                this.isLoading = false;
                this.currentStep = '4';
                this.dispatchEvent(new CustomEvent('valuechange', {
                    detail: {
                        value: {
                            visitId: this.selectedVisitId,
                            updatesJson: JSON.stringify(updatesPayload)
                        }
                    }
                }));
            })
            .catch(error => {
                this.isLoading = false;
                this.isConfirming = false;
                console.error('Error updating visit record via AuraEnabled:', error);
            });
    }
}