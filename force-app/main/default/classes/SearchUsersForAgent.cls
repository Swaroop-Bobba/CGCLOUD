public with sharing class SearchUsersForAgent {
    public class Request {
        @InvocableVariable(required=true description='The search query for the user name.')
        public String searchQuery;
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

    public class Result {
        @InvocableVariable(description='List of matching users.')
        public List<UserOption> users;
    }

    @InvocableMethod(
        label='Search Users For Agent'
        description='Search for users by name to retrieve details like ID, Alias, and Profile.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            Result res = new Result();
            res.users = new List<UserOption>();
            
            if (String.isNotBlank(req.searchQuery)) {
                String searchStr = '%' + req.searchQuery.trim() + '%';
                
                List<User> userRecords = [
                    SELECT Id, Name, Alias, Profile.Name 
                    FROM User 
                    WHERE Name LIKE :searchStr 
                    AND IsActive = true 
                    WITH USER_MODE 
                    LIMIT 10
                ];
                
                for (User u : userRecords) {
                    UserOption opt = new UserOption();
                    opt.userId = u.Id;
                    opt.name = u.Name;
                    opt.alias = u.Alias;
                    opt.profileName = u.Profile.Name;
                    res.users.add(opt);
                }
            }
            results.add(res);
        }
        
        return results;
    }
}