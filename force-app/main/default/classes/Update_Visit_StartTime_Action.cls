public with sharing class Update_Visit_StartTime_Action {

    public class Request {
        @InvocableVariable(required=true description='The active Visit record ID.')
        public String visitId;
        @InvocableVariable(required=true description='The new planned start date and time.')
        public VisitDateTimeWrapper plannedStartTime;
    }

    public class Result {
        @InvocableVariable(description='True if the planned start time was successfully updated.')
        public Boolean success;
        @InvocableVariable(description='Result status message.')
        public String message;
    }

    @InvocableMethod(label='Update Visit Start Time' description='Update the planned start date and time of the current Visit.')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Visit_Agent_Handler.Request serviceReq = new Visit_Agent_Handler.Request();
            serviceReq.agentName = 'Visit_Intelligence';
            serviceReq.actionType = 'updateVisit';
            serviceReq.visitId = req.visitId;
            serviceReq.plannedStartTime = req.plannedStartTime != null ? req.plannedStartTime.dateTimeValue : null;
            
            Visit_Agent_Handler.Result serviceRes = Visit_Agent_Service.updateVisit(serviceReq);
            
            Result res = new Result();
            res.success = serviceRes.success;
            res.message = serviceRes.message;
            results.add(res);
        }
        return results;
    }
}
