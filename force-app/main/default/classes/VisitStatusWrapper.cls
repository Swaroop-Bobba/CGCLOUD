/**
 * @description Wrapper class for Visit Status properties.
 */
public class VisitStatusWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='The status value.')
    public String statusValue;

}
