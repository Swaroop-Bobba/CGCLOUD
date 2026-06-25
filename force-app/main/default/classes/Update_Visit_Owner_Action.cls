public with sharing class Update_Visit_Owner_Action {

    public class Request {
        @InvocableVariable(required=true description='The active Visit record ID.')
        public String visitId;
        @InvocableVariable(required=true description='The new owner details.')
        public VisitOwnerWrapper owner;
    }

    public class Result {
        @InvocableVariable(description='True if the owner was successfully updated.')
        public Boolean success;
        @InvocableVariable(description='Result status message.')
        public String message;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getActiveUsers() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            for (User u : [SELECT Id, Name FROM User WHERE IsActive = true WITH USER_MODE ORDER BY Name LIMIT 100]) {
                options.add(new Map<String, String>{
                    'label' => u.Name,
                    'value' => u.Name
                });
            }
        } catch (Exception e) {
            System.debug('Error getting active users: ' + e.getMessage());
        }
        return options;
    }

    @InvocableMethod(label='Update Visit Owner' description='Assign the current Visit record to a different user.')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Visit_Agent_Handler.Request serviceReq = new Visit_Agent_Handler.Request();
            serviceReq.agentName = 'Visit_Intelligence';
            serviceReq.actionType = 'updateVisit';
            serviceReq.visitId = req.visitId;
            serviceReq.ownerName = req.owner != null ? req.owner.ownerName : null;
            
            Visit_Agent_Handler.Result serviceRes = Visit_Agent_Service.updateVisit(serviceReq);
            
            Result res = new Result();
            res.success = serviceRes.success;
            res.message = serviceRes.message;
            results.add(res);
        }
        return results;
    }
}
