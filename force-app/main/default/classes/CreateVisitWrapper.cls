global class CreateVisitWrapper {
    @AuraEnabled
    @InvocableVariable(description='The Subject of the visit')
    global String subject;

    @AuraEnabled
    @InvocableVariable(description='The Account ID associated with the visit')
    global String accountId;

    @AuraEnabled
    @InvocableVariable(description='The Planned Visit Start Time')
    global DateTime plannedStartTime;

    @AuraEnabled
    @InvocableVariable(description='The Place ID associated with the visit')
    global String placeId;

    @AuraEnabled
    @InvocableVariable(description='The Visit Template ID')
    global String visitTemplateId;

    @AuraEnabled
    @InvocableVariable(description='The Planned End Time')
    global DateTime plannedEndTime;

    @AuraEnabled
    @InvocableVariable(description='Is this an all day event?')
    global Boolean isAllDayEvent;

    @AuraEnabled
    @InvocableVariable(description='The Accountable User ID')
    global String accountableId;

    @AuraEnabled
    @InvocableVariable(description='The Responsible User ID')
    global String responsibleId;

    global CreateVisitWrapper() {}
}
