/**
 * @description Wrapper class for Visit Owner properties.
 */
public class VisitOwnerWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='The owner name.')
    public String ownerName;

}
