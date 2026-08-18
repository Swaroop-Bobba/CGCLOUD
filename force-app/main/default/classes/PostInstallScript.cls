/**
 * Automatically assigns the Visit Intel Access permission set to package
 * installers upon package installation or upgrade.
 */
global class PostInstallScript implements System.InstallHandler {
    @TestVisible private static Boolean forceException = false;

    global void onInstall(System.InstallContext context) {
        try {
            if (Test.isRunningTest() && forceException) {
                throw new QueryException('Forced test exception');
            }
            Id installingUserId = context != null ? context.installerId() : UserInfo.getUserId();

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
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PostInstallScript Exception: ' + e.getMessage());
        }
    }
}