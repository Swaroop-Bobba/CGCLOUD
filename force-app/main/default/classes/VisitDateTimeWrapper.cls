/**
 * @description Wrapper class for Visit DateTime properties.
 */
public class VisitDateTimeWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='The datetime value.')
    public DateTime dateTimeValue;

}
