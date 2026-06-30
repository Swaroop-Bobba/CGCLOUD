import { LightningElement, api, wire } from 'lwc';
import searchAccounts from '@salesforce/apex/CreateVisitAction.searchAccounts';
import getAccountName from '@salesforce/apex/CreateVisitAction.getAccountName';
import getPlaceOptions from '@salesforce/apex/CreateVisitAction.getPlaceOptions';
import getTemplateOptions from '@salesforce/apex/CreateVisitAction.getTemplateOptions';
import getUserOptions from '@salesforce/apex/CreateVisitAction.getUserOptions';
import getCurrentUserInfo from '@salesforce/apex/CreateVisitAction.getCurrentUserInfo';

export default class CreateVisitEditor extends LightningElement {
    @api value; // Input value representing the CreateVisitWrapper

    isLoading = false;
    subject = '';
    accountId = '';
    plannedStartTime = null;
    placeId = '';
    visitTemplateId = '';
    plannedEndTime = null;
    isAllDayEvent = false;
    accountableId = '';
    
    responsibleId = '';
    responsibleName = '';

    accountSearchTerm = '';
    showAccountDropdown = false;
    isLoadingAccounts = false;
    filteredAccounts = [];
    searchTimeout;

    placeOptions = [];
    templateOptions = [];
    userOptions = [];

    @wire(getPlaceOptions)
    wiredPlaces({ error, data }) {
        if (data) {
            this.placeOptions = data;
        } else if (error) {
            console.error('Error loading Places:', error);
        }
    }

    @wire(getTemplateOptions)
    wiredTemplates({ error, data }) {
        if (data) {
            this.templateOptions = data;
        } else if (error) {
            console.error('Error loading Templates:', error);
        }
    }

    @wire(getUserOptions)
    wiredUsers({ error, data }) {
        if (data) {
            this.userOptions = data;
        } else if (error) {
            console.error('Error loading Users:', error);
        }
    }

    @wire(getCurrentUserInfo)
    wiredCurrentUser({ error, data }) {
        if (data) {
            this.responsibleId = data.Id;
            this.responsibleName = data.Name;
            this.dispatchChange();
        } else if (error) {
            console.error('Error loading Current User:', error);
        }
    }

    connectedCallback() {
        // Initialize from value if provided
        if (this.value) {
            this.subject = this.value.subject || '';
            this.accountId = this.value.accountId || '';
            this.plannedStartTime = this.value.plannedStartTime || null;
            this.placeId = this.value.placeId || '';
            this.visitTemplateId = this.value.visitTemplateId || '';
            this.plannedEndTime = this.value.plannedEndTime || null;
            this.isAllDayEvent = this.value.isAllDayEvent || false;
            this.accountableId = this.value.accountableId || '';

            if (this.accountId) {
                getAccountName({ accountId: this.accountId })
                    .then(name => {
                        this.accountSearchTerm = name;
                    })
                    .catch(err => {
                        console.error('Error fetching account name:', err);
                    });
            }
        }
    }

    get isAccountListEmpty() {
        return !this.isLoadingAccounts && this.filteredAccounts.length === 0;
    }

    handleAccountSearch(event) {
        const term = event.target.value;
        this.accountSearchTerm = term;
        
        if (!term) {
            this.accountId = '';
            this.filteredAccounts = [];
            this.dispatchChange();
            return;
        }

        this.isLoadingAccounts = true;
        this.showAccountDropdown = true;

        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            searchAccounts({ searchTerm: term })
                .then(results => {
                    this.filteredAccounts = results;
                    this.isLoadingAccounts = false;
                })
                .catch(error => {
                    console.error('Error searching accounts:', error);
                    this.isLoadingAccounts = false;
                });
        }, 300);
    }

    handleAccountFocus() {
        this.showAccountDropdown = true;
        if (this.filteredAccounts.length === 0) {
            this.isLoadingAccounts = true;
            searchAccounts({ searchTerm: this.accountSearchTerm })
                .then(results => {
                    this.filteredAccounts = results;
                    this.isLoadingAccounts = false;
                })
                .catch(error => {
                    console.error('Error loading accounts:', error);
                    this.isLoadingAccounts = false;
                });
        }
    }

    handleAccountBlur() {
        // Delay closing so that the mousedown event selection registers first
        setTimeout(() => {
            this.showAccountDropdown = false;
        }, 250);
    }

    handleAccountSelect(event) {
        this.accountId = event.currentTarget.dataset.id;
        this.accountSearchTerm = event.currentTarget.dataset.label;
        this.showAccountDropdown = false;
        this.dispatchChange();
    }

    handleFieldChange(event) {
        const fieldName = event.target.name;
        this[fieldName] = event.target.value;
        this.dispatchChange();
    }

    handleCheckboxChange(event) {
        this.isAllDayEvent = event.target.checked;
        this.dispatchChange();
    }

    dispatchChange() {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    subject: this.subject,
                    accountId: this.accountId,
                    plannedStartTime: this.plannedStartTime,
                    placeId: this.placeId,
                    visitTemplateId: this.visitTemplateId,
                    plannedEndTime: this.plannedEndTime,
                    isAllDayEvent: this.isAllDayEvent,
                    accountableId: this.accountableId,
                    responsibleId: this.responsibleId
                }
            }
        }));
    }
}
