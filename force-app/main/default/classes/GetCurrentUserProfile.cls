/**
 * @description Service class to retrieve the current user's profile information.
 */
public with sharing class GetCurrentUserProfile implements IAgentService {
    @TestVisible private static Boolean forceException = false;

    /**
     * @description Executes the service logic to get the current user's profile.
     * @param req The agent request containing necessary context.
     * @return Agent_Response The response containing the profile name.
     */
    public Agent_Response execute(Agent_Request req) {
        Agent_Response res = new Agent_Response();
        res.success = true;

        try {
            if (Test.isRunningTest() && forceException) {
                throw new QueryException('Forced test exception');
            }
            Id profileId = UserInfo.getProfileId();
            List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId WITH USER_MODE LIMIT 1];
            res.profileName = !profiles.isEmpty() ? profiles[0].Name : 'Unknown';
        } catch (Exception e) {
            res.success = false;
            res.message = e.getMessage();
        }

        return res;
    }
}