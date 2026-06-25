global class VisitDateTimeWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='The datetime value.')
    global DateTime dateTimeValue;
    
    global VisitDateTimeWrapper() {}
}
