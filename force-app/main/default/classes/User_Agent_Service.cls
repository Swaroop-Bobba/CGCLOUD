public with sharing class User_Agent_Service {

    // --- USER METHODS ---

    public static List<User_Agent_Handler.UserOption> searchUsers(String searchQuery) {
        List<User_Agent_Handler.UserOption> options = new List<User_Agent_Handler.UserOption>();
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
                User_Agent_Handler.UserOption opt = new User_Agent_Handler.UserOption();
                opt.userId = u.Id;
                opt.name = u.Name;
                opt.alias = u.Alias;
                opt.profileName = u.Profile.Name;
                options.add(opt);
            }
        } catch (Exception e) {}
        return options;
    }
}