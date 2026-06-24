public with sharing class Update_Visit_Status_Action {
    public class VisitStatusWrapper {
        @InvocableVariable(required=true description='The status value.')
        public String statusValue;
    }

    public class Request {
        @InvocableVariable(required=true description='The active Visit record ID.')
        public String visitId;
        @InvocableVariable(required=true description='The new status of the visit.')
        public VisitStatusWrapper status;
    }

    public class Result {
        @InvocableVariable(description='True if the status was successfully updated.')
        public Boolean success;
        @InvocableVariable(description='Result status message.')
        public String message;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getStatusOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            Schema.DescribeFieldResult fieldResult = Visit.Status.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry entry : ple) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        } catch (Exception e) {
            System.debug('Error getting status options: ' + e.getMessage());
        }
        return options;
    }

    @InvocableMethod(label='Update Visit Status' description='Update the status of the current Visit record.')
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Visit_Agent_Handler.Request serviceReq = new Visit_Agent_Handler.Request();
            serviceReq.agentName = 'Visit_Intelligence';
            serviceReq.actionType = 'updateVisit';
            serviceReq.visitId = req.visitId;
            serviceReq.status = req.status != null ? req.status.statusValue : null;
            
            Visit_Agent_Handler.Result serviceRes = Visit_Agent_Service.updateVisit(serviceReq);
            
            Result res = new Result();
            res.success = serviceRes.success;
            res.message = serviceRes.message;
            results.add(res);
        }
        return results;
    }
}
