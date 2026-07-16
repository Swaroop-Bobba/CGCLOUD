/**
 * @description Wrapper class containing the Visit ID to navigate to via Agentforce custom renderer.
 */
public with sharing class VisitNavigationWrapper {
    @AuraEnabled
    @InvocableVariable(description='The Visit ID to navigate to.')
    public String visitId;

    /**
     * @description Default empty constructor.
     */
    public VisitNavigationWrapper() {}

    /**
     * @description Parameterized constructor.
     * @param visitId The ID of the Visit record.
     */
    public VisitNavigationWrapper(String visitId) {
        this.visitId = visitId;
    }
}
