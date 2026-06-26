public with sharing class Visit_Agent_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request (e.g. CGC_Intelligence or Visit_Intelligence).')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform.')
        public String actionType; // 'getAvailable', 'search', 'getStoreBrief', 'generateSummary', 'updateVisit'

        @InvocableVariable(description='The search query.')
        public String searchQuery;

        @InvocableVariable(description='The Account ID.')
        public String accountId;

        @InvocableVariable(description='The Visit ID.')
        public String visitId;

        // Fields for updateVisit
        @InvocableVariable(description='New status value.')
        public String status;

        @InvocableVariable(description='Representative notes to append.')
        public String notes;

        @InvocableVariable(description='Actual start date/time.')
        public DateTime startTime;

        @InvocableVariable(description='Actual end date/time.')
        public DateTime endTime;

        @InvocableVariable(description='Name of the user to assign.')
        public String ownerName;

        @InvocableVariable(description='Record ID of the user to assign.')
        public String ownerId;

        @InvocableVariable(description='Alias of the user to assign.')
        public String ownerAlias;

        @InvocableVariable(description='Profile Name of the user to assign.')
        public String ownerProfileName;

        @InvocableVariable(description='New planned start date/time.')
        public DateTime plannedStartTime;

        @InvocableVariable(description='New planned end date/time.')
        public DateTime plannedEndTime;
    }

    public class Result {
        @InvocableVariable(description='List of available/matching visits.')
        public List<VisitOption> visits;

        @InvocableVariable(description='Store brief markdown summary.')
        public String summary;

        @InvocableVariable(description='Visit summary report.')
        public String visitSummary;

        @InvocableVariable(description='Visit summary wrapper object.')
        public VisitSummaryWrapper visitSummaryObj;

        // Update outcome
        @InvocableVariable(description='True if update succeeded.')
        public Boolean success;

        @InvocableVariable(description='Status outcome message.')
        public String message;
    }

    public class VisitOption {
        @InvocableVariable(description='The Visit ID.')
        public String visitId;

        @InvocableVariable(description='The associated Account ID.')
        public String accountId;

        @InvocableVariable(description='The associated Account Name.')
        public String accountName;

        @InvocableVariable(description='Formatted label.')
        public String label;

        @InvocableVariable(description='Category (e.g. Today, Upcoming).')
        public String category;

        public VisitOption() {}
        public VisitOption(String id, String accName, String lbl, String cat) {
            this.visitId = id;
            this.accountName = accName;
            this.label = lbl;
            this.category = cat;
        }
    }

    @InvocableMethod(
        label='Visit Agent Handler'
        description='Handles all Visit operations for Agents'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'getavailable') {
                res.visits = Visit_Agent_Service.getAvailableVisits();
            } else if (action == 'search') {
                res.visits = Visit_Agent_Service.searchVisits(req.searchQuery);
            } else if (action == 'getstorebrief') {
                res.summary = Visit_Agent_Service.getStoreBrief(req.visitId, req.accountId);
            } else if (action == 'generatesummary') {
                res.visitSummary = Visit_Agent_Service.generateVisitSummary(req.visitId);
                res.visitSummaryObj = Visit_Agent_Service.generateVisitSummaryObj(req.visitId);
            } else if (action == 'updatevisit') {
                res = Visit_Agent_Service.updateVisit(req);
            }
            results.add(res);
        }
        return results;
    }
}