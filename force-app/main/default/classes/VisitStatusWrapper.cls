global class VisitStatusWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='The status value.')
    global String statusValue;
    
    global VisitStatusWrapper() {}
}
