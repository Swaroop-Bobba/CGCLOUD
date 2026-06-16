public class CreateOnboardingTasksAction {
    public class Request {
        @InvocableVariable(label='Account ID' required=true)
        public String accountId;
    }
    
    public class Result {
        @InvocableVariable(label='Tasks Created')
        public Decimal tasksCreated;
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Create Onboarding Tasks' description='Creates Sales, Finance, and Distribution tasks for a new account')
    public static List<Result> createTasks(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            try {
                List<cgcloud__Account_Task__c> tasksToInsert = new List<cgcloud__Account_Task__c>();
                
                // Sales Tasks
                tasksToInsert.add(new cgcloud__Account_Task__c(cgcloud__Description_Language_1__c='Customer introduction', cgcloud__Account__c=req.accountId, cgcloud__Phase__c='Initial', cgcloud__Priority__c='B'));
                tasksToInsert.add(new cgcloud__Account_Task__c(cgcloud__Description_Language_1__c='Product discussion', cgcloud__Account__c=req.accountId, cgcloud__Phase__c='Initial', cgcloud__Priority__c='B'));
                tasksToInsert.add(new cgcloud__Account_Task__c(cgcloud__Description_Language_1__c='Initial visit scheduling', cgcloud__Account__c=req.accountId, cgcloud__Phase__c='Initial', cgcloud__Priority__c='B'));
                
                // Finance Tasks
                tasksToInsert.add(new cgcloud__Account_Task__c(cgcloud__Description_Language_1__c='Credit verification', cgcloud__Account__c=req.accountId, cgcloud__Phase__c='Initial', cgcloud__Priority__c='A'));
                tasksToInsert.add(new cgcloud__Account_Task__c(cgcloud__Description_Language_1__c='Payment setup', cgcloud__Account__c=req.accountId, cgcloud__Phase__c='Initial', cgcloud__Priority__c='A'));
                
                // Distribution Tasks
                tasksToInsert.add(new cgcloud__Account_Task__c(cgcloud__Description_Language_1__c='Delivery readiness verification', cgcloud__Account__c=req.accountId, cgcloud__Phase__c='Initial', cgcloud__Priority__c='B'));
                
                insert tasksToInsert;
                
                res.tasksCreated = tasksToInsert.size();
                res.success = true;
                res.errorMessage = '';
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
                res.tasksCreated = 0;
            }
            results.add(res);
        }
        return results;
    }
}
