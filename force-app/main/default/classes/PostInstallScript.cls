global class PostInstallScript implements System.InstallHandler {
    
    global void onInstall(System.InstallContext context) {
        try {
            Id installingUserId = context.installerId();
            
            // Assign Visit_Intel_Access permission set to installer if available
            List<PermissionSet> permSets = [SELECT Id FROM PermissionSet WHERE Name = 'Visit_Intel_Access' LIMIT 1];
            if (!permSets.isEmpty() && installingUserId != null) {
                Id permSetId = permSets[0].Id;
                
                List<PermissionSetAssignment> existingAssignments = [
                    SELECT Id FROM PermissionSetAssignment 
                    WHERE AssigneeId = :installingUserId AND PermissionSetId = :permSetId 
                    LIMIT 1
                ];
                
                if (existingAssignments.isEmpty()) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(
                        AssigneeId = installingUserId,
                        PermissionSetId = permSetId
                    );
                    insert psa;
                }
            }

            // Automatically provision Agentforce Agents via Queueable API callout
            System.enqueueJob(new AgentProvisioningQueueable());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PostInstallScript Exception: ' + e.getMessage());
        }
    }
}
