public class AssignAccountManagerAction {
    public class Request {
        @InvocableVariable(label='Account ID' required=true)
        public String accountId;
        @InvocableVariable(label='Search Name' required=false)
        public String searchName;
    }
    
    public class Result {
        @InvocableVariable(label='Assigned User ID')
        public String assignedUserId;
        @InvocableVariable(label='Assigned User Name')
        public String assignedUserName;
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Assign Account Manager' description='Searches and assigns an Account Manager')
    public static List<Result> assignManager(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            try {
                // Determine user to assign
                User assignedUser = null;
                if (String.isNotBlank(req.searchName)) {
                    List<User> users = [SELECT Id, Name FROM User WHERE Name LIKE :('%' + req.searchName + '%') AND IsActive = true LIMIT 1];
                    if (!users.isEmpty()) {
                        assignedUser = users[0];
                    }
                }
                
                // If not found or not provided, default to running user
                if (assignedUser == null) {
                    assignedUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                }
                
                // Create Account Manager record
                cgcloud__Account_Manager__c am = new cgcloud__Account_Manager__c(
                    cgcloud__Account__c = req.accountId,
                    cgcloud__User__c = assignedUser.Id,
                    cgcloud__Valid_From__c = Date.today(),
                    cgcloud__Valid_Thru__c = Date.newInstance(2099, 12, 31)
                );
                insert am;
                
                res.assignedUserId = assignedUser.Id;
                res.assignedUserName = assignedUser.Name;
                res.success = true;
                res.errorMessage = '';
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
