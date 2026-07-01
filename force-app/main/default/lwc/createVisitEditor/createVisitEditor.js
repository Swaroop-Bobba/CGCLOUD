import { LightningElement, api, wire } from 'lwc';
import searchAccounts from '@salesforce/apex/CreateVisitAction.searchAccounts';
import getAccountName from '@salesforce/apex/CreateVisitAction.getAccountName';
import searchPlaces from '@salesforce/apex/CreateVisitAction.searchPlaces';
import getPlaceName from '@salesforce/apex/CreateVisitAction.getPlaceName';
import searchTemplates from '@salesforce/apex/CreateVisitAction.searchTemplates';
import getTemplateName from '@salesforce/apex/CreateVisitAction.getTemplateName';
import searchUsers from '@salesforce/apex/CreateVisitAction.searchUsers';
import getUserName from '@salesforce/apex/CreateVisitAction.getUserName';
import getResponsibleUserContext from '@salesforce/apex/CreateVisitAction.getResponsibleUserContext';

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

    isCGCloudUser = false;
    isNarrow = false;
    resizeObserver;

    // Account Lookup Variables
    accountSearchTerm = '';
    showAccountDropdown = false;
    isLoadingAccounts = false;
    filteredAccounts = [];
    accountSearchTimeout;

    // Place Lookup Variables
    placeSearchTerm = '';
    showPlaceDropdown = false;
    isLoadingPlaces = false;
    filteredPlaces = [];
    placeSearchTimeout;

    // Template Lookup Variables
    templateSearchTerm = '';
    showTemplateDropdown = false;
    isLoadingTemplates = false;
    filteredTemplates = [];
    templateSearchTimeout;

    // Accountable User Lookup Variables
    accountableSearchTerm = '';
    showAccountableDropdown = false;
    isLoadingAccountable = false;
    filteredAccountable = [];
    accountableSearchTimeout;

    // Responsible User Lookup Variables
    responsibleSearchTerm = '';
    showResponsibleDropdown = false;
    isLoadingResponsible = false;
    filteredResponsible = [];
    responsibleSearchTimeout;

    @wire(getResponsibleUserContext)
    wiredResponsibleContext({ error, data }) {
        if (data) {
            this.isCGCloudUser = data.isCGCloudUser;
            if (this.isCGCloudUser) {
                // If CG Cloud user, auto-assign and make read-only
                this.responsibleId = data.userId;
                this.responsibleName = data.userName;
            } else {
                // If not CG Cloud user, default to current user as selected option initially, but let them search/change it
                if (!this.responsibleId) {
                    this.responsibleId = data.userId;
                    this.responsibleSearchTerm = data.userName;
                }
            }
            this.dispatchChange();
        } else if (error) {
            console.error('Error loading Responsible User Context:', error);
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
            this.responsibleId = this.value.responsibleId || '';

            if (this.accountId) {
                getAccountName({ accountId: this.accountId })
                    .then(name => {
                        this.accountSearchTerm = name;
                    })
                    .catch(err => console.error('Error fetching account name:', err));
            }

            if (this.placeId) {
                getPlaceName({ placeId: this.placeId })
                    .then(name => {
                        this.placeSearchTerm = name;
                    })
                    .catch(err => console.error('Error fetching place name:', err));
            }

            if (this.visitTemplateId) {
                getTemplateName({ templateId: this.visitTemplateId })
                    .then(name => {
                        this.templateSearchTerm = name;
                    })
                    .catch(err => console.error('Error fetching template name:', err));
            }

            if (this.accountableId) {
                getUserName({ userId: this.accountableId })
                    .then(name => {
                        this.accountableSearchTerm = name;
                    })
                    .catch(err => console.error('Error fetching accountable user name:', err));
            }

            if (this.responsibleId) {
                getUserName({ userId: this.responsibleId })
                    .then(name => {
                        this.responsibleSearchTerm = name;
                        this.responsibleName = name;
                    })
                    .catch(err => console.error('Error fetching responsible user name:', err));
            }
        }
    }

    // ==========================================
    // Account Lookup Search Handlers
    // ==========================================
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

        clearTimeout(this.accountSearchTimeout);
        this.accountSearchTimeout = setTimeout(() => {
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

    // ==========================================
    // Place Lookup Search Handlers
    // ==========================================
    get isPlaceListEmpty() {
        return !this.isLoadingPlaces && this.filteredPlaces.length === 0;
    }

    handlePlaceSearch(event) {
        const term = event.target.value;
        this.placeSearchTerm = term;
        
        if (!term) {
            this.placeId = '';
            this.filteredPlaces = [];
            this.dispatchChange();
            return;
        }

        this.isLoadingPlaces = true;
        this.showPlaceDropdown = true;

        clearTimeout(this.placeSearchTimeout);
        this.placeSearchTimeout = setTimeout(() => {
            searchPlaces({ searchTerm: term })
                .then(results => {
                    this.filteredPlaces = results;
                    this.isLoadingPlaces = false;
                })
                .catch(error => {
                    console.error('Error searching places:', error);
                    this.isLoadingPlaces = false;
                });
        }, 300);
    }

    handlePlaceFocus() {
        this.showPlaceDropdown = true;
        if (this.filteredPlaces.length === 0) {
            this.isLoadingPlaces = true;
            searchPlaces({ searchTerm: this.placeSearchTerm })
                .then(results => {
                    this.filteredPlaces = results;
                    this.isLoadingPlaces = false;
                })
                .catch(error => {
                    console.error('Error loading places:', error);
                    this.isLoadingPlaces = false;
                });
        }
    }

    handlePlaceBlur() {
        setTimeout(() => {
            this.showPlaceDropdown = false;
        }, 250);
    }

    handlePlaceSelect(event) {
        this.placeId = event.currentTarget.dataset.id;
        this.placeSearchTerm = event.currentTarget.dataset.label;
        this.showPlaceDropdown = false;
        this.dispatchChange();
    }

    // ==========================================
    // Template Lookup Search Handlers
    // ==========================================
    get isTemplateListEmpty() {
        return !this.isLoadingTemplates && this.filteredTemplates.length === 0;
    }

    handleTemplateSearch(event) {
        const term = event.target.value;
        this.templateSearchTerm = term;
        
        if (!term) {
            this.visitTemplateId = '';
            this.filteredTemplates = [];
            this.dispatchChange();
            return;
        }

        this.isLoadingTemplates = true;
        this.showTemplateDropdown = true;

        clearTimeout(this.templateSearchTimeout);
        this.templateSearchTimeout = setTimeout(() => {
            searchTemplates({ searchTerm: term })
                .then(results => {
                    this.filteredTemplates = results;
                    this.isLoadingTemplates = false;
                })
                .catch(error => {
                    console.error('Error searching templates:', error);
                    this.isLoadingTemplates = false;
                });
        }, 300);
    }

    handleTemplateFocus() {
        this.showTemplateDropdown = true;
        if (this.filteredTemplates.length === 0) {
            this.isLoadingTemplates = true;
            searchTemplates({ searchTerm: this.templateSearchTerm })
                .then(results => {
                    this.filteredTemplates = results;
                    this.isLoadingTemplates = false;
                })
                .catch(error => {
                    console.error('Error loading templates:', error);
                    this.isLoadingTemplates = false;
                });
        }
    }

    handleTemplateBlur() {
        setTimeout(() => {
            this.showTemplateDropdown = false;
        }, 250);
    }

    handleTemplateSelect(event) {
        this.visitTemplateId = event.currentTarget.dataset.id;
        this.templateSearchTerm = event.currentTarget.dataset.label;
        this.showTemplateDropdown = false;
        this.dispatchChange();
    }

    // ==========================================
    // Accountable User Lookup Search Handlers
    // ==========================================
    get isAccountableListEmpty() {
        return !this.isLoadingAccountable && this.filteredAccountable.length === 0;
    }

    handleAccountableSearch(event) {
        const term = event.target.value;
        this.accountableSearchTerm = term;
        
        if (!term) {
            this.accountableId = '';
            this.filteredAccountable = [];
            this.dispatchChange();
            return;
        }

        this.isLoadingAccountable = true;
        this.showAccountableDropdown = true;

        clearTimeout(this.accountableSearchTimeout);
        this.accountableSearchTimeout = setTimeout(() => {
            searchUsers({ searchTerm: term })
                .then(results => {
                    this.filteredAccountable = results;
                    this.isLoadingAccountable = false;
                })
                .catch(error => {
                    console.error('Error searching users:', error);
                    this.isLoadingAccountable = false;
                });
        }, 300);
    }

    handleAccountableFocus() {
        this.showAccountableDropdown = true;
        if (this.filteredAccountable.length === 0) {
            this.isLoadingAccountable = true;
            searchUsers({ searchTerm: this.accountableSearchTerm })
                .then(results => {
                    this.filteredAccountable = results;
                    this.isLoadingAccountable = false;
                })
                .catch(error => {
                    console.error('Error loading users:', error);
                    this.isLoadingAccountable = false;
                });
        }
    }

    handleAccountableBlur() {
        setTimeout(() => {
            this.showAccountableDropdown = false;
        }, 250);
    }

    handleAccountableSelect(event) {
        this.accountableId = event.currentTarget.dataset.id;
        this.accountableSearchTerm = event.currentTarget.dataset.label;
        this.showAccountableDropdown = false;
        this.dispatchChange();
    }

    // ==========================================
    // Responsible User Lookup Search Handlers
    // ==========================================
    get isResponsibleListEmpty() {
        return !this.isLoadingResponsible && this.filteredResponsible.length === 0;
    }

    handleResponsibleSearch(event) {
        const term = event.target.value;
        this.responsibleSearchTerm = term;
        
        if (!term) {
            this.responsibleId = '';
            this.filteredResponsible = [];
            this.dispatchChange();
            return;
        }

        this.isLoadingResponsible = true;
        this.showResponsibleDropdown = true;

        clearTimeout(this.responsibleSearchTimeout);
        this.responsibleSearchTimeout = setTimeout(() => {
            searchUsers({ searchTerm: term })
                .then(results => {
                    this.filteredResponsible = results;
                    this.isLoadingResponsible = false;
                })
                .catch(error => {
                    console.error('Error searching responsible users:', error);
                    this.isLoadingResponsible = false;
                });
        }, 300);
    }

    handleResponsibleFocus() {
        this.showResponsibleDropdown = true;
        if (this.filteredResponsible.length === 0) {
            this.isLoadingResponsible = true;
            searchUsers({ searchTerm: this.responsibleSearchTerm })
                .then(results => {
                    this.filteredResponsible = results;
                    this.isLoadingResponsible = false;
                })
                .catch(error => {
                    console.error('Error loading responsible users:', error);
                    this.isLoadingResponsible = false;
                });
        }
    }

    handleResponsibleBlur() {
        setTimeout(() => {
            this.showResponsibleDropdown = false;
        }, 250);
    }

    handleResponsibleSelect(event) {
        this.responsibleId = event.currentTarget.dataset.id;
        this.responsibleSearchTerm = event.currentTarget.dataset.label;
        this.showResponsibleDropdown = false;
        this.dispatchChange();
    }

    // ==========================================
    // Generic Field Change Handlers
    // ==========================================
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

    renderedCallback() {
        if (!this.resizeObserver) {
            const container = this.template.querySelector('.create-visit-card');
            if (container) {
                this.resizeObserver = new ResizeObserver(entries => {
                    for (let entry of entries) {
                        const width = entry.contentRect.width;
                        // Set narrow threshold to 480px width
                        this.isNarrow = width < 480;
                    }
                });
                this.resizeObserver.observe(container);
            }
        }
    }

    disconnectedCallback() {
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
    }

    get columnClassName() {
        return this.isNarrow 
            ? 'slds-col slds-size_1-of-1 slds-p-bottom_small' 
            : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-p-bottom_small';
    }
}
