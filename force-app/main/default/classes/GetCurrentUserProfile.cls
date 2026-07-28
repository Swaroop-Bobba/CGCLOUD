/**
 * @description Service class to retrieve the current user's profile information.
 */
public with sharing class GetCurrentUserProfile implements IAgentService {

    /**
     * @description Executes the service logic to get the current user's profile.
     * @param req The agent request containing necessary context.
     * @return Agent_Response The response containing the profile name.
     */
    public Agent_Response execute(Agent_Request req) {
        Agent_Response res = new Agent_Response();
        res.success = true;

        try {
            Id profileId = UserInfo.getProfileId();
            List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId WITH USER_MODE LIMIT 1];

            if (!profiles.isEmpty()) {
                res.profileName = profiles[0].Name;
            } else {
                res.profileName = 'Unknown';
            }
        } catch (Exception e) {
            res.success = false;
            res.message = e.getMessage();
        }

        return res;
    }
}