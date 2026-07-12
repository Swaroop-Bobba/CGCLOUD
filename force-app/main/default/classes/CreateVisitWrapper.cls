/**
 * @description Wrapper class containing all data required to create a new Visit.
 */
public class CreateVisitWrapper {
    @AuraEnabled
    @InvocableVariable(description='The Subject of the visit')
    public String subject;

    @AuraEnabled
    @InvocableVariable(description='The Account ID associated with the visit')
    public String accountId;

    @AuraEnabled
    @InvocableVariable(description='The Planned Visit Start Time')
    public DateTime plannedStartTime;

    @AuraEnabled
    @InvocableVariable(description='The Place ID associated with the visit')
    public String placeId;

    @AuraEnabled
    @InvocableVariable(description='The Visit Template ID')
    public String visitTemplateId;

    @AuraEnabled
    @InvocableVariable(description='The Planned End Time')
    public DateTime plannedEndTime;

    @AuraEnabled
    @InvocableVariable(description='Is this an all day event?')
    public Boolean isAllDayEvent;

    @AuraEnabled
    @InvocableVariable(description='The Accountable User ID')
    public String accountableId;

    @AuraEnabled
    @InvocableVariable(description='The Responsible User ID')
    public String responsibleId;

}
