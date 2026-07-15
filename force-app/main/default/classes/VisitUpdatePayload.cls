global class VisitUpdatePayload {
    @AuraEnabled @InvocableVariable global String visitId;
    @AuraEnabled @InvocableVariable global String updatesJson;

    global VisitUpdatePayload() { /* empty block */ }
}