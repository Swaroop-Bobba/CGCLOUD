public with sharing class User_Agent_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request (e.g. CGC_Intelligence or Visit_Intelligence).')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform.')
        public String actionType; // 'search'

        @InvocableVariable(required=true description='The search query for the user name.')
        public String searchQuery;
    }

    public class Result {
        @InvocableVariable(description='List of matching users.')
        public List<UserOption> users;
    }

    public class UserOption {
        @InvocableVariable(description='The User ID.')
        public String userId;
        
        @InvocableVariable(description='The User Name.')
        public String name;
        
        @InvocableVariable(description='The User Alias.')
        public String alias;

        @InvocableVariable(description='The Profile Name of the User.')
        public String profileName;
    }

    @InvocableMethod(
        label='User Agent Handler'
        description='Handles all User operations for Agents'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'search') {
                res.users = User_Agent_Service.searchUsers(req.searchQuery);
            }
            results.add(res);
        }
        return results;
    }
}
