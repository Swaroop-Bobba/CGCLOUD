public with sharing class GetVisitJobsStatus {

    public class Request {
        @InvocableVariable(label='Visit ID' description='The ID of the Visit record' required=true)
        public String visitId;

        @InvocableVariable(label='Status Filter' description='Filter by: all, answered, pending' required=false)
        public String statusFilter;
    }

    public class Result {
        @InvocableVariable(label='Jobs' description='List of matching visit jobs (questions/surveys)')
        public List<JobStatusInfo> jobs;
    }

    public class JobStatusInfo {
        @InvocableVariable(label='Job ID' description='The ID of the Visit Job record')
        public String jobId;

        @InvocableVariable(label='Question Name' description='The Name of the job definition template')
        public String questionName;

        @InvocableVariable(label='Question Description' description='The description of the question/survey')
        public String questionDescription;

        @InvocableVariable(label='Is Done' description='Whether the question/survey has been answered')
        public Boolean isDone;

        @InvocableVariable(label='Value' description='The raw answer value')
        public String value;

        @InvocableVariable(label='Display Value' description='The formatted display answer value')
        public String displayValue;

        @InvocableVariable(label='Product Name' description='Associated product name if applicable')
        public String productName;

        @InvocableVariable(label='Promotion Name' description='Associated promotion name if applicable')
        public String promotionName;
    }

    @InvocableMethod(
        label='Get Visit Jobs Status'
        description='Retrieves answered or pending visit jobs (questions/surveys) for a specific visit, calculating pending from total template questions.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        Set<Id> visitIds = new Set<Id>();
        for (Request req : requests) {
            if (String.isNotBlank(req.visitId)) {
                visitIds.add((Id)req.visitId);
            }
        }

        if (visitIds.isEmpty()) {
            for (Integer i = 0; i < requests.size(); i++) {
                results.add(new Result());
            }
            return results;
        }

        // Query Visit records to get their template IDs
        Map<Id, Visit> visitsMap = new Map<Id, Visit>([
            SELECT Id, cgcloud__Visit_Template__c
            FROM Visit
            WHERE Id IN :visitIds
            WITH USER_MODE
        ]);

        // Map template IDs to their visits
        Map<Id, Set<Id>> templateToVisits = new Map<Id, Set<Id>>();
        for (Visit v : visitsMap.values()) {
            if (v.cgcloud__Visit_Template__c != null) {
                if (!templateToVisits.containsKey(v.cgcloud__Visit_Template__c)) {
                    templateToVisits.put(v.cgcloud__Visit_Template__c, new Set<Id>());
                }
                templateToVisits.get(v.cgcloud__Visit_Template__c).add(v.Id);
            }
        }

        // Query total planned questions (templates) for these visit templates
        Map<Id, List<cgcloud__Job_DL_Job_Definition_Template__c>> templateToPlannedQuestions = new Map<Id, List<cgcloud__Job_DL_Job_Definition_Template__c>>();
        if (!templateToVisits.isEmpty()) {
            List<cgcloud__Job_DL_Job_Definition_Template__c> plannedList = [
                SELECT cgcloud__Job_Definition_Template__c,
                       cgcloud__Job_Definition_Template__r.Name,
                       cgcloud__Job_Definition_Template__r.cgcloud__Description__c,
                       cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c
                FROM cgcloud__Job_DL_Job_Definition_Template__c
                WHERE cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c IN :templateToVisits.keySet()
                  AND cgcloud__Job_Definition_List__r.cgcloud__Active__c = true
                WITH USER_MODE
            ];
            for (cgcloud__Job_DL_Job_Definition_Template__c item : plannedList) {
                Id visitTemplateId = item.cgcloud__Job_Definition_List__r.cgcloud__Visit_Template__c;
                if (!templateToPlannedQuestions.containsKey(visitTemplateId)) {
                    templateToPlannedQuestions.put(visitTemplateId, new List<cgcloud__Job_DL_Job_Definition_Template__c>());
                }
                templateToPlannedQuestions.get(visitTemplateId).add(item);
            }
        }

        // Query all actual Visit Jobs for the collected visits
        List<cgcloud__Visit_Job__c> allVisitJobs = [
            SELECT Id, Name, cgcloud__Visit__c,
                   cgcloud__Job_Definition_Template__c,
                   cgcloud__Job_Definition_Template__r.Name,
                   cgcloud__Job_Definition_Template_Description__c,
                   cgcloud__Done__c,
                   cgcloud__Value__c,
                   cgcloud__Display_Value__c,
                   cgcloud__Product__r.Name,
                   cgcloud__Promotion__r.Name
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__c IN :visitIds
            WITH USER_MODE
        ];

        // Map visit jobs by Visit ID
        Map<Id, List<cgcloud__Visit_Job__c>> visitToJobs = new Map<Id, List<cgcloud__Visit_Job__c>>();
        for (cgcloud__Visit_Job__c job : allVisitJobs) {
            if (!visitToJobs.containsKey(job.cgcloud__Visit__c)) {
                visitToJobs.put(job.cgcloud__Visit__c, new List<cgcloud__Visit_Job__c>());
            }
            visitToJobs.get(job.cgcloud__Visit__c).add(job);
        }

        // Process requests
        for (Request req : requests) {
            Result res = new Result();
            res.jobs = new List<JobStatusInfo>();
            
            String filter = String.isNotBlank(req.statusFilter) ? req.statusFilter.toLowerCase() : 'all';
            
            if (String.isNotBlank(req.visitId)) {
                Visit v = visitsMap.get(req.visitId);
                Id visitTemplateId = (v != null) ? v.cgcloud__Visit_Template__c : null;
                
                // Get all actual jobs for this visit
                List<cgcloud__Visit_Job__c> actualJobs = visitToJobs.containsKey(req.visitId) ? visitToJobs.get(req.visitId) : new List<cgcloud__Visit_Job__c>();
                
                // Map to track actual jobs by their Template ID
                Map<Id, List<cgcloud__Visit_Job__c>> templateToActualJobs = new Map<Id, List<cgcloud__Visit_Job__c>>();
                for (cgcloud__Visit_Job__c job : actualJobs) {
                    if (job.cgcloud__Job_Definition_Template__c != null) {
                        if (!templateToActualJobs.containsKey(job.cgcloud__Job_Definition_Template__c)) {
                            templateToActualJobs.put(job.cgcloud__Job_Definition_Template__c, new List<cgcloud__Visit_Job__c>());
                        }
                        templateToActualJobs.get(job.cgcloud__Job_Definition_Template__c).add(job);
                    }
                }
                
                List<JobStatusInfo> answeredJobsList = new List<JobStatusInfo>();
                List<JobStatusInfo> pendingJobsList = new List<JobStatusInfo>();
                
                // Process actual jobs first
                for (cgcloud__Visit_Job__c job : actualJobs) {
                    Boolean isDone = (job.cgcloud__Done__c == true || String.isNotBlank(job.cgcloud__Value__c));
                    
                    JobStatusInfo info = new JobStatusInfo();
                    info.jobId = job.Id;
                    info.questionName = job.cgcloud__Job_Definition_Template__r != null ? job.cgcloud__Job_Definition_Template__r.Name : '';
                    info.questionDescription = job.cgcloud__Job_Definition_Template_Description__c;
                    info.value = job.cgcloud__Value__c;
                    info.displayValue = job.cgcloud__Display_Value__c;
                    info.productName = job.cgcloud__Product__r != null ? job.cgcloud__Product__r.Name : '';
                    info.promotionName = job.cgcloud__Promotion__r != null ? job.cgcloud__Promotion__r.Name : '';
                    
                    if (isDone) {
                        info.isDone = true;
                        answeredJobsList.add(info);
                    } else {
                        info.isDone = false;
                        pendingJobsList.add(info);
                    }
                }
                
                // Process planned templates that have no actual job records
                Set<Id> addedPendingTemplateIds = new Set<Id>();
                if (visitTemplateId != null && templateToPlannedQuestions.containsKey(visitTemplateId)) {
                    for (cgcloud__Job_DL_Job_Definition_Template__c planned : templateToPlannedQuestions.get(visitTemplateId)) {
                        Id tId = planned.cgcloud__Job_Definition_Template__c;
                        // If there are no actual jobs for this template, it is completely pending
                        if (!templateToActualJobs.containsKey(tId) && !addedPendingTemplateIds.contains(tId)) {
                            addedPendingTemplateIds.add(tId);
                            
                            JobStatusInfo info = new JobStatusInfo();
                            info.jobId = '';
                            info.questionName = planned.cgcloud__Job_Definition_Template__r.Name;
                            info.questionDescription = planned.cgcloud__Job_Definition_Template__r.cgcloud__Description__c;
                            info.isDone = false;
                            info.value = '';
                            info.displayValue = '';
                            info.productName = '';
                            info.promotionName = '';
                            pendingJobsList.add(info);
                        }
                    }
                }
                
                // Filter and assemble results
                if (filter == 'answered' || filter == 'completed') {
                    res.jobs.addAll(answeredJobsList);
                } else if (filter == 'pending' || filter == 'unanswered') {
                    res.jobs.addAll(pendingJobsList);
                } else { // 'all'
                    res.jobs.addAll(answeredJobsList);
                    res.jobs.addAll(pendingJobsList);
                }
            }
            results.add(res);
        }

        return results;
    }
}
