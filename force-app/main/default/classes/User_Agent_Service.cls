/**
 * @description Service class to handle user-related agent actions.
 */
public with sharing class User_Agent_Service implements IAgentService {

    /**
     * @description Executes user agent actions based on the provided request.
     * @param req The incoming agent request containing action type and payload.
     * @return Agent_Response The result of the user action execution.
     */
    public Agent_Response execute(Agent_Request req) {
        Agent_Response res = new Agent_Response();
        res.success = true;

        String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

        try {
            if (action == 'search') {
                res.users = searchUsers(req.searchQuery);
            } else {
                res.success = false;
                res.message = 'Unknown actionType: ' + action;
            }
        } catch (Exception e) {
            res.success = false;
            res.message = e.getMessage();
        }

        return res;
    }

    /**
     * @description Searches for active users by name.
     * @param searchQuery The search string to match against User Name.
     * @return List<Agent_Response.UserOption> A list of matched user options.
     */
    @SuppressWarnings('PMD.AvoidDebugStatements')
    public static List<Agent_Response.UserOption> searchUsers(String searchQuery) {
        List<Agent_Response.UserOption> options = new List<Agent_Response.UserOption>();
        if (String.isBlank(searchQuery)) {
            return options;
        }

        try {
            String searchStr = '%' + searchQuery.trim() + '%';
            List<User> userRecords = [
                SELECT Id, Name, Alias, Profile.Name
                FROM User
                WHERE Name LIKE :searchStr
                AND IsActive = true
                WITH USER_MODE
                LIMIT 10
            ];

            for (User u : userRecords) {
                Agent_Response.UserOption opt = new Agent_Response.UserOption();
                opt.userId = u.Id;
                opt.name = u.Name;
                opt.alias = u.Alias;
                opt.profileName = u.Profile.Name;
                options.add(opt);
            }
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        return options;
    }
}