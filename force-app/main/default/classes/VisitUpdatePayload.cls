/**
 * Data structure holding updated field values submitted from the
 * visit updater wizard component.
 */
global class VisitUpdatePayload {
    @AuraEnabled @InvocableVariable global String visitId;
    @AuraEnabled @InvocableVariable global String updatesJson;

    global VisitUpdatePayload() { /* empty block */ }
}