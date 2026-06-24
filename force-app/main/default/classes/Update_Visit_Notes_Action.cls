public with sharing class Update_Visit_Notes_Action {
    public class Request {
        @InvocableVariable(required=true description='The active Visit record ID.')
        public String visitId;
        @InvocableVariable(required=true description='The notes text to append to the visit.')
        public String notes;
    }

    public class Result {
        @InvocableVariable(description='True if the notes were successfully updated.')
        public Boolean success;
        @InvocableVariable(description='Result status message.')
        public String message;
    }

    @InvocableMethod(label='Update Visit Notes' description='Update or append notes to the current Visit record.')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Visit_Agent_Handler.Request serviceReq = new Visit_Agent_Handler.Request();
            serviceReq.agentName = 'Visit_Intelligence';
            serviceReq.actionType = 'updateVisit';
            serviceReq.visitId = req.visitId;
            serviceReq.notes = req.notes;
            
            Visit_Agent_Handler.Result serviceRes = Visit_Agent_Service.updateVisit(serviceReq);
            
            Result res = new Result();
            res.success = serviceRes.success;
            res.message = serviceRes.message;
            results.add(res);
        }
        return results;
    }
}
