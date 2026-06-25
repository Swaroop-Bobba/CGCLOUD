global class VisitOwnerWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='The owner name.')
    global String ownerName;
    
    global VisitOwnerWrapper() {}
}
