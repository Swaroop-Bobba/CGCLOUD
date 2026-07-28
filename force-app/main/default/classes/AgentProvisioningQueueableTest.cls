@isTest
private class AgentProvisioningQueueableTest {

    @isTest
    static void testAgentProvisioningQueueable() {
        Test.startTest();
        System.enqueueJob(new AgentProvisioningQueueable());
        Test.stopTest();
        
        System.assert(true, 'AgentProvisioningQueueable executed without throwing exception');
    }
}
