public with sharing class Visit_Activity_Handler {

    public class Request {
        @InvocableVariable(required=true description='The name of the agent executing the request (e.g., Visit_Activity_Agent).')
        public String agentName;

        @InvocableVariable(required=true description='The type of action to perform: getAvailable, search, getActivities, getJobsStatus, getNextSteps.')
        public String actionType;

        @InvocableVariable(description='The search query for visits.')
        public String searchQuery;

        @InvocableVariable(description='The Visit ID.')
        public String visitId;

        @InvocableVariable(description='Filter status for visit jobs (all, answered, pending).')
        public String statusFilter;

        @InvocableVariable(description='The option label to exclude.')
        public String excludeOption;

        @InvocableVariable(description='Filter by question type: all, question, survey')
        public String questionOrSurveyFilter;
    }

    public class Result {
        @InvocableVariable(description='List of available or matching visits.')
        public List<VisitOption> visits;

        @InvocableVariable(description='List of activities and questions/surveys associated with the visit.')
        public List<ActivityInfo> activities;

        @InvocableVariable(description='List of visit jobs (questions/surveys) with answer status.')
        public List<JobStatusInfo> jobs;

        @InvocableVariable(description='List of next steps options.')
        public List<ItemDetail> itemDetails;
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

        public VisitOption() {}
        public VisitOption(String id, String accId, String accName, String lbl) {
            this.visitId = id;
            this.accountId = accId;
            this.accountName = accName;
            this.label = lbl;
        }
    }

    public class ActivityInfo {
        @InvocableVariable(description='The ID of the Job Definition List record.')
        public String activityId;

        @InvocableVariable(description='The Name of the activity.')
        public String activityName;

        @InvocableVariable(description='The description of the activity.')
        public String description;

        @InvocableVariable(description='List of related questions/surveys.')
        public List<QuestionInfo> questions;
    }

    public class QuestionInfo {
        @InvocableVariable(description='The ID of the Job Definition Template record.')
        public String questionId;

        @InvocableVariable(description='The Name of the question/survey.')
        public String questionName;

        @InvocableVariable(description='The description of the question/survey.')
        public String description;

        @InvocableVariable(description='Is this question mandatory?')
        public Boolean mandatory;
    }

    public class JobStatusInfo {
        @InvocableVariable(description='The ID of the Visit Job record.')
        public String jobId;

        @InvocableVariable(description='The Name of the job definition template.')
        public String questionName;

        @InvocableVariable(description='The description of the question/survey.')
        public String questionDescription;

        @InvocableVariable(description='Whether the question/survey has been answered.')
        public Boolean isDone;

        @InvocableVariable(description='The raw answer value.')
        public String value;

        @InvocableVariable(description='The formatted display answer value.')
        public String displayValue;

        @InvocableVariable(description='Associated product name if applicable.')
        public String productName;

        @InvocableVariable(description='Associated promotion name if applicable.')
        public String promotionName;
    }

    public class ItemDetail {
        @InvocableVariable(description='The text label of the option.')
        public String itemName;

        @InvocableVariable(description='The description of the option.')
        public String itemDescriptionText;

        @InvocableVariable(description='The image URL of the option.')
        public String itemImageUrl;

        @InvocableVariable(description='The MIME type of the option image.')
        public String itemMimeType;

        public ItemDetail() {}
        public ItemDetail(String itemName, String itemDescriptionText) {
            this.itemName = itemName;
            this.itemDescriptionText = itemDescriptionText;
            this.itemImageUrl = null;
            this.itemMimeType = null;
        }
    }

    @InvocableMethod(
        label='Visit Activity Agent Handler'
        description='Handles all Visit Activity and Survey operations for Agents'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

            if (action == 'getavailable') {
                res.visits = Visit_Activity_Service.getAvailableVisits();
            } else if (action == 'search') {
                res.visits = Visit_Activity_Service.searchVisits(req.searchQuery);
            } else if (action == 'getactivities') {
                res.activities = Visit_Activity_Service.getVisitActivities(req.visitId, req.questionOrSurveyFilter);
            } else if (action == 'getjobsstatus') {
                res.jobs = Visit_Activity_Service.getVisitJobsStatus(req.visitId, req.statusFilter, req.questionOrSurveyFilter);
            } else if (action == 'getnextsteps') {
                res.itemDetails = Visit_Activity_Service.getNextStepsOptions(req.excludeOption);
            }
            results.add(res);
        }
        return results;
    }
}
