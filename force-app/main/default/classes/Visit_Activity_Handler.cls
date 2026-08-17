/**
 * @description Self-contained Invocable Service for Visit Activities and Assessment Tasks in Visit Intelligence Agentforce agents.
 *              Handles AssessmentTask execution, survey question tracking, and delivery activities
 *              with 0 external helper class dependencies.
 */
global with sharing class Visit_Activity_Handler {

    /**
     * @description Explicit zero-argument default constructor for 2GP serialization.
     */
    global Visit_Activity_Handler() {}

    /**
     * @description Input DTO for Visit_Activity_Handler.
     */
    global class Request {
        @InvocableVariable(required=true description='Action to perform (e.g. getAssessmentTasks, getActivities, getJobsStatus, getDeliveryActivities, getNextSteps).')
        global String actionType;

        @InvocableVariable(description='The name of the agent executing the request.')
        global String agentName;

        @InvocableVariable(description='Domain context.')
        global String domain;

        @InvocableVariable(description='Target Visit ID.')
        global String visitId;

        @InvocableVariable(description='Target Account ID.')
        global String accountId;

        @InvocableVariable(description='Status filter (e.g. Completed, Pending, In Progress).')
        global String statusFilter;

        @InvocableVariable(description='Filter by question or survey type.')
        global String questionOrSurveyFilter;

        @InvocableVariable(description='Exclude option string.')
        global String excludeOption;

        global Request() {}
    }

    /**
     * @description Output DTO for Visit_Activity_Handler.
     */
    global class Response {
        @InvocableVariable(description='True if operation succeeded.')
        global Boolean success;

        @InvocableVariable(description='Outcome message.')
        global String message;

        @InvocableVariable(description='Markdown formatted report or result list.')
        global String summary;

        @InvocableVariable(description='Total assessment activities count.')
        global Integer totalTasks;

        @InvocableVariable(description='Completed assessment activities count.')
        global Integer completedTasks;

        @InvocableVariable(description='Pending assessment activities count.')
        global Integer pendingTasks;

        global Response() {
            this.success = true;
            this.totalTasks = 0;
            this.completedTasks = 0;
            this.pendingTasks = 0;
        }
    }

    @InvocableMethod(
        label='Visit Activity Handler'
        description='Dispatches self-contained Visit Activity and Assessment Task actions for Visit Intelligence agents.'
    )
    global static List<Response> execute(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                String action = req.actionType != null ? req.actionType.toLowerCase().trim() : '';

                if (action == 'getassessmenttasks' || action == 'get_assessment_tasks' || action == 'getactivities' || action == 'get_activities') {
                    res = handleGetAssessmentTasks(req.visitId, req.statusFilter);
                } else if (action == 'getjobsstatus' || action == 'get_jobs_status') {
                    res = handleGetJobsStatus(req.visitId, req.statusFilter);
                } else if (action == 'getdeliveryactivities' || action == 'get_delivery_activities' || action == 'getdeliveries') {
                    res = handleGetDeliveryActivities(req.visitId);
                } else if (action == 'getnextsteps' || action == 'get_next_steps') {
                    res = handleGetNextSteps(req.visitId);
                } else {
                    res.success = false;
                    res.message = 'Unknown Activity action type: ' + req.actionType;
                    res.summary = 'The requested action "' + req.actionType + '" is not supported.';
                }
            } catch (Exception e) {
                res.success = false;
                res.message = 'Error executing activity action: ' + e.getMessage();
                res.summary = 'An error occurred while processing activity request: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    // =========================================================================
    // INLINED DOMAIN LOGIC: VISIT ACTIVITIES (No external helper calls)
    // =========================================================================

    private static Response handleGetAssessmentTasks(String visitId, String statusFilter) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a valid Visit ID to view assessment tasks.';
            return res;
        }

        Boolean hasAssessmentTask = Schema.getGlobalDescribe().containsKey('AssessmentTask');
        if (!hasAssessmentTask) {
            res.success = true;
            res.message = 'No AssessmentTask schema installed.';
            res.summary = 'No Assessment Tasks found for this visit.';
            return res;
        }

        String soql = 'SELECT Id, Name, TaskType, Status, Description, StartTime, EndTime FROM AssessmentTask WHERE ParentId = :visitId';
        if (String.isNotBlank(statusFilter)) {
            soql += ' AND Status = :statusFilter';
        }
        soql += ' ORDER BY CreatedDate ASC LIMIT 25';

        List<SObject> taskList = Database.query(soql);
        res.totalTasks = taskList.size();

        Integer completed = 0;
        Integer pending = 0;

        String sb = '### Visit Assessment Tasks (' + taskList.size() + ' found):\n\n';
        for (SObject t : taskList) {
            String tId = (String) t.get('Id');
            String tName = (String) t.get('Name');
            String taskType = (String) t.get('TaskType');
            String status = (String) t.get('Status');

            if (status == 'Completed') {
                completed++;
                sb += '* ✅ **[' + tName + '](/lightning/r/AssessmentTask/' + tId + '/view)** | Type: ' + (taskType != null ? taskType : 'General') + ' | Status: Completed\n';
            } else {
                pending++;
                sb += '* ⏳ **[' + tName + '](/lightning/r/AssessmentTask/' + tId + '/view)** | Type: ' + (taskType != null ? taskType : 'General') + ' | Status: ' + (status != null ? status : 'Pending') + '\n';
            }
        }

        if (taskList.isEmpty()) {
            sb = 'No Assessment Tasks are currently assigned to this Visit.';
        }

        res.completedTasks = completed;
        res.pendingTasks = pending;
        res.success = true;
        res.message = 'Retrieved ' + taskList.size() + ' Assessment Task(s). Completed: ' + completed + ', Pending: ' + pending;
        res.summary = sb;
        return res;
    }

    private static Response handleGetJobsStatus(String visitId, String statusFilter) {
        return handleGetAssessmentTasks(visitId, statusFilter);
    }

    private static Response handleGetDeliveryActivities(String visitId) {
        Response res = new Response();
        if (String.isBlank(visitId)) {
            res.success = false;
            res.message = 'Visit ID is required.';
            res.summary = 'Please provide a Visit ID to check delivery activities.';
            return res;
        }

        Boolean hasDelivery = Schema.getGlobalDescribe().containsKey('cgcloud__Delivery_Task__c');
        if (!hasDelivery) {
            res.success = true;
            res.message = 'No delivery tasks found.';
            res.summary = 'No special delivery tasks are logged for this Visit.';
            return res;
        }

        String soql = 'SELECT Id, Name, cgcloud__Status__c, cgcloud__Delivery_Note__c FROM cgcloud__Delivery_Task__c WHERE cgcloud__Visit__c = :visitId LIMIT 10';
        List<SObject> delList = Database.query(soql);

        if (delList.isEmpty()) {
            res.success = true;
            res.message = 'No delivery tasks for this visit.';
            res.summary = 'No scheduled delivery tasks found for this Visit.';
            return res;
        }

        String sb = '### Scheduled Delivery Tasks (' + delList.size() + ' found):\n\n';
        for (SObject d : delList) {
            String dId = (String) d.get('Id');
            String dName = (String) d.get('Name');
            String st = (String) d.get('cgcloud__Status__c');
            sb += '* **[' + dName + '](/lightning/r/cgcloud__Delivery_Task__c/' + dId + '/view)** | Status: ' + (st != null ? st : 'Pending') + '\n';
        }

        res.success = true;
        res.message = 'Found ' + delList.size() + ' delivery task(s).';
        res.summary = sb;
        return res;
    }

    private static Response handleGetNextSteps(String visitId) {
        Response res = new Response();
        String sb = '### Recommended Next Actions:\n\n';
        sb += '1. **Execute In-Store Audit**: Complete pending shelf inspections and price compliance checks.\n';
        sb += '2. **Review Replenishment Recommendations**: Check recommended order quantities with the store manager.\n';
        sb += '3. **Log Notes & Wrap Up**: Record any customer feedback and update visit status to Completed.\n';

        res.success = true;
        res.message = 'Generated recommended next steps.';
        res.summary = sb;
        return res;
    }
}
